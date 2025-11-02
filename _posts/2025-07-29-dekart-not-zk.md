---
tags:
 - range proofs
 - zero-knowledge proofs (ZKPs)
 - KZG
 - negative result
title: "Negative result: Non-ZK DeKART range proof"
#date: 2020-11-05 20:45:59
#published: false
permalink: dekart-not-zk
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
This blog post describes a **flawed**, non-ZK range range proof based on univariate polynomials.
(For an actually-ZK scheme, see [this post](/dekart).)

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
\def\ellOne#1{\crs{\one{\lagr_{#1}(\tau)}}}
\def\ellTwo#1{\crs{\two{\lagr_{#1}(\tau)}}}
\def\sim{\mathcal{S}}
$</div> <!-- $ -->

## Introduction

In a short blog post[^Borg20], Borgeaud describes a very simple range proof for a single value $z$, which we summarize [here](borgeauds-unbatched-range-proof).
In the summer of 2024, we observed that Borgeaud's elegant protocol **very efficiently** extends to batch-proving **many values**[^BDFplus25e].
This ultimately led to a ZK range proof scheme based on [multilinear polynomials](/mle) and [sumcheck](/sumcheck), which is fully described in our academic paper[^BDFplus25e],

However, initially, we started with a ZK range proof based on [univariate polynomials](/polynomials) and [KZG commitments](/kzg).

This blog post describes that range proof and explains why it cannot be ZK in Type III bilinear groups[^GPS08].

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
{% include fiat-shamir-prelims.md %}
 - We will often [interpolate polynomials](/lagrange-interpolation) over the FFT basis $\term{\H}\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$, where $\term{\omega}$ is a primitive $(n+1)$th root of unity.

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

## (Likely-not-ZK) univariate batched range proof 

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

To verify Eq. \ref{eq:binarity-check} holds, the verifier could check, for each $j\in[\ell)$, that:
\begin{align}
\label{eq:hj-inefficient}
\pair{\one{h_j(\tau)}}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}} &= \pair{\one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}},\forall j\in[\ell)
\end{align}
For this to work, the verifier would also verify "duality" of the $\Gr_1$ and $\Gr_2$ commitments to $f_j$ as per Eq. \ref{eq:duality}.

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
\label{eq:verification}
\pair{D}{\two{\frac{\tau^{n+1} - 1}{\tau - \omega^n}}}
 &= 
\sum_{j\in[\ell)} \pair{\beta_j \cdot \one{f_j(\tau)}}{\two{f_j(\tau)}-\two{1}}
\end{align}

We describe the scheme in detail below.

### $\widetilde{\mathsf{Dekart}}^\mathsf{FFT}.\mathsf{Setup}(1^\lambda, n)\rightarrow \mathsf{prk},\mathsf{vk}$

Generate powers of $\tau$ up to and including $\tau^n$: 

 - $\term{\tau}\randget\F$
 - $\term{\omega} \gets$ a primitive $(n+1)$th root of unity in $\F$
 - $\term{\H}\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$

Let $\term{\lagr_i(X)} \bydef \prod_{j\in\H, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}$ denote the $i$th [Lagrange polynomial](/lagrange-interpolation), for $i\in[0, n]$.

Return the public parameters:
 - $\vk\gets \left(\tauTwo,\vanishTwo\right)$
 - $\prk\gets \left(\vk, \left(\ellOne{i}\right)\_{i\in[0,n]}, {\left(\ellTwo{i}\right)\_{i\in[0,n]}}\right)$

### $\widetilde{\mathsf{Dekart}}^\mathsf{FFT}.\mathsf{Commit}(\mathsf{prk},z_0,\ldots,z_{n-1}; r)\rightarrow C$

The same as [$\dekartUni.\mathsf{Commit}$](#mathsfdekartmathsffftmathsfcommitmathsfprkz_0ldotsz_n-1-rrightarrow-c), but ignores the extra $\ellTwo{i}$ parameters in the $\prk$, of course.

### $\widetilde{\mathsf{Dekart}}^\mathsf{FFT}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, C, \ell; z_0,\ldots,z_{n-1}, r)\rightarrow \pi$

Recall $\emph{z_{i,j}}$ denotes the $j$th bit of each $z_i\in[0,2^\ell)$.

 - $\left(\vk, \left(\ellOne{i}\right)\_{i\in[0,n]}, \left(\ellTwo{i}\right)\_{i\in[0,n]}\right)\parse\prk$
 - $(r_j)_{j\in[n)} \randget \correlate{r, \ell}$
 - $C_j \gets r_j\cdot \ellOne{n} + \sum_{i\in[n)} z_{i,j}\cdot \ellOne{i} \bydef \one{\emph{f_j(\tau)}},\forall j\in[\ell)$
 - ${\tilde{C}\_j \gets r_j \cdot \ellTwo{n} + \sum_{i\in[n)} z_{i,j}\cdot \ellTwo{i} \bydef \two{\emph{f_j(\tau)}},\forall j\in[\ell)}$
 - add $(\vk, C, \ell, (C_j, \tilde{C}\_j)_{j\in[\ell})$ to the $\FS$ transcript
 - $h_j(X)\gets \frac{f_j(X)(f_j(X) - 1)}{(X^{n+1} - 1) / (X-\omega^n)} = \frac{(X-\omega^n)f_j(X)(f_j(X) - 1)}{X^{n+1} - 1},\forall j \in[\ell)$
 - $(\term{\beta_j})_{j\in[\ell)} \fsget \\{0,1\\}^\lambda$
 - $\term{h(X)}\gets \sum_{j\in[\ell)} \beta_j \cdot h_j(X) = \frac{\sum_{j\in[\ell)}\beta_j (X-\omega^n)f_j(X)(f_j(X) - 1)}{X^{n+1} - 1}$ 
 - $D \gets \sum_{i\in[0,n]} h(\omega^i) \cdot \ellOne{i} \bydef \one{\emph{h(\tau)}}$
    + **Note:** We [discuss above](#appendix-computing-hx) how to interpolate these efficiently!
 - $\term{\pi}\gets {\left(D, (C_j,\tilde{C}\_j)_{j\in[\ell)}\right)}$

### Proof size and prover time

**Proof size** is _trivial_: $(\ell+1)\Gr_1 + \ell \Gr_2$ group elements $\Rightarrow$ independent of the batch size $n$, but linear in the bit-width $\ell$ of the values.

**Prover time** is:

 - $\ell n$ $\Gr_1$ $\textcolor{green}{\text{additions}}$ for each $C_j, j\in[\ell)$
 - $\ell$ $\Gr_1$ scalar multiplications to blind each $C_j$ with $r_j$
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
 - **assert** ${\pair{D}{\vanishTwo} \equals \sum_{j\in[\ell)}\pair{\beta_j\cdot C_j}{\tilde{C}_j - \two{1}}}$

**Step 4:** Ensure duality of the $C_j$ and $\tilde{C}_j$ bit commitments:
 - ${(\term{\alpha_j})_{j\in[\ell)} \fsget \\{0,1\\}^\lambda}$
 - **assert** ${\pair{\sum_{j\in[\ell)} \alpha_j \cdot C_j}{\two{1}} \stackrel{?}{=} \pair{\one{1}}{\sum_{j\in[\ell)} \alpha_j \cdot \tilde{C}_j}}$

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

### Verifier time

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

### Cannot simulate in the Type 3 setting

Suppose, there exists a simulator $\sim$ for the scheme above such that $\sim(\tau, C, \ell)$ outputs a valid proof $\pi \bydef (D, (C\_j,\tilde{C}\_j)\_{j\in[\ell)})$.

Then, the [verifier's](#widetildemathsfdekartmathsffftmathsfverifymathcalfscdotmathsfvk-c-ell-pirightarrow-01) last check will pass:
\begin{align}
\pair{\sum_{j\in[\ell)} \alpha_j \cdot C_j}{\two{1}} \equals \pair{\one{1}}{\sum_{j\in[\ell)} \alpha_j \cdot \tilde{C}_j}
\end{align}

In particular, for $\ell = 1$, recall that the verifier ensures that $C \equals \sum_{j\in[\ell)} 2^j\cdot C_j = 2^0 C_0 = C_0$.
Furthermore, the pairing check from above will imply:
\begin{align}
\pair{\alpha_0 \cdot C_0}{\two{1}} &\equals \pair{\one{1}}{\alpha_0 \cdot \tilde{C}_0}\Leftrightarrow\\\\\
\pair{C_0}{\two{1}} &\equals \pair{\one{1}}{\tilde{C}_0}\Leftrightarrow\\\\\
\pair{C}{\two{1}} &\equals \pair{\one{1}}{\tilde{C}_0} \Leftrightarrow\\\\\
\pair{\underbrace{\one{x}}\_{\bydef C}}{\two{1}} &\equals \pair{\one{1}}{\underbrace{\two{x}}\_{\bydef \tilde{C}\_0}}
\end{align}

Let $\term{\phi_\tau} : \Gr_1 \rightarrow \Gr_2$, be defined as:
\begin{align}
\forall G \in \Gr\_1,
\emph{\phi\_\tau(G)} \bydef \tilde{C}\_0,\ \text{where}\ (\cdot, (\cdot,\tilde{C}\_0))\gets \sim(\tau, G, 1)
\end{align}

When $\tau \randget \F$ is randomly picked, $\phi_\tau$ is a homomorphism, since $\phi_\tau(\one{x}) = \two{x}$ for all inputs $\one{x}$.
Therefore, the simulator $\sim$ yields a homomorphism $\Rightarrow$ symmetric external Diffie-Hellman (SXDH) would be broken in $(\Gr_1,\Gr_2)$.

## Conclusion

Your thoughts or comments are welcome on [this thread](https://x.com/alinush/status/1950600327066980693).

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

## References

[^pr1]: Pull request: [Add univariate DeKART range proof](https://github.com/aptos-labs/aptos-core/pull/17531/files)
[^Borg20]: [Membership proofs from polynomial commitments](https://solvable.group/posts/membership-proofs-from-polynomial-commitments/), William Borgeaud, 2020

For cited works, see below 👇👇

{% include refs.md %}
