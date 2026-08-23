# TODOs

 - fix `\nmid` issue in Linear diophantine article (`amssymb`) probably due to new jsdelivr URL for MathJax
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

## Running the dev server (sandboxed)

`./run-server.sh [port]` no longer runs Jekyll on your machine directly. I`t launches it inside an
`sbx` sandbox named `alinush-github-io-jekyll`, built from the stock `ruby:3.2` image (which already
ships Ruby, bundler, git and a compiler, so nothing has to be installed at startup). 

The first run does a `bundle install`; later runs re-attach to the same sandbox, so the gems persist and startup
is fast. Requires the `sbx` CLI on your `PATH`.

Gems are installed inside the container (under `$HOME/.bundle`), not into this repo, so your
working tree stays clean.

Then, access it at [http://localhost:4000](http://localhost:4000) (or whatever port you passed).

The image and the published port are both fixed when the sandbox is created. To change the port,
switch the Ruby version, or just get a clean environment, delete the sandbox first:

    sbx rm alinush-github-io-jekyll

`./trace-server.sh [port]` works the same way, but runs `jekyll serve --trace`.

`sandbox-serve.sh` is the part that runs *inside* the sandbox (`bundle install` + `jekyll serve`); it is
invoked by `run-server.sh` and is not meant to be run on the host directly.

## Running locally on Apple M1

If you'd rather run Jekyll directly on your machine, install prerequisites.

_Note:_ Had some issue getting this to run the server on Apple M1. The instructions from [here](https://www.earthinversion.com/blogging/how-to-install-jekyll-on-appple-m1-macbook/) ended up being helpful:

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
#bundle install --path vendor/bundle  # I don't know if this is needed
bundle install --redownload
```

Once prerequisites are installed, run the local web server:
```
bundle exec jekyll serve
```

Then, access the page at [http://localhost:4000](http://localhost:4000).

## License

TeXt Theme is [MIT licensed](https://github.com/kitian616/jekyll-TeXt-theme/blob/master/LICENSE).
