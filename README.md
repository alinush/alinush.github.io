# TODOs

 - fix `\nmid` issue in Linear diophantine article (`amssymb`) probably due to new jsdelivr URL for MathJax
 - re-tag everything
 - front page with highlights
 - add more cross-links between articles


# Jekyll with TeXt Theme

See original [README here](https://github.com/kitian616/jekyll-TeXt-theme)

[![license](https://img.shields.io/github/license/kitian616/jekyll-TeXt-theme.svg)](https://github.com/kitian616/jekyll-TeXt-theme/blob/master/LICENSE)
[![Gem Version](https://img.shields.io/gem/v/jekyll-text-theme.svg)](https://github.com/kitian616/jekyll-TeXt-theme/releases)
[![Travis](https://img.shields.io/travis/kitian616/jekyll-TeXt-theme.svg)](https://travis-ci.org/kitian616/jekyll-TeXt-theme)
[![Tip Me via PayPal](https://img.shields.io/badge/PayPal-tip%20me-1462ab.svg?logo=paypal)](https://www.paypal.me/kitian616)
[![Tip Me via Bitcoin](https://img.shields.io/badge/Bitcoin-tip%20me-f7931a.svg?logo=bitcoin)](https://raw.githubusercontent.com/kitian616/jekyll-TeXt-theme/master/docs/assets/images/3Fkufxcw2xd8HnaRJBNK4ccdtkUDyyNu4V.jpg)

![TeXt Theme Details](https://raw.githubusercontent.com/kitian616/jekyll-TeXt-theme/master/screenshots/TeXt-layouts.png)

TeXt is a super customizable Jekyll theme for personal site, team site, blog, project, documentation, etc. Similar to iOS 11 style, it has large and prominent titles, round buttons and cards.

## Local build

First, install prerequisites:

    bundle install --path vendor/bundle

Second, run website locally using:

    bundle exec jekyll serve

Then, access it at [http://localhost:4000](http://localhost:4000).

## For Apple M1

Had some issue getting this to run the server on Apple M1. The instructions from [here](https://www.earthinversion.com/blogging/how-to-install-jekyll-on-appple-m1-macbook/) ended up being helpful:

```
xcode-select --install
brew install rbenv ruby-build

rbenv install 3.2.10
rbenv global 3.2.10
ruby -v
rbenv rehash

echo 'eval "$(rbenv init - bash)"' >> ~/.profile

gem install --user-install bundler jekyll

rm -f Gemfile.lock  # Remove old lock file with incompatible gem versions
bundle install
bundle update --bundler
bundle install --redownload
```

You should now be ready to run the web-server:
```
./run-server.sh
```

## License

TeXt Theme is [MIT licensed](https://github.com/kitian616/jekyll-TeXt-theme/blob/master/LICENSE).
