#!/bin/bash
#
# Runs *inside* the sbx sandbox; not meant to be run on the host directly.
# Invoked by check-links.sh as: sandbox-check-links.sh <mode>
# <mode> is "--internal-only", "--external-only", or "--all".

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

if [ "$mode" != "--external-only" ]; then
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

    # Deduplicated URLs, reordered round-robin by host: a straight
    # dedupe still leaves every eprint.iacr.org (or similar) URL adjacent
    # to every other one from that host, which is exactly the back-to-back
    # request pattern that trips a host's rate limiter. Tagging each URL
    # with its host and having awk take one URL per host per pass (in
    # first-seen host order) spaces same-host requests apart by roughly
    # (distinct host count) other requests instead.
    mapfile -t urls < <(
        cut -f2 "$links_tsv" | sort -u \
        | sed -E 's#^[a-zA-Z]+://([^/]+).*#\1\t&#' \
        | awk -F'\t' '
            {
              host = $1; url = $2
              c = ++count[host]
              bucket[host, c] = url
              if (!(host in seen)) { order[++nhosts] = host; seen[host] = 1 }
            }
            END {
              maxc = 0
              for (h in count) if (count[h] > maxc) maxc = count[h]
              for (i = 1; i <= maxc; i++)
                for (d = 1; d <= nhosts; d++) {
                  h = order[d]
                  if (i <= count[h]) print bucket[h, i]
                }
            }'
    )
    total="${#urls[@]}"

    # A real browser UA instead of an honest bot-style one: several hosts
    # (LinkedIn, Cloudflare-fronted sites returning 403s, etc.) block or
    # challenge anything that self-identifies as a script/crawler.
    user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
    spinner_frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

    # Runs curl against $1 (url) with method $2 (HEAD or GET) in the
    # background, animating a spinner on the current line via \r while
    # it's in flight (a plain foreground curl call blocks, so there's
    # nothing to animate around otherwise). Leaves the resulting HTTP
    # status code (or empty, if curl couldn't complete the request at
    # all) in $curl_status.
    spin_curl() {
        local url="$1" method="$2" label="$3" status_file pid i=0
        status_file="$(mktemp)"
        if [ "$method" = "HEAD" ]; then
            curl -o /dev/null -s -w '%{http_code}' --head --location \
                --user-agent "$user_agent" --max-time 15 -- "$url" \
                > "$status_file" 2>/dev/null &
        else
            curl -o /dev/null -s -w '%{http_code}' --location \
                --user-agent "$user_agent" --max-time 15 -- "$url" \
                > "$status_file" 2>/dev/null &
        fi
        pid=$!
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r\033[K%s %s' "${spinner_frames[$((i % ${#spinner_frames[@]}))]}" "$label"
            i=$((i + 1))
            sleep 0.1
        done
        wait "$pid" 2>/dev/null || true
        curl_status="$(cat "$status_file")"
        rm -f "$status_file"
    }

    declare -A broken        # url -> http status (or "no response")
    declare -A rate_limited  # url -> 429
    declare -A forbidden     # url -> 403
    n=0
    for url in "${urls[@]}"; do
        n=$((n + 1))
        label="[$n/$total] $url"

        spin_curl "$url" HEAD "$label"
        status="$curl_status"
        # 429 isn't retried with GET: that would just be a second request
        # at the same host that already asked us to back off.
        if { [ -z "$status" ] || [ "$status" = "000" ] || [ "$status" -ge 400 ]; } && [ "$status" != "429" ]; then
            # Some servers reject HEAD outright — a real GET is the only
            # way to be sure before concluding it's actually broken.
            spin_curl "$url" GET "$label"
            status="$curl_status"
        fi

        if [ -n "$status" ] && [ "$status" != "000" ] && [ "$status" -lt 400 ]; then
            printf '\r\033[K\033[32m✓\033[0m %s\n' "$label"
        elif [ "$status" = "429" ]; then
            printf '\r\033[K\033[33m⚠\033[0m %s (HTTP 429)\n' "$label"
            rate_limited["$url"]=429
        elif [ "$status" = "403" ]; then
            # Often anti-bot/anti-scraper blocking (Cloudflare challenges,
            # etc.) triggered by curl's user-agent or lack of a real
            # browser session — not necessarily an actually-dead link, so
            # it's kept separate from "broken" the same way 429 is.
            printf '\r\033[K\033[33m⚠\033[0m %s (HTTP 403)\n' "$label"
            forbidden["$url"]=403
        else
            printf '\r\033[K\033[31m✗\033[0m %s (HTTP %s)\n' "$label" "${status:-no response}"
            broken["$url"]="${status:-no response}"
        fi
    done

    if [ "${#broken[@]}" -gt 0 ]; then
        overall_status=1
    fi

    # Built up as plain text (not printed straight away) so the exact same
    # content can go both to the terminal and, for --external-only, to the
    # log file below — without re-running anything or piping through tee,
    # which would put the "overall_status=1" above in a subshell and lose
    # it.
    report=""
    if [ "${#rate_limited[@]}" -gt 0 ]; then
        report+=$'\n'"Rate-limited (HTTP 429) — the host asked us to back off, this doesn't mean the link is actually broken:"$'\n'
        for url in "${!rate_limited[@]}"; do
            report+="$url"$'\n'
            report+="$(awk -F'\t' -v u="$url" '$2==u {print "  " $1}' "$links_tsv")"$'\n'
        done
    fi
    if [ "${#forbidden[@]}" -gt 0 ]; then
        report+=$'\n'"Forbidden (HTTP 403) — often anti-bot blocking on automated requests, not necessarily broken:"$'\n'
        for url in "${!forbidden[@]}"; do
            report+="$url"$'\n'
            report+="$(awk -F'\t' -v u="$url" '$2==u {print "  " $1}' "$links_tsv")"$'\n'
        done
    fi
    if [ "${#broken[@]}" -gt 0 ]; then
        report+=$'\n'"Broken external links:"$'\n'
        for url in "${!broken[@]}"; do
            report+="$url (HTTP ${broken[$url]})"$'\n'
            report+="$(awk -F'\t' -v u="$url" '$2==u {print "  " $1}' "$links_tsv")"$'\n'
        done
    fi

    if [ -n "$report" ]; then
        printf '%s' "$report"
    fi

    # --external-only always writes a log, even when nothing was found —
    # "always store its results" per the ask, not just when there's
    # something to report.
    if [ "$mode" = "--external-only" ]; then
        log_file="$(date +%Y-%m-%d)-broken-external-urls.log"
        if [ -n "$report" ]; then
            printf '%s' "$report" > "$log_file"
        else
            echo "No broken, forbidden (403), or rate-limited (429) external links found." > "$log_file"
        fi
        echo
        echo "Results saved to $log_file"
    fi

    rm -f "$links_tsv"
    trap - EXIT
fi

exit "$overall_status"
