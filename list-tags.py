#!/usr/bin/env python3
#
# Prints every tag used across _posts, alphabetically, with how many posts
# use each one.
#
# Usage: ./list-tags.py

import glob
import os
import re
import sys
from collections import Counter

try:
    import yaml
except ImportError:
    sys.exit("Missing dependency: pip install pyyaml")

FRONT_MATTER_RE = re.compile(r'^---\s*$', re.MULTILINE)


def main():
    scriptdir = os.path.dirname(os.path.abspath(__file__))
    posts_dir = os.path.join(scriptdir, '_posts')

    tag_counts = Counter()
    posts_with_tags = 0

    for path in sorted(glob.glob(os.path.join(posts_dir, '*.md'))):
        with open(path, encoding='utf-8') as f:
            content = f.read()
        if not content.startswith('---'):
            continue

        parts = FRONT_MATTER_RE.split(content, maxsplit=2)
        if len(parts) < 3:
            continue
        front_matter_text = parts[1]

        try:
            front_matter = yaml.safe_load(front_matter_text)
        except yaml.YAMLError as e:
            print(f"{os.path.basename(path)}: skipping, YAML frontmatter didn't parse ({e})",
                  file=sys.stderr)
            continue
        if not isinstance(front_matter, dict):
            continue

        tags = front_matter.get('tags')
        if not isinstance(tags, list) or not tags:
            continue

        posts_with_tags += 1
        for tag in tags:
            tag_counts[str(tag).strip()] += 1

    for tag, count in sorted(tag_counts.items(), key=lambda kv: kv[0].lower()):
        print(f"{tag} ({count})")

    print()
    print(f"{len(tag_counts)} unique tags across {posts_with_tags} tagged posts")


if __name__ == '__main__':
    main()
