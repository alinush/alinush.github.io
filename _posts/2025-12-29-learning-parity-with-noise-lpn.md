---
tags:
 - LPN
title: Learning parity with noise (LPN)
#date: 2020-11-05 20:45:59
#published: false
permalink: lpn
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A very useful cryptographic assumption that is related to coding theory.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\b{\mathbf{b}}
\def\e{\mathbf{e}}
\def\s{\mathbf{s}}
\def\A{\mathbf{A}}
\def\E{\mathcal{E}}
\def\G{\mathbf{G}}
$</div> <!-- $ -->

## Preliminaries

 - bolded, lowercase variables (e.g., $\s$) denote **column** vectors in $\F^m\bydef \F^{m\times 1}$.
 - $n$ is the dimension
 - $m$ is the number of samples

## Introduction

The **learning parity with noise (LPN)** assumption was proposed in a 1993 CRYPTO paper by Blum, Furst, Kearns and Lipton[^BFKL94].

Informally, the **computational variant** says that, for a public matrix $\A \in \F^{n \times m}$, a secret vector $\s\in \F^m$ and noise $\e\in \F^n$ sampled from an **error distribution** $\E$, it is hard to recover $\s$ from $(\A,\A\s+\e)$.

There is also a **decisional variant** that says it is hard to distinguish $(\A,\A\s+\e)$ from $(\A,\b)$, when $\b\randget \F^n$ (uniformly) and $\e$ is sampled appropriately from $\E$.

There is also a **dual LPN variant** introduced by Micciancio and Mol[^MM11], which says that for a public matrix $\G\randget \mathcal{G}$, where $\mathcal{G}$ is a **generator distribution**, and noise $\e$ sampled from $\E$, it is hard to recover $\e$ from $(\G,\G\e)$

## References

For cited works, see below 👇👇

{% include refs.md %}
