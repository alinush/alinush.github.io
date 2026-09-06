#!/bin/sh

sandbox_name="alinush-github-io-jekyll"

# Same image/sandbox as run-server.sh, so this reuses its already-installed
# gems (bundle install is incremental) instead of paying for a fresh
# install every time.
image="ruby:3.2"

usage() {
    echo "Usage: $0 --internal-only|--external-only|--all"
    echo
    echo "Builds the site and checks it for broken links using html-proofer"
    echo "(internal) and curl (external), inside the same sbx sandbox"
    echo "'$sandbox_name' that run-server.sh uses (created if it doesn't"
    echo "exist yet)."
    echo
    echo "  --internal-only  skip external link checks: faster, and avoids"
    echo "                   needing outbound network access to arbitrary"
    echo "                   external hosts from the sandbox (see the"
    echo "                   network-policy notes this prints if an"
    echo "                   external check gets blocked)"
    echo "  --external-only  skip internal link checks"
    echo "  --all            run both"
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
    usage
    exit
fi

case "$1" in
    --internal-only | --external-only | --all)
        ;;
    "")
        echo "ERROR: missing argument." >&2
        usage >&2
        exit 1
        ;;
    *)
        echo "ERROR: unrecognized argument '$1'." >&2
        usage >&2
        exit 1
        ;;
esac

mode="$1"

if ! command -v sbx >/dev/null 2>&1; then
    echo "ERROR: 'sbx' not found on PATH. This script runs html-proofer inside an sbx sandbox." >&2
    exit 1
fi

# Same re-attach-or-create dance as run-server.sh, and the same sandbox name,
# so a link check can run whether or not the dev server is currently up.
if sbx ports "$sandbox_name" >/dev/null 2>&1; then
    set -- --name "$sandbox_name"
else
    echo ">>> Creating sandbox '$sandbox_name' from '$image'..."
    set -- shell --name "$sandbox_name" --template "$image" -p "4000:4000"
fi

exec sbx run "$@" -- \
    -c "exec bash ./sandbox-check-links.sh '$mode'"
