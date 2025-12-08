---
tags:
 - digital signatures
 - post-quantum
title: Post-quantum signature schemes
#date: 2020-11-05 20:45:59
#published: false
permalink: post-quantum-signatures
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Some notes on post-quantum (PQ) signature schemes.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Introduction

This is a research blog post on the state-of-the-art PQ signature schemes.

Steps:

 - [x] Surveyed NIST's Round 2 additonal candidates[^nist-round-2-additional]
    * Filtered after Round 1. (See status report[^ABCplus24].)
    * See all schemes [here](/pictures/nist-round-1.png), with the advanced ones marked in $\textcolor{blue}{\text{blue}}$
        + **A criticism:** The MPC-in-the-Head schemes actually rely on all sorts of exotic assuptions. The caption makes it seem like they do not, which is confusing.

## Symmetric-crypto-based schemes

### FAEST[^BBdplus23]

 - based on AES128/192/256 and **Vector Oblivious Linear Evaluation (VOLE) in the head (VOLEiTH)**
    + VOLEitH is constructed only from symmetric-key primitives
 - NIST cites it as _"somewhat complex"_ and says _"the security proof is very technical."_[^ABCplus24]

#### Construction

\begin{align}
\pk &= (x,y)\\\\\
\sk &= k
\end{align}
such that:
\begin{align}
E_k(x) = y,\ \text{where}\ E\ \text{is a block cipher}
\end{align}

Signing works by doing a ZKPoK of $k$ using VOLEitH and the QuickSilver information-theoretic proof system[^YSWW21e] (under the Fiat-Shamir transform).

#### Performance

Benchmarked on:
 > _"a single core of a consumer notebook with an AMD Ryzen 7 5800H processor, with a base clock speed of 3.2 GHz and 16 GiB memory."_ 
 > _"Simultaneous Multi-Threading was enabled."_
 > _The computer was running Linux 6.1.30, and the implementations were built with GCC 12.2.1."_

Secret and public keys are small: 32 bytes at 128-bit security.

**Unoptimized** reference implementation is **too slow** (tens of milliseconds to verify):

<div align="center"><img style="width:60%" src="/pictures/faest-v1-ref-impl.png" /></div>

But **x86-64 AVX2** implementation could be **practical** at 128-bit security level (0.87 ms to verify 6,336-byte signatures):

{: .warning}
These numbers are **multi-threaded**!

<div align="center"><img style="width:80%" src="/pictures/faest-v1-x86_64-avx2-impl.png" /></div>

{: .note}
Perhaps this recent QuickSilver improvement[^BCCplus23e] will help?
I quote: _"For a circuit of size $\sizeof{C} = 2^{27}$, it shows up to 83.6× improvement on communication, compared to the general VOLE-ZK Quicksilver. In terms of running time, it is 70% faster when bandwidth is 10Mbps"_.

## Lattice-based schemes

### SIS-based

{: .todo}
GPV hash-and-sign signatures and their plain-lattice descendants[^GPV07e].
(Also see [this](https://www.cs.columbia.edu/~tal/6261/SP13/lecture7-GPV.pdf?utm_source=chatgpt.com).)
"Fiat-Shamir with Aborts" signatures[^Lyub09]$,$[^Lyub12].
[Squirrels](https://csrc.nist.gov/csrc/media/Projects/pqc-dig-sig/documents/round-1/spec-files/Squirrels-spec-web.pdf).
[HuFu](https://csrc.nist.gov/csrc/media/Projects/pqc-dig-sig/documents/round-1/spec-files/HuFu-spec-web.pdf).
(Also see [this survey](https://csrc.nist.gov/csrc/media/events/workshop-on-cybersecurity-in-a-post-quantum-world/documents/papers/session9-oneill-paper.pdf?utm_source=chatgpt.com).)

## References

For cited works, see below 👇👇

[^nist-round-2-additional]: [Post-Quantum Cryptography: Additional Digital Signature Schemes (Round 2)](https://csrc.nist.gov/projects/pqc-dig-sig/round-2-additional-signatures)

{% include refs.md %}
