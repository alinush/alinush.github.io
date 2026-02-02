---
tags:
 - sigma protocols
 - encryption
 - verifiable shuffle
 - zero-knowledge proofs (ZKPs)
title: Bayer-Groth verifiable shuffle
#date: 2020-11-05 20:45:59
#published: false
permalink: bayer-groth
#sidebar:
#    nav: cryptomat
#article\_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Notes on the [BG12] verifiable shuffle.
<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\enc{\mathcal{E}}
\def\pk{\mathsf{PK}}
$</div> <!-- $ -->

## Notation

 - The original ciphertexts $\vec{C} = (C_i)\_{i\in[n]} = (B\_i, D\_i)_{i\in[n]}$
 - The shuffled ciphertexts $\vec{C'} = (C'\_i)\_{i\in[n]} = (B'\_i, D'\_i)_{i\in[n]}$
 - $\rho_i$ is the blinder used to rerandomize for the $i$th ciphertext $C_i$ and permute it into $C'_{\pi(i)}$ for some permutation $\pi$
 - $\pi$ is the permutation such that $C'\_i = C\_{\pi(i)} + \enc(0, \rho\_i)$
   + or, in vector notation: $\vec{C'} = \pi(\vec{C}) + \enc(\vec{0}, \vec{\rho})$
 - $x$ is a random Fiat-Shamir challenges.

\begin{align}
\vec{C}^\vec{x} &= \begin{bmatrix}
   \sum\_i {x\_i} \cdot B\_i = \sum\_i {x^i} \cdot C\_i,\\\\\
   \sum\_i {x\_i} \cdot D\_i = \sum\_i {x^i} \cdot D\_i
\end{bmatrix}\\\\\
\vec{C’}^\vec{b} &= \begin{bmatrix}
   \sum\_i {b\_i} \cdot B'\_i = \sum\_i {x^{\pi(i)}} \cdot C'\_i,\\\\\
   \sum\_i {b\_i} \cdot D'\_i = \sum\_i {x^{\pi(i)}} \cdot D'\_i
\end{bmatrix}\\\\\
\rho &= -\sum\_i \rho\_i x^{\pi(i)}\\\\\
\enc\_{\pk}(0, \rho) &=(\rho\cdot G, 0 + \rho\cdot \pk) = \begin{bmatrix}
	\left(-\sum\_i \rho\_i x^{\pi(i)}\right) \cdot G,\\\\\
	\left(- \sum\_i \rho\_i x^{\pi(i)}\right)\cdot \pk
\end{bmatrix}\\\\\
\end{align}

## Key technique

The key check in [BG12][^BG12] is that:
\begin{align}
 \sum\_i {x^i}\cdot B\_i = \left(- \sum\_i \rho\_i x^{\pi(i)}\right) \cdot G  + \sum\_i {x^{\pi(i)}}\cdot B'\_i\\\\\
 \sum\_i {x^i}\cdot D\_i = \left(- \sum\_i \rho\_i x^{\pi(i)}\right) \cdot\pk + \sum\_i {x^{\pi(i)}}\cdot D'\_i
\end{align}

Does it make sense to decompose the random linear combination entry by entry?
No, but let's write it down anyway...
\begin{align}
x^i\cdot B\_i 
	&= \left(-\rho\_i x^{\pi(i)}\right) \cdot G  + {x^{\pi(i)}}\cdot B'\_i\\\\\
	&= x^{\pi(i)} \cdot \left(B'\_i - \rho\_i \cdot G\right)\\\\\
x^i\cdot D\_i 
	&= \left(-\rho\_i x^{\pi(i)}\right) \cdot\pk + {x^{\pi(i)}}\cdot D'\_i\\\\\
	&= x^{\pi(i)} \cdot \left(D'\_i - \rho\_i \cdot \pk\right) \\\\\
\end{align}
It's more that the random linear combinations by $x^i$'s and $x^{\pi(i)}$'s help "match up" permuted ciphertexts with one another.
So, the effective checks is that, for all $i\in[n]$:
\begin{align}
B\_{\pi(i)} 
	&= B'\_{i} - \rho_{i} \cdot G\\\\\
D\_{\pi(i)}
	&= D'\_{i} - \rho_{i} \cdot \pk\\\\\
\end{align}

{: .note}
Intuition is that they rerandomize the $i$th original ciphertext by $x^i$ and the $i$th new ciphertext by $x^{\pi(i)}$ and check equality of product of rerandomizations.

It's a bit hard to see but because $B_i$ gets multiplied by $x^i$ and $B'_i$ by $x^{\pi(i)}$. 
This means that $B'_i$ will only be cancelled out by a corresponding $B_j$ with $j = \pi(i)$.
So that's why get the non-intuitive equality above.

## Open question

{: .todo}
Can we improve upon the BG12 approach by leveraging [univariate sumchecks](/univariate-sumcheck) for the product argument and/or multi-exponentiation argument (or even multivariate ones)?
Or Bulletproof-like (G)IPAs?

## References

For cited works, see below 👇👇

{% include refs.md %}
