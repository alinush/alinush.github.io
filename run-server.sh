#!/bin/sh

sandbox_name="alinush-github-io-jekyll"

# Ships ruby, bundler, git and a compiler, so nothing has to be installed at
# startup. Jekyll itself comes from the Gemfile via "bundle install".
image="ruby:3.2"

usage() {
    echo "Usage: $0 [-s|--skip-urls] [port]"
    echo
    echo "Launches the website in an sbx sandbox at http://localhost:<port>"
    echo "<port> defaults to 4000"
    echo
    echo "  -s, --skip-urls   Skip the broken-link check and start the server"
    echo "                    right away"
    echo
    echo "Reuses the sandbox named '$sandbox_name' (built from the"
    echo "'$image' image) across runs, so the gems installed by the first"
    echo "run persist and later runs start fast. To start over from scratch:"
    echo
    echo "    sbx rm $sandbox_name"
    echo
    echo "Note: the image and the published port are both fixed when the sandbox"
    echo "is created, so changing <port> also requires deleting it first."
}

port=""
skip_urls=false

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit
            ;;
        -s|--skip-urls)
            skip_urls=true
            ;;
        -*)
            echo "ERROR: unknown option '$1'" >&2
            echo >&2
            usage >&2
            exit 1
            ;;
        *)
            if [ -n "$port" ]; then
                echo "ERROR: too many arguments ('$1'); only one <port> is accepted." >&2
                exit 1
            fi
            port="$1"
            ;;
    esac
    shift
done

port="${port:-4000}"

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
# The link check runs first (internal-only: fast, no network dependency) as
# a warning, not a gate — its exit code is deliberately ignored (plain ";",
# not "&&") so a broken anchor somewhere never blocks starting the dev
# server, it just prints ahead of it. --skip-urls drops it entirely, for
# when even that wait is more than you want between edit and reload.
serve_cmd="exec bash ./sandbox-serve.sh '$port' '$JEKYLL_TRACE' '$sandbox_name'"
if [ "$skip_urls" = false ]; then
    serve_cmd="bash ./sandbox-check-links.sh --internal-only; $serve_cmd"
else
    echo ">>> Skipping the broken-link check (--skip-urls)."
fi

# NOTE: args after "--" are arguments to the agent itself, and the "shell" agent
# already is bash, so this runs "bash -c <cmd>". Do NOT prepend another "bash".
exec sbx run "$@" -- -c "$serve_cmd"
