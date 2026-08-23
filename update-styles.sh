#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

path=$scriptdir/_sass/apollo/_alerts.scss

vim "$path"

echo "$path"
