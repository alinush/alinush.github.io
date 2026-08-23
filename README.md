# TODOs

 - fix `\nmid` issue in Linear diophantine article (`amssymb`) probably due to new jsdelivr URL for MathJax
 - front page with highlights
 - add more cross-links between articles

# Theme

The site runs on a Jekyll port of [Apollo](https://www.getzola.org/themes/apollo/)
([source](https://github.com/not-matthias/apollo)), a minimal Zola theme: mono/`ZedText`
typography, `#`-prefixed headings, a red accent, and a light/dark toggle.

Apollo is written for Zola, so its Tera templates could not be reused; the markup, CSS and
JS were reimplemented here:

| Piece | Where |
| --- | --- |
| Styles | `_sass/apollo/*.scss`, imported by `assets/css/main.scss` |
| Site-specific overrides | `_sass/apollo/_custom.scss` |
| Callout boxes (`{: .info}`, `{: .note}`, ...) | `_sass/apollo/_alerts.scss` |
| Layouts | `_layouts/{base,article,page,home,posts,notes,404}.html` |
| Partials | `_includes/apollo/*.html` |
| Scripts | `assets/js/{themetoggle,toc,codeblock,search,tagfilter,swiper}.js` |
| Fonts and icons | `assets/fonts/`, `assets/icons/` (vendored from Apollo) |

Things worth knowing:

- **Posts vs. notes.** A post with `type: note` in its front matter is a *note*: it is listed on
  `/notes.html` and gets a 🌱; everything else is listed on `/posts.html` and gets a 🌲. Both
  listings group by year and are filterable by tag (`?tag=...` still works).
- **The Cryptomat.** A page with `sidebar: {nav: cryptomat}` gets the book navigation from
  `_data/navigation.yml` in the left column, plus previous/next links at the foot. On narrow
  screens that navigation moves below the article.
- **Table of contents.** `aside: {toc: true}` (the default for posts) renders a scroll-spying TOC
  in the right column, built client-side from the heading ids.
- **Cover images.** `article_header: {type: cover, image: {src: ...}}` still works, but Apollo has
  no hero: the image is rendered inline at the top of the article.
- **Light/dark.** Both palettes live in one stylesheet as `:root.light` / `:root.dark`;
  `assets/js/themetoggle.js` swaps the class on `<html>`. `theme_toggle` in `_config.yml` chooses
  between the 2- and 3-state button.
- **Search** is a small JSON index (`assets/search-index.json`) over titles, tags and excerpts.
  Press `/` or ctrl/cmd-K.

The previous theme was [TeXt](https://github.com/kitian616/jekyll-TeXt-theme). Its stylesheets
(`_sass/common`, `_sass/components`, `_sass/layout`, `_sass/skins`, ...) and its includes are still
in the tree but are no longer imported or rendered by anything; they can be deleted once the port
has settled.

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

The [Apollo](https://github.com/not-matthias/apollo) theme this port is based on is
[MIT licensed](https://github.com/not-matthias/apollo/blob/main/LICENSE), as is the
[TeXt](https://github.com/kitian616/jekyll-TeXt-theme/blob/master/LICENSE) theme it replaced.
