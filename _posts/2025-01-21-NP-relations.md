---
tags:
 - basics
 - zero-knowledge proofs (ZKPs)
title: NP relations
#date: 2020-11-05 20:45:59
#published: false
sidebar:
    nav: cryptomat
permalink: np-relations
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

**tl;dr:** An _NP relation_ $R(\mathbf{x}; \mathbf{w})$ is a formalization of an algorithm $R$ that verifies a solution $\mathbf{w}$ to a problem $\mathbf{x}$ (in time $\poly(|\mathbf{x}|+|\mathbf{w}|)$.
For example, $\mathsf{Sudoku}(\mathbf{x}; \mathbf{w})$ verifies if $\mathbf{w}$ is a valid solution to the Sudoku puzzle $\mathbf{x}$.
NP relations are extremely helpful when formalizing **zero-knowledge proofs** as a way of _"proving knowledge of a witness $\mathbf{w}$ such that $R(\mathbf{x}; \mathbf{w}) = 1$ for a public statement $\mathbf{x}$_".
{: .info}

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

{% include zkp.md %}

## What is an NP relation?

An **NP relation** $R(\stmt; \witn)$ is a deterministic algorithm that runs in polynomial time in the length of the **statement** $\stmt$ and the **witness** $\witn$ and outputs either 0 or 1, based on custom checks it performs on $\stmt$ or $\witn$.

NP relations are a useful mathematical formalization of **hard** problems ($\stmt$) whose solutions ($\witn$) are **easy** to _verify_ (i.e., in polynomial time).

{: .info}
We often denote $R(\stmt;\witn) = 1$ as $(\stmt, \witn)\in R$.

## Examples

### Factoring

$\mathsf{Factors}(n; p, q)$ is an NP relation that checks if $n$ factors into prime factors $p$ and $q$: i.e., it outputs 1 if $n,p,q\in \mathbb{N}^\*$ and $n=pq$ and $p\ne 1$ and $q\ne 1$, or outputs 0 otherwise.

\begin{align\*}
\mathsf{Factors}(n; p, q) =
\begin{cases}
1 & \text{if } n, p, q \in \mathbb{N}^*, p \ne 1, q \ne 1, \text{ and } n = pq \\\\\
0 & \text{otherwise}
\end{cases}
\end{align\*}

For a sufficiently large composite number $n$, it is **very** hard to find its factors $p$ and $q$.
In fact, there is no known polynomial-time algorithm (in the bit-length of $n$) for this problem.
In this sense, factoring perfectly illustrates the "hard-to-solve-but-easy-to-verify" nature of NP relations.

### Merkle tree membership

$\mathsf{IsMember}(r, v_i; i, \pi)$ is an NP relation that outputs 1 if the Merkle proof $\pi$ correctly attests that $v_i$ is the value of the $i$th leaf in the [Merkle tree](/merkle) with root hash $r$. Otherwise, it outputs 0.

{: .note}
Note that a zero-knowledge proof for this relation would allow the prover to hide the position $i$ of the leaf and its Merkle proof $\pi$, while convincing the verifier that the value $v_i$ is (somewhere) in the tree.
This can be very useful.
For example, anonymous payment schemes like Zcash are built on top of such a relation!

### Merkle proof aggregation

$\mathsf{AreMembers}\left(r, \\{v\_j\\}\_{j \in [n]}; (i\_j, \pi\_j)\_{j\in [n]}\right)$ is an NP relation that outputs 1 if, for all $j\in[n]$, the Merkle proof $\pi_j$ correctly attests that $v_j$ is the value of the $i_j$th leaf in the [Merkle tree](/merkle) with root hash $r$. Otherwise, it outputs 0.

{: .note}
A succinct (not necessarily zero-knowledge) proof for this relation would allow the prover to "compress" the $n$ proofs $\pi_j$ for the $n$ values.
For an example of such a succinct proof when the Merkle tree is algebraic, see our [Hyperproofs](/hyperproofs) paper.

---

{% include refs.md %}
