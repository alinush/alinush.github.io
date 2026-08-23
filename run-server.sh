#!/bin/sh

sandbox_name="alinush-github-io-jekyll"

# Ships ruby, bundler, git and a compiler, so nothing has to be installed at
# startup. Jekyll itself comes from the Gemfile via "bundle install".
image="ruby:3.2"

if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo "Usage: $0 [port]"
    echo
    echo "Launches the website in an sbx sandbox at http://localhost:<port>"
    echo "<port> defaults to 4000"
    echo
    echo "Reuses the sandbox named '$sandbox_name' (built from the"
    echo "'$image' image) across runs, so the gems installed by the first"
    echo "run persist and later runs start fast. To start over from scratch:"
    echo
    echo "    sbx rm $sandbox_name"
    echo
    echo "Note: the image and the published port are both fixed when the sandbox"
    echo "is created, so changing <port> also requires deleting it first."
    exit
fi

port="${1:-4000}"

if ! command -v sbx >/dev/null 2>&1; then
    echo "ERROR: 'sbx' not found on PATH. This script runs the Jekyll server inside an sbx sandbox." >&2
    exit 1
fi

# --template and --publish are only accepted while creating a sandbox: passing
# --template when re-attaching is a hard error, and --publish is ignored with a
# warning. So only pass them on the run that actually creates the sandbox.
if sbx ports "$sandbox_name" >/dev/null 2>&1; then
    echo ">>> Re-attaching to sandbox '$sandbox_name'. Its image and published"
    echo ">>> port were fixed when it was created; 'sbx rm $sandbox_name'"
    echo ">>> first if you need to change either."
    set -- --name "$sandbox_name"
else
    echo ">>> Creating sandbox '$sandbox_name' from '$image'..."
    set -- shell --name "$sandbox_name" --template "$image" -p "$port:$port"
fi

# The repo is mounted into the sandbox, so the server is driven by
# sandbox-serve.sh in this same directory rather than by an inlined script.
#
# NOTE: args after "--" are arguments to the agent itself, and the "shell" agent
# already is bash, so this runs "bash -c <cmd>". Do NOT prepend another "bash".
exec sbx run "$@" -- \
    -c "exec bash ./sandbox-serve.sh '$port' '$JEKYLL_TRACE' '$sandbox_name'"
