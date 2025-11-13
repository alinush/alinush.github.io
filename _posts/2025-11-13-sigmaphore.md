---
tags:
 - zero-knowledge proofs (ZKPs)
 - Merkle
title: $\Sigma$-phore
#date: 2020-11-05 20:45:59
#published: false
permalink: sigmaphore
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A primitive much more powerful than Semaphore, that we'd like to build without zkSNARKs.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\rt{\mathsf{rt}}
\def\cm{\mathsf{cm}}
\def\com{\mathsf{Com}}
\def\comRerand{\com.\mathsf{Rerand}}
\def\mht{\mathsf{MHT}}
\def\mhtVerifyMem{\mht.\mathsf{VerifyMem}}
$</div> <!-- $ -->

## Some thoughts

Assume we have a full/complete tree data structure that stores commitments in its leaves, such that all leaves stay at the same level: i.e., trees grows from left to right by appending new leaves.
(Otherwise, privacy challenges with leaf depth leaking when revealed via a non-constant-sized ZK proof.)

Assume we can authenticate the tree by having each parent Pedersen commit to the Pedersen commitments in the children, in a somewhat-structure-preserving way (e.g., via cycles or chains of elliptic curves).

Can we come up with a scheme that proves in ZK that a commitment $\cm'$ was obtained by taking some commitment $\cm$ in such a tree with root $\rt$ and re-randomizing it using some secret blinder $\Delta{r}$?

Let $\com$ denote the Pedersen commitment scheme.
Let $\comRerand(\cdot)$ denote the naturally-defined commitment re-randomization algorithm.

Let $\mht$ denote such a tree-based append-only authenticated data structure, henceforth an **accumulator**.
Let $\mhtVerifyMem(\cdot)$ denote the naturally-defined algorithm for verify a membership proof for a leaf in this tree.

More formally, the NP relation we'd like to prove looks like:
\begin{align}
\mathcal{R}(\rt,\cm'; \cm, \pi,\Delta{r})=1 \Leftrightarrow\begin{cases}
1 &= \mhtVerifyMem(\rt, \cm; \pi)\\\\\
\cm' &= \comRerand(\cm; \Delta{r})
\end{cases}
\end{align}

### Reduction to proving scalar multiplication of committed points by a witness scalar

Given a parent node's commitment $\cm$ to its children $(\cm_0,\cm_1)$, the main challenge lies in proving that $\comRerand(\cm_b;\Delta{r}),b\in\\{0,1\\}$ was computed correctly over one of the children of $\cm$ without leaking which one ($b$) nor the blinding factor ($\Delta{r}$).

There are of course many ways of proving this quite effectively using the right zkSNARK.
These solutions would fall under the category of "improvements upon _curve trees_[^CH22e]".
Very interesting, but not my goal.

My obsession is to see if we can leverage (and improve upon) some existing techniques and do this efficiently with only $\Sigma$-protocols and/or structure-preserving cryptography.
(A bit tricky, since there are some impossibilities around structure-preserving and compressing commitments to group elements.)

{: .todo}
Write exact relation!

## References

For cited works, see below 👇👇

{% include refs.md %}
