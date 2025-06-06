#!/bin/bash

set -e

scriptdir=$(cd $(dirname $(readlink -f $0)); pwd -P)
notesdir="$scriptdir"
    
if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` <title> [note-date-YYYY-mm-dd]"
    #echo
    #echo "OPTIONS"
    exit
fi

title="$1"

if [ -z "$2" ]; then
    date=`date +%Y-%m-%d`
else
    date="$2"
fi

# Convert spaces to dashes and convert title to lowercase
title_dashes=`echo -n "$title" | tr '[:upper:]' '[:lower:]' | tr '[:space:]' '-' | tr -dc '[:alnum:]-'`

filename="$date-${title_dashes}"    # file name w/o extension
mdfile="${filename}.md"             # file name w/ extension
notepath=$notesdir/$mdfile          # full file path

if [ -f "$notepath" ]; then
    echo "ERROR: $mdfile already exists in $notesdir. Will not overwrite, so please rename or delete yourself."
    exit 1
fi

# Create note from template file
echo "Creating file $mdfile..."
templ=$(cat $notesdir/templ.md | sed "s/insert-title-here/$title/g")
#fulldate=`date "+%A, %B %-d, %Y, %-I:%M%p, at"`
echo "$templ" > "$notepath"

hash_init=`sha256sum $notepath`
vim "$notepath"
hash_mod=`sha256sum $notepath`

if [ "$hash_init" == "$hash_mod" ]; then
    rm $notepath
    echo "You did not make any changes to '$notepath', so not saving it."
fi
