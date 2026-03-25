All papers that can be cited are in `_includes/refs.md`.

You can search for papers using the locally-installed `ck` tool (source code available in `../ck` when in doubt):
```
ck s <author-or-title-or-anything-in-the-bibtex-file>
```

You can see where the paper repository is locally by parsing the `ck` config file:
```
cat "`ck config`"
```

When writing math derivations in blog posts, each new equation/line should introduce only **one small change** from the previous line. Do not skip steps or combine multiple operations into a single line.

When writing blog posts, do NOT redefine LaTeX macros that are already defined globally in `_includes/markdown-enhancements/mathjax.html` (in the `window.MathJax.tex.macros` object). Globally-available macros include: `\pk`, `\sk`, `\vk`, `\aux`, `\negl`, `\poly`, `\F`, `\Fp`, `\Fq`, `\Fr`, `\Gr`, `\Z`, `\Zp`, `\Zq`, `\N`, and others. Check that file before adding per-page `\def` macros in a hidden div.
