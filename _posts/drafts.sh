#!/bin/bash

scriptdir=$(cd $(dirname $(readlink -f $0)); pwd -P)

(
    cd $scriptdir/
    grep '^published: false' *.md | cut -f1 -d:
)

if [ -d "$scriptdir/_drafts" ]; then
    (
        cd $scriptdir/_drafts/
        ls *.md 2>/dev/null | sed 's/^/_drafts\//'
    )
fi
