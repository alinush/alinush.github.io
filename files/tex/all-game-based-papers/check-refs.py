#!/usr/bin/env python3
"""Check that every citation in refs.bib points at the paper it claims to.

For each entry, the title recorded in the .bib is compared against the title the
source itself reports: Crossref for `doi = {...}`, the ePrint abstract page for
`url = {https://eprint.iacr.org/YYYY/NNN}`. A wrong DOI or a transposed ePrint
number is the one mistake in a reading list that silently sends the reader to
the wrong paper, and it is invisible in the rendered PDF -- hence this script.

Usage: python3 check-refs.py refs.bib   (or: make check)
"""

import html
import json
import re
import sys
import time
import urllib.error
import urllib.request

UA = "all-game-based-papers-refcheck/1.0"
# Comparison is on lowercase alphanumerics only: the .bib deliberately differs
# from the source in capitalization, braces, LaTeX accents and en-dashes.
NORMALIZE = re.compile(r"[^a-z0-9]+")


def fetch(url, accept=None, tries=5):
    """GET with backoff: ePrint starts answering 429 after ~30 requests."""
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    if accept:
        req.add_header("Accept", accept)
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt == tries - 1:
                raise
            time.sleep(15 * (attempt + 1))


def normalize(s):
    s = html.unescape(s)
    s = re.sub(r"\\[a-zA-Z]+", "", s)        # \emph, \'{e}, ...
    return NORMALIZE.sub("", s.lower())


def parse_bib(path):
    """Minimal .bib reader: enough for this file, not a general parser."""
    text = open(path, encoding="utf-8").read()
    text = re.sub(r"^\s*%.*$", "", text, flags=re.M)
    entries = []
    for m in re.finditer(r"@(\w+)\s*\{\s*([^,]+),(.*?)\n\}", text, re.S):
        # The trailing "\n" the entry regex ate is what terminates the last
        # field; put it back. re.S so values wrapped over two lines (most
        # titles here) parse, and the required ",\n" is what keeps the
        # non-greedy value from stopping early on a brace inside an accent
        # like Sch{\"a}ge.
        body = m.group(3) + "\n"
        fields = {}
        for fm in re.finditer(r"(\w+)\s*=\s*\{(.*?)\}\s*,\s*\n", body, re.S):
            fields[fm.group(1).lower()] = " ".join(fm.group(2).split())
        entries.append((m.group(2).strip(), fields))
    return entries


def source_title(fields):
    """(kind, url, title-as-the-source-reports-it) or None if nothing to check."""
    if "doi" in fields:
        doi = fields["doi"]
        url = "https://api.crossref.org/works/" + doi
        data = json.loads(fetch(url))["message"]
        return "doi", doi, (data.get("title") or [""])[0]
    url = fields.get("url", "")
    if "eprint.iacr.org" in url:
        page = fetch(url)
        m = re.search(r"<title>(.*?)</title>", page, re.S)
        return "eprint", url.rsplit("/", 2)[-2] + "/" + url.rsplit("/", 1)[-1], \
            (m.group(1).strip() if m else "")
    return None


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "refs.bib"
    bad = unchecked = 0
    for key, fields in parse_bib(path):
        title = fields.get("title", "")
        try:
            found = source_title(fields)
        except (urllib.error.URLError, json.JSONDecodeError, TimeoutError) as e:
            print(f"?? {key:<16} fetch failed: {e}")
            unchecked += 1
            continue
        if found is None:
            print(f"-- {key:<16} no doi or ePrint url to check")
            unchecked += 1
            continue
        kind, ident, remote = found
        if not remote:
            print(f"?? {key:<16} {kind} {ident}: source returned no title")
            unchecked += 1
        elif normalize(title) in normalize(remote) or \
                normalize(remote) in normalize(title):
            print(f"ok {key:<16} {kind} {ident}")
        else:
            bad += 1
            print(f"!! {key:<16} {kind} {ident}")
            print(f"       bib: {title}")
            print(f"    source: {html.unescape(remote)}")
        time.sleep(1)  # both APIs throttle aggressively

    print(f"\n{bad} mismatch(es), {unchecked} unchecked")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
