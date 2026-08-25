#!/bin/sh

sandbox_name="alinush-github-io-jekyll"

if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo "Usage: $0"
    echo
    echo "Prints all blog tags by running list-tags.py inside the"
    echo "'$sandbox_name' sbx sandbox (the same one run-server.sh uses),"
    echo "installing python3/pyyaml there on first run if needed."
    echo
    echo "Requires that sandbox to already exist: run ./run-server.sh first."
    echo "(Not creating it here, since run-server.sh fixes the image and"
    echo "published port at creation time, and this script has no reason to"
    echo "duplicate or diverge from those.)"
    exit
fi

if ! command -v sbx >/dev/null 2>&1; then
    echo "ERROR: 'sbx' not found on PATH. This script runs list-tags.py inside an sbx sandbox." >&2
    exit 1
fi

if ! sbx ports "$sandbox_name" >/dev/null 2>&1; then
    echo "ERROR: sandbox '$sandbox_name' isn't running. Start it first with ./run-server.sh" >&2
    exit 1
fi

# The repo is mounted into the sandbox, so this is driven by
# sandbox-list-tags.sh in this same directory rather than an inlined script.
#
# NOTE: args after "--" are arguments to the agent itself, and the "shell" agent
# already is bash, so this runs "bash -c <cmd>". Do NOT prepend another "bash".
exec sbx run --name "$sandbox_name" -- \
    -c "exec bash ./sandbox-list-tags.sh"
