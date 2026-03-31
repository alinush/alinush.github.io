## Citing, adding and searching for papers

All papers that can be cited are in `_includes/refs.md`.

You can search for papers using the locally-installed `ck` tool (source code available in `../ck` when in doubt):
```
ck s <author-or-title-or-anything-in-the-bibtex-file>
```
**Important:** `ck s` searches a single keyword/term at a time. Do NOT combine multiple search terms (e.g., do `ck s "Bulletproofs"` or `ck s "Bunz"` separately, NOT `ck s "Bulletproofs Bunz"`).

You can see where the paper repository is locally by parsing the `ck` config file:
```
cat "`ck config`"
```

You can add new papers to the bibliography via their ePrint URL:
```
ck add <eprint-url> --tag <tag>
```
Choose the `--tag` from the existing tag hierarchy (see `ck tags`). For example, for a multilinear PCS paper use `--tag polycommit/multivariate/multilinear`. After adding papers, run `./update-refs.sh` in the blog's root directory to sync `_includes/refs.md`.

## Terminology

A blog post's use of terminology should be immaculate.
Every blog post has a certain audience in mind, with a minimum background.
But past that minimum background, every term should either be defined in the preliminaries or hyperlinked externally (perhaps another local blogpost).

When first using an undefined term, you should **bold** it, to indicate that you are defining it "inline" as you are using it (e.g., see the `/ibe` post).
You will sometimes hyperlink instead of bolding. That's okay too.
In the preliminaries, newly-introduced terms should also be hyperlinked / bolded.

## Writing math

When writing math derivations in blog posts, each new equation/line should introduce only **one small change** from the previous line. Do not skip steps or combine multiple operations into a single line.

## LaTeX macros

When writing blog posts, do NOT redefine LaTeX macros that are already defined globally in `_includes/markdown-enhancements/mathjax.html` (in the `window.MathJax.tex.macros` object). Globally-available macros include: `\pk`, `\sk`, `\vk`, `\aux`, `\negl`, `\poly`, `\F`, `\Fp`, `\Fq`, `\Fr`, `\Gr`, `\Z`, `\Zp`, `\Zq`, `\N`, and others. Check that file before adding per-page `\def` macros in a hidden div.

## Citing papers

When citing papers whose citation key contains `+` (e.g., `GLS+21e`), replace `+` with `plus` in the footnote reference (e.g., `[^GLSplus21e]`). This is because Jekyll/kramdown does not support `+` in footnote IDs.
