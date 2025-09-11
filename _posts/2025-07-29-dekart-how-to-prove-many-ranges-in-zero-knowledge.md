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
\def\tildeDekartUni{\widetilde{\dekart}^\mathsf{FFT}}
\def\dekartMulti{\dekart^{\vec{X}}}
\def\H{\mathbb{H}}
\def\bad#1{\textcolor{red}{\text{#1}}}
\def\good#1{\textcolor{green}{\text{#1}}}
\def\vanish{\frac{X^{n+1} - 1}{X - \omega^n}}
\def\vanishTwo{\crs{\two{\frac{\tau^{n+1} - 1}{\tau-\omega^n}}}}
\def\crs#1{\textcolor{green}{#1}}
\def\tauOne{\crs{\one{\tau}}}
\def\tauTwo{\crs{\two{\tau}}}
\def\ellOne#1{\crs{\one{\ell_{#1}(\tau)}}}
\def\ellTwo#1{\crs{\two{\ell_{#1}(\tau)}}}
$</div> <!-- $ -->

## Introduction

In a very short blog post[^Borg20], Borgeaud describes a very simple range proof for a single value $z$, which we summarize [here](borgeauds-unbatched-range-proof).
In this blog post, accompanying our academic paper[^BDFplus25e], we observe that Borgeaud's elegant protocol **very efficiently** extends to batch-proving **many values**[^BDFplus25e].

## Preliminaries

 - [Univariate polynomials](/polynomials)
 - [KZG polynomial commitments](/kzg)
 - [MLEs](/mle)
 - $[0,n]\bydef\\{0,1,\ldots,n\\}$
 - $[\ell)\bydef\\{0,1,\ldots,\ell-1\\}$
 - $\F$ is a finite field of prime order $p$
 - $r\randget S$ denotes randomly sampling from a set $S$
 - We use $\one{a}\bydef a\cdot G_1$ and $\two{b}\bydef b\cdot G_2$ and $\three{c}\bydef c\cdot G_\top$ to denote scalar multiplication in bilinear groups $(\Gr_1,\Gr_2,\Gr_\top)$ with generators $G_1,G_2,G_\top$, respectively (i.e., additive group notation).
 - We use "small-MSM" to refer to multi-scalar multiplications (MSMs) where the scalars are small; we use "L-MSM" to refer to ones where the scalars are large
{% include prelims-fiat-shamir.md %}

### Lagrange polynomials

We will often work with polynomials $f(X)$ interpolated over the FFT basis $\term{\H}\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$, where $\term{\omega}$ is a primitive $(n+1)$ith root of unity.
(A bit clumsy, maybe we can fix later.)
So, given $f(\omega^i)$ evaluations, for all $i\in[0,n]$, we want to interpolate $f(X)$ as:
\begin{align}
    f(X) \gets \sum_{i\in[0,n]} f(\omega^i)\cdot \ell_i(X),\ \text{where}\ \term{\ell_i(X)} = \prod_{\substack{j\in[0,n]\\\\j\ne i}} \frac{X - \omega^j}{\omega^i-\omega^j}
\end{align}
Let $\term{A(X)} = X^{n+1}-1 \bydef \prod_{i\in[0,n]} (X-\omega^n)$ and note that $\term{A'(X)} = (n+1) X^n$.
We can rewrite the **Lagrange polynomial** $\ell_i(X)$ as[^TABplus20]:
\begin{align}
\ell_i(X) 
    &= \frac{A(X)}{A'(\omega^i) (X - \omega^i)}\\\\\
    &= \frac{X^{n+1} -1 }{A'(\omega^i) (X - \omega^i)}\\\\\
    &= \frac{X^{n+1} -1 }{(n+1)\omega^{in} (X - \omega^i)}
\end{align}
Note that $\omega^{in} = \omega^{i(n+1) - i} = (\omega^{n+1})^i \cdot \omega^{-i} = \omega^{-i}$. So:
\begin{align}
\ell_i(X) 
    &= \frac{(X^{n+1} - 1) \omega^i}{(n+1) (X - \omega^i)}\\\\\
    &= \frac{(1 - X^{n+1})}{n+1} \cdot \frac{\omega^i}{\omega^i - X}\\\\\
\end{align}
This implies that, for any point $\term{\gamma}\notin \H$, we can interpolate $f(\gamma)$ as:
\begin{align}
\label{eq:interpolate}
\term{f(\gamma)} = \frac{1 - \gamma^{n+1}}{n+1} \sum_{i\in[0, n]} f(\omega^i) \frac{\omega^i}{\omega^i - \gamma}
\end{align}

{: .note}
This will be useful later in our [proving algorithm](#mathsfdekartmathsffftmathsfprovemathcalfscdotmathsfprk-c-ell-z_0ldotsz_n-1-rrightarrow-pi) and takes (1) $\approx \log_2{(n+1)}$ $\F$ muls for $\gamma^{n+1}$, (2) a size-$(n+1)$ [batch inversion](/batch-inversion) (3) $3(n+1)+1$ $\F$ multiplications for the 3 products inside the sum and (4) $2(n+1)$ $\F$ additions

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

For example, if the verifier has KZG commitments to the $f_j$'s, the verifier can be given a KZG commitment to $h_j$ and use a pairing-check to enforce the above relation:
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

The key observation is that proving that $f_j$ stores bits is equivalent to:
\begin{align}
f_j(X) \in \\{0,1\\}, \forall X\in \H\setminus\\{\omega^n\\}\Leftrightarrow
\\\\\
\left. \vanish\ \middle|\ f_j(X)\left(f_j(X) - 1\right) \right.
\end{align}
This, in turn, is equivalent to proving there exists a quotient polynomial $\term{h_j(X)}$ of degree $2n - n = n$ such that:
\begin{align}
\label{eq:binarity-check}
\vanish\cdot h_j(X) = f_j(X)\left(f_j(X) - 1\right)
\end{align}

From here, there are two possible approaches to continue and obtain a ZK range proof.
Both assume that we use univariate KZG commitments to $f$ and the $f_j$'s.

### Our approach

<!--
For each $j\in[\ell)$, the verifier could be given a commitment to $h_j(X)$.
Then, the verifier would ask for openings for $h_j(\gamma)$ and $f_j(\gamma)$ at a random point $\gamma$.

Then, after checking the openings against the commitments to the $h_j$'s and $f_j$'s, the verifier checks that, $\forall j\in[\ell)$:
\begin{align}
\frac{\gamma^{n+1} - 1}{\gamma - \omega^n} \cdot h_j(\gamma) = f_j(\gamma)\left(f_j(\gamma) - 1\right)
\end{align}

This check could be batched (a little) using random $\term{\beta_j}$'s as:
\begin{align}
\frac{\gamma^{n+1} - 1}{\gamma - \omega^n} \cdot \sum_{j\in[\ell)} \emph{\beta_j} \cdot h_j(\gamma) = \sum_{j\in[\ell)} \emph{\beta_j} \cdot f_j(\gamma)\left(f_j(\gamma) - 1\right)
\end{align}

As a result, the verifier need only be given a commitment to $\sum_{j\in[\ell)} \beta_j\cdot h_j(X)$ and an opening of it at $\gamma$, plus the individual openings $f_j(\gamma)$.

Furthermore, these $\ell+1$ openings at the same point $\gamma$ can be easily batched in a scheme like KZG.
We call this scheme $\term{\dekartUni}$ and describe its [prover](#mathsfdekartmathsffftmathsfprovemathcalfscdotmathsfprk-c-ell-z_0ldotsz_n-1-rrightarrow-pi) and [verifier](#mathsfdekartmathsffftmathsfverifymathcalfscdotmathsfvk-c-ell-pirightarrow-01) algorithms (non-interactively) below.

{: .note}
DeKART easily generalizes to other homomorphic commitment schemes (e.g., Bulletproofs[^BBBplus18]).
-->

{: .todo}
Redo.

#### An alternative approach

As a different approach for enforcing Eq. \ref{eq:binarity-check}, the verifier could check, for each $j\in[\ell)$ that:
\begin{align}
\label{eq:hj-inefficient}
\pair{\one{h_j(\tau)}}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}} &= \pair{\one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}},\forall j\in[\ell)
\end{align}
As before, for this to work, the verifier would also verify "duality" of the $\Gr_1$ and $\Gr_2$ commitments to $f_j$ as per Eq. \ref{eq:duality}.

For performance, the verifier could pick random challenges $\term{\beta_j}\randget\F$ and combine all the checks from Eq. \ref{eq:hj-inefficient} into one:
\begin{align}
\label{eq:hj}
\pair{\underbrace{\sum_{j\in[\ell)} \beta_j \cdot \one{h_j(\tau)}}\_{\term{D}}}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}}
 &= 
\sum_{j\in[\ell)} \pair{\beta_j \cdot \one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}}
\end{align}
(A similar trick can be applied for the duality check as well from Eq. \ref{eq:duality}.
Furthermore, everything can be combined into a single multi-pairing.)

Next, instead of asking for the individual $h_j(X)$ commitments, the verifier will send the $\beta_j$'s to the prover and expect to receive just the commitment $\emph{D}$ to the random linear combination of the $h_j$'s.
This reduces proof size and makes the check in Eq. \ref{eq:hj} slightly faster:
\begin{align}
\label{eq:hj-efficient}
\pair{D}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}}
 &= 
\sum_{j\in[\ell)} \pair{\beta_j \cdot \one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}}
\end{align}
We describe this formally [in the appendix](#appendix-plausibly-zk-univariate-scheme).

<!--

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Setup}(1^\lambda, n)\rightarrow \mathsf{prk},\mathsf{vk}$

Generate powers of $\tau$ up to and including $\tau^n$:

 - $\term{\tau}\randget\F$
 - $\term{\omega} \gets$ a primitive $(n+1)$th root of unity in $\F$
 - $\term{\H}\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$

_Note:_ The highest degree of any committed polynomial in this scheme is $n$.
Even the vanishing polynomial $\vanish$ will have degree $n$.

Let $\term{\ell_i(X)} \bydef \prod_{j\in\H, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}$ denote the $i$th [Lagrange polynomial](/lagrange-interpolation), for $i\in[0, n]$.

Return the public parameters:
 - $\vk\gets \left(\tauTwo,\vanishTwo\right)$
 - $\prk\gets \left(\vk, \left(\ellOne{i}\right)\_{i\in[0,n]}\right)$

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Commit}(\mathsf{prk},z_0,\ldots,z_{n-1}; r)\rightarrow C$

This is just a [KZG commitment](/kzg) to the vector $\vec{z}\bydef [z_0,\ldots,z_{n-1}]$:

 - $\left(\cdot, (\ellOne{i})\_{i\in[0,n]}\right)\parse\prk$
 - $C \gets r\cdot \ellOne{n} + \sum_{i\in[n)} z_i \cdot \ellOne{i} \bydef \one{\emph{f(\tau)}}$ (as per Eq. \ref{eq:f-batched})

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, C, \ell; z_0,\ldots,z_{n-1}, r)\rightarrow \pi$

Recall $\emph{z_{i,j}}$ denotes the $j$th bit of each $z_i\in[0,2^\ell)$.

**Step 1:** Parse the proving key:
\begin{align}
\left(\vk, \left(\ellOne{i}\right)\_{i\in[0,n]}\right) &\parse\prk\\\\\
\end{align}

**Step 2:** Commit to $f_j(X)$, which stores the $j$th bits of each value:
\begin{align}
(\emph{r\_j})\_{j\in[n)} &\randget \correlate{r, \ell}\\\\\
\term{C\_j} &\gets r\_j\cdot \ellOne{n} + \sum\_{i\in[n)} z\_{i,j}\cdot \ellOne{i} \bydef \one{\emph{f\_j(\tau)}},\forall j\in[\ell)
\end{align}

*Note:* The $\ell$ size-$(n+1)$ MSMs here can be carefully-optimized: the scalars are either 0 or 1.

**Step 3a:** Interpolate a quotient polynomial arguing that $f_j(\omega^i) \in \\{0,1\\}$, except at $\omega^n$: 
\begin{align}
\emph{h_j(X)}\gets \frac{f_j(X)(f_j(X) - 1)}{(X^{n+1} - 1) / (X-\omega^n)} = \frac{(X-\omega^n)f_j(X)(f_j(X) - 1)}{X^{n+1} - 1},\forall j \in[\ell)
\end{align}

*Note:* Numerator is degree $2n$ and denominator is degree $n \Rightarrow h_j(X)$ is degree $n$

**Step 3b:** Add $(\vk, C, \ell, (C\_j)\_{j\in[\ell})$ to the $\FS$ transcript.

**Step 4a:** Combine all $h_j$'s into a single polynomial using random challenges from the verifier:
\begin{align}
\term{(\beta\_j)\_{j\in[\ell)}}
    &\fsget \\{0,1\\}^\lambda\\\\\
\term{h(X)} 
    &\gets \sum\_{j\in[\ell)} \beta\_j \cdot h\_j(X)
    = \frac{\sum\_{j\in[\ell)}\beta\_j (X-\omega^n)f\_j(X)(f\_j(X) - 1)}{X^{n+1} - 1}
\end{align}

*Note:* $h(X)$ remains of degree $n$. We discuss [how to interpolate it efficiently](#appendix-computing-hx) in the appendix.

**Step 4b:** Commit to $h(X)$:
\begin{align}
\term{D} \gets \sum\_{i\in[0,n]} h(\omega^i) \cdot \ellOne{i} \bydef \one{\emph{h(\tau)}}
\end{align}

**Step 4c:** Add $D$ to the $\FS$ transcript.

Next, we argue that $f_j(\omega^i) \in \\{0,1\\}$ for all $j$ by proving that $h(X) \cdot \vanish = \sum_{j\in[\ell)} \beta_j f_j(X)(f_j(X)-1)$ at a random point $X=\term{\gamma}$.
To do this, we must open $h(\gamma)$ and all $f_j(\gamma)$'s.

**Step 5a:** The verifier asks us to take a random linear combination of $h(X)$ and the $f_j(X)$'s:
\begin{align}
\term{\left(\xi\_j\right)\_{j\in[0,\ell]}} &\fsget \left(\\{0,1\\}^\lambda\right)^{\ell+1}\\\\\
\term{u(X)} &\bydef \sum\_{j\in[\ell)} \emph{\xi\_j} f\_j(X) + \emph{\xi\_\ell} h(X)
\end{align}
<!-- **Step 5b:** We commit to $u(X)$ as $\term{U} \gets \sum\_{j\in[\ell)} \xi_j \cdot C_j + \xi_\ell\cdot D\bydef \one{u(\tau)}$. --\>

**Step 6:** We get a random $\emph{\gamma\in\F}$ from the verifier and evaluate:
\begin{align}
    \emph{\gamma} &\fsget \F\\\\\
    \term{e\_{j,\gamma}} &\gets f\_j(\gamma),\forall j\in[\ell)\\\\\
    \term{e_\gamma} &\gets h(\gamma)
\end{align}

**Step 7:** We compute a KZG proof for $u(\gamma)$:
\begin{align}
    \term{\pi_\gamma} \gets \one{\frac{u(\tau) - u(\gamma)}{\tau-\gamma}}
\end{align}

_Note:_ By definition of the quotient polynomial committed in $\emph{\pi_\gamma}$, this can be done in a size-$(n+1)$ MSM as $\sum_{i\in[0,n]} \frac{u(\omega^i) - u(\gamma)}{\omega^i - \gamma} \cdot \ellOne{i}$[^kzg-lagrange-no-ffts].

Return the proof:
\begin{align}
\term{\pi}\gets \left((C\_j)\_{j\in[\ell)}, D, (e\_{j,\gamma})\_{j\in[\ell)}, e\_\gamma, \pi\_\gamma\right)
\end{align}

{: .note}
A nice trade-off is possible where, instead of base 2 (i.e., $z_i < 2^\ell$), we can use base-$b$ (i.e., $z_i < b^\ell$).
This reduces proof size and verifier time by a factor of $\log_2{b}$.
But it does increase the proving time and $\|\prk\|$ by a factor of $b$, because the degree of $h(X)$ increases from $n$ to $(b-1)n$.
(Something similar happens to $u(X)$.)
It also complicates the $h(X)$ interpolation [in the appendix](#appendix-computing-hx), which can no longer happen over the domain $\H$ of size $n+1$, but has to happen over some other domain of size $\ge (b-1)n + 1$.

#### Proof size and prover time

**Proof size** is _trivial_: $(\ell+2)\Gr_1 + (\ell+1)\F$ $\Rightarrow$ independent of the batch size $n$, but linear in the bit-width $\ell$ of the values.

**Prover time** is:

 - $\ell n$ $\Gr_1$ $\textcolor{green}{\text{additions}}$ for each $c_j, j\in[\ell)$
 - $\ell$ $\Gr_1$ scalar multiplications to blind each $c_j$ with $r_j$
 - $O(\ell n\log{n})$ $\F$ multiplications to interpolate $h(X)$
    + See [break down here](#time-complexity).
 - 1 size-$(n+1)$ L-MSM for committing to $h(X)$
 - 1 size-$(n+1)$ L-MSM for committing to the KZG proof in $\pi_\gamma$

{: .todo}
Fastest way to compute the evaluations $f_j(\gamma)$ and $h(\gamma)$, when those polynomials are in Lagrange basis, is via the Barycentric formula in Eq. \ref{eq:interpolate} in $O(n)$ field operations.

### $\mathsf{Dekart}^\mathsf{FFT}.\mathsf{Verify}^{\mathcal{FS}(\cdot)}(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

**Step 1:** Parse the $\vk$ and the proof $\pi$:
 - $\left(\tauTwo,\vanishTwo\right) \parse \vk$
 - $\left((C_j)_{j\in[\ell)}, D, (e\_{j,\gamma})\_{j\in[\ell)}, e\_\gamma, \pi\_\gamma\right) \parse \pi$

**Step 2:** Make sure the radix-2 decomposition is correct:
\begin{align}
\label{eq:c_j-decomposition}
\textbf{assert}\ C \equals \sum\_{j\in[\ell)} 2^j \cdot C\_j
\end{align}

**Step 3:** Reconstruct a commitment $\term{U}$ to $\sum_{j\in[\ell)} \xi_j\cdot f_j(X) + \xi_\ell h(X)$:
 - add $(\vk, C, \ell, (C_j)_{j\in[\ell})$ to the $\FS$ transcript
 - $(\beta_j)_{j\in[\ell)} \fsget \\{0,1\\}^\lambda$
 - add $D$ to the $\FS$ transcript.
 - $\left(\xi\_j\right)\_{j\in[0,\ell]} \fsget \left(\\{0,1\\}^\lambda\right)^{\ell+1}$
 - $\term{U} \gets \sum\_{j\in[\ell)} \xi_j \cdot C_j + \xi_\ell\cdot D$
 - $\gamma \fsget \F$

**Step 4:** Verify that $e_{j,\gamma} \equals f_j(\gamma)$ and $e_\gamma \equals h(\gamma)$:
\begin{align}
\label{eq:kzg-batch-verify}
\textbf{assert}\ \pair{\emph{U} - \one{\sum\_{j\in[\ell)} \xi\_j \cdot e\_{j,\gamma} + \xi\_\ell \cdot e\_\gamma}}{\two{1}} \equals \pair{\pi\_\gamma}{\tauTwo - \two{\gamma}}
\end{align}

**Step 5:** Make sure that the $f_j(\omega^i)$'s are either 0 or 1:
\begin{align}
\label{eq:zero-check}
\textbf{assert}\ e\_\gamma \cdot \frac{\gamma^{n+1} - 1}{\gamma - \omega^n} \equals \sum\_{j\in[\ell)} \beta\_j\cdot e\_{j,\gamma}(e\_{j,\gamma} - 1)
\end{align}

#### Verifier time

The verifier must do:

 - size-$\ell$ $\mathbb{G}_1$ small-MSM (i.e., small $2^0, 2^1, 2^2, \ldots, 2^{\ell-1}$ scalars)
 - size-$(\ell+2)$ $\mathbb{G}_1$ L-MSM for the left input the LHS pairing
 - 1 $\Gr_2$ scalar multiplication for the right input the RHS pairing
 - size-$2$ multipairing for the KZG proof verification


### Knowledge-soundness and ZKness proofs

{: .warning}
The proofs below are for the **interactive** version of DeKART, which is **not** what we described in the previous section.
Instead, we described the _non-interactive_ version, by manually (and hopefully correctly) applying the Fiat-Shamir (FS) transform [^FS87].
Nonetheless, this should be okay.
First, FS preserves the knowledge-soundness property proved below, since our protocol is (1) public-coin and (2) constant-round. 
(**TODO:** Reference needed.)
Second, FS preserves the ZKness property proved below, since our simulator will be given all verifier challenges and is straight-line.
(**TODO:** Reference needed.)
Why do we do things this way?
We want this blog to serve as a good reference for _practitioners_, who almost always need to implement the non-interactive variant.
If we were to describe the interactive variant, they'd have to manually apply the FS transform and, unfortunately, this is awfully easy to get wrong.

{: .todo}
Make sure you are not missing anything.

#### Knowledge soundness proof

<!-- Here you can define LaTeX macros --\>
<div style="display: none;">$
\def\E{\mathcal{E}}
$</div> <!-- $ --\>

We show how, given an _interactive_ **algebraic adversary** $\Adv$ (in the AGM[^FKL18]), there exists an **extractor** $\E$ that interacts with $\Adv$ such that if $\Adv$ outputs $C,\ell$ and a valid proof $\pi$, then $\E$ can output the original vector of $\ell$-bit values committed in $C$ and the randomness $r$ it was committed with.
Here, $\E$ will play the role of the verifier: e.g., $\E$ is the one who generates the public coin challenges (randomness).
$\E$ is also allowed to "rewind" $\Adv$ so as to get different answers for different challenges at any point in its interaction with $\Adv$.

The **public list** of group elements consists of the KZG SRS that $\Adv$ gets as input: i.e., $\ellOne{i},\forall i\in[0,n]$.
In the AGM, every group element $P \in \Gr_1$ that $\Adv$ outputs must have a **representation** $(p_0, \ldots, p_n)$ w.r.t. to this public list.
Viewed differently, representations are just polynomials: i.e., $P$'s representation is $P(X) = \sum_{i\in[0,n]} p_i \cdot \ell_i(X)$ of degree $\le n$ such that $P=\one{P(\tau)}$.

The adversary will output elements, one by one, sending them to the extractor, as it builds the proof $\pi\bydef \left((C_j)_{j\in[\ell)}, D, (e\_{j,\gamma})\_{j\in[\ell)}, e\_\gamma, \pi\_\gamma\right)$, as per the steps in [$\dekartUni.\mathsf{Prove}$](#mathsfdekartmathsffftmathsfprovemathcalfscdotmathsfprk-c-ell-z_0ldotsz_n-1-rrightarrow-pi).

The extractor's goal is to output the values $z_i\in[2^\ell)$ and randomness $r$ such that:
 1. $C=\one{f(\tau)}$
 2. $f(\omega^i) = z_i,\forall i\in[n)$
 3. $f(\omega^n) = r$.

**Let's begin.**

The adversary $\Adv$ first outputs $C$ and its $f(X)$ representation.
Then, the adversary gradually outputs the proof $\pi$.
First, $\Adv$ outputs the $C_j$'s in $\pi$ and their associated $f_j(X)$'s.

_Note:_ All extracted polynomials have degree $\le n$, since their representation is w.r.t. the public list of degree-$n$ Lagrange polynomial commitments.

From the check in Eq. \ref{eq:c_j-decomposition}, it follows with overwhelming probability that:
\begin{align}
f(X) &= \sum\_{j\in[\ell)} 2^j \cdot f\_j(X)\\\\\
\end{align}

{: .note}
Here, we are relying on the key property of the AGM that representations are chosen independently of the public list of elements.
But, in an abundance of caution, let's prove that this must be the case.
Suppose the check in Eq. \ref{eq:c_j-decomposition} passes but we instead have $f(X) \ne \sum\_{j\in[\ell)} 2^j \cdot f_j(X) \Leftrightarrow f(X) - \sum\_{j\in[\ell)} 2^j \cdot f_j(X) \ne 0$.
Since the check passed, this means that $f(\tau) - \sum\_{j\in[\ell)} 2^j \cdot f_j(\tau) = 0$ for an independently-and-uniformly sampled $\tau$.
But we know via Schwartz-Zippel that the probability of this happening for the non-zero polynomial above is $n / \|\F\|$, so it is negligible, since the degrees here are $\le n$.
Therefore, the extractor can proceed safely, and the probability of it failing will remain very small.

Next, we have to show that the values $\emph{z_i}\bydef f(\omega^i),\forall i\in[n)$ are in $[0,2^\ell)$.
Let $\emph{z_{i,j}}\bydef f_j(\omega^i),\forall i\in[n),j\in[\ell)$.
We know from the extraction above that $z_i = \sum_{j\in[\ell)} 2^j \cdot z_{i,j}$.
The only remaining thing to argue is that all $z_{i,j} \in \\{0,1\\}$.
To do this, it is sufficient to argue that $\forall j\in[\ell), f_j(X)(f_j(X) - 1)$ is divisible by $\vanish$.
Unfortunately, our aggressive batching will make this a bit involved.

At this point, the extractor $\E$ flips coins and generates $\lambda$-bit uniform $\beta_j$'s which it sends to $\Adv$.
Then, $\Adv$ sends back $D$ with its $h(X)$ representation.

Next, the extractor $\E$ flips more coins and generates (1) $\lambda$-bit uniform $\xi_j$'s and (2) a uniform $\gamma \in \F$ which it also sends to $\Adv$.
Then, $\Adv$ sends evaluations $e_{j,\gamma}$ and $e_\gamma$ together with a proof $\pi_\gamma\in \Gr_1$ and its representation $q(X)$.

Since the proof verifies as per Eq. \ref{eq:kzg-batch-verify}, re-arranging a bit, we have:
\begin{align}
\sum\_{j\in[\ell)} \xi\_j (f\_j(\tau) - e_{j,\gamma})+ \xi\_\ell (h(\tau)-e_\gamma) &= q(\tau)(\tau - \gamma)
\end{align}
By the same Schwartz-Zippel reasoning from before, it implies that:
\begin{align}
\label{eq:gamma}
\sum\_{j\in[\ell)} \xi\_j (f\_j(X) - e_{j,\gamma})+ \xi\_\ell (h(X)-e_\gamma) &= q(X)(X - \gamma)
\end{align}
With overwhelming probability, this implies that $f_j(\gamma) = e_{j,\gamma},\forall j\in[\ell)$ and $h(\gamma)=e_\gamma$.

Suppose that this were not the case and, wlog., consider $h(\gamma)\ne e_\gamma$ (the other cases being symmetrical to this one).
Let $G(\xi_0,\ldots,\xi_\ell)\bydef G(\boldsymbol{\xi}) \bydef \sum\_{j\in[\ell)} \xi\_j (f\_j(\gamma) - e_{j,\gamma})+ \xi\_\ell (h(\gamma)-e_\gamma)$.
By our assumption, it follows that $G(\boldsymbol{Y})$ is a **non-zero** multivariate polynomial of degree 1, since at least one of its coefficents is non-zero (i.e., $h(\gamma) - e_\gamma$).
But $G(\boldsymbol{\xi}) = 0$ by Eq. \ref{eq:gamma} holding for all $X$, including for $\gamma$.
Since the $\xi_j$'s were sampled uniformly in $[2^\lambda)$ and independently of the coefficients of $G$, the probability that $G(\boldsymbol{\xi}) = 0$ is $1/2^\lambda$ which is negligible (due to Schwartz-Zippel on multivariate polynomials of degree 1 where the evaluation points are in $[2^\lambda)$).

We have shown above that $e_{j,\gamma} = f_j(\gamma)$ and $e_\gamma = h(\gamma)$.
Then, since Eq. \ref{eq:zero-check} holds, it means that:
\begin{align}
h(\gamma) \cdot \frac{\gamma^{n+1} - 1}{\gamma - \omega^n} = \sum_{j\in[\ell)} \beta_j \cdot f_j(\gamma) (f_j(\gamma) - 1) 
\end{align}
By the same Schwartz-Zippel reasoning from before, predicated on $\gamma$ being picked uniformly and independently from $h(X)$ and $f_j(X)$ (which it is), it implies that:
\begin{align}
h(X) \cdot \vanish = \sum_{j\in[\ell)} \beta_j \cdot f_j(X) (f_j(X) - 1) 
\end{align}

With overwhelming probability, this implies that $f_j(\omega^i) \in \\{0,1\\},\forall j\in[\ell), i\in[n)$.

Suppose that this were not the case.
Then, we are saying there exists $j'\in[\ell], i'\in[n)$ s.t. $f_{j'}(\omega^{i'}) \notin\\{0,1\\}$ **and yet** the equation above holds for $X=\omega^{i'}$.
Let $G_{i'}(\beta_0,\ldots,\beta_{\ell-1}) \bydef G_{i'}(\boldsymbol{\beta}) \bydef \sum_{j\in[\ell)} \beta_j \cdot f_j(\omega^{i'}) (f_j(\omega^{i'}) - 1)$.
Then, this is the same thing as saying that $G_{i'}(\boldsymbol{\beta}) = 0$ by virtue of the equation above holding for $X=\omega^{i'}$.
But $G_{i'}$ is a **non-zero** multivariate polynomial since, by our assumption above, there exists $j'\in[\ell)$ such that one of its coefficients $f_{j'}(\omega^{i'})(f_{j'}(\omega^{i'}) - 1)$ is not zero!
Since the $\beta_j$'s were sampled uniformly in $[2^\lambda)$ and independently of the coefficients of $G_{i'}$, the probability that $G_{i'}(\boldsymbol{\beta}) = 0$ is $1/2^\lambda$ which is negligible (due to Schwartz-Zippel on multivariate polynomials of degree 1 where the evaluation points are in $[2^\lambda)$).

Therefore, we are done, since we have shown that all $z_{i,j}\bydef f_j(\omega^i)\in\\{0,1\\}$.

#### ZKness proof

<!-- Here you can define LaTeX macros --\>
<div style="display: none;">$
\def\S{\mathcal{S}}
$</div> <!-- $ --\>

We must show that there exists a **simulator** $\S$ which, when given as input the KZG commitment $C$, bit length $\ell$, the KZG trapdoor $\tau$ in the $\vk$ and all of the $\beta_j$'s, $\xi_j$'s and $\gamma$ verifier challenges, it can output a proof $\pi$ such that:
1. The interactive counterpart of $\dekartUni.\mathsf{Verify}(\vk, C, \ell; \pi)$ accepts when the verifier challenges are set to $\left((\beta_j, \xi_j)_{j\in\ell}, \gamma\right)$.
2. The distribution of $\pi$'s outputted by $\S$ is the same as the distribution of $\pi$'s outputted by $\dekartUni.\mathsf{Prove}(\cdot)$, given that the $\vk$ and $\prk$ are honestly-computed from the same $\tau$ via $\dekartUni.\mathsf{Setup}(\cdot)$.

**Step 1:** $\S$ picks uniform $C_0, \ldots, C_{\ell-2}$ from the group $\Gr_1$ and sets the last $C_{\ell-1}$ as:
\begin{align}
C\_{\ell-1}\gets \frac{C - \sum_{j\in[\ell-1)} 2^j \cdot C_j}{2^{\ell-1}}
\end{align}
This ensures the $C_j$'s are uniform and they satisfy the radix-2 decomposition check from Eq. \ref{eq:c_j-decomposition}.

**Step 2:** $\S$ picks uniform evaluations $e_{0,\gamma}, \ldots,e_{\ell-1,\gamma}$ from $\F$ and computes:
\begin{align}
e\_\gamma \gets \sum\_{j\in[\ell)} \beta\_j\cdot e\_{j,\gamma}(e\_{j,\gamma} - 1) \cdot \frac{\gamma - \omega^n}{\gamma^{n+1} - 1}
\end{align}
so as to satisfy Eq. \ref{eq:zero-check}.

{: .todo}
This is wrong: the adversary $\Adv$ can have the full witness ($z_i$'s and $r$) and therefore all of the $f_j(\omega^i)$'s except for their randomness $r_j = f_j(\omega^n)$.
Imagine the $z_i$'s were all zero, then $f_j(X) = \ell_n(X)\cdot r_j$, but $\Adv$ still does not know $r_j$.
But the proof reveals $f_j(\gamma)$ and $\Adv$ can compute $\ell_n(\gamma)$, so it can compute $r_j = f_j(\gamma) / \ell_n(\gamma)$.
As a result, $\Adv$ can tell that the randomly-sampled $C_j=\one{f_j(\tau)}$ commitment was not computed correctly from the zeros and from $r_j$.
\
\
The implication here is that if we are gonna give out $f_j$ commitments, we can't even reveal one evaluation on them?
(Whether we do the correlated-randomness radix-2 check has no bearing on this either... It does have a bearing on whether we also leak $f(\gamma)$ though, which right now we do, which is also a problem.)

**Step 3**: $\S$ picks a uniform $D$ in $\Gr_1$.

**Step 4:** $\S$ simulates a valid KZG proof w.r.t. $U\bydef\sum_{j\in[\ell)} \xi_j\cdot C_j + \xi_\ell D$ for the evaluations from Step 2 as follows:
\begin{align}
\pi\_\gamma\gets 
(\tau - \gamma)^{-1}\cdot \left(U - \one{\sum\_{j\in[\ell)} \xi\_j \cdot e\_{j,\gamma} + \xi\_\ell \cdot e\_\gamma}\right)
\end{align}
so as to satisfy Eq. \ref{eq:kzg-batch-verify}

-->

## Multilinear batched ZK range proof

The previous section's [univariate construction](#univariate-batched-zk-range-proof) requires FFT work for interpolating $h(X)$, which takes up a significant chunk of the prover time.

As a result, our paper[^BDFplus25e] focuses on a [multilinear-based](/mle) variant of DeKART that uses a zero-knowledge variant of the [sumcheck protocol](/sumcheck).

## Conclusion

Your thoughts or comments are welcome on [this thread](https://x.com/alinush407/status/1950600327066980693).

## Appendix: Computing $h(X)$

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

### Time complexity

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

## Appendix: Plausibly-ZK univariate scheme

The variant below suffers from two problems:

 - It lacks a proof of ZKness: it's hard to show a simulator exists.
 - It incurs extra $\Gr_2$ commitment cost (for the $\tilde{C}_j$ commitments to the $f_j$'s)

Nonetheless, we describe it below for future reference.
We highlight the bulk of the differences in $\bluedashedbox{\text{dashed blue boxes}}$.

### $\widetilde{\mathsf{Dekart}}^\mathsf{FFT}.\mathsf{Setup}(1^\lambda, n)\rightarrow \mathsf{prk},\mathsf{vk}$

Generate powers of $\tau$ up to and including $\tau^n$: 

 - $\term{\tau}\randget\F$
 - $\term{\omega} \gets$ a primitive $(n+1)$th root of unity in $\F$
 - $\term{\H}\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$

Let $\term{\ell_i(X)} \bydef \prod_{j\in\H, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}$ denote the $i$th [Lagrange polynomial](/lagrange-interpolation), for $i\in[0, n]$.

Return the public parameters:
 - $\vk\gets \left(\tauTwo,\vanishTwo\right)$
 - $\prk\gets \left(\vk, \left(\ellOne{i}\right)\_{i\in[0,n]}, \bluedashedbox{\left(\ellTwo{i}\right)\_{i\in[0,n]}}\right)$

### $\widetilde{\mathsf{Dekart}}^\mathsf{FFT}.\mathsf{Commit}(\mathsf{prk},z_0,\ldots,z_{n-1}; r)\rightarrow C$

The same as [$\dekartUni.\mathsf{Commit}$](#mathsfdekartmathsffftmathsfcommitmathsfprkz_0ldotsz_n-1-rrightarrow-c), but ignores the extra $\ellTwo{i}$ parameters in the $\prk$, of course.

### $\widetilde{\mathsf{Dekart}}^\mathsf{FFT}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, C, \ell; z_0,\ldots,z_{n-1}, r)\rightarrow \pi$

Recall $\emph{z_{i,j}}$ denotes the $j$th bit of each $z_i\in[0,2^\ell)$.

 - $\left(\vk, \left(\ellOne{i}\right)\_{i\in[0,n]}, \left(\ellTwo{i}\right)\_{i\in[0,n]}\right)\parse\prk$
 - $(r_j)_{j\in[n)} \randget \correlate{r, \ell}$
 - $C_j \gets r_j\cdot \ellOne{n} + \sum_{i\in[n)} z_{i,j}\cdot \ellOne{i} \bydef \one{\emph{f_j(\tau)}},\forall j\in[\ell)$
 - $\bluedashedbox{\tilde{C}\_j \gets r_j \cdot \ellTwo{n} + \sum_{i\in[n)} z_{i,j}\cdot \ellTwo{i} \bydef \two{\emph{f_j(\tau)}},\forall j\in[\ell)}$
 - add $(\vk, C, \ell, (C_j, \tilde{C}\_j)_{j\in[\ell})$ to the $\FS$ transcript
 - $h_j(X)\gets \frac{f_j(X)(f_j(X) - 1)}{(X^{n+1} - 1) / (X-\omega^n)} = \frac{(X-\omega^n)f_j(X)(f_j(X) - 1)}{X^{n+1} - 1},\forall j \in[\ell)$
 - $(\term{\beta_j})_{j\in[\ell)} \fsget \\{0,1\\}^\lambda$
 - $\term{h(X)}\gets \sum_{j\in[\ell)} \beta_j \cdot h_j(X) = \frac{\sum_{j\in[\ell)}\beta_j (X-\omega^n)f_j(X)(f_j(X) - 1)}{X^{n+1} - 1}$ 
 - $D \gets \sum_{i\in[0,n]} h(\omega^i) \cdot \ellOne{i} \bydef \one{\emph{h(\tau)}}$
    + **Note:** We [discuss above](#appendix-computing-hx) how to interpolate these efficiently!
 - $\term{\pi}\gets \bluedashedbox{\left(D, (C_j,\tilde{C}\_j)_{j\in[\ell)}\right)}$

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

### $\widetilde{\mathsf{Dekart}}^\mathsf{FFT}.\mathsf{Verify}^{\mathcal{FS}(\cdot)}(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

**Step 1:** Parse the $\vk$ and the proof $\pi$:
 - $\left(\tauTwo,\vanishTwo\right) \parse \vk$
 - $\left(D, (C_j,\tilde{C}\_j)_{j\in[\ell)}\right) \parse \pi$

**Step 2:** Make sure the radix-2 decomposition is correct:
 - **assert** $C \equals \sum_{j=0}^{\ell-1} 2^j \cdot C_j$

**Step 3:** Make sure the $C_j$'s are bit commitments:
 - add $(\vk, C, \ell, (C_j, \tilde{C}\_j)_{j\in[\ell})$ to the $\FS$ transcript
 - $(\term{\beta_j})_{j\in[\ell)} \fsget \\{0,1\\}^\lambda$
 - **assert** $\bluedashedbox{\pair{D}{\vanishTwo} \equals \sum_{j\in[\ell)}\pair{\beta_j\cdot C_j}{\tilde{C}_j - \two{1}}}$

**Step 4:** Ensure duality of the $C_j$ and $\tilde{C}_j$ bit commitments:
 - $\bluedashedbox{(\term{\alpha_j})_{j\in[\ell)} \fsget \\{0,1\\}^\lambda}$
 - **assert** $\bluedashedbox{\pair{\sum_{j\in[\ell)} \alpha_j \cdot C_j}{\two{1}} \stackrel{?}{=} \pair{\one{1}}{\sum_{j\in[\ell)} \alpha_j \cdot \tilde{C}_j}}$

The two pairing equation checks above can be combined into a single size $\ell+3$ multipairing by picking a random $\term{\gamma}\in\F$ and checking:
\begin{align}
\pair{\sum\_{j\in[\ell)} \alpha_j\cdot C_j}{-\two{\emph{\gamma}}} +
\pair{\one{\emph{\gamma}}}{\sum\_{j\in[\ell)} \alpha_j\cdot \tilde{C}\_j} + {} \\\\\ 
{} + \pair{-D}{\vanishTwo} + 
\sum\_{j\in[\ell)} \pair{\beta_j \cdot C_j}{\tilde{C}_j - \two{1}} \equals \three{0}
\end{align}
(Unclear what will be faster: computing $(\one{\gamma},\two{\gamma})$, or multiplying $\gamma$ by the $\alpha_j$'s, which will increase the MSM scalar length from $\lambda$ bits to $2\lambda$. 
My sense is that the 1st option, which we take above, should be faster.)
{: .note}

#### Verifier time

The verifier must do:

 - size-$\ell$ $\mathbb{G}_1$ small-MSM (i.e., small $2^0, 2^1, 2^2, \ldots, 2^{\ell-1}$ scalars)
 - size-$\ell$ $\mathbb{G}_1$ L-MSM for the $C_j$'s (i.e., 128-bit $\alpha_j$ scalars)
 - size-$\ell$ $\mathbb{G}_2$ L-MSM for the $\tilde{C}_j$'s (i.e., 128-bit $\alpha_j$ scalars)
 - size-$(\ell+3)$ multipairing

### Concrete performance

We implemented $\tildeDekartUni$ in Rust over BLS12-381 using `blstrs` in this pull request[^pr1].
Our code stands to be further optimized.
Here are a few benchmarks, for 16-bit ranges, comparing it with Bulletproofs over the **faster** Ristretto255 curve:

<!--
| $\tildeDekartUni$ | 16-bit |        |                   |                  |                 |                    |
-->

| Scheme            | $\ell$ | $n$    | Proving time (ms) | Verify time (ms) | Total time (ms) | Proof size (bytes) |
| ------------------| -- --- | ------ | ----------------- | ---------------- | --------------- | ------------------ |
| $\tildeDekartUni$ | 16-bit | $3$    | $\good{3.96}$     | $\bad{8.86}$     | $12.82$         | $\bad{2352}$       |
| Bulletproofs      | 16-bit | $4$    | $\bad{10.5}$      | $\good{1.4}$     | $11.9$          | $\good{672}$       |
| $\tildeDekartUni$ | 16-bit | $7$    | $\good{4.26}$     | $\bad{8.66}$     | $\good{12.92}$  | $\bad{2352}$       |
| Bulletproofs      | 16-bit | $8$    | $\bad{20.6}$      | $\good{2.4}$     | $\bad{23}$      | $\good{736}$       |
| $\tildeDekartUni$ | 16-bit | $15$   | $\good{4.93}$     | $\bad{8.66}$     | $\good{13.59}$  | $\bad{2352}$       |
| Bulletproofs      | 16-bit | $16$   | $\bad{41.1}$      | $\good{4}$       | $\bad{45.1}$    | $800$              | 
| $\tildeDekartUni$ | 16-bit | $31$   | $\good{5.19}$     | $\bad{8.62}$     | $\good{13.81}$  | $\bad{2352}$       |
| $\tildeDekartUni$ | 16-bit | $4064$ | $\good{123}$      | $\good{5.4}$     | $\good{128}$    | $\bad{2,352}$      |
| Bulletproofs      | 16-bit | $4064$ | $\bad{5,952}$     | $\bad{412}$      | $\bad{6,364}$   | $\good{1,312}$     |

For 32-bit ranges:

| Scheme            | $\ell$ | $n$    | Proving time (ms) | Verify time (ms) | Total time (ms) | Proof size (bytes) |
| ------------------| -- --- | ------ | ----------------- | ---------------- | --------------- | ------------------ |
| $\tildeDekartUni$ | 32-bit | $2032$ | $\good{121}$      | $\good{6.9}$     | $\good{128}$    | $\bad{4,656}$      |
| Bulletproofs      | 32-bit | $2032$ | $\bad{5,539}$     | $\bad{411}$      | $\bad{5,950}$   | $\good{1,312}$     |

{: .warning}
Why the odd 4064 and 2032 numbers? From $16\times254$ and $8\times 254$, which arises when chunking 254 ElGamal ciphertexts into into 16 chunks, each encrypting 16-bits.

{: .note}
Some sample MSM times for BLS12-381 [here](/pairings#multi-exponentiations) may be useful to make sense of the numbers below.
(e.g., a size-4096 MSM in $\Gr_1$ was 6.04 ms on that machine).

In terms where most of the time is spent in $\tildeDekartUni$, here's a breakdown for $\ell=16$ and $n=2^{12}-1=4095$ (run on a different machine) via `ELL=16 N=4095 cargo bench -- range_proof` inside `aptos-core/crates/aptos-dkg/` in the pull request[^pr1]:

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
The time to commit to the $f_j(X)$'s currently $\bad{dominates}$ but this can be sped up significantly using pre-computation since the scalars are small and the bases $\ellOne{i}$ and $\ellTwo{i}$ are fixed.


## References

[^kzg-lagrange-no-ffts]: When $\gamma\notin\H$, we can use [a simple trick](https://ethresear.ch/t/kate-commitments-from-the-lagrange-basis-without-ffts/6950). However, when $\gamma = \omega^i \in \H$, we can use [differentiation tricks](/2025/01/24/Polynomial-differentiation-tricks.html) to compute the otherwise-uncomputable $\frac{u(\omega^i) - u(\omega^i)}{\omega^i - \omega^i}$ scalar by evaluating the derivative of $\frac{u(X) - u(\omega^i)}{X - \omega^i}$ at $X = \omega^i$. So, by evaluating $u'(X)$ at $X = \omega^i$, which should give $\sum_{j\ne i, j\in[0,n]} \frac{\omega^{j - i} (u(\omega^i) - u(\omega^j))}{\omega^j - \omega^i}$.
[^pr1]: Pull request: [Add univariate DeKART range proof](https://github.com/aptos-labs/aptos-core/pull/17531/files)
[^Borg20]: [Membership proofs from polynomial commitments](https://solvable.group/posts/membership-proofs-from-polynomial-commitments/), William Borgeaud, 2020

For cited works, see below 👇👇

{% include refs.md %}
