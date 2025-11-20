#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

path=$scriptdir/_sass/additional/_alert.scss

vim "$path"

echo "$path"
