#!/usr/bin/env bash
# Compiles all .tex files in this directory to .png via pdflatex + ghostscript.
# Usage: cd pictures/binary-trees && ./build.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

for tex in *.tex; do
    [ -f "$tex" ] || continue
    base="${tex%.tex}"
    echo "Building $tex -> ${base}.png ..."
    pdflatex -interaction=nonstopmode "$tex" >/dev/null 2>&1
    gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r300 -sOutputFile="${base}.png" "${base}.pdf" >/dev/null 2>&1
    rm -f "${base}.aux" "${base}.log" "${base}.pdf"
    echo "  Done."
done

echo "All done."
