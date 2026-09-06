#!/bin/bash
#
# Runs *inside* the sbx sandbox; not meant to be run on the host directly.
# Invoked by check-links.sh as: sandbox-check-links.sh <mode>
# <mode> is "--internal-only" to skip external link checks, or empty to
# check both internal and external links.

set -e
# So `bundle exec htmlproofer ... | awk ...` below fails the script (and
# reports htmlproofer's exit code, not awk's) if the link check itself
# fails, not just if the awk filter does.
set -o pipefail

cd "$(dirname "$0")"

mode="$1"

if ! command -v bundle >/dev/null 2>&1; then
    echo "ERROR: no bundler in this sandbox, so it was most likely created from an" >&2
    echo "older template. The image is fixed when the sandbox is created, so the" >&2
    echo "sandbox has to be deleted and recreated:" >&2
    echo >&2
    echo "    sbx rm alinush-github-io-jekyll" >&2
    exit 1
fi

# Same gem cache location as sandbox-serve.sh, so this shares its installed
# gems instead of duplicating them.
export BUNDLE_PATH="$HOME/.bundle/$(basename "$PWD")"

# jekyll-text-theme.gemspec shells out to "git ls-files", and git refuses to
# run in a tree owned by a different UID than the sandbox user, which it is
# here.
git config --global --add safe.directory "$PWD" 2>/dev/null || true

bundle install

# See sandbox-serve.sh for why this has to go.
rm -f _site/drafts/refs.md

echo ">>> Building site..."
bundle exec jekyll build

htmlproofer_flags=(
    --allow-hash-href
    # The theme's own footer links to http://jekyllrb.com/ (its own choice,
    # not something specific to this site's content) and has plain <a>
    # tags with no href used purely as JS click targets (e.g. the sidebar
    # toggle button) — neither is an actual broken link worth flagging.
    # (Thor-style boolean flag negation — "--enforce-https false" is parsed
    # as two separate args, with "false" landing as a bogus positional
    # directory argument and crashing the CLI.)
    --no-enforce-https
    --allow-missing-href
    # Missing alt text is an accessibility lint, not a broken link.
    --ignore-missing-alt
    # Some external hosts (LinkedIn, certain journal sites, etc.) reject
    # Typhoeus's default user-agent outright — a browser-like one avoids
    # false positives from that alone.
    --typhoeus '{"headers":{"User-Agent":"Mozilla/5.0 (compatible; html-proofer)"}}'
)
if [ "$mode" = "--internal-only" ]; then
    htmlproofer_flags+=(--disable-external)
else
    echo ">>> Checking internal AND external links — this can take a while,"
    echo ">>> and needs outbound network access to every external host linked"
    echo ">>> from the site. If a host gets blocked, run on the host:"
    echo ">>>   sbx policy allow network <domain>"
    echo ">>> or re-run with --internal-only to skip external checks entirely."
fi

# html-proofer's own text report repeats "* At <file>:<line>:" above every
# single failure, even when several failures share the same file, and pads
# each one with blank lines. This regroups it as one file-path header
# followed by its own failures indented underneath, with no blank lines.
group_by_file='
{
  line = $0
  gsub(/\r$/, "", line)
  if (line ~ /^[[:space:]]*$/) next

  if (line ~ /^\*[[:space:]]+At /) {
    file = line
    sub(/^\*[[:space:]]+At /, "", file)
    sub(/:[0-9]+:[[:space:]]*$/, "", file)
    if (file != lastfile) {
      print file
      lastfile = file
    }
    in_report = 1
    next
  }

  if (line ~ /^HTML-Proofer/) {
    in_report = 0
    print line
    next
  }

  if (in_report) {
    msg = line
    sub(/^[[:space:]]+/, "", msg)
    print "  " msg
    next
  }

  print line
}
'

# 2>&1 is load-bearing: html-proofer's failure report goes to stderr, not
# stdout, so without merging the streams the awk filter below only ever
# sees an empty stdin while the real (unfiltered) report leaks straight
# through the inherited stderr fd.
bundle exec htmlproofer ./_site "${htmlproofer_flags[@]}" 2>&1 | awk "$group_by_file"
