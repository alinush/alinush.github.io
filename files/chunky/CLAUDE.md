# Reveal.md presentation for Chunky PVSS using DeKART range proofs

## Guidelines for editing this deck

- LaTeX macros live in the `$$ \newcommand{...} $$` block at the top of `chunky.md` — add new ones there.
- Use `\begin{aligned}` inside `$$...$$`, not `\begin{align}` (MathJax doesn't support `align` in display math — use `\begin{align}` as its own top-level block at paragraph level; see the PVSS-definition slide for an example of numbered `align`).
- Fragments inside math: wrap terms with `\class{fragment}{...}`; prefix with `{}` to keep spacing.
- Fragments on markdown bullets only work cleanly when the bullet is plain text. If a bullet *starts with* inline HTML (e.g., `<strong>`), `<!-- .element: class="fragment" -->` at the end of the line attaches to the inner HTML element instead of the `<li>`, so only part of the bullet animates in. Fix: write the whole list as raw `<ul>`/`<li>` with `class="fragment"` directly on each `<li>` (see the tl;dr slide).
- Per-slide attributes go in a comment as the first line of the slide: `<!-- .slide: class="..." -->`.
- Slide numbers do not work under `view: scroll` — heads up before suggesting it.
- When appending new slides, put them at the end of `chunky.md` (before any appendix/hidden slides if they exist).
- MathJax config is set in `chunky.md`'s frontmatter under `revealOptions.math`. SVG output (`config: 'TeX-AMS_SVG-full'`) is required for clean rendering of accents like `\widetilde`; do not switch back to HTML-CSS output without reason. `\textcolor` also requires `TeX.extensions: ["color.js"]` to be listed explicitly — the SVG variant of the config doesn't bundle it.
- **Escape `_` as `\_` inside display-math `$$...$$` blocks.** Marked pairs unescaped `_..._` as Markdown italic delimiters even inside `$$`, so `V^*_\mathbb{S}(X) = ... \sum_{j}` gets its `_`s eaten. Either escape every `_` in the block (`V^*\_\mathbb{S}`, `\sum\_{j}`, `f\_j`, etc.), or restructure to avoid them. Inline `$...$` math is generally fine — the issue is specifically `$$...$$` display math where marked does more processing.
- **No trailing period at the end of display math.** Do NOT end `$$...$$` blocks, `\begin{align}...\end{align}`, or `\begin{aligned}...\end{aligned}` with a `.` — leave equations unpunctuated. (Same goes for trailing `,` on single-equation displays.)
- **No LaTeX micro-spacing in math. This is a hard rule — do not reach for `\!` out of habit.** Banned: `\,`, `\;`, `\!`, `\:`, `\>`, `\hspace{...}`. Several render as literal characters in our MathJax 2 SVG config (`\;` showed up as a literal `;`, `\!` as a literal `!`), and even when they render they look visually noisy. `\quad` and `\qquad` are OK when a real noticeable gap is needed (e.g., between a main statement and a side condition on the same line). If spacing looks wrong, restructure the equation or split into two `$$` blocks — never reach for `\!` or `\,`.
- **`#` in hex colors inside `\def` bodies — escape rules.** TeX reserves `#` as a parameter marker in `\def` bodies. In practice, against MathJax 2.7.9:
    - If the macro takes *no* argument (e.g., `\def\ek{\textcolor{#d33682}{\mathsf{ek}}}`), a single `#` in the hex color works — MathJax is lenient when there's no parameter pattern to worry about.
    - If the macro takes an argument (e.g., `\def\secret#1{\textcolor{##b58900}{#1}}`), you **must** double the `#` in the hex color to `##` — otherwise TeX tries to parse `#b58900` as a (bogus) parameter reference and the macro fails to define.
    - When in doubt, use `##` — strict-TeX-correct and always safe. Named CSS colors (`crimson`, `darkgoldenrod`, etc.) sidestep the issue entirely.

## Styling classes already defined

- `<strong class="term">...</strong>` — blue, for introducing a new term (e.g., "Chunky", "DeKART").
- `<span class="cite">[Key]</span>` — purple, for in-slide citations.
- `<span class="good">...</span>` — green + semibold, for highlighting good numbers.
- `<span class="me">...</span>` — green + bold, for highlighting "me" (Alin Tomescu) in author lists / citation keys.
- `<!-- .slide: class="no-caps" -->` on a slide to disable the `white` theme's uppercase-headings.
- `<!-- .slide: class="left" -->` on a slide to left-justify its text (slides default to center-aligned).

## Citing papers

- All citable papers live in the blog's bibliography at `~/repos/alinush.github.io/_includes/refs.md`.
- Search the bibliography with the locally-installed `ck` tool (source: `~/repos/ck` when in doubt):
    - `ck s <author-or-title-or-anything-in-the-bibtex-file>`
    - **`ck s` searches a single keyword/term at a time.** Do NOT combine terms — run `ck s "Bulletproofs"` and `ck s "Bunz"` separately, NOT `ck s "Bulletproofs Bunz"`.
- Locate the paper repository locally via the `ck` config file: `cat "$(ck config)"`.
- Add new papers to the bibliography by ePrint URL: `ck add <eprint-url> --tag <tag>`.
    - Pick `--tag` from the existing hierarchy (`ck tags`). For a multilinear PCS paper, e.g. `--tag polycommit/multivariate/multilinear`.
    - After adding, run `./update-refs.sh` in the blog's root directory to sync `_includes/refs.md`.
- When you cite a paper in a slide, **also add its entry to the `# References` slide** in `chunky.md`. Use the citation key from `refs.md` as the display label, e.g., `<span class="cite">[BDF+25e]</span>`. The `+` → `plus` kramdown rule doesn't apply here (we're not using Jekyll footnotes).
- **Link the citation key, not a trailing URL.** If the paper has a URL, hyperlink the citation-key text inside the brackets. Format: `**[<a href="https://url">Key</a>]**` on the References slide, and likewise for inline citations: `<span class="cite">[<a href="https://url">Key</a>]</span>`. Use HTML `<a>` (not markdown link syntax) so nested spans like `<span class="me">` inside the key still work.
- **Don't restate "ePrint YYYY/NNNN"** in a References entry — the linked key pointing to `eprint.iacr.org/YYYY/NNNN` already conveys it.
- **Highlighting "me" in authored papers.** Whenever a citation has **Alin Tomescu** as a co-author, highlight it in both the References slide and any inline citation of that key:
    - In the References author list, wrap `Alin Tomescu` in `<span class="me">...</span>`.
    - In the citation key, wrap Alin's initial (`T`) in `<span class="me">T</span>`. If `T` is absent because the key uses `+` for trailing authors (e.g., `BDF+25e`), wrap the `+` instead: `BDF<span class="me">+</span>25e`. Do this both on the References slide and in every inline `<span class="cite">[...]</span>`.

## Thinking about what should be in the presentation

The presentation is centered around the Chunky PVSS scheme and its core building block is DeKART range proofs.

Both are described in the /chunky and /dekart blogposts in `~/repos/alinush.github.io` (read the `CLAUDE.md` there).

### Goal 1

The 1st goal of the presentation is to argue that Chunky PVSS is the best choice for pairing-friendly VSS/DKGs.

Why?

 1. Each player can decrypt their share in a few milliseconds
 1. Faster than everything else on dealing and verification
    * cgVSS is faster to deal for n > 64 but it relies on class groups
    * Groth21 with $\ell = 32$ is also faster to deal but its decryption time will be slower
 2. Reasonably succinct (within ~2x); if you want more, you need to either
    * For large enough $n$, can rely on lattices (but slower)
    * Groth21, but adds another 10-20 bits to your DLs ==> slower decryption
    * Golden, but zkSNARKs will be slower
    * cgVSS, but class groups

Show benchmark numbers from /chunky blogpost for $n \in \{32, 256, 1024\}$ (small, medium, very large)

### Goal 2

Make it clear that Chunky is very simple and instantiates a well-known paradigm for PVSS:
 - SSS
 - Feldman commitments to shares
 - SCRAPE low-degree testing on committed shares
 - Chunking of shares
     - ElGamal encryption of the chunks
     - Batched range proof for the encrypted chunks
 - Pairing-based consistency checks between committed shares and encrypted shares

Moral of the story:
 - The batched range proof helped us reduce a lot of overhead during dealing (and especially during verification)
 - The rest is just carefully gluing together well-known building blocks (in fact, there may be more tricks to play here)

### Goal 3

Illustrate how simple our range proof is: show the non-ZK PIOP.

Show comparison with Bulletproofs and MissileProof from /dekart blogpost at the same $n\in \{32, 256, 1024\}$.

### Chunky high level explanation

The high level *unweighted* design is to have the dealer deal via Shamir secret sharing (SSS) as usual: each player $i$ gets a share $s_i=p(i)$ where $p(X)$ is a degree $t-1$ polynomial and the dealt secret is $p(0)$.
Then, the dealer **"chunks"** $s_i$ into $m$ chunks $s_{i,1},\ldots,s_{i,m}$.
This is really a base-$B=2^\ell$ representation of $s_i$:
i.e., $s_i = \sum_{k=0}^{m-1} B^k s_{i,k}$

The dealer commits to the $s_i$'s and encrypts the $s_{i,k}$ chunks via ElGamal.

The dealer then does a batched range proof for all the chunks via DeKART.

The verifier checks a couple of things:
 - that the committed shares lie on a degree $t-1$ polynommial (via a SCRAPE LDT)
 - that the encrypted chunks correspond to the committed shares (this only checks radix-$B$ representation; not base-$B$)
 - that the encrypted chunks are "in range" (this guarantees base-$B$)

There's a bit more going on there, but it is all detail: e.g., we have to prove that we have a KZG commitment to the encrypted chunks since that's what the range proof operates over. In the process of proving this, we actually produce an SoK from the dealer, which helps us with non-malleability when using this PVSS during a DKG.

The dealt transcript contains:
 - the share commitments ($n$ of them)
 - the ElGamal-encrypted chunks $nm$ of them
 - and the range proof (which really is a KZG commitment, the actual DeKART range proof, and the SoK linking together the ElGamal ciphertext to the KZG commitment)

### DeKART high level explanation

Present the non-ZK protocol and handwave the ZKness away.

See `dekart-piop-not-zk.md`.

### Future work

 - Mention the multivariate DeKART line of work that tries to further make this better using sumcheck and MLE PCS's.
