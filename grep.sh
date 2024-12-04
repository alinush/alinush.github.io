grep --color=always --exclude-dir=vendor --exclude-dir=.jekyll-cache --exclude-dir=_site --exclude-dir=.git --exclude=feed.xml -Irn $@

echo
echo "Note: Excludes files and useless directories (e.g., .git, vendor, etc.)"
echo
