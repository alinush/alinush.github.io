#!/bin/bash

scriptdir=$(cd $(dirname $0); pwd -P)
incldir=$scriptdir/_includes

. ~/.bash_aliases # for ck to be defined

rm -f $incldir/refs.md && ck genbib -m $incldir/refs.md
