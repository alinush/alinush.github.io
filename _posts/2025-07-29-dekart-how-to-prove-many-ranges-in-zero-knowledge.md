---
tags:
title: "DeKART: How to prove many ranges in zero-knowledge"
#date: 2020-11-05 20:45:59
#published: false
permalink: dekart
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** [Dan](https://crypto.stanford.edu/~dabo/), [Kamilla](https://x.com/nazirkamilla), Alin, [Rex](https://x.com/rex1fernando) and [Trisha](https://x.com/TrishaCDatta) came up with a blazing-fast batched ZK range proof for KZG-like committed vectors of values.

<!--more-->

{% include pairings.md %}
{% include fiat-shamir.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\correlate#1{\mathsf{CorrelatedRandomness}(#1)}
\def\dekart{\mathsf{DeKART}}
\def\dekartUni{\dekart^\mathsf{FFT}}
\def\dekartMulti{\dekart^{\vec{X}}}
\def\H{\mathbb{H}}
\def\bbb#1{#1}
\def\bad#1{\textcolor{red}{\text{#1}}}
\def\good#1{\textcolor{green}{\text{#1}}}
$</div> <!-- $ -->

## Introduction

In a very short blog post[^Borg20], Borgeaud describes a very simple range proof for a single value $z$, which we summarize [here](borgeauds-unbatched-range-proof).
In this blog post, accompanying our academic paper[^BDFplus25e], we observe that Borgeaud's elegant protocol **very efficiently** extends to batch-proving **many values**[^BDFplus25e].

## Preliminaries

 - [Univariate polynomials](/polynomials)
 - [KZG polynomial commitments](/kzg)
 - [MLEs](/mle)
 - $[\ell)\bydef\\{0,1,\ldots,\ell-1\\}$
 - $\F$ is a finite field of prime order $p$
 - $r\randget S$ denotes randomly sampling from a set $S$
 - We use $\one{a}\bydef a\cdot G_1$ and $\two{b}\bydef b\cdot G_2$ and $\three{c}\bydef c\cdot G_\top$ to denote scalar multiplication in bilinear groups $(\Gr_1,\Gr_2,\Gr_\top)$ with generators $G_1,G_2,G_\top$, respectively (i.e., additive group notation).
 - We use "small-MSM" to refer to multi-scalar multiplications (MSMs) where the scalars are small; we use "L-MSM" to refer to ones where the scalars are large
{% include prelims-fiat-shamir.md %}

### Borgeaud's unbatched range proof

The **verifier** has a homomorphic commitment (e.g., a [KZG commitment](/kzg)) to a polynomial $\term{f(X)}$ that encodes a value $\term{z}$ as:
\begin{align}
f(X) = \term{r}X + z
\end{align}
where $\emph{r}\randget \F$ is a blinder. Note that $f(0)=z$.
The **prover** wants to prove that $z$ is an $\term{\ell}$-bit value: i.e., that $z\in[0,2^\ell)$.

Prover commits to each bit $\term{z_j}$ of $z\bydef \sum_{j\in[\ell)} z_j 2^j$ via $\ell$ blinded polynomials:
\begin{align}
\term{f_j(X)} = \term{r_j} X + z_j
\end{align}
where $\emph{r_j}\randget \F$ is a blinder. Note that $f_j(0)=z_j$. As a result, we have:
\begin{align}
\label{eq:f}
f(X) = \sum_{j\in[\ell)} f_j(X) 2^j
\end{align}

For Eq. \ref{eq:f} to hold, the prover picks $r_j$’s randomly but correlates them such that:
\begin{align}
r = \sum_{j\in[\ell)} r_j 2^j
\end{align}
We denote this by $(r_j)_{j\in[\ell)}\randget \term{\correlate{r, \ell}}$.

Note that, if the prover gives the $f_j$ commitments to the verifier, then the verifier can combine them homomorphically and obtain's $f$’s commitment.
This assures the verifier that $z=\sum_{j\in[\ell)} z_j 2^j$.
Thus the prover's remaing work is to prove that $z_j\in\\{0,1\\},\forall j\in[\ell)$.

The key observation is that $z_j\in\\{0,1\\}$ can be reduced to a claim about the $f_j$'s:
\begin{align}
z_j\in\\{0,1\\} \Leftrightarrow\\\\\
f_j(0) \in \\{0,1\\} \Leftrightarrow\\\\\
\begin{cases}
f_j(0) = 0 \lor{}\\\\\
f_j(0) = 1\\\\\
\end{cases}\Leftrightarrow\\\\\
\begin{cases}
    (X - 0) \mid f_j(X) - 0 \lor {}\\\\\
    (X - 0) \mid f_j(X) - 1\\\\\
\end{cases}\Leftrightarrow\\\\\
\emph{X \mid f_j(X) (f_j(X) - 1)}
%\Leftrightarrow\\\\\ 
\end{align}
The last claim can be proved by showing there exists a quotient polynomial $\term{h_j(X)}$ such that:
\begin{align}
X\cdot h_j(X) = f_j(X)\left(f_j(X) - 1\right) 
\end{align}

If the verifier has KZG commitments to the $f_j$'s, the verifier can be given a KZG commitment to $h_j$ and use a pairing-check to enforce the above relation:
\begin{align}
\pair{\one{h_j(\tau)}}{\two{\tau}} &= \pair{\one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}},\forall j\in[\ell)
\end{align}
(Note that $\term{\tau}$ denotes the KZG trapdoor here.)
For this to work, the verifier must verify "duality" of the $\Gr_1$ and $\Gr_2$ commitments to $f_j$:
\begin{align}
\label{eq:duality}
\pair{\one{f_j(\tau)}}{\two{1}} &= \pair{\one{1}}{\two{f_j(\tau)}},\forall j\in[\ell)
\end{align}

## Univariate batched ZK range proof 

{: .warning}
This construction is [not yet known to be ZK](#multilinear-batched-zk-range-proof).

We observe that the $f$ and $f_j$ polynomials could be re-defined to store the bits of **$n$ different values** $\term{z_0, \ldots, z_{n-1}}$ without affecting the proof size and verifier time too much!

Firt, we store all the $n$ values in the polynomial $\emph{f}$, now of degree $n$:
\begin{align}
\label{eq:f-batched}
f(\omega^i) &= z_i,\forall i\in[n)\\\\\
f(\omega^n) &= r
\end{align}
where $r\randget \F$ is a blinding factor as before.

Let $\term{z_{i,j}}$ denote the $j$th bit of the $i$th value $z_i \bydef \sum_{i\in[\ell)} z_{i,j} 2^j$.
Second, we store the $j$th bit of all the values in the $\emph{f_j}$ polynomials, now of degree $n$ too:
\begin{align}
f_j(\omega^i) &= z_{i,j},\forall i\in[n)\\\\\
f_j(\omega^n) &= r_j
\end{align}
where $(r_j)_{j\in[\ell)} \randget \correlate{r, \ell}$ are randomly picked as before and $\term{\omega}$ is a $(n+1)$th primitive root of unity in $\F$. 

{: .note}
We will typically (and a bit awkwardly) require that $n \gets 2^k-1$, since many fields $\F$ of interest have prime order $p$ where $p-1$ is divisible by $2^k\bydef n+1$ and thus will admit an $(n+1)$th primitive root of unity. e.g., [BLS12-381](/pairings#bls12-381-performance) admits a root of unity for $k=32$.

Importantly, note that Eq. \ref{eq:f} still holds for these (redefined) $f$ and $f_j$ polynomials!
\begin{align}
f(X) = \sum_{j\in[\ell)} f_j(X) 2^j
\end{align}

Let $\term{\H}\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$ denote all $(n+1)$th roots of unity.
The key observation is that proving that $f_j$ stores bits is equivalent to:
\begin{align}
f_j(X) \in \\{0,1\\}, \forall X\in \H\setminus\\{\omega^n\\}\Leftrightarrow
\\\\\
\left. \frac{X^{n+1} - 1}{X - \omega^n}\ \middle|\ f_j(X)\left(f_j(X) - 1\right) \right.
\end{align}
This, in turn, is equivalent to proving there exists a quotient polynomial $\term{h_j(X)}$ of degree $2n - n = n$ such that:
\begin{align}
\frac{X^{n+1} - 1}{X - \omega^n} \cdot h_j(X) = f_j(X)\left(f_j(X) - 1\right)
%\Leftrightarrow
%(X^{n+1} - 1)\cdot h_j(X) = (X-\omega^n)f_j(X)\left(f_j(X) - 1\right)
\end{align}
The verifier would how to check, for each $j\in[\ell)$ that:
\begin{align}
\label{eq:hj-inefficient}
\pair{\one{h_j(\tau)}}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}} &= \pair{\one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}},\forall j\in[\ell)
\end{align}
As before, for this to work, the verifier would also verify "duality" of the $\Gr_1$ and $\Gr_2$ commitments to $f_j$ as per Eq. \ref{eq:duality}.

For performance, the verifier could verify pick a random challenge $\term{\beta}\randget\F$ and combine all the checks from Eq. \ref{eq:hj-inefficient} into one:
\begin{align}
\label{eq:hj}
\pair{\underbrace{\sum_{j\in[\ell)} \beta_j \cdot \one{h_j(\tau)}}\_{\term{D}}}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}}
 &= 
\sum_{j\in[\ell)} \pair{\beta_j \cdot \one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}}
\end{align}
(A similar trick can be applied for the duality check as well from Eq. \ref{eq:duality}.
Furthermore, everything can be combined into a single multi-pairing.)

Next, instead of asking for the individual $h_j$ commitments, the verifier will send $\beta$ to the prover and expect to receive just the commitment $\emph{D}$ to the random linear combination of the $h_j$'s.
This reduces proof size and makes the check in Eq. \ref{eq:hj} slightly faster:
\begin{align}
\label{eq:hj-efficient}
\pair{D}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}}
 &= 
\sum_{j\in[\ell)} \pair{\beta_j \cdot \one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}}
\end{align}
This is the bulk of a KZG-based **univariate** DeKART, which we describe formally below.

{: .note}
DeKART easily generalizes to other homomorphic commitment schemes (e.g., Bulletproofs[^BBBplus18]).
With some effort, it will also work for non-homomorphic ones (e.g., FRI[^BBHR18FRI]).

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Setup}(1^\lambda, n)\rightarrow \mathsf{prk},\mathsf{vk}$

Generate powers of $\tau$ up to and including $\tau^n$: the highest degree of a committed polynomial is $n$.
(Note that even the vanishing polynomial $(X^{n+1}-1)/(X-\omega^n)$ will have degree $n$.)

 - $\tau\randget\F$
 - $\term{G_i}\gets \one{\tau^i},\forall i\in[0,n]$ 
 - $\omega \gets$ a primitive $(n+1)$th root of unity in $\F$
 - $\H\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$

Let $\term{\ell_i(X)} \bydef \prod_{j\in\H, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}$ denote the $i$th [Lagrange polynomial](/lagrange-interpolation), for $i\in[0, n]$.

 - $\term{L_i}\gets \one{\ell_i(\tau)},\forall i\in[0,n]$
 - $\term{\tilde{L}_i}\gets \two{\ell_i(\tau)},\forall i\in[0,n]$
 - $\term{\tilde{V}} \gets \two{\frac{\tau^{n+1} - 1}{\tau-\omega^n}}$
    + Note that this has degree $n$

Return the public parameters:
 - $\vk\gets (\two{\tau},\tilde{V})$
 - $\prk\gets \left(\vk, (L_i)\_{i\in[0,n]},(\tilde{L}\_i)_{i\in[0,n]}\right)$

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Commit}(\mathsf{prk},z_0,\ldots,z_{n-1}; r)\rightarrow C$

This is just a [KZG commitment](/kzg) to the vector $\vec{z}\bydef [z_0,\ldots,z_{n-1}]$:

 - $\left(\cdot, (L_i)\_{i\in[0,n]}, \cdot)_{i\in[0,n]}\right)\parse\prk$
 - $C \gets r\cdot L_n + \sum_{i\in[n)} z_i \cdot L_i = r\cdot\one{\ell_n(\tau)} + \sum_{i\in[n)} z_i \cdot \one{\ell_i(\tau)} \bydef \one{\emph{f}(\tau)}$ (as per Eq. \ref{eq:f-batched})

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, C, \ell; z_0,\ldots,z_{n-1}, r)\rightarrow \pi$

Let $\emph{z_{i,j}}$ denote the $j$th bit of each $z_i\in[0,2^\ell)$.

 - $\left(\vk, (L_i)\_{i\in[0,n]},(\tilde{L}\_i)_{i\in[0,n]}\right)\parse\prk$
 - $(r_j)_{j\in[n)} \randget \correlate{r, \ell}$
 - $C_j \gets r_j \cdot L_n + \sum_{i\in[n)} z_{i,j}\cdot L_i = r_j\cdot \one{\ell_n(\tau)} + \sum_{i\in[n)} z_{i,j}\cdot\one{\ell_i(\tau)} \bydef \one{\emph{f_j}(\tau)},\forall j\in[\ell)$
 - $\tilde{C}\_j \gets r_j \cdot \tilde{L}\_n + \sum_{i\in[n)} z_{i,j}\cdot \tilde{L}_i = \ldots \bydef \two{\emph{f_j}(\tau)},\forall j\in[\ell)$
    - **Note:** The $2\ell$ size-$(n+1)$ MSMs here can be carefully-optimized: the scalars are either 0 or 1.
 - add $(\vk, C, \ell, (C_j, \tilde{C}\_j)_{j\in[\ell})$ to the $\FS$ transcript
 - $h_j(X)\gets \frac{f_j(X)(f_j(X) - 1)}{(X^{n+1} - 1) / (X-\omega^n)} = \frac{(X-\omega^n)f_j(X)(f_j(X) - 1)}{X^{n+1} - 1},\forall j \in[\ell)$
    + **Note:** Numerator is degree $2n$ and denominator is degree $n \Rightarrow h_j(X)$ is degree $n$
  $(\beta_j)_{j\in[\ell)} \fsget \\{0,1\\}^\lambda$
 - $\term{h(X)}\gets \sum_{j\in[\ell)} \beta_j \cdot h_j(X) = \frac{\sum_{j\in[\ell)}\beta_j (X-\omega^n)f_j(X)(f_j(X) - 1)}{X^{n+1} - 1}$ 
    - **Note:** Of degree $n$
 - $D \gets \sum_{i\in[0,n]} h(\omega^i) \cdot L_i \bydef \one{\emph{h}(\tau)}$
    + **Note:** We [discuss below](#computing-hx) how to interpolate these efficiently!
 - $\term{\pi}\gets \left(D, (C_j,\tilde{C}\_j)_{j\in[\ell)}\right)$

#### Proof size and prover time

**Proof size** is _trivial_: $(\ell+1)\Gr_1 + \ell \Gr_2$ group elements $\Rightarrow$ independent of the batch size $n$, but linear in the bit-width $\ell$ of the values.

**Prover time** is:

 - $\ell n$ $\Gr_1$ $\textcolor{green}{\text{additions}}$ for each $c_j, j\in[\ell)$
 - $\ell$ $\Gr_1$ scalar multiplications to blind each $c_j$ with $r_j$
 - $\ell n$ $\Gr_2$ $\textcolor{green}{\text{additions}}$ for each $\tilde{c}_j, j\in[\ell)$
 - $\ell$ $\Gr_2$ scalar multiplications to blind each $\tilde{c}_j$ with $r_j$
 - $O(\ell n\log{n})$ $\F$ multiplications to interpolate $h(X)$
    + See [break down here](#time-complexity).
 - 1 size-$(n+1)$ L-MSM for committing to $h(X)$

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Verify}^{\mathcal{FS}(\cdot)}(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

 - $\left(D, (C_j,\tilde{C}\_j)_{j\in[\ell)}\right) \parse \pi$
 - **assert** $C \equals \sum_{j=0}^{\ell-1} 2^j \cdot C_j$
 - $\alpha_j \randget \\{0,1\\}^\lambda,\forall j\in[\ell)$
 - **assert** $\pair{\sum_{j\in[0,\ell)} \alpha_j \cdot C_j}{\two{1}} \stackrel{?}{=} \pair{\one{1}}{\sum_{j\in[0,\ell)} \alpha_j \cdot \tilde{C}_j}$
 - add $(\vk, C, \ell, (C_j, \tilde{C}\_j)_{j\in[\ell})$ to the $\FS$ transcript
 - $(\beta_j)_{j\in[\ell)} \fsget \\{0,1\\}^\lambda$
 - **assert** $\pair{D}{\two{\frac{\tau^{n+1} - 1}{\tau-\omega^n}}} \equals \sum_{j\in[0,\ell)}\pair{\beta_j\cdot C_j}{\tilde{C}_j - \two{1}}$

The two pairing equation checks above can be combined into a single size $\ell+3$ multipairing by picking a random $\gamma\in\F$ and checking:
\begin{align}
\pair{\sum\_{j\in[\ell)} \alpha_j\cdot C_j}{\two{-\gamma}} +
\pair{\one{\gamma}}{\sum\_{j\in[\ell)} \alpha_j\cdot \tilde{C}\_j} + {} \\\\\ 
{} + \pair{-D}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}} + 
\sum\_{j\in[\ell)} \pair{\beta_j \cdot C_j}{\tilde{C}_j - \two{1}} \equals \three{0}
\end{align}
{: .note}

#### Verifier time

The verifier must do:

 - size-$\ell$ $\mathbb{G}_1$ small-MSM (i.e., small $2^0, 2^1, 2^2, \ldots, 2^{\ell-1}$ scalars)
 - size-$\ell$ $\mathbb{G}_1$ L-MSM for the $C_j$'s (i.e., 128-bit $\alpha_j$ scalars)
 - size-$\ell$ $\mathbb{G}_2$ L-MSM for the $\tilde{C}_j$'s (i.e., 128-bit $\alpha_j$ scalars)
 - size-$(\ell+3)$ multipairing

### Concrete performance

We implemented $\dekartUni$ in Rust over BLS12-381 using `blstrs`.
Our code stands to be further optimized and will be open source soon.
Until then, here are some benchmarks comparing it with Bulletproofs over a **faster** curve: Ristretto255.

| Scheme       | $\ell$ | $n$    | Proving time (ms) | Verify time (ms) | Total time (ms) | Proof size (bytes) |
| ------------ | -- --- | ------ | ----------------- | ---------------- | --------------- | ------------------ |
| Bulletproofs | 16-bit | $4064$ | $\bad{5,952}$     | $\bad{412}$      | $\bad{6,364}$   | $\good{1,312}$     |
| $\dekartUni$ | 16-bit | $4064$ | $\good{123}$      | $\good{5.4}$     | $\good{128}$    | $\bad{2,368}$      |
| Bulletproofs | 32-bit | $2032$ | $\bad{5,539}$     | $\bad{411}$      | $\bad{5,950}$   | $\good{1,312}$     |
| $\dekartUni$ | 32-bit | $2032$ | $\good{121}$      | $\good{6.9}$     | $\good{128}$    | $\bad{4,672}$      |

In terms where most of the time is spent in $\dekartUni$, here's a breakdown for $\ell=16$ and $n=2^{12}-1=4095$ (run on a different machine):
```
 39.47 ms: All 16 deg-4095 f_j G_1 commitments
           + Each C_j took: 2.467122ms
101.62 ms: All 16 deg-4095 f_j G_2 commitments
           + Each \hat{C}_j took: 6.351356ms
 37.03 ms: All 16 deg-4095 h_j(X) coeffs
  1.07 ms: h(X) as a size-16 linear combination
  6.77 ms: deg-4095 h(X) commitment
```

{: .warning}
The time to commit to the $f_j(X)$'s currently $\bad{dominates}$ but this can be sped up significantly using pre-computation since the scalars are small and the bases $L_i$ and $\tilde{L_i}$ are fixed.

## Multilinear batched ZK range proof

The previous section's [univariate construction](#univariate-batched-zk-range-proof) suffers from a few problems:

1. It currently **lacks a simulator** to show that $\dekartUni$ is ZK.
    + With some effort such a simulator should exist, perhaps with a few changes in the construction or with extra cryptographic assumptions.
1. It incurs extra $\Gr_2$ commitment cost (for the $\tilde{C}_j$ commitments to the $f_j$'s)
1. The FFT work for interpolating $h(X)$ is a significant chunk of the prover time

As a result, our paper[^BDFplus25e] focuses on a [multilinear-based](/mle) variant of DeKART that uses a zero-knowledge variant of the [sumcheck protocol](/sumcheck).

## Appendix

### Computing $h(X)$

We borrow differentiation tricks from [Groth16](/groth16#computing-hx) to ensure we only do size-$(n+1)$ FFTs.
(Otherwise, we'd have to use size-$2(n+1)$ FFTs to compute the $\ell$ different $f_j(X)(f_j(X) - 1)$ multiplications.)

Our goal will be to obtain all $(h(\omega^i))_{i\in[0,n]}$ evaluations and then do a size-$(n+1)$ L-MSM to commit to it and obtain $\emph{D}$.

Recall that:
\begin{align}
h(X)
    &= \frac{\sum_{j\in[\ell)}\beta_j \cdot \overbrace{(X-\omega^n)f_j(X)(f_j(X) - 1)}^{\term{N_j(X)}}}{X^{n+1} - 1}
    \\\\\
    &\bydef \frac{\sum_{j\in[\ell)} \beta_j \cdot \emph{N_j(X)}}{X^{n+1} - 1}
\Leftrightarrow\\\\\
\Leftrightarrow
h(X) (X^{n+1} - 1)
    &=
\sum_{j\in[\ell)} \beta_j \cdot N_j(X)
\end{align}
Differentiating the above expression:
\begin{align}
h'(X)(X^{n+1} - 1) + h(X) (n+1)X^n &= \sum_{j\in[\ell)} \beta_j \cdot N_j'(X)\Leftrightarrow\\\\\
\Leftrightarrow
h(X) &= \frac{\sum_{j\in[\ell)} \beta_j \cdot N_j'(X) - h'(X)(X^{n+1} - 1)}{(n+1)X^n}
\end{align}
This reduces computing all $h(\omega^i)$'s to computing all $N_j'(\omega^i)$'s:
\begin{align}
\label{eq:h}
\emph{h(\omega^i)} &= \frac{\sum_{j\in[\ell)} \beta_j \cdot N_j'(\omega^i)}{(n+1)\omega^{in}}
\end{align}
Our challenge is to compute all the $N_j'(\omega^i)$'s efficiently.
Recall that:
\begin{align}
N_j(X) &\bydef (X-\omega^n)f_j(X)(f_j(X) - 1)
\end{align}
Differentiating it yields:
\begin{align}
N_j'(X) &= (X-\omega^n)' \cdot \left(f_j(X)(f_j(X) - 1)\right) + (X-\omega^n) \left(f_j(X)(f_j(X) - 1)\right)'\Leftrightarrow\\\\\
N_j'(X) &= f_j(X)(f_j(X) - 1) + (X-\omega^n) \left(f_j(X)^2 - f_j(X)\right)'\Leftrightarrow\\\\\
N_j'(X) &= f_j(X)(f_j(X) - 1) + (X-\omega^n) \left(2f_j(X)f'_j(X) - f_j'(X)\right)\Leftrightarrow\\\\\
N_j'(X) &= f_j(X)(f_j(X) - 1) + (X-\omega^n) f_j'(X)\left(2f_j(X)-1\right)
\end{align}
This reduces computing all $N_j'(\omega^i)$'s to computing all $f_j'(\omega^i)$'s:
\begin{align}
N_j'(\omega^i) = f_j(\omega^i)(f_j(\omega^i) - 1) + (\omega^i-\omega^n) f_j'(\omega^i)\left(2f_j(\omega^i)-1\right)\Rightarrow\\\\\
\label{eq:nj-prime}
\Rightarrow\begin{cases}
    \emph{N_j'(\omega^i)} &= (\omega^i-\omega^n) f_j'(\omega^i)\left(2f_j(\omega^i)-1\right) = \pm(\omega^i-\omega^n) f_j'(\omega^i), i\in[0,n)\\\\\
    \emph{N_j'(\omega^n)} &= f_j(\omega^n)(f_j(\omega^n) - 1) + 0 = r_j (r_j - 1)
\end{cases}
\end{align}

#### Time complexity

To compute all $f_j'(\omega^i)$'s for a single $j$:
 1. 1 size-$(n+1)$ inverse FFT, for $f_j$'s coefficients in monomial basis 
 2. $n$ $\F$ multiplications, for the coefficients of the derivative $f_j'$
 3. 1 size-$(n+1)$ FFT, for all $f_j'(\omega^i)$'s.

Then, to compute all $N_j'(\omega^i)$'s for a single $j$:
 4. $2n+1$ $\F$ multiplications, for all $N'_j(\omega^i)$'s as per Eq. \ref{eq:nj-prime}
    + (Assuming all $\pm (\omega^i - \omega^n)$ are precomputed.)

{: .note}
All the numbers above get multipled by $\ell$, since we are doing this for every $j\in[\ell)$.

Lastly, to compute all the $h(\omega^i)$'s, we do:
 5. $\ell n$ $\F$ multiplications to compute the $n$ different numerators from Eq. \ref{eq:h}, one for each evaluation $h(\omega^i)$
 6. $n$ $\F$ multiplications, to divide the $n$ numerators by (the precomputed) $(n+1)\omega^{-in}$'s

{: .note}
Doing this $h(X)$ interpolation faster is an open problem, which is why in the paper we explore a multinear variant of DeKART[^BDFplus25e].

## References

[^Borg20]: [Membership proofs from polynomial commitments](https://solvable.group/posts/membership-proofs-from-polynomial-commitments/), William Borgeaud, 2020

For cited works, see below 👇👇

{% include refs.md %}
