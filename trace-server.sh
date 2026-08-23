#!/bin/sh

# Same as run-server.sh, but runs "jekyll serve --trace" for full backtraces.
# Shares the same sandbox, so the toolchain/gems are not installed twice.

scriptdir=$(cd $(dirname $0); pwd -P)

if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo "Usage: $0 [port]"
    echo
    echo "Launches the website in an sbx sandbox at http://localhost:<port>,"
    echo "with jekyll's --trace enabled. See run-server.sh --help for details."
    exit
fi

JEKYLL_TRACE=--trace
export JEKYLL_TRACE
exec "$scriptdir/run-server.sh" "$@"
