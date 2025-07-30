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
article_header:
  type: cover
  image:
    src: /pictures/aMb.png
---

<!-- LaTeX for header picture
\begin{bmatrix}a_1 & a_2 & a_3 & a_4\end{bmatrix} 
\begin{pmatrix}
  \cdot & \cdot & \cdot & \cdot & \cdot\\
  \cdot & \cdot & \cdot & \cdot & \cdot\\
  \cdot & \cdot & \cdot & \cdot & \cdot\\
  \cdot & \cdot & \cdot & \cdot & \cdot\\
\end{pmatrix}
\begin{bmatrix}b_1\\ b_2\\ b_3 \\ b_4\\ b_5\end{bmatrix}
-->

{: .info}
**tl;dr:** Hyrax is polynomial commitment scheme (PCS) with (1) sublinear commitment-and-proof sizes and (2) sublinear opening-and-verification times.
Hyrax is constructed from _Pedersen vector commitments_ and _Bulletproofs_ inner product arguments (IPAs).
Hyrax has _information-theoretic hiding_ commitments and _honest verifier zero-knowledge (HVZK)_ PCS openings.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\a{\vec{a}}
\def\b{\vec{b}}
\def\A{\vect{A}}
\def\C{\vect{C}}
\def\G{\vect{G}}
\def\hyrax{\mathsf{Hyrax}}
\def\hyraxnm{\hyrax^{n,m}}
\def\hyraxSqN{\hyrax^{\sqN}}
\def\hyraxSetup{\hyrax.\mathsf{Setup}}
\def\hyraxZk{\hyrax_\mathsf{ZK}}
\def\hyraxZknm{\hyraxZk^{n,m}}
\def\hyraxZkSqN{\hyraxZk^{\sqN}}
\def\hyraxZkSetup{\hyraxZk.\mathsf{Setup}}
\def\ipa{\mathsf{IPA}}
\def\ipaProve{\mathcal{P}_\ipa}
\def\ipaVer{\mathcal{V}_\ipa}
\def\r{\vect{r}}
\def\sqN{\sqrt{N}}
$</div> <!-- $ -->

{% include mle.md %}
{% include time-complexities.md %}

## Preliminaries

{% include prelims-time-complexities.md %}
 - [Multilinear extensions (MLEs)](/mle)

## Overview

The main idea in Hyrax is that, for a **row** vector $\term{a}\in\F^{1\times n}$, a **column** vector $\term{b}^\top \in \F^m$ and a matrix $\term{\mat{A}}\in \F^{n\times m}$, you can express a dot product as:
\begin{align}
    \label{eq:hyrax}
    \sum_{i\in[n), j\in[m)} a_i \cdot M_{i,j} \cdot b_j
    = 
    \emph{\a\cdot \mat{M}\cdot \b^\top}
    &\bydef
    \underbrace{\a}\_{\in\F^{1\times n}}
    \cdot \underbrace{\begin{bmatrix}
        \mat{M}\_0 \cdot \b^\top\\\\\
        \mat{M}\_1 \cdot \b^\top\\\\\
        \vdots &\\\\\
        \mat{M}\_{n-1} \cdot \b^\top\\\\\
    \end{bmatrix}}\_{\in \F^n}\\\\\
    %\label{eq:hyrax-rows}
    &\bydef
    \underbrace{\begin{bmatrix}
        %\| & \| & & \|\\\\\
        \a \cdot \mat{M}\_0^\top &
        \a \cdot \mat{M}\_1^\top &
        \cdots &
        \a \cdot \mat{M}\_{m-1}^\top\\\\\
        %\| & \| & & \|\\\\\
    \label{eq:hyrax-cols}
    \end{bmatrix}}\_{\in\F^{1\times m}}\cdot\underbrace{\b^\top}\_{\in\F^m}
\end{align}
where $\term{\mat{M}_i}\in\F^{1\times m}$ is the $i$th row in $\mat{M}$ and $\term{\mat{M}^\top_j}\in\F^n$ is the $j$th column.

<details><summary>Why❓ (Click to expand 👇)</summary>
\begin{align}
\a\cdot \mat{M}\cdot \b^\top  
    &= \a\cdot \left( \begin{bmatrix}
           M_{0,0} & M_{0,1} & \ldots & M_{0,m-1}\\\
           M_{1,0} & M_{1,1} & \ldots & M_{1,m-1}\\\
           \vdots & \vdots & \ddots & \vdots \\\
           M_{n-1,0} & M_{n-1,1} & \ldots & M_{n-1,m-1}
       \end{bmatrix}
       \cdot
       \begin{bmatrix} b_0\\\ b_1\\\ \vdots\\\ b_{m-1}\end{bmatrix} \right)\\\
    &= \a\cdot \begin{bmatrix}
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
        \sum_{i\in[n), j\in[m)} a_i \cdot M_{i,j} \cdot b_j
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
    &=\sum_{i\in[n), j\in[m)} \eq(\x, \i) \cdot \eq(\y,\j) \cdot f(\i,\j)\\\\\
    &=\sum_{i\in[n), j\in[m)} \eq(\x, \i) \cdot M_{i,j} \cdot \eq(\y,\j)\\\\\
    &\bydef 
    \sum_{i\in[n), j\in[m)} a_i \cdot M_{i,j} \cdot b_j 
    =\a\cdot\mat{M}\cdot\b^\top
\end{align}
where $\a \bydef (\eq(\x,\i))\_{i\in[n)}$ and $\b \bydef (\eq(\y, \j))_{j\in[m)}$.

What does an opening proof look like exactly?

First, both the prover and the verifier compute the $\a,\b$ vectors from $\x$ and $\y$.

Second, the verifier uses $\a$ and the $C_i$'s to derive a commitment $\term{D}$ to the vector $\a \cdot \mat{M} \in \F^{1\times m}$ from Eq. \ref{eq:hyrax-cols}:
\begin{align}
\term{D} \gets \sum_{i\in[n)} a\_i\cdot D\_i 
    &= \sum\_{i\in[n)} a\_i\cdot(r_i \cdot H + \mat{M}\_i\cdot \G)\\\\\
    &= \sum\_{i\in[n)} (a\_i\cdot r_i) \cdot H + \sum\_{i\in[n)} a\_i\cdot\left(\sum\_{j\in[m)} M\_{i,j} \cdot G\_j\right)\\\\\
    &\bydef \term{u}\cdot H + \sum\_{i\in[n)}\sum\_{j\in[m)} (a\_i\cdot M\_{i,j}) \cdot G\_j\\\\\
    &= u\cdot H + \sum\_{j\in[m)}\left(\sum\_{i\in[n)} (a\_i\cdot M\_{i,j})\right) \cdot G\_j\\\\\
    &= u\cdot H + \sum\_{j\in[m)}(\a\cdot \mat{M}^\top\_j) \cdot G\_j\\\\\
\end{align}
(This can be generalized into a nicer homorphic property of such Pedersen matrix commitments.)

Third, the prover computes $\a\cdot \mat{M}$ via $m$ inner-products in $\F$ of size $n$ each (as per Eq. \ref{eq:hyrax-cols}).

Fourth, the prover gives the verifier a size-$m$ **inner-product argument (IPA)** proof[^BBBplus18] that $z = (\a \cdot \mat{M})\cdot\b^\top$.

Lastly, the verifier checks the IPA proof against (1) the commitment $D$ to $\a\cdot{\mat{M}}$ and (2) $\b$.

{: .note}
To commit to MLEs $f\in\MLE{N}$, Hyrax is typically used with $n=m=\sqrt{N}$, yielding sublinear-sized commitments & proofs and sublinear-time verifier.
The proving time will be dominated by the $\sqrt{N}$-sized IPA.

## ZK construction

### $\mathsf{Hyrax}_\mathsf{ZK}.\mathsf{Setup}(1^\lambda, \nu,\mu) \rightarrow (\mathsf{vk},\mathsf{ck})$

Notation:
 - $n \gets 2^\nu$ denotes the # of matrix rows
 - $m \gets 2^\mu$ denotes the # of matrix columns
 - $N = n\cdot m\bydef 2^{\nu + \mu}$ denotes the total # of entries in the matrix

Pick random generators:

 - $(\G,H)\randget\Gr^{m+1}$
 - $\vk\gets (n, \G,H)$
 - $\ck\gets \vk$

### $\mathsf{Hyrax}_\mathsf{ZK}.\mathsf{Commit}(\mathsf{ck}, f(\boldsymbol{X},\boldsymbol{Y}); \r) \rightarrow (\boldsymbol{C},\aux)$

Let:
 - $\emph{\mat{M}}\in\F^{n\times m}$ denote the matrix represention of the MLE $f$.

Compute the commitment:

 - $(n,\G, H)\parse \ck$
 - $C_i \gets r_i\cdot H + \mat{M}_i\cdot \G,\forall i\in[n)$ 
 - $\aux \gets \r$

{: .note}
Computing each commitment takes an $\msm{m+1}\Rightarrow n\times\msm{m+1}$ in total.
(Committing will be faster for sparse matrices, but in the [Spartan](/spartan) setting, we don't care about it.)

### $\mathsf{Hyrax}_\mathsf{ZK}.\mathsf{Open}(\ck, f(\boldsymbol{X},\boldsymbol{Y}), (\boldsymbol{x}, \boldsymbol{y}), z; \aux, \C)\rightarrow \pi$
 
Parse commitment key and auxiliary data:
 - $(n,\G,H)\parse \ck$
 - $\r\gets\aux$

Compute the opening proof:
 - $\a\gets (\eq(\x, \i))_{i\in[n)}\in\F^{1\times n}$ 
 - $\b \gets (\eq(\y, \j))_{j\in[m)}\in \F^{1\times m}$ 
 - $\A\gets \a\cdot \mat{M}\in \F^{1\times m}$
 - $u\gets \sum_{i\in[n)} a_i\cdot r_i$ 
    + This will be the randomness for the commitment to $\A$, which the verifier will homomorphically-reconstruct
 - $\pi \gets \ipaProve(\prk_\ipa, \A, \b, z; u)$ where $\prk_\ipa = (\G,H)$
    - This will be a ZK IPA proof that $z = \A\cdot \b^\top = \a\cdot\mat{M}\cdot\b^\top \bydef f(\x,\y)$

### ZK opening time

First, recall that [computing all Lagrange evaluations](/mle#computing-all-lagrange-evaluations-fast) for a size-$n$ MLE takes $2n$ $\F$ multiplications.

 - $\a$ takes $\Fmul{2n}$
 - $\b$ takes $\Fmul{2m}$
 - $\A$ takes $m \times(\Fmul{n}+\Fadd{n})=\Fmul{nm}+\Fadd{nm}$ because we are inner-producting $\a$ with every column $\mat{M}_j^\top\in\F^n$.
    + When the matrix is "sparse", i.e., only has $\term{t}\bydef\sum_{j\in[m)} \term{t_j} \ll nm$ non-zero entries, with column $j$ having $\emph{t_j}$ non-zero entries, then this cost lowers to $\sum_{j\in[m)} (\Fmul{t_j}+\Fadd{t_j}) = \Fmul{t} + \Fadd{t}$
 - $\vec{u}$ takes $\Fmul{n}+\Fadd{n}$
 - $\pi$ takes $\term{\ipaProve(m)}$, which denotes the time of a size-$m$ IPA prover
    + e.g., $O(\Gmul{m})$ for Bulletproofs[^BBBplus18]

In **total**, we have:
\begin{align}
&\underbrace{\Fmul{(2n + 2m)}}\_{\a, \b} + \underbrace{(\Fmul{t} + \Fadd{t})}\_{\A} + \underbrace{(\Fmul{n} + \Fadd{n})}_{\vec{u}} + \ipaProve(m)= 
\\\\\
\def\zkopen{\Fmul{(3n + 2m + t)} + \Fadd{(t + n)} + \ipaProve(m)}
= &\zkopen
\end{align}

### $\mathsf{Hyrax}_\mathsf{ZK}.\mathsf{Verify}(\vk, \boldsymbol{C}, (\boldsymbol{x}, \boldsymbol{y}), z; \pi)\rightarrow \\{0,1\\}$
 
 - $(n,\G, H)\parse \vk$
 - $\a\gets (\eq(\x, \i))_{i\in[n)}\in\F^{1\times n}$ 
 - $\b \gets (\eq(\y, \j))_{j\in[m)}\in \F^{1\times m}$ 
 - $D \gets \sum_{i\in[n)} a_i\cdot C_i$
    + This will be the Pedersen commitment to $\A\bydef\a\cdot\mat{M}$
 - $\vk_\ipa\gets (\G,H)$
 - **assert** $\ipaVer(\vk_\ipa, D, \b, z; \pi) \equals 1$

### ZK verifier time

 - $\a$ takes $\Fmul{2n}$ (recall from [here](/mle#computing-all-lagrange-evaluations-fast))
 - $\b$ takes $\Fmul{2m}$
 - $D$ takes $\msm{n}$
 - Verfiying $\pi$ takes $\term{\ipaVer(m)}$, which denotes the time of a size-$m$ IPA verifier (e.g., $O(\msm{m})$ for Bulletproofs[^BBBplus18])

In **total**, we have:
\begin{align}
\def\zkverify{\Fmul{2(n + m)} + \msm{n} + \ipaVer(m)}
\zkverify
\end{align}

### ZK performance

We use $\hyraxZknm$ to refer to the $\hyraxZk$ scheme set up with [$\hyraxZkSetup(1^\lambda, \log_2{n},\log_2{m})$](#).
We use $\hyraxZkSqN$ to refer to $\hyraxZk^{\sqN,\sqN}$.

#### Setup, hiding commitments and ZK proof sizes

|--------------+-------+-------+-------------+------+--------+-------|
| Scheme       | $\ck$ | $\vk$ | Commit time | $\C$ | $\aux$ | $\pi$ |
|--------------|-------|-------|-------------|------+--------|-------|
| $\hyraxZknm$  | $\Gr^{n+1},\ck_\ipa$    | $\Gr^{n+1},\vk_\ipa   $ | $n\cdot\msm{m+1}$       | $\Gr^n$     | $\r\in\F^n$   | $\pi_\ipa(m)$ |
| $\hyraxZkSqN$ | $\Gr^{\sqN+1},\ck_\ipa$ | $\Gr^{\sqN+1},\vk_\ipa$ | $\sqN\cdot\msm{\sqN+1}$ | $\Gr^\sqN$ | $\r\in\F^\sqN$ | $\pi_\ipa(\sqN)$ |
|--------------+-------+-------+-------------|------|--------|-------|

#### ZK openings at arbitry points

Recall that $\emph{t}\le nm$ denotes the # of non-zero entries in the MLE $f$ or, equivalently, matrix $\mat{M}$.

|----------------+--------------------+---------------|
| Scheme         | Open time (random) | Verifier time |
|----------------|--------------------|---------------|
| $\hyraxZknm$   | $\zkopen$          | $\Fmul{2(n+m)} + \msm{n} + \ipaVer(m)$ |
| $\hyraxZkSqN$  | $\zkverify$        | $\Fmul{4\sqN} + \msm{\sqN} + \ipaVer(\sqN)$ |
|----------------+--------------------+---------------|

#### ZK openings at points on the hypercube

|----------------+-----------------------+---------------|
| Scheme         | Open time (hypercube) | Verifier time |
|----------------|-----------------------|---------------|
| $\hyraxZknm$  | $\ipaProve(m)$    | $\ipaVer(m)$ |
| $\hyraxZkSqN$ | $\ipaProve(\sqN)$ | $\ipaVer(\sqN)$ |
|----------------+-----------------------+---------------|

## Non-ZK construction

### $\mathsf{Hyrax}.\mathsf{Setup}(1^\lambda, \nu,\mu) \rightarrow (\mathsf{vk},\mathsf{ck})$

Pick random generators (reusing [$\hyraxZk$ notation](#mathsfhyrax_mathsfzkmathsfsetup1lambda-numu-rightarrow-mathsfvkmathsfck)):

 - $\G\randget\Gr^m$
 - $\vk\gets (n, \G)$
 - $\ck\gets \vk$

### $\mathsf{Hyrax}.\mathsf{Commit}(\mathsf{ck}, f(\boldsymbol{X},\boldsymbol{Y})) \rightarrow \boldsymbol{C}$

Recall that $\mat{M}\in\F^{n \times m}$ represents the MLE $f\in\MLE(n,m)$.

 - $(n,\G)\parse \ck$
 - $C_i \gets \mat{M}_i\cdot \G,\forall i\in[n)$ 

{: .note}
Computing each commitment takes an $\msm{m}\Rightarrow n\times\msm{m}$ in total.
(Committing will be faster for sparse matrices, but in the [Spartan](/spartan) setting, we don't care about it.)

### $\mathsf{Hyrax}.\mathsf{Open}(\ck, f(\boldsymbol{X},\boldsymbol{Y}), (\boldsymbol{x}, \boldsymbol{y}), z; \C)\rightarrow \pi$
 
Parse commitment key:
 - $(n,\G)\parse \ck$

Compute the opening proof:
 - $\a\gets (\eq(\x, \i))_{i\in[n)}\in\F^{1\times n}$ 
 - $\b \gets (\eq(\y, \j))_{j\in[m)}\in \F^{1\times m}$ 
 - $\A\gets \a\cdot \mat{M}\in \F^{1\times m}$
 - $\pi\gets \A$

{: .note}
A more succinct but less computationally-efficient variant would compute an IPA proof that $z = \A\cdot \b^\top$ instead of sending $\A$ over and having the verifier manually check.

### Non-ZK opening time

 - $\a$ takes $\Fmul{2n}$
 (recall from [here](/mle#computing-all-lagrange-evaluations-fast))
 - $\b$ takes $\Fmul{2m}$
 - $\A$ takes $\Fmul{nm}+\Fadd{nm}$ in the worst case, and $\Fmul{t}+\Fadd{t}$ in the sparse case with $\emph{t}$ non-zero entries in $\mat{M}$
 (recall from [here](#zk-opening-time))

In **total**, we have $\Fmul{(2n + 2m + t)} + \Fadd{t}$ proving work for vanilla $\hyrax$.
The $\hyrax_\ipa$ variant would require extra $\emph{\ipaProve(m)}$ work.

{: .note}
When $(\x,\y)$ are on the hypercube: 
(1) $\a$ and $\b$ are 0 everywhere except at location $x$ and $y$,
and (2) $\A$ is just the $x$th row of $\mat{M}$.
So opening time involves no computation.
The proof remains the same size though.

### $\mathsf{Hyrax}.\mathsf{Verify}(\vk, \boldsymbol{C}, (\boldsymbol{x}, \boldsymbol{y}), z; \pi)\rightarrow \\{0,1\\}$
 
 - $(n,\cdot)\parse \vk$
 - $\a\gets (\eq(\x, \i))_{i\in[n)}\in\F^{1\times n}$ 
 - $\b \gets (\eq(\y, \j))_{j\in[m)}\in \F^{1\times m}$ 
 - $D \gets \sum_{i\in[n)} a_i\cdot C_i$
    + This will be the Pedersen commitment to $\A\bydef\a\cdot\mat{M}\in\F^{1\times m}$
 - $\A\parse \pi$
 - **assert** $D\equals \A\cdot\vect{G}$ 
 - **assert** $z\equals \A\cdot \b^\top$

{: .note}
A more succinct but less computationally-efficient variant would verify an IPA proof instead of checking that $\A$ is committed in $D$ and manually re-computing $z$.

### Non-ZK verifier time

 - $\a$ takes $\Fmul{2n}$
 (recall from [here](/mle#computing-all-lagrange-evaluations-fast))
 - $\b$ takes $\Fmul{2m}$
 - $D$ takes $\msm{n}$
 - Verifying $\A$ against $D$ takes $\msm{m}$
 - $\Rightarrow$ but these two checks can be combined into a single $\msm{n+m}$ as $\left(\A\cdot (-\G)\right)\cdot \sum_{i\in[n)} a_i \cdot C_i\equals 1$
 - Verifying $z$ is a size-$m$ inner product, so takes $\Fmul{m}+\Fadd{m}$

In **total**, we have $\Fmul{(2n + 3m)} + \Fadd{m} + \msm{n+m}$ verifier work for vanilla $\hyrax$.
The $\hyrax_\ipa$ variant would take $\Fmul{2(n+m)} + \msm{n} + \ipaVer(m)$ (because no decommitment check for $D$ and no $\A\cdot\b^\top$ inner-product).

{: .note}
When $(\x,\y)$ are on the hypercube: 
(1) $\a$ and $\b$ are 0 everywhere except at location $x$ and $y$,
(2) $D$ is just the commitment $C_x$ to the $x$th row
(3) $\A$ is verified directly against $C_x$ via an $\msm{m}$
(4) $z$ is verified by checking if $z \equals A_y$

### Non-ZK performance

We use $\hyraxnm$ to refer to the $\hyrax$ scheme set up with [$\hyraxSetup(1^\lambda, \log_2{n},\log_2{m})$](#).
We use $\hyraxSqN$ to refer to $\hyrax^{\sqN,\sqN}$.

#### Setup, commitments and proof sizes

|---------------+-------+-------+-------------+------+--------+-------|
| Scheme        | $\ck$ | $\vk$ | Commit time | $\C$ | $\aux$ | $\pi$ |
|---------------|-------|-------|-------------|------+--------|-------|
| $\hyraxnm$    | $\Gr^n$     | $\Gr^n$      | $n\cdot\msm{m}$       | $\Gr^n$    | $\bot$ | $\F^m$ |
| $\hyraxSqN$   | $\Gr^\sqN$  | $\Gr^\sqN+1$ | $\sqN\cdot\msm{\sqN}$ | $\Gr^\sqN$ | $\bot$ | $\F^\sqN$ |
|---------------+-------+-------+-------------|------|--------|-------|

#### Non-ZK openings at arbitry points

Recall that $\emph{t}\le nm$ denotes the # of non-zero entries in the MLE $f$ or, equivalently, matrix $\mat{M}$.

|----------------+--------------------+---------------|
| Scheme         | Open time (random) | Verifier time |
|----------------|--------------------|---------------|
| $\hyraxnm$     | $\Fmul{(2n+2m+t)} + \Fadd{t}$ | $\Fmul{(2n+3m)} + \Fadd{m} + \msm{n+m}$ |
| $\hyraxSqN$    | $\Fmul{(4\sqN+t)} + \Fadd{t}$ | $\Fmul{5\sqN} + \Fadd{\sqN} + \msm{2\sqN}$ |
|----------------+--------------------+---------------|

#### Non-ZK openings at points on the hypercube

|----------------+-----------------------+---------------|
| Scheme         | Open time (hypercube) | Verifier time |
|----------------|-----------------------|---------------|
| $\hyraxnm$     | $\bot$                | $\msm{n}$     |
| $\hyraxSqN$    | $\bot$                | $\msm{\sqN}$  |
|----------------+-----------------------+---------------|

## Conclusion

Your thoughts or comments are welcome on [this thread](https://x.com/alinush407/status/1947662884961477017).

## References

For cited works, see below 👇👇

{% include refs.md %}
