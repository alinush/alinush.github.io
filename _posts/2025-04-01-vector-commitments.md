---
tags:
 - vector commitments (VCs)
title: Vector commitments (VCs)
#date: 2020-11-05 20:45:59
#published: false
permalink: vc
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Definition of **vector commitment (VC)** schemes (e.g., [Merkle trees](/merkle), [KZG-based](/kzg), Pointproofs[^GRWZ20], aSVC[^TABplus20], etc. can all satisfy this definition.)

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\ad{\mathsf{authData}}
$</div> <!-- $ -->

## Preliminaries

A $B$-subvector of a vector $\mathbf{v}$ is defined as just the elements from $\mathbf{v}$ that are at the positions in $B$:
i.e., $\mathbf{v}[B] \bydef (v\_j)\_{j\in B}$.

## Definitions

All algorithms are deterministic.

Typically, the VC setting includes:
 1. A _prover_, who computes a _commitment_ to a _vector_.
 2. A _verifier_, who is given such a commitment and is interested in verifying that an element $v_j$ is indeed at position $j$ in the committed vector.

### Vanilla VCs

$\mathsf{VC.Commit}(\mathbf{v}\bydef [v\_1, v\_2,\ldots,v\_n])\rightarrow (c, \ad)$  
Given a *vector* $\mathbf{v}$, computes its commitment $c$ and _authentication data_ $\ad$, which helps speed up the prover.

{: .note}
Depending on the VC scheme, $\ad$ can store the vector $\mathbf{v}$, the commitment $c$, and/or any pre-computed proofs.
For [Merke-based VCs](/merkle), the $\ad$ would include the Merkle tree itself.
This way, the prover, who has $\ad$, can prove $v_j$ is the $j$th element by giving a Merkle path to it.
For [KZG-based VCs with FK](/feist-khovratovich), the $\ad$ would include all $n$ precomputed _(individual) proofs_ for each position $j\in[n]$.

$\mathsf{VC.Prove}(\ad, j) \rightarrow (\pi\_j)$  
Given authentication data $\ad$, fetch (or compute) an _individual proof_ $\pi_j$ for *element* $v_j$ being at position $j$.

$\mathsf{VC.Verify}(c, j, v\_j, \pi\_j)\rightarrow \{0,1\}$  
Verifies the individual proof $\pi_j$ that $v_j$ is the $j$th element of the vector committed in $c$.

### SVCs

$\mathsf{VC.Aggregate}(c, (j,v\_j,\pi\_j)\_{j\in B})\rightarrow \hat{\pi}$  
Given a *$B$-subvector* and individual proofs $\pi_j$ for each position $j\in B$ in this subvector, *aggregates* them into a _subvector proof_ $\hat{\pi}$.

$\mathsf{VC.AggVerify}(c, B, \mathbf{v}[B], \hat{\pi})\rightarrow \{0,1\}$  
Verifies the subvector proof $\hat{\pi}$ that $\mathbf{v}[B]$ is indeed the $B$-subvector of the vector committed in $c$.

### Cross-aggregatable SVCs

$\mathsf{VC.CrossAggregate}\left(\{c\_i, B\_i,\mathbf{v}\_i[B\_i],\hat{\pi}\_i)\}\_{i\in[\ell]}\right)\rightarrow \pi$  
*Cross-aggregates* a bunch of subvector proofs for different vectors into a _cross-aggregated proof_ $\pi$.

$\mathsf{VC.CrossVerify}\left(\{c\_i, B\_i,\mathbf{v}\_i[B\_i]\}_{i\in[\ell]},\pi\right)\rightarrow \{0,1\}$  
Verifies a cross-aggregated proof for the given subvectors and their associated vectors' commitments.

## TODOs

 - Proof updates for vanilla VCs and SVCs (and maybe cross-agg VCs[^TXN20e]?)
    + hintless
    + with hints
    + with update keys
 - Hiding VCs

## References

For cited works, see below 👇👇

{% include refs.md %}
