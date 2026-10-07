require "cgi"

# Wikipedia-style "[citation needed]" markers, for deferring a citation to later.
#
# In a post's Markdown, write either:
#
#   Some claim.[^citation-needed]
#   Some claim.[^citation-needed: maybe the Groth16 paper?]
#
# The optional note after the colon is shown as a hover tooltip, as a reminder
# of what to cite. The marker looks like a kramdown footnote reference on
# purpose, but it is rewritten here into a styled <sup> before kramdown runs,
# so no footnote definition is needed (and none is generated). Styled by
# .citation-needed in _sass/custom.scss.
#
# Fenced code blocks are left untouched, so the syntax itself can be shown in
# posts. To find all outstanding ones: grep -rn 'citation-needed' _posts
module CitationNeeded
  MARKER = /\[\^citation-needed(?::\s*([^\]]*?))?\s*\]/
  FENCE = /^(```|~~~).*?^\1[ \t]*$/m

  def self.render(note)
    title = note.nil? || note.empty? ? "Citation needed" : "Citation needed: #{note}"
    %(<sup class="citation-needed" title="#{CGI.escapeHTML(title)}">[<i>citation needed</i>]</sup>)
  end

  # Rewrites markers everywhere except inside fenced code blocks.
  def self.rewrite(content)
    out = +""
    last = 0
    content.scan(FENCE) do
      m = Regexp.last_match
      out << content[last...m.begin(0)].gsub(MARKER) { render(Regexp.last_match(1)) }
      out << m[0]
      last = m.end(0)
    end
    out << content[last..].gsub(MARKER) { render(Regexp.last_match(1)) }
  end
end

Jekyll::Hooks.register [:documents, :pages], :pre_render do |doc|
  next unless doc.content&.include?("[^citation-needed")
  next unless [".md", ".markdown"].include?(doc.extname)

  doc.content = CitationNeeded.rewrite(doc.content)
end
