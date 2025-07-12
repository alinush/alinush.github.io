---
tags:
 - sumcheck
 - polynomials
title: The multivariate sumcheck protocol
date: 2025-06-20 20:45:59
#published: false
permalink: sumcheck
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** The sumcheck protocol is an extremely-powerful technique for (zero-knowledge) argument systems.
In this short blog post, I will try to summarize it for my own benefit and, hopefully, yours too.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\P{\mathcal{P}}
\def\V{\mathcal{V}}
\def\oracle#1{[[#1]]}
\def\b{\boldsymbol{b}}
\def\bin{\{0,1\}}
\def\binMu{\{0,1\}^\mu}
$</div> <!-- $ -->

{% include mle.md %}

## Preliminaries

 - $\F$ is a prime-order finite field
 - $f(X_1,X_2,\ldots,X_\mu)$ denotes a $\mu$-variate polynomial with coefficients in $\F$.
 - $d_j\bydef \deg_j(f)$ is the highest degree of $f$ in the variable $X_j$
 - $f$ is said to be **multilinear** when $\deg_j(f) = 1$ for all $j\in[\mu]$
 - a [multilinear extensions (MLE)](/mle) of a vector $\vec{v} = [v_0,\ldots,v_{2^\mu -1}]$ is a multilinear polynomial $f$ such that $f(i_1,i_1,\dots,i_\mu) = v_i$ where $i= \sum_{j=1}^{\mu} i_j \cdot 2^{j-1}$
    + this is the multivariate counterpart of [univariate polynomials interpolated from a vector](/2022/07/28/lagrange-interpolation.html)
 - we often work with the **boolean hypercube** $\binMu$
    + a fancy name for: _"all the bit-strings of size $\mu$"_
 - we denote vectors by bolded variables: e.g., $\x \bydef [x_1, x_2, \ldots, x_n]$
 - $\b$ is often used to denote a bit vector of size $\mu$ 
 - we use $\oracle{f}$ to denote an oracle to the polynomial $f$
    + such an oracle will correctly respond to any evaluation query of the form: $f(a_1,\ldots,a_\mu) \equals b$

## What is sumcheck?

The sumcheck protocol allows a **prover** $\term{\P}$ to convince a **verifier** $\term{\V}$ that a multivariate polynomial $\term{f}$ sums to $\term{H}$ over the boolean hypercube $\binMu$:

\begin{align}
\label{rel:sumcheck}
\emph{H} &= \sum_{\b \in \binMu} \emph{f}(b_1,b_2,\ldots,b_\mu)\\\\\
  &= \sum_{b_1 \in \bin} \sum_{b_2 \in \bin} \cdots \sum_{b_\mu \in \bin} f(b_1,b_2,\ldots,b_\mu)\\\\\
\end{align}

{: .note}
Both $\P$ and $\V$ have access to the same $\term{\mu}$-variate polynomial $f$, although $\V$ is assumed to only have **oracle access** (e.g., typically, via a polynomial commitment scheme).

While the sumcheck protocol inherently must require $\P$ to compute $O(2^\mu)$ polynomial evaluations of $f$ it **surprisingly** only requires $\V$ to compute **a single** _random_ polynomial evaluation of $f$, together with some other sumcheck verification work linear in the number of variables (which is typically sublinear in the number of coefficients of the polynomial).

## Overview

The **key idea** is: reduce a sumcheck of size $\mu$ to a sumcheck of size $\mu-1$ by replacing the current variable $X_1$ with a random value $r_1\in \F$ from $\V$.

We do this until we "run out" of variables and $\V$ is simply left with the task of evaluating $f(r_1, r_2,\ldots,r_\mu)$.

We explain the **interactive** sumcheck protocol below.
First, there is an [initialization](#initialization) phase for both $\P$ and $\V$.
Then, there $\mu$ rounds of interaction.
We begin by describing the first two rounds, as a warm up.
Then, we explain what a general round $j$ looks likely.
We finish by describing the last round which handles things a bit differently.

### Initialization

 - $\P$ starts with the polynomial $\emph{f}(X_1,\ldots,X_\mu)$
 - $\V$ starts with:
    - the number of variables $\mu$
    + the degrees $d_j\bydef \deg_j(f)$ of each variable $X_j$ of $f$
    + an **oracle** $\term{\oracle{f}}$ to $f$

### Round $1 \lt \mu$ (special case)

 - $\P$ computes $\term{g_1(X)} \gets \underbrace{\sum_{b_2 \in \bin} \cdots \sum_{b_\mu \in \bin}}\_{\mu-1\ \text{variables}} f(X, b_2,\ldots,b_\mu)$.
    + Note we are not summing over $b_1$; we are excluding $\sum_{b_1\in\bin}$.
 - $\P \xrightarrow{g_1(X)}\V$
 - $\V$ checks:
    + $g_1(X)$ is of degree $d_1$
    + $\emph{H} \equals g_1(0) + g_1(1)$, as it should be (by definition of $H$ and $g_1$).
 + $\V$ randomly picks $\term{r_1}\randget\F$
 + $\V \xrightarrow{r_1} \P$

### Round $2 \lt \mu$ (example)

 - $\P$ computes $\term{g_2(X)} \gets \underbrace{\sum_{b_3 \in \bin} \cdots \sum_{b_\mu \in \bin}}\_{\mu-2\ \text{variables}} f(r_1, X, b_3, \ldots,b_\mu)$.
 - $\P \xrightarrow{g_2(X)}\V$
 - $\V$ checks:
    + $g_2(X)$ is of degree $d_2$
    + $\emph{g_1(r_1)} \equals g_2(0) + g_2(1)$, as it should be (by definition of $g_1$ and $g_2$).
 + $\V$ randomly picks $\term{r_2}\randget\F$
 + $\V \xrightarrow{r_2} \P$

### Round $j \lt \mu$ (general case)

The protocol continues in this fashion for every round $j \lt \mu$:
  - $\P$ computes $\term{g_j(X)} \gets \underbrace{\sum_{b_{j+1} \in \bin} \cdots \sum_{b_\mu \in \bin}}\_{\mu-j\ \text{variables}} f(r_1, \ldots, r_{j-1}, X, b_{j+1}, \ldots,b_\mu)$.
  - $\P \xrightarrow{g_j(X)}\V$
  - $\V$ checks:
     + $g_j(X)$ is of degree $d_j$
     + $\emph{g_{j-1}(r_{j-1})} \equals g_j(0) + g_j(1)$, as it should be (by definition of $g_{j-1}$ and $g_j$).
  + $\V$ randomly picks $\term{r_j}\randget\F$
  + $\V \xrightarrow{r_j} \P$

### Round $\mu$ (special case)

Note: In the previous round, the polynomial $g_{\mu -1}(X)\bydef \sum_{b_\mu\in\bin} f(r_1, \ldots, r_{\mu-2}, X, b_\mu)$.

 - $\P$ computes $\term{g_\mu(X)} \gets f(r_1, \ldots, r_{\mu-1}, X)$.
 - $\P \xrightarrow{g_\mu(X)}\V$
 - $\V$ checks:
    + $g_\mu(X)$ is of degree $d_\mu$
    + $\emph{g_{\mu-1}(r_{\mu-1})} \equals g_\mu(0) + g_\mu(1)$, as it should be (by definition of $g_{\mu-1}$ and $g_\mu$).
 + $\V$ randomly picks $\term{r_\mu}\randget\F$
 - $\V$ queries $\oracle{f}$ on whether $\emph{f(r_1, \ldots, r_\mu) \equals g_\mu(r_\mu)}$ 

### The proof

The **sumcheck proof** will consist of all the univariate polynomials sent by the prover:
\begin{align}
\label{eq:proof}
  \pi &\bydef \left(g\_j(X)\right)\_{j\in[\mu]},\ \text{where}\\\\\
  g\_j(X) &\bydef \sum_{i\in[0, d\_j]} g\_{j, i} X^i \bydef [g_{j,0}, g_{j,1},\ldots,g_{j,d_j}]
\end{align}

{: .note}
The prover can send the $d+1$ coefficients of the polynomials, as expressed above, or $d+1$ different evaluations.

## Properties

The sumcheck protocol has many nice properties:

 1. Works over any set $S^\mu$, not just $\binMu$
 1. Soundness error is $\le \frac{\mu d}{\vert \F \vert}$, where $d = \max_j (\deg_j(f))$
    + For the scalar field of an elliptic curve, $\vert \F \vert \approx 2^{256}$, so this error is negligible
 1. $\P$'s overhead is only a constant factor higher than what is required to compute the sum $H$ itself
    + **TODO:** clarify how much higher
 1. $\V$'s messages are completely independent of the polynomial $f$
 1. $\V$ need only have:
    - The number of variables $\mu$, since that dictates the number of rounds
    - The max degrees of each variable $\deg_j(f),\forall j\in[\mu]$
       + Since $\V$ needs to check the degrees of the univariate polynomials $g_j$ sent by $\P$
    - An oracle $\oracle{f}$
 1. $\V$ only needs to query the oracle $\oracle{f}$ on one random evaluation $f(r_1, r_2, \ldots, r_\mu)$
 1. $\P$ can be optimized when $f$ is a multilinear extension (MLE) or a product of MLEs

## Efficiency

### Proof size
 
Since the sumcheck proof consists of all the univariate polynomials sent by the prover, as per Eq. \ref{eq:proof}, its size is:
\begin{align}
\|\pi\| 
 &= \left(\sum\_{j\in[\mu]} (\deg\_j(f) + 1)\right) \times \F\\\\\
 &= \left(\sum\_{j\in[\mu]} (d\_j + 1)\right) \times \F
\end{align}

For example:
 + When $f$ is multilinear, the proof size is $2\mu$!
 - When $f$ has max degree $d$ in _any_ variable, the proof size is $\sum_{j\in[mu]} (d+1) = (d+1)\mu$ elements in $\F$

{: .note}
HyperPLONK[^CBBZ22e] gives a technique to reduce the proof size.
For example, when using KZG commitments, the proof is reduced to (1) $\mu\times \Gr_1 + \mu\times \F$ elements and (2) a batch evaluation proof[^BDFG20], IIUC.

## Conclusion

### Acknowledgements
Most of this write-up is a re-transcription of Justin Thaler's notes[^Thal20], as an excercise in making sure I understand things well enough.
Thanks to Wicher Malten for early feedback on this post.

### Prize-winning stuff

The sumcheck interactive proof (IP) relation $\mathcal{R}\_\mathsf{sum}^\mathsf{IP}$ (note that there is no secret witness):

\begin{align}
%\label{rel:sumcheck}
\mathcal{R}\_\mathsf{sum}^\mathsf{IP}(f, H) = 1 \Leftrightarrow H = \sum_{b_1 \in \bin} \sum_{b_2 \in \bin} \cdots \sum_{b_\mu \in \bin} f(b_1,b_2,\ldots,b_\mu)
\end{align}

{% include refs.md %}
