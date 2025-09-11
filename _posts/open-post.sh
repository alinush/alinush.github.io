#!/bin/bash

scriptdir=$(cd "$(dirname "$0")"; pwd -P)
postdir="$scriptdir/"
cd "$postdir/"

# Gather and filter markdown files
files=$(find . -name "*.md" | grep -vE "/_drafts/|/files/|/templ.md|/TODO.md|/refs.md|/*welcome.md|/*header-image.md" | cut -c 3- | sort -r)

# Arrays
index_keys=()
index_files=()
perma_keys=()
perma_files=()
titles=()
all_files=()
all_keys=()

display_titles=()
index=1

# Collect metadata
for file in $files; do
    permalink=$(grep -m 1 '^permalink:' "$file" | sed -E 's/^permalink:[[:space:]]*//')
    title=$(grep -m 1 '^title:' "$file" | sed -E 's/^title:[[:space:]]*//;s/^"//;s/"$//')
    [ -z "$title" ] && title="(untitled)"

    if [ -z "$permalink" ]; then
        key="$index"
        index_keys=("${index_keys[@]}" "$index")
        index_files=("${index_files[@]}" "$file")
        index=$((index + 1))
    else
        key="$permalink"
        perma_keys=("${perma_keys[@]}" "$permalink")
        perma_files=("${perma_files[@]}" "$file")
    fi

    all_keys=("${all_keys[@]}" "$key")
    all_files=("${all_files[@]}" "$file")
    titles=("${titles[@]}" "$title")
    display_titles=("${display_titles[@]}" "$title")
done

# If no input, display list
if [ $# -eq 0 ]; then
    for title in "${display_titles[@]}"; do
        echo "$title"
    done | more
    exit 0
fi

# Otherwise, fuzzy open
input="$1"
file_to_open=""

# Exact match: number
i=0
for key in "${index_keys[@]}"; do
    if [ "$key" = "$input" ]; then
        file_to_open="${index_files[$i]}"
        break
    fi
    i=$((i + 1))
done

# Exact match: permalink
if [ -z "$file_to_open" ]; then
    i=0
    for key in "${perma_keys[@]}"; do
        if [ "$key" = "$input" ]; then
            file_to_open="${perma_files[$i]}"
            break
        fi
        i=$((i + 1))
    done
fi

# Fuzzy match (permalink or title)
if [ -z "$file_to_open" ]; then
    i=0
    for key in "${all_keys[@]}"; do
        title="${titles[$i]}"
        match_key=$(echo "$key" | tr '[:upper:]' '[:lower:]')
        match_title=$(echo "$title" | tr '[:upper:]' '[:lower:]')
        match_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
        if echo "$match_key" | grep -q "$match_input" || echo "$match_title" | grep -q "$match_input"; then
            file_to_open="${all_files[$i]}"
            break
        fi
        i=$((i + 1))
    done
fi

# Open or error
if [ -n "$file_to_open" ]; then
    vim "$file_to_open"
    echo
    echo "$file_to_open"
else
    echo "No match found for '$input'"
    exit 1
fi

