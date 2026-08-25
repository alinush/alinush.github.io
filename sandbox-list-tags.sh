#!/bin/bash
#
# Runs *inside* the sbx sandbox; not meant to be run on the host directly.
# Invoked by list-tags.sh.
#
# The sandbox is built from the ruby image (see run-server.sh), which ships
# python3 but not pip3 or pyyaml, so this script installs whatever's missing
# here on first run. apt/pip state persists in the sandbox across runs, so
# later runs are fast.

set -e

cd "$(dirname "$0")"

# Check python3 and pip3 independently: this image ships python3 already, so
# gating both installs on "is python3 missing" (as an earlier version of this
# script did) skips installing pip3 entirely once python3 is found present.
need_apt=""
command -v python3 >/dev/null 2>&1 || need_apt="$need_apt python3"
command -v pip3 >/dev/null 2>&1 || need_apt="$need_apt python3-pip"

if [ -n "$need_apt" ]; then
    echo ">>> Installing$need_apt..." >&2
    apt-get update -qq
    apt-get install -y -qq $need_apt
fi

if ! python3 -c "import yaml" 2>/dev/null; then
    echo ">>> Installing PyYAML..." >&2
    # Debian's system pip refuses a plain install ("externally-managed-environment",
    # PEP 668) on newer images; retry with the override flag if that happens.
    pip3 install --quiet pyyaml 2>/dev/null \
        || pip3 install --quiet --break-system-packages pyyaml
fi

exec python3 list-tags.py
