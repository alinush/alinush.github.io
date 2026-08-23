#!/bin/bash
#
# Runs *inside* the sbx sandbox; not meant to be run on the host directly.
# Invoked by run-server.sh as: sandbox-serve.sh <port> <trace-flag> <sandbox-name>
#
# The sandbox is built from the ruby image (see run-server.sh), which already
# ships ruby, bundler, git and a compiler, so there is nothing to install here.

set -e

cd "$(dirname "$0")"

port="${1:-4000}"
trace="$2"
sandbox_name="$3"

if ! command -v bundle >/dev/null 2>&1; then
    echo "ERROR: no bundler in this sandbox, so it was most likely created from an" >&2
    echo "older template. The image is fixed when the sandbox is created, so the" >&2
    echo "sandbox has to be deleted and recreated:" >&2
    echo >&2
    echo "    sbx rm ${sandbox_name:-<sandbox-name>}" >&2
    exit 1
fi

# Install gems inside the container rather than into the mounted repo, so the
# host working tree stays clean.
export BUNDLE_PATH="$HOME/.bundle/$(basename "$PWD")"

# jekyll-text-theme.gemspec shells out to "git ls-files", and git refuses to run
# in a tree owned by a different UID than the sandbox user, which it is here.
git config --global --add safe.directory "$PWD" 2>/dev/null || true

bundle install

# NOTE(Alin): For some reason, jekyll gets confused when overwriting the symlink in _site/drafts/refs.md, so I have to delete it here

rm -f _site/drafts/refs.md

# Jekyll binds only the loopback interface by default, which the published port
# cannot reach, so a --host is required. It has to be '*' rather than the more
# obvious 0.0.0.0: sbx publishes the port on both 127.0.0.1 and [::1], but
# WEBrick sets IPV6_V6ONLY, so 0.0.0.0 listens on IPv4 only and '::' on IPv6
# only. Either one leaves half of the published port dead, which breaks
# http://localhost (macOS resolves it to ::1 first). '*' binds both families,
# plus eth0, which is what the port forwarder actually connects to.
exec bundle exec jekyll serve $trace -P "$port" --host '*'
