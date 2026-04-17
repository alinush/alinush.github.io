---
tags:
 - Ligero
 - Reed-Solomon
 - polynomial commitments
 - Merkle
 - coding theory
title: Ligero polynomial commitment scheme
#date: 2020-11-05 20:45:59
published: false
permalink: ligero
sidebar:
    nav: cryptomat
article_header:
  type: cover
  image:
    src: /pictures/aMb.png
---

{: .info}
**tl;dr:** Ligero is a polynomial commitment scheme (PCS) with $O(N)$ prover time, $O(\sqrt{N})$ proof size and $O(\sqrt{N})$ verification time, where $N$ is the number of coefficients.
Ligero is constructed from _Reed-Solomon codes_ and _Merkle trees_.
Unlike group-based PCS (e.g., [Hyrax](/hyrax), [KZG](/kzg), [KZH](/kzh)), Ligero is _hash-based_: it avoids elliptic curve operations entirely and works over any sufficiently-large field, including small fields like Goldilocks64.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\a{\vec{a}}
\def\b{\vec{b}}
\def\y{\vec{y}}
\def\ligero{\mathsf{Ligero}}
\def\ligeronm{\ligero^{n,m}}
\def\ligeroSqN{\ligero^{\sqN}}
\def\ligeroSetup{\ligero.\mathsf{Setup}}
\def\sqN{\sqrt{N}}
\def\RS{\mathsf{RS}}
$</div> <!-- $ -->

{% include mle.md %}
{% include defs-time-complexities.md %}

## Preliminaries

 - [Multilinear extensions (MLEs)](/mle)
 - The finite field $\F$ is of prime order $p$
 - We often denote the binary representation of $b$ as $\term{\vect{b}} \bydef [b_0,\ldots,b_{s-1}]\in\bin^s$, such that $b = \sum_{i\in[s)} b_i 2^i$.

### Reed-Solomon codes

A Reed-Solomon (RS) code $\RS[k, \rho, \F]$ encodes a message $\vec{m}\in\F^k$ as evaluations of a degree-$(k-1)$ polynomial $f$ with coefficient vector $\vec{m}$, yielding a codeword of length $k/\rho$:
\begin{align}
\RS(\vec{m}) = \left(f(\omega^0), f(\omega^1), \ldots, f(\omega^{k/\rho - 1})\right)
\end{align}
where $\omega$ is a $(k/\rho)$-th root of unity.
The parameter $\rho = k/(k/\rho)$ is the **code rate**.
A lower rate means more redundancy, which translates to higher prover cost but better soundness (smaller proof size).

{: .note}
Elsewhere (e.g., in the [ECC](/ecc) and [WHIR](/whir) posts), we use the notation $\RS[\F, L, m]$ where $L$ is the evaluation domain and $m$ is the degree bound.
The two notations relate as follows: $L = \\{\omega^0, \omega^1, \ldots, \omega^{k/\rho - 1}\\}$, $m = k$ (the dimension), and $\rho = m / |L|$ (the rate).

### Merkle trees

A **Merkle tree** over a list of values $(v_0, \ldots, v_{n-1})$ produces a single hash digest (the _root_) that commits to all values.
Opening a single leaf $v_i$ requires an $O(\log n)$-sized authentication path.

## Overview

Like [Hyrax](/hyrax), Ligero represents an MLE $\term{f(\X,\Y)}\in\MLE{\nu,\mu}$ as a matrix:
\begin{align}
\mat{M}\bydef(M\_{i,j})\_{i\in[m],j\in[n]}\bydef (f(\i,\j))\_{i\in[m],j\in[n]}
\end{align}
where $m = 2^\nu$ rows and $n = 2^\mu$ columns, with $N = mn$.

Both Hyrax and Ligero use the same **inner product trick**: to evaluate $f(\x,\y)$, decompose the evaluation into:
\begin{align}
f(\x,\y)
    &= \sum_{i\in[m), j\in[n)} \underbrace{\eq(\x, \i)}\_{a\_i} \cdot M\_{i,j} \cdot \underbrace{\eq(\y,\j)}\_{b\_j}\\\\\
    &= \a\cdot\mat{M}\cdot\b^\top
\end{align}

The key divergence is _how_ the matrix rows are committed and _how_ the inner product is verified:
 - **Hyrax** commits each row via a Pedersen vector commitment and verifies using an inner-product argument (IPA).
 - **Ligero** RS-encodes each row, hashes the columns, commits via a Merkle tree, and verifies by random column sampling (proximity testing).

### The core check

To open an evaluation $z = f(\x,\y)$, the prover computes:
\begin{align}
\a &\gets (\eq(\x, \i))\_{i\in[m)}\in\F^m\\\\\
\y &\gets \a^\top\cdot\mat{M}\in\F^n
\end{align}

This vector $\y$ is a **linear combination of the rows** of $\mat{M}$, weighted by $\a$.
The verifier can check $z = \y\cdot\b^\top$ directly.
But the verifier also needs to check that $\y$ is consistent with the committed matrix.

In Hyrax, this is done by homomorphically deriving a Pedersen commitment to $\y$ from the row commitments, then checking it with an IPA.

In Ligero, this is done by **RS-encoding $\y$** and checking it against random columns of the encoded matrix $\mat{M}'$:
\begin{align}
\RS(\y)[i] = \langle \a, \mat{M}'[:,i] \rangle, \quad \forall i\in I
\end{align}
This works because RS encoding is linear: a linear combination of encoded rows equals the encoding of the linear combination.

## Construction

### $\mathsf{Ligero}.\mathsf{Setup}(1^\lambda, \nu,\mu) \rightarrow \mathsf{pp}$

Notation:
 - $m \gets 2^\nu$ denotes the # of matrix rows
 - $n \gets 2^\mu$ denotes the # of matrix columns
 - $N = m\cdot n\bydef 2^{\nu + \mu}$ denotes the total # of entries in the matrix
 - $\rho$ denotes the RS code rate

The setup is **transparent**: no trusted setup is needed.
The only public parameter is the choice of hash function $H$ for the Merkle tree.

### $\mathsf{Ligero}.\mathsf{Commit}(\mathsf{pp}, f(\boldsymbol{X},\boldsymbol{Y})) \rightarrow (C, \mathcal{D})$

Let:
 - $\mat{M}\in\F^{m\times n}$ denote the matrix representation of the MLE $f$.
 - $\mat{M}'\in\F^{m\times (n/\rho)}$ denote the RS-encoded matrix, where $\mat{M}'[i,:] = \RS(\mat{M}[i,:])$ for each row $i$.

Compute the commitment:

1. RS-encode each row: $\mat{M}'[i,:] \gets \RS(\mat{M}[i,:]),\ \forall i\in[m)$
2. Hash each column of $\mat{M}'$ to get $n/\rho$ column hashes
3. Build a Merkle tree $T$ on top of the column hashes

The commitment is $C \gets \mathsf{root}(T)$.
The auxiliary data is $\mathcal{D} \gets (\mat{M}, \mat{M}', T)$.

{: .note}
Each column of $\mat{M}'$ has $m$ field elements.
The Merkle tree has $n/\rho$ leaves (one per column).

### Commit time

 - RS-encoding each row takes $O(n\log n)$ via FFT, for $m$ rows: $O(mn\log n) = O(N\log n)$
 - Hashing $n/\rho$ columns, each of size $m$: $O(mn/\rho)$ hash operations
 - Building the Merkle tree: $O(n/\rho)$ hashes

In **total**: $O(N\log n)$ field operations + $O(N/\rho)$ hashes.

### $\mathsf{Ligero}.\mathsf{Eval}(\mathsf{pp}, \mathcal{D}, (\boldsymbol{x},\boldsymbol{y}), z) \rightarrow \pi$

To prove $z = f(\x,\y)$:

 - $\a\gets (\eq(\x, \i))\_{i\in[m)}\in\F^{m}$
 - $\b \gets (\eq(\y, \j))\_{j\in[n)}\in \F^{n}$
 - $\y\gets \a^\top\cdot \mat{M}\in \F^{n}$

**Interaction:**

1. $\mathcal{P}$ sends $\mathcal{V}$ the vector $\y = \a^\top\cdot \mat{M}\in\F^n$.
2. $\mathcal{V}$ checks $\langle \y, \b \rangle = z$.
3. $\mathcal{V}$ samples a random subset $I\subseteq [n/\rho]$ with $\|I\| = \Theta(\lambda)$ and sends $I$ to $\mathcal{P}$.
4. $\mathcal{P}$ sends $\mathcal{V}$ columns $\{\mat{M}'[:,i]\}\_{i\in I}$ and corresponding Merkle authentication paths.
5. $\mathcal{V}$ checks the Merkle paths are correct (against commitment $C$).
6. $\mathcal{V}$ checks $\forall i\in I$:
\begin{align}
\RS(\y)[i] = \langle \a, \mat{M}'[:,i] \rangle
\end{align}

### Why step 6 works

$\RS$ is a linear map.
So:
\begin{align}
\RS(\y) &= \RS(\a^\top\cdot \mat{M})\\\\\
&= \a^\top\cdot \RS(\mat{M}) \quad\text{(by linearity)}\\\\\
&= \a^\top\cdot \mat{M}'
\end{align}
Therefore $\RS(\y)[i] = \a^\top\cdot \mat{M}'[:,i] = \langle \a, \mat{M}'[:,i]\rangle$.

If the prover committed to correctly-encoded rows, this check passes.
If any row was incorrectly encoded, the mismatch propagates through the random linear combination $\a$ and is detected at the sampled columns with high probability.

### Proof size

The proof consists of:
 - $\y\in\F^n$: size $O(n) = O(\sqN)$
 - $\Theta(\lambda)$ columns of $\mat{M}'$, each of size $m$: size $O(\lambda m) = O(\lambda\sqN)$
 - $\Theta(\lambda)$ Merkle paths, each of size $O(\log(n/\rho))$: size $O(\lambda\log n)$

In **total**: $O(\lambda\sqN)$.

### Verifier time

 - Computing $\a$: $O(m)$ field operations
 - Computing $\b$: $O(n)$ field operations
 - Checking $\langle \y, \b\rangle = z$: $O(n)$ field operations
 - Computing $\RS(\y)$ at positions in $I$: $O(n\log n)$ via FFT (encode once, read off $\|I\|$ positions), or $O(\lambda n)$ by evaluating the degree-$(n-1)$ polynomial at each point individually
 - Checking $\langle \a, \mat{M}'[:,i]\rangle$ for each $i\in I$: $O(\lambda m)$ field operations
 - Checking Merkle paths: $O(\lambda\log n)$ hashes

In **total**: $O(n\log n + \lambda m + \lambda\log n) = O(\lambda\sqN)$ (when $m=n=\sqN$).

### Prover time

 - Computing $\a$: $O(m)$
 - Computing $\y = \a^\top\cdot\mat{M}$: $O(mn) = O(N)$ field operations
 - Opening $\Theta(\lambda)$ columns and their Merkle paths: $O(\lambda m + \lambda\log n)$

In **total**: $O(N)$ (dominated by the matrix-vector product, which was already done at commit time for the RS encoding).

## Performance summary

We use $\ligeronm$ to refer to $\ligero$ with $m$ rows and $n$ columns, and $\ligeroSqN$ for $m=n=\sqN$.

### Setup, commitments and proof sizes

|---------------+-------+-------------+------+-------|
| Scheme        | $\mathsf{pp}$ | Commit time | $C$ | $\pi$ |
|---------------|-------|-------------|------|-------|
| $\ligeronm$    | $H$    | $O(N\log n)\cdot\F + O(N/\rho)\cdot H$       | $O(1)$    | $O(n + \lambda m + \lambda\log n)$ |
| $\ligeroSqN$   | $H$ | $O(N\log \sqN)\cdot\F + O(N/\rho)\cdot H$ | $O(1)$ | $O(\lambda\sqN)$ |
|---------------+-------+-------------|------|-------|

Here, $C$ is a single Merkle root (constant size), and $H$ denotes the hash function (transparent setup).

### Openings at arbitrary points

|----------------+--------------------+---------------|
| Scheme         | Prover time | Verifier time |
|----------------|--------------------|---------------|
| $\ligeronm$     | $O(mn)\ \F$ | $O(n\log n + \lambda m + \lambda\log n)\ \F$ |
| $\ligeroSqN$    | $O(N)\ \F$ | $O(\lambda\sqN)\ \F$ |
|----------------+--------------------+---------------|

## Key differences between Ligero and Hyrax

| | **Hyrax** | **Ligero** |
|---|---|---|
| **Commitment** | Pedersen vector commitments (one per row) | Merkle tree over RS-encoded columns |
| **Commitment size** | $O(\sqN)$ group elements | $O(1)$ (single Merkle root) |
| **Commit time** | $\sqN$ MSMs of size $\sqN$ | $O(N\log\sqN)$ field ops + hashing |
| **Opening mechanism** | Inner product argument (IPA) | Random column sampling (proximity test) |
| **Algebraic structure** | Group-based (needs elliptic curves) | Hash-based (works over any field) |
| **Field requirements** | Large prime field (for discrete log security) | Any sufficiently-large field (including Goldilocks64) |
| **Proof size** | $O(\sqN)$ (with IPA: $O(\log N)$) | $O(\lambda\sqN)$ |
| **Verifier time** | $O(\sqN)$ (dominated by MSM) | $O(\lambda\sqN)$ (field ops + hashing only) |
| **Prover time** | $O(N)\ \F$ + $O(\sqN)$ group ops | $O(N\log\sqN)\ \F$ + hashing |
| **Trusted setup** | Yes (for group generators) | No (transparent) |
| **Zero-knowledge** | IT hiding + HVZK openings | Requires additional masking |

### The same trick, different tools

Both schemes decompose the polynomial into a matrix $\mat{M}\in\F^{m\times n}$ and reduce evaluation to:
\begin{align}
f(\x,\y) = \a\cdot\mat{M}\cdot\b^\top
\end{align}

Both compute the "aggregated row" $\y = \a^\top\cdot\mat{M}$ and send it to the verifier, who checks $z = \y\cdot\b^\top$.

The divergence is in how the verifier checks that $\y$ is consistent with the committed matrix:

 - **Hyrax**: The Pedersen commitments are _homomorphic_. The verifier computes $D = \sum_i a_i\cdot C_i$, which is a commitment to $\y$ by linearity of Pedersen. Then an IPA (or direct decommitment) proves the inner product $z = \y\cdot\b^\top$ against $D$.

 - **Ligero**: The RS encoding is _linear_. The verifier computes $\RS(\y)$ and checks it against $\a^\top\cdot\mat{M}'[:,i]$ at random column positions $i\in I$. Linearity of RS ensures that $\RS(\a^\top\cdot\mat{M}) = \a^\top\cdot\mat{M}'$.

In both cases, **linearity** is the property that bridges the gap between the committed data and the aggregated row.
Hyrax exploits linearity of Pedersen commitments; Ligero exploits linearity of Reed-Solomon encoding.

### When to prefer which

 - **Ligero** is preferred when you want to avoid elliptic curves, work over small fields (Goldilocks64), or need a transparent setup. Its prover is faster in practice because field operations are much cheaper than group exponentiations.
 - **Hyrax** is preferred when you want smaller proofs ($O(\sqN)$ vs $O(\lambda\sqN)$) or need information-theoretic hiding. Its reliance on discrete-log-based commitments gives it naturally hiding commitments.

## References

For cited works, see below

{% include refs.md %}
