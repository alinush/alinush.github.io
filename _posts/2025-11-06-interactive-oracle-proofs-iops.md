---
type: note
tags:
 - zero-knowledge proofs (ZKPs)
title: Interactive Oracle Proofs (IOPs)
#date: 2020-11-05 20:45:59
#published: false
permalink: iop
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** An **interactive oracle proof (IOP)** is an interactive proof system where the verifier has **oracle access** to the prover's messages rather than reading them in full. This combines the expressiveness of interactive proofs with the efficiency of PCPs. Introduced in [BCS16][^BCS16].

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\newcommand{\Prover}{\mathcal{P}}
\newcommand{\Verifier}{\mathcal{V}}
\newcommand{\relation}{\mathcal{R}}
$</div> <!-- $ -->

## What is an IOP?

An **interactive oracle proof (IOP)** is an interactive proof system where the prover's **messages** are not read in full by the verifier.
Instead, the verifier has **oracle access** to each prover message, meaning it can _query_ individual positions of the message string. 
This combines the expressiveness of interactive proofs (multiple rounds of interaction) with the efficiency of PCPs (sublinear verification via oracle queries).

## Formal definition

An IOP for a **relation** $\term{\relation}$ consists of a **prover** $\term{\Prover}$ and a **verifier** $\term{\Verifier}$.
The protocol proceeds over $\term{k}$ **rounds**. In each round $\term{i}$:

1. The prover sends an **oracle** $\term{\pi_i} \in \Sigma^{\ell_i}$ (a string over **alphabet** $\term{\Sigma}$ of length $\term{\ell_i}$).
2. The verifier sends a uniformly random **challenge** $\term{\alpha_i}$.

After all $k$ rounds, the verifier makes **queries** to the prover's oracle $\pi_1, \ldots, \pi_k$ and decides to accept or reject.
Crucially, the verifier does not read any $\pi_i$ in full --- it only reads the positions it explicitly queries.

**Completeness** requires that for every $(x, w) \in \relation$, the honest prover convinces the verifier with probability 1 (perfect completeness) or close to 1.

**Soundness** requires that for every $x$ such that $(x, w) \notin \relation$ for all $w$, and for every unbounded malicious prover $\tilde{\Prover}$, the verifier accepts with a probability $< 1$, referred to as the **soundness error**.

## Efficiency parameters

The key efficiency parameters of an IOP are:

- **Query complexity**: the number of positions the verifier reads across all oracles.
- **Round complexity**: the number of rounds $k$.
- **Proof length**: the total length $\sum_i \ell_i$ of all prover oracles.

## Relationship to IPs and PCPs

IOPs generalize both **interactive proofs** (IPs) and **probabilistically checkable proofs** (PCPs):

- An **IP** is an IOP where the verifier reads each prover's oracle in full.
- A **PCP** is a single-round IOP (i.e., $k = 1$ with no interaction).

By combining interaction with oracle access, IOPs can achieve better tradeoffs between proof length and query complexity than either model alone.

## References

For cited works, see below 👇👇

{% include refs.md %}
