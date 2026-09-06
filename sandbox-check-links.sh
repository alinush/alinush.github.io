#!/bin/bash
#
# Runs *inside* the sbx sandbox; not meant to be run on the host directly.
# Invoked by check-links.sh as: sandbox-check-links.sh <mode>
# <mode> is "--internal-only" to skip external link checks, or empty to
# check both internal and external links.

set -e
# So `bundle exec htmlproofer ... | awk ...` below reports htmlproofer's
# exit code, not awk's (which is what "$?" — and "if !" — would see
# otherwise, and awk essentially always succeeds regardless of whether
# html-proofer found broken links).
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

overall_status=0

# --- Internal links/anchors/images: html-proofer -----------------------
#
# External checking used to also go through html-proofer (via Typhoeus),
# but that turned into a losing battle: no per-host rate limiting (so
# heavily-linked hosts 429'd), and no way to get clean live progress out of
# it (html-proofer's own logging never prints per-request lines, and
# Typhoeus's verbose curl tracing — the only layer that does — turned out
# to have no consistent prefix to filter it by once it's going through this
# environment's proxy, which just produced a wall of TLS/header/cookie
# noise). html-proofer stays for internal checks, where none of that
# applies, and is disabled here for external ones, which are handled
# separately below instead.
htmlproofer_flags=(
    --disable-external
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
)

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

echo ">>> Checking internal links..."
# 2>&1 is load-bearing: html-proofer's failure report goes to stderr, not
# stdout, so without merging the streams the awk filter below only ever
# sees an empty stdin while the real (unfiltered) report leaks straight
# through the inherited stderr fd. The "if !" (rather than letting set -e
# abort here) is deliberate: a broken internal link shouldn't skip the
# external check below, it should just also fail the script at the end.
if ! bundle exec htmlproofer ./_site "${htmlproofer_flags[@]}" 2>&1 | awk "$group_by_file"; then
    overall_status=1
fi

# --- External links: a plain, deduplicated curl loop --------------------
if [ "$mode" != "--internal-only" ]; then
    echo
    echo ">>> Checking external links — this can take a while, and needs"
    echo ">>> outbound network access to every external host linked from the"
    echo ">>> site. If a host gets blocked, run on the host:"
    echo ">>>   sbx policy allow network <domain>"
    echo ">>> or re-run with --internal-only to skip this step entirely."
    echo

    links_tsv="$(mktemp)"
    trap 'rm -f "$links_tsv"' EXIT

    # file<TAB>url for every external href in the built site, so a broken
    # URL can be traced back to whichever page(s) link to it.
    grep -rHoE 'href="https?://[^"]+"' _site --include="*.html" \
        | sed -E 's/^([^:]*):href="/\1\t/; s/"$//' \
        > "$links_tsv"

    mapfile -t urls < <(cut -f2 "$links_tsv" | sort -u)
    total="${#urls[@]}"
    declare -A broken   # url -> http status (or "no response")
    n=0
    for url in "${urls[@]}"; do
        n=$((n + 1))
        echo ">>> [$n/$total] Checking: $url"
        status="$(curl -o /dev/null -s -w '%{http_code}' --head --location \
            --user-agent 'Mozilla/5.0 (compatible; html-proofer)' \
            --max-time 15 -- "$url" || true)"
        if [ -z "$status" ] || [ "$status" = "000" ] || [ "$status" -ge 400 ]; then
            # Some servers reject HEAD outright — a real GET is the only
            # way to be sure before concluding it's actually broken.
            status="$(curl -o /dev/null -s -w '%{http_code}' --location \
                --user-agent 'Mozilla/5.0 (compatible; html-proofer)' \
                --max-time 15 -- "$url" || true)"
        fi
        if [ -z "$status" ] || [ "$status" = "000" ] || [ "$status" -ge 400 ]; then
            echo "    -> BROKEN (HTTP ${status:-no response})"
            broken["$url"]="${status:-no response}"
        fi
    done

    if [ "${#broken[@]}" -gt 0 ]; then
        overall_status=1
        echo
        echo "Broken external links:"
        for url in "${!broken[@]}"; do
            echo "$url (HTTP ${broken[$url]})"
            awk -F'\t' -v u="$url" '$2==u {print "  " $1}' "$links_tsv"
        done
    fi

    rm -f "$links_tsv"
    trap - EXIT
fi

exit "$overall_status"
