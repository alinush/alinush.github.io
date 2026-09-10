---
type: note
tags: Lean
title: Formal verification in Lean
#date: 2020-11-05 20:45:59
#published: true
permalink: lean 
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A bunch of resources I hope to get to.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Cryptography

 - [Verified-zkEVM](https://github.com/Verified-zkEVM)
     - [VCVio](https://github.com/Verified-zkEVM/VCVio)
     - [ArkLib](https://github.com/Verified-zkEVM/ArkLib)
     - [clean zkDSL](https://github.com/Verified-zkEVM/clean)
 - [zkLean: A DSL for ZK statement verification](https://www.galois.com/articles/zklean-a-dsl-for-zk-statement-verification)

## Software engineering in Lean

 - [Why lean is faster than Rust](https://kim-em.github.io/blog/2026-7-24-why-lean-is-faster-than-rust/)
    + [Lean proved this program was correct; then I found a bug.](https://kirancodes.me/posts/log-who-watches-the-watchers.html)
 - [Just Lean: a verified, fast sort](https://just-lean.mitscha-baude.at/)
 - [Sort in Rust, prove in Lean example](https://github.com/alinush/sort-in-rust-prove-in-lean-example)
 - [Lean-ing into Software Engineering](https://paulbutcher.com/lean1.html)
 - [A (somewhat) formally verified implementation of Markdown](https://paulbutcher.com/lean-markdown.html)
 - [Formally verified CRUD](https://paulbutcher.com/lean2.html)
 - [Formally Verified [zkVM] Autoprecompiles](https://powdr.org/blog/formally-verified-autoprecompiles)
 - [A new software engineering paradigm](https://georgwiese.github.io/posts/formal-verification-ai/)


## Rust (Non-Lean)

 - [Verus](https://github.com/verus-lang/verus): Verified Rust for low-level systems code
 - [Creusot](https://creusot.rs/): a deductive verifier for the Rust programming language
 - [Aeneas](https://github.com/AeneasVerif/aeneas): translation from Rust's MIR internal language to a pure lambda calculus
    + Often [used to "compile" a subset of Rust to Lean](https://lean-lang.org/use-cases/aeneas/)

## Logic

 - [Propositional logic](https://en.wikipedia.org/wiki/Propositional_logic), $p \wedge \neg p$ type of thing; no quantifiers; no predicates
 - [First-order logic](https://en.wikipedia.org/wiki/First-order_logic), $\exists y, \forall x, P(x, y)$; quantifiers and predicates
 - [Second-order logic](https://en.wikipedia.org/wiki/Second-order_logic), $\exists P, \forall x. P(x)$; more expressive than first-order logic (quantifies over predicates too)

## Docs

 - [mathlib4 docs](https://leanprover-community.github.io/mathlib4_docs/)
 - [LeanSearch](https://leansearch.net/?q=is+sorted+array)
 - [Loogle](https://loogle.lean-lang.org/?q=sort)

## Misc

 - [CSLib](https://www.cslib.io/)
 - [lean4-skills](https://github.com/cameronfreer/lean4-skills)
 - [Lean game server](https://adam.math.hhu.de/)
 - [Hitchhiker's guide to formal verification](https://raw.githubusercontent.com/blanchette/logical_verification_2023/main/hitchhikers_guide.pdf) [in Lean]
 - [Lean metaprogramming](https://leanprover-community.github.io/lean4-metaprogramming-book/)
 - [Insertion sort in Lean with termination proof](https://lean-lang.org/functional_programming_in_lean/Programming___-Proving___-and-Performance/Insertion-Sort-and-Array-Mutation/)
 - [Tutorial: Introduction to Formal Verification with Lean (Part 1)](https://hashcloak.com/blog/tutorial-introduction-to-formal-verification-with-lean-(part-1))
 - [From Prompts to Protocols: lean4-skills for AI-Assisted Lean Formalization](https://cameronfreer.github.io/slides/202608-aitp/#/title)

## Questions

### Probability

How good is Lean at modeling probabilistic games in cryptography?

### High-performance code

Need two things that are in tension:
 - high performance code
 - code that is provable against the spec

e.g., if the code is in (some subset of) Rust, we can translate it to Lean using Aeneas (see above). But not sure how well this works in practice. Also, not sure how much TCB this involves.

## References

For cited works, see below 👇👇

{% include refs.md %}
