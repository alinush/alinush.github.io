---
tags:
 - digital signatures
 - Pedersen
 - vector commitments (VCs)
title: Pointcheval-Sanders (PS) signatures
#date: 2020-11-05 20:45:59
permalink: pointcheval-sanders
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Pointcheval-Sanders (PS) is the coolest most versatile signature scheme I know of!

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\x{\red{x}}
\def\y{\red{y}}
\def\tg{\tilde{g}}
\def\tX{\tilde{\green{X}}}
\def\tY{\tilde{\green{Y}}}
\def\pedRerand{\mathsf{Ped.Rerand}}
\def\cm{\mathsf{cm}}
$</div> <!-- $ -->

I love PS signatures[^PS16].

This is an **early draft** on how they work.

For further details, I will refer you to some decentralized thoughts we had on PS[^dt].

## Related work

{: .todo}
CL, BBS+

## Preliminaries


PS requires [pairing-friendly groups](/pairings) $(\Gr_1,\Gr_2,\Gr_T)$ of Type III (important!): there should not be any homomorphism from $\Gr_2$ back to $\Gr_1$.

Let $p$ denote the prime order of these groups.

Let $(g,\tg)$ denote the generators of $\Gr_1$ and $\Gr_2$, respectively.

### Pedersen vector commitments

{: .todo}
Define re-randomization via $\pedRerand$: $\cm'\gets \cm\cdot h^{\Delta{r}}$.
Move to its own cryptomat page [here](/pedersen).

## The PS signature scheme

### Algorithms

$\mathsf{PS}$.$\mathsf{KeyGen}(1^\lambda) \rightarrow (\sk, \pk)$:
 - $(\x,\y_1,\ldots,\y_\ell)\randget\Zp^{\ell+1}$
 - $(\tX,\tY_1,\ldots,\tY_\ell) \bydef (\tg^\x, \tg^{\y_1},\ldots,\tg^{\y_\ell})$
 - $\sk\gets (\x,\y_1,\ldots,\y_\ell)$
 - $\pk\gets (\tX, \tY_1, \ldots, \tY_\ell)$

$\mathsf{PS}$.$\mathsf{Sign}(\vec{m}\bydef[m_1,\ldots,m_\ell], \sk) \rightarrow \sigma$:
 - $u\randget \Zp$
 - $h\gets g_1^u$
 - $(\x,\y_1,\ldots,\y_\ell)\parse\sk$
 - $\sigma\gets \left(h, h^{\x + \sum_{i\in[\ell]} m_i \y_i}\right)$

$\mathsf{PS}$.$\mathsf{Verify}(\vec{m}, \pk, \sigma) \rightarrow \\{0,1\\}$:
 - $(\tX,\tY_1,\ldots,\tY_\ell)\parse\pk$
 - $(\sigma_1,\sigma_2)\parse\sigma$
 - **assert** $e(\sigma_1, \tX) e\left(\sigma_1, \prod_{i\in[\ell]} \tY_i^{m_i}\right) = e(\sigma_2, \tg) $ 

$\mathsf{PS}$.$\mathsf{Rerand}(\sigma) \rightarrow \sigma'$
 - $(\sigma_1,\sigma_2)\parse\sigma$
 - $t\randget \Zp$
 - $\sigma' \gets (\sigma_1^t, \sigma_2^t)$

{: .todo}
Explain that this is better than CL signatures, which had three group elements.
Explain that a PoK of a signature has to be used with this, since the actual signature always leaks the message by virtue of the verification algorithm.
Explain that this can be handled by verifying over a re-randomized commitment[^TBAplus22e].

## References

For cited works, see below 👇👇

{% include refs.md %}

[^dt]: [Pairing-based Anonymous Credentials and the Power of Re-randomization](https://decentralizedthoughts.github.io/2023-01-08-re-rand-cred/), by Ittai Abraham and Alin Tomescu
