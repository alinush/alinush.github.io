---
tags:
 - hyrax
 - pedersen
 - polynomial commitments
 - inner-product arguments (IPAs)
title: Hyrax polynomial commitment scheme
#date: 2020-11-05 20:45:59
#published: false
permalink: hyrax
# TODO: uncomment
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Hyrax is polynomial commitment scheme (PCS) with (1) sublinear commitment-and-proof sizes and (2) sublinear opening-and-verification times.
Hyrax is constructed from _Pedersen vector commitments_ and _Bulletproofs_ inner product arguments (IPAs).
Hyrax has _information-theoretic hiding_ commitments and _honest verifier zero-knowledge (HVZK)_ PCS openings.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\C{\vect{C}}
\def\G{\vect{G}}
\def\hyrax{\mathsf{Hyrax}}
\def\hyraxSetup{\mathsf{Hyrax}.\mathsf{Setup}}
\def\ipa{\mathsf{IPA}}
\def\r{\vect{r}}
\def\sqN{\sqrt{N}}
$</div> <!-- $ -->

{% include mle.md %}
{% include time-complexities.md %}

## Preliminaries

{% include prelims-time-complexities.md %}

## Overview

The main idea in Hyrax is that, for a **row** vector $\term{a}\in\F^{1\times n}$, a **column** vector $\term{b}^\top \in \F^m$ and a matrix $\term{\mat{A}}\in \F^{n\times m}$, you can express a dot product as:
\begin{align}
    \label{eq:hyrax}
    \sum_{i\in[n)} \sum_{j\in[m)} a_i \cdot M_{i,j} \cdot b_j
    = 
    \vec{a}\cdot \mat{M}\cdot \vec{b}^\top
    &\bydef
    \underbrace{\vec{a}}\_{\in\F^{1\times n}}
    \cdot \underbrace{\begin{bmatrix}
        \mat{M}\_0 \cdot \vec{b}^\top\\\\\
        \mat{M}\_1 \cdot \vec{b}^\top\\\\\
        \vdots &\\\\\
        \mat{M}\_{n-1} \cdot \vec{b}^\top\\\\\
    \end{bmatrix}}\_{\in \F^n}\\\\\
    %\label{eq:hyrax-rows}
    &\bydef
    \underbrace{\begin{bmatrix}
        %\| & \| & & \|\\\\\
        \vec{a} \cdot \mat{M}\_0^\top &
        \vec{a} \cdot \mat{M}\_1^\top &
        \cdots &
        \vec{a} \cdot \mat{M}\_{m-1}^\top\\\\\
        %\| & \| & & \|\\\\\
    \label{eq:hyrax-cols}
    \end{bmatrix}}\_{\in\F^{1\times m}}\cdot\underbrace{\vec{b}^\top}\_{\in\F^m}
\end{align}
where $\term{\mat{M}_i}\in\F^{1\times m}$ is the $i$th row in $\mat{M}$ and $\term{\mat{M}^\top_j}\in\F^n$ is the $j$th column.

<details><summary>Why❓ (Click to expand 👇)</summary>
\begin{align}
\vec{a}\cdot \mat{M}\cdot \vec{b}^\top  
    &= \vec{a}\cdot \left( \begin{bmatrix}
           M_{0,0} & M_{0,1} & \ldots & M_{0,m-1}\\\
           M_{1,0} & M_{1,1} & \ldots & M_{1,m-1}\\\
           \vdots & \vdots & \ddots & \vdots \\\
           M_{n-1,0} & M_{n-1,1} & \ldots & M_{n-1,m-1}
       \end{bmatrix}
       \cdot
       \begin{bmatrix} b_0\\\ b_1\\\ \vdots\\\ b_{m-1}\end{bmatrix} \right)\\\
    &= \vec{a}\cdot \begin{bmatrix}
           M_{0,0}\cdot b_0 + M_{0,1}\cdot b_1 + \cdots + M_{0,m-1}\cdot b_{m-1}
           \\\
           M_{1,0}\cdot b_0 + M_{1,1}\cdot b_1 + \cdots + M_{1,m-1}\cdot b_{m-1}
           \\\
           \vdots
           \\\
           M_{n-1,0}\cdot b_0 + M_{n-1,1}\cdot b_1 + \cdots + M_{n-1,m-1}\cdot b_{m-1}
       \end{bmatrix}
       \\\
    &= \begin{bmatrix}a_0 & a_1 & \cdots & a_{n-1}\end{bmatrix} \cdot \begin{bmatrix}
           \sum_{j\in[m)} M_{0,j} \cdot b_j
           \\\
           \sum_{j\in[m)} M_{1,j} \cdot b_j
           \\\
           \vdots
           \\\
           \sum_{j\in[m)} M_{n-1,j} \cdot b_j
       \end{bmatrix}
       \\\
    &=
        \left(a_0 \sum_{j\in[m)} M_{0,j} \cdot b_j\right) +
        \left(a_1 \sum_{j\in[m)} M_{1,j} \cdot b_j\right) +
        \cdots +
        \left(a_{n-1} \sum_{j\in[m)} M_{n-1,j} \cdot b_j\right)\\\
    &\goddamnequals
        \sum_{i\in[n)} \sum_{j\in[m)} a_i \cdot M_{i,j} \cdot b_j
\end{align}
</details>

Hyrax represents an MLE $\term{f(\X,\Y)}\in \MLE{n,m}$ as a matrix $\mat{M}$, where each row $\emph{\mat{M}\_i} \bydef (f(\i,\j))\_{j\in[m)}$.
Put differently, $\term{M_{i,j}}\bydef f(\i,\j)$.

Hyrax commits to $f$ by **individually** committing to the rows $\mat{M}\_i$ using a _hiding_ Pedersen vector commitment as:
\begin{align}
    \term{C\_i} \gets \term{r\_i} \cdot \term{H} + \mat{M}\_i \cdot \term{\G} = r\_i\cdot H+ \sum\_{j\in[m)} f(\i, \j) \cdot G_j\in \Gr
\end{align}
where $\emph{\G,H}\in\Gr^{m+1}$ is the **commitment key** and $r_i\randget \F$.
This yields an $n$-sized commitment $\C\bydef(C_i)_{i\in[n)}$.

An opening proof for $z\equals f(\x,\y)$, can be framed through the lens of Eq. \ref{eq:hyrax}:
\begin{align}
z 
    &=\sum_{i\in[n)}\sum_{j\in[m)} \eq(\x, \i) \cdot \eq(\y,\j) \cdot f(\i,\j)\\\\\
    &=\sum_{i\in[n)}\sum_{j\in[m)} \eq(\x, \i) \cdot M_{i,j} \cdot \eq(\y,\j)\\\\\
    &\bydef 
    \sum_{i\in[n)}\sum_{j\in[m)} a_i \cdot M_{i,j} \cdot b_j 
    =\vec{a}\cdot\mat{M}\cdot\vec{b}^\top
\end{align}
where $\vec{a} \bydef (\eq(\x,\i))\_{i\in[n)}$ and $\vec{b} \bydef (\eq(\y, \j))_{j\in[m)}$.

What does an opening proof look like exactly?

First, both the prover and the verifier compute the $\vec{a},\vec{b}$ vectors from $\x$ and $\y$.

Second, the verifier uses $\vec{a}$ and the $C_i$'s to derive a commitment $\term{D}$ to the vector $\vec{a} \cdot \mat{M} \in \F^{1\times m}$ from Eq. \ref{eq:hyrax-cols}:
\begin{align}
\term{D} \gets \sum_{i\in[n)} a\_i\cdot D\_i 
    &= \sum\_{i\in[n)} a\_i\cdot(r_i \cdot H + \mat{M}\_i\cdot \G)\\\\\
    &= \sum\_{i\in[n)} (a\_i\cdot r_i) \cdot H + \sum\_{i\in[n)} a\_i\cdot\left(\sum\_{j\in[m)} M\_{i,j} \cdot G\_j\right)\\\\\
    &\bydef u\cdot H + \sum\_{i\in[n)}\sum\_{j\in[m)} (a\_i\cdot M\_{i,j}) \cdot G\_j\\\\\
    &= u\cdot H + \sum\_{j\in[m)}\left(\sum\_{i\in[n)} (a\_i\cdot M\_{i,j})\right) \cdot G\_j\\\\\
    &= u\cdot H + \sum\_{j\in[m)}(\vec{a}\cdot \mat{M}^\top\_j) \cdot G\_j\\\\\
\end{align}
(This can be generalized into a nicer homorphic property of such Pedersen matrix commitments.)

Third, the prover computes $\vec{a}\cdot \mat{M}$ via $m$ inner-products in $\F$ of size $n$ each (as per Eq. \ref{eq:hyrax-cols}) and gives the verifier an **inner-product argument (IPA)** proof[^BBBplus18] that $z = (\vec{a} \cdot \mat{M})\cdot\vec{b}^\top$.
The verifier checks the IPA proof against (1) the commitment $D$ to $\vec{a}\cdot{\mat{M}}$ and (2) $\vec{b}$.

{: .note}
The prover proves an inner-product of size only $m$!

{: .note}
To commit to MLEs $f\in\MLE{N}$, Hyrax is typically used with $n=m=\sqrt{N}$, yielding sublinear-sized commitments & proofs and sublinear-time verifier.
The prover time will be dominated by the $\sqrt{N}$-sized IPA proof

## Construction

### $\mathsf{Hyrax}.\mathsf{Setup}(1^\lambda, \nu,\mu) \rightarrow (\mathsf{vk},\mathsf{ck})$

Notation:
 - $n \gets 2^\nu$ denotes the # of matrix rows
 - $m \gets 2^\mu$ denotes the # of matrix columns
 - $N = n\cdot m\bydef 2^{\nu + \mu}$ denotes the total # of entries in the matrix

Pick random generators:

 - $(\G,H)\randget\Gr^{m+1}$
 - $\vk\gets (n, \G,H)$
 - $\ck\gets \vk$

### $\mathsf{Hyrax}.\mathsf{Commit}(\mathsf{ck}, f(\boldsymbol{X},\boldsymbol{Y}); \r) \rightarrow (\boldsymbol{C},\aux)$

Denote the matrix represention of the MLE $f$ as $\mat{M}\in\F^{n \times m}$.

 - $(n,\G, H)\parse \ck$
 - $C_i \gets r_i\cdot H + \mat{M}_i\cdot \G,\forall i\in[n)$ 
 - $\aux \gets \r$

{: .note}
Computing each commitment takes an $\msm{m+1}\Rightarrow n\times\msm{m+1}$ in total.

### $\mathsf{Hyrax}.\mathsf{Open}(\ck, f(\boldsymbol{X},\boldsymbol{Y}), (\boldsymbol{x}, \boldsymbol{y}), z; \aux, \C)\rightarrow \pi$
 
Parse commitment key and auxiliary data:
 - $(n,\G,H)\parse \ck$
 - $\r\gets\aux$

Denote the matrix representation of the MLE $f$ as $\mat{M}\in\F^{n \times m}$.

 - $\vec{a}\gets (\eq(\x, \i))_{i\in[n)}\in\F^{1\times n}$ 
 - $\vec{b} \gets (\eq(\y, \j))_{j\in[m)}\in \F^{1\times m}$ 
 - $\vect{A}\gets \vec{a}\cdot \mat{M}\in \F^{1\times m}$
 - $u\gets \sum_{i\in[n)} a_i\cdot r_i$ 
    + This will be the randomness for the commitment to $\vect{A}$ homomorphically-reconstructed by the verifier
 - $\prk_\ipa\gets (\G,H)$
 - $\pi \gets \ipa.\mathcal{P}(\prk_\ipa, \vect{A}, \vec{b}; u)$
    - This will be a ZK IPA proof that $z = \vect{A}\cdot \vec{b}^\top = \vec{a}\cdot\mat{M}\cdot\vec{b}^\top \bydef f(\x,\y)$

### Opening time

First, recall that [computing all Lagrange evaluations](/mle#computing-all-lagrange-evaluations-fast) for a size-$n$ MLE takes $2n$ $\F$ multiplications.

 - $\vec{a}$ takes $\Fmul{2n}$
 - $\vec{b}$ takes $\Fmul{2m}$
 - $\vect{A}$ takes $m \times(\Fmul{n}+\Fadd{n})=\Fmul{nm}+\Fadd{nm}$ because we are inner-producting $\vec{a}$ with every column $\mat{M}_j^\top\in\F^n$.
    + When the matrix is "sparse", i.e., only has $t\bydef\sum_{i\in[m)} t_i \ll nm$ non-zero entries, with column $i$ having $t_i$ non-zero entries, then this cost lowers to $\sum_{i\in[m)} (\Fmul{t_i}+\Fadd{t_i}) = \Fmul{t} + \Fadd{t}$
 - $\vec{u}$ takes $\Fmul{n}+\Fadd{n}$
 - $\pi$ takes $\term{\ipa.\mathcal{P}(m)}$, which denotes the time of a size-$m$ IPA prover
    + e.g., $O(\Gmul{m})$ for Bulletproofs[^BBBplus18]

{: .note}
Adding time complexities up, we get $\Fmul{(2n + 2m)} + \Fmul{nm} + \Fadd{nm} + \Fmul{n} + \Fadd{n} + \ipa.\mathcal{P}(m)$, 
which gives a **total opening time** of $\Fmul{(3n + 2m + nm)} + \Fadd{(nm + n)} + \ipa.\mathcal{P}(m)$.

### $\mathsf{Hyrax}.\mathsf{Verify}(\vk, \boldsymbol{C}, (\boldsymbol{x}, \boldsymbol{y}), z; \pi)\rightarrow \\{0,1\\}$
 
 - $(n,\cdot)\parse \vk$
 - $\vec{a}\gets (\eq(\x, \i))_{i\in[n)}\in\F^{1\times n}$ 
 - $\vec{b} \gets (\eq(\y, \j))_{j\in[m)}\in \F^{1\times m}$ 
 - $D \gets \sum_{i\in[n)} a_i\cdot C_i$
    + This will be the Pedersen commitment to $\vec{a}\cdot\mat{M}$
 - $\vk_\ipa\gets (\G,H)$
 - **assert** $\ipa.\mathcal{V}(\vk_\ipa, D, \vec{b}; \pi) \equals 1$

### Verifier time

 - $\vec{a}$ takes $\Fmul{2n}$ (recall from [here](/mle#computing-all-lagrange-evaluations-fast))
 - $\vec{b}$ takes $\Fmul{2m}$
 - $D$ takes $\msm{n}$
 - Verfiying $\pi$ takes $\term{\ipa.\mathcal{V}(m)}$, which denotes the time of a size-$m$ IPA verifier
    + e.g., $O(\msm{m})$ for Bulletproofs[^BBBplus18]

{: .note}
Adding time complexities up, we get a **total verifier time** of $\Fmul{2(n + m)} + \msm{n} + \ipa.\mathcal{V}(m)$.

## Performance

{: .info}
We use $\hyrax^{n,m}$ to refer to the $\hyrax$ scheme set up with [$\hyraxSetup(1^\lambda, \log_2{n},\log_2{m})$](#).
We use $\hyrax^{\sqN}$ to refer to $\hyrax^{\sqN,\sqN}$.

### Setup, commitments and proof sizes

|--------------+-------+-------+-------------+------+--------+-------|
| Scheme       | $\ck$ | $\vk$ | Commit time | $\C$ | $\aux$ | $\pi$ |
|--------------|-------|-------|-------------|------+--------|-------|
| $\hyrax^{n,m}$  | $\Gr^{n+1},\ck_\ipa$    | $\Gr^{n+1},\vk_\ipa   $ | $n\cdot\msm{m+1}$       | $\Gr^n$     | $\r\in\F^n$   | $\pi_\ipa(m)$ |
| $\hyrax^{\sqN}$ | $\Gr^{\sqN+1},\ck_\ipa$ | $\Gr^{\sqN+1},\vk_\ipa$ | $\sqN\cdot\msm{\sqN+1}$ | $\Gr^\sqN$ | $\r\in\F^\sqN$ | $\pi_\ipa(\sqN)$ |
|--------------+-------+-------+-------------|------|--------|-------|

### Openings at arbitry points

Recall that $\emph{t}\le nm$ denotes the # of non-zero entries in the MLE $f$ or, equivalently, matrix $\mat{M}$.

|----------------+--------------------+---------------|
| Scheme         | Open time (random) | Verifier time |
|----------------|--------------------|---------------|
| $\hyrax^{n,m}$  | $\Fmul{(3n+2m+t)} + \Fadd{(t+n)} + \ipa.\mathcal{P}(m)$         | $\Fmul{2(n+m)} + \msm{n} + \ipa.\mathcal{V}(m)$ |
| $\hyrax^{\sqN}$ | $\Fmul{(5\sqN + t)} + \Fadd{(t + \sqN)} + \ipa.\mathcal{P}(\sqN)$ | $\Fmul{4\sqN} + \msm{\sqN} + \ipa.\mathcal{V}(\sqN)$ |
|----------------+--------------------+---------------|

### Openings at points on the hypercube

|----------------+-----------------------+---------------|
| Scheme         | Open time (hypercube) | Verifier time |
|----------------|-----------------------|---------------|
| $\hyrax^{n,m}$  | $\ipa.\mathcal{P}(m)$    | $\ipa.\mathcal{V}(m)$ |
| $\hyrax^{\sqN}$ | $\ipa.\mathcal{P}(\sqN)$ | $\ipa.\mathcal{V}(\sqN)$ |
|----------------+-----------------------+---------------|

## References

For cited works, see below 👇👇

{% include refs.md %}
