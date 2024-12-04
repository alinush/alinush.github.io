#!/bin/bash

set -e

scriptdir=$(cd $(dirname $0); pwd -P)

vim $scriptdir/_sass/additional/_alert.scss
