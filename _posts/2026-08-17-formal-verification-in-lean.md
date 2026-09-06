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

## Cryptography

 - [Verified-zkEVM](https://github.com/Verified-zkEVM)
     - [VCVio](https://github.com/Verified-zkEVM/VCVio)
     - [ArkLib](https://github.com/Verified-zkEVM/ArkLib)
     - [clean zkDSL](https://github.com/Verified-zkEVM/clean)
 - [zkLean: A DSL for ZK statement verification](https://www.galois.com/articles/zklean-a-dsl-for-zk-statement-verification)

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Rust (Non-Lean)

 - [Verus](https://github.com/verus-lang/verus): Verified Rust for low-level systems code
 - [Creusot](https://creusot.rs/): a deductive verifier for the Rust programming language
 - [Aeneas](https://github.com/AeneasVerif/aeneas): translation from Rust's MIR internal language to a pure lambda calculus
    + Often [used to "compile" a subset of Rust to Lean](https://lean-lang.org/use-cases/aeneas/)

## Misc

 - [CSLib](https://www.cslib.io/)
 - [lean4-skills](https://github.com/cameronfreer/lean4-skills)
 - [Lean game server](https://adam.math.hhu.de/)
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
