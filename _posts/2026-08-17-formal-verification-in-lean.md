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

 - [ ] [Verified-zkEVM](https://github.com/Verified-zkEVM)
      - [ ] [VCVio](https://github.com/Verified-zkEVM/VCVio)
      - [ ] [ArkLib](https://github.com/Verified-zkEVM/ArkLib)
      - [ ] [clean zkDSL](https://github.com/Verified-zkEVM/clean)
 - [ ] [zkLean: A DSL for ZK statement verification](https://www.galois.com/articles/zklean-a-dsl-for-zk-statement-verification)
 - [ ] Paper: [SoK: Computer-aided cryptography](https://eprint.iacr.org/2019/1393)
 - [ ] Paper: [SSProve: A foundational framework for modular cryptographic proofs in Coq](https://eprint.iacr.org/2021/397)
 - [ ] [AICR](https://aicr.info/): A living, AI-native record of open cryptographic problems, attempts, partial progress, and verification

## Software engineering in Lean

 - [x] [Why lean is faster than Rust](https://kim-em.github.io/blog/2026-7-24-why-lean-is-faster-than-rust/)
      + [x] [Lean proved this program was correct; then I found a bug.](https://kirancodes.me/posts/log-who-watches-the-watchers.html)
 - [x] [Just Lean: a verified, fast sort](https://just-lean.mitscha-baude.at/)
 - [x] [Sort in Rust, prove in Lean example](https://github.com/alinush/sort-in-rust-prove-in-lean-example)
 - [ ] [Lean-ing into Software Engineering](https://paulbutcher.com/lean1.html)
 - [ ] [(somewhat) formally verified implementation of Markdown](https://paulbutcher.com/lean-markdown.html)
 - [ ] [Formally verified CRUD](https://paulbutcher.com/lean2.html)
 - [x] [Formally Verified [zkVM] Autoprecompiles](https://powdr.org/blog/formally-verified-autoprecompiles)
 - [x] [A new software engineering paradigm](https://georgwiese.github.io/posts/formal-verification-ai/)
 - [x] [evm.asm](https://github.com/Verified-zkEVM/evm-asm): EVM implemented in RISC-V assembly and proved against a Lean spec of RISC-V and a Lean spec of the EVM.


## Rust (Non-Lean)

 - [ ] [Verus](https://github.com/verus-lang/verus): Verified Rust for low-level systems code
 - [ ] [Creusot](https://creusot.rs/): a deductive verifier for the Rust programming language
 - [x] [Aeneas](https://github.com/AeneasVerif/aeneas): translation from Rust's MIR internal language to a pure lambda calculus
    + Often [used to "compile" a subset of Rust to Lean](https://lean-lang.org/use-cases/aeneas/)

## Logic

 - [Propositional logic](https://en.wikipedia.org/wiki/Propositional_logic), $p \wedge \neg p$ type of thing; no quantifiers; no predicates
 - [First-order logic](https://en.wikipedia.org/wiki/First-order_logic), $\exists y, \forall x, P(x, y)$; quantifiers and predicates
 - [Second-order logic](https://en.wikipedia.org/wiki/Second-order_logic), $\exists P, \forall x. P(x)$; more expressive than first-order logic (quantifies over predicates too)
 - [Intuitionistic logic (constructive logic)](https://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence)
    + Does not assume the [law of excluded middle (LEM)](https://en.wikipedia.org/wiki/Law_of_excluded_middle): i.e., $p \lor \lnot p$ (a.k.a., $p$ or not $p$) is not an axiom; you must actually prove either "$p$" or "not $p$"
    + ...nor [double negation elimination (DNE)](https://en.wikipedia.org/wiki/Double_negation#Elimination_and_introduction): i.e., $\lnot\lnot p \to p$ is not an axiom
       * The converse, *introduction*, does hold: $p \to \lnot\lnot p$ is constructively provable
    + But... but! If you assume one, you can prove the other one is implied. e.g., assuming LEM, can prove constructively that DNE holds
       * In Lean, it so happens you tend to assume a particular flavor of the axiom of choice, which implies LEM, which implies DNE
 - [Curry-Howard correspondence](https://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence)

## Docs

 - [mathlib4 docs](https://leanprover-community.github.io/mathlib4_docs/)
 - [LeanSearch](https://leansearch.net/?q=is+sorted+array)
 - [Loogle](https://loogle.lean-lang.org/?q=sort)

## Misc

 - [CSLib](https://www.cslib.io/)
 - [lean4-skills](https://github.com/cameronfreer/lean4-skills)
 - [Hitchhiker's guide to formal verification](https://raw.githubusercontent.com/blanchette/logical_verification_2023/main/hitchhikers_guide.pdf) [in Lean]
 - [Lean metaprogramming](https://leanprover-community.github.io/lean4-metaprogramming-book/)
 - [From Prompts to Protocols: lean4-skills for AI-Assisted Lean Formalization](https://cameronfreer.github.io/slides/202608-aitp/#/title)

## Tutorials

 - [Lean Lab](https://www.leanlanguage.app/), by [Alexander John Lee](https://x.com/alexanderlee314/status/2099233160856801306)
 - [Lean game server](https://adam.math.hhu.de/)
 - [Insertion sort in Lean with termination proof](https://lean-lang.org/functional_programming_in_lean/Programming___-Proving___-and-Performance/Insertion-Sort-and-Array-Mutation/)
 - [Tutorial: Introduction to Formal Verification with Lean (Part 1)](https://hashcloak.com/blog/tutorial-introduction-to-formal-verification-with-lean-(part-1))

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
