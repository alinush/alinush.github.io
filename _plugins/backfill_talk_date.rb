# Every _talks/ document has talk_date (the field /talks itself sorts by),
# but a talk-only entry has no separate publication "date" the way
# posts/papers/projects do. The home page's "Updates" feed needs to sort
# posts+papers+talks+projects together with one common field name, and
# Liquid's `sort` filter takes a literal field name — it can't fall back to
# a different field per item. Rather than hand-duplicating
# `date: <same value as talk_date>` into every _talks/*.md file (easy to
# forget to keep in sync), backfill it here once, automatically, so `date`
# is reliably present on every collection by the time any page renders.
#
# :site, :pre_render (not :documents, :pre_render) deliberately: the talks
# collection is `output: false` (it's data consumed by other pages, not
# rendered to its own URL), and per-document hooks are only guaranteed to
# fire for documents that go through their own render pass. Iterating the
# collection directly at the site level sidesteps that question entirely.
Jekyll::Hooks.register :site, :pre_render do |site|
  talks = site.collections["talks"]
  next unless talks

  talks.docs.each do |doc|
    doc.data["date"] ||= doc.data["talk_date"]
  end
end
