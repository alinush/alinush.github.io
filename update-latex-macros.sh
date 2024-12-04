#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)
file=_includes/markdown-enhancements/mathjax.html

vim $scriptdir/$file +22 

echo
echo $scriptdir/$file
echo
