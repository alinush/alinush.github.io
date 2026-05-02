---
type: note
tags:
 - zero-knowledge proofs (ZKPs)
title: Polynomial Interactive Oracle Proofs (PIOPs)
#date: 2020-11-05 20:45:59
#published: false
permalink: piop
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** PIOPs, as originally introduced in the DARK paper[^BFS20].
(Although I think they were kind of already defined in PLONK[^GWC19] and Marlin[^CHMplus19e]?)

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

<!--
## PIOP structure

## Protocol structure (fully general)

For rounds $ i = 1, \dots, k $:

1. **Verifier message (challenge):**
	\begin{align}
		\rho_i \leftarrow \mathsf{V}(\text{state})
	\end{align}
   The verifier sends randomness/challenges to the prover.
2. **Prover oracle message:**
   The prover responds with $m_i$ polynomials:
   \begin{align}
		\mathcal{F}\_i = \\{ f\_{i,1}, \dots, f\_{i,m\_i} \\} \subseteq \mathbb{F}[X]
   \end{align}
3. **Adaptive oracle queries (interleaved):**
   After receiving $ \mathcal{F}_i $, the verifier may:
   * adaptively choose query points $ \alpha \in \mathbb{F} $
   * query any polynomial sent so far
   * base future queries on previous answers

This continues across rounds; **queries are not restricted to the end**.
-->

## References

For cited works, see below 👇👇

{% include refs.md %}
