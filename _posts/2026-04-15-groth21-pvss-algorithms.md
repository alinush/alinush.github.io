---
tags:
 - PVSS
 - zero-knowledge proofs (ZKPs)
 - range proofs
 - ElGamal
 - sigma protocols
 - distributed key generation (DKG)
title: "Groth21 PVSS"
type: note
#date: 2020-11-05 20:45:59
#published: false
permalink: groth21
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Groth's non-interactive distributed key generation paper[^Grot21e], which uses a novel approximate ZK range proofs to argue correct chunking, but inadvertantly increases share decryption time.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
%
\def\ek{\mathsf{ek}}
\def\dk{\mathsf{dk}}
\def\Gone{G_1}
\def\Gtwo{G_2}
%
\def\ProveSh{\mathsf{NIZK.ProveSh}}
\def\VerSh{\mathsf{NIZK.VerSh}}
\def\ProveChunk{\mathsf{NIZK.ProveChunk}}
\def\VerChunk{\mathsf{NIZK.VerChunk}}
%
\def\pvss{\mathsf{PVSS}}
\def\deal{\mathsf{Deal}}
\def\verify{\mathsf{Verify}}
\def\decrypt{\mathsf{DecryptShare}}
\def\setup{\mathsf{Setup}}
%
\def\trx{\mathsf{trx}}
$</div> <!-- $ -->

## Overview 

{: .info}
$\term{t}$-out-of-$\term{n}$ means you need $t$ shares to reconstruct out of all $n$ shares.

**Step 1:** Commit to shares $\rightarrow$ split each share into $\term{m}$ **chunks** $\rightarrow$ [ElGamal](/elgamal)-encrypt chunks:

- Pick random degree $t-1$ polynomial
- Commits to its $t$ coefficients
- Vanilla ElGamal batch encrypt the $nm$ chunks of the shares for each player

**Step 2**: Proofs:

1. **Proof of correct secret sharing:** i.e., ciphertexts encrypt the chunks of the $n$ evaluations of the committed degree-$t$ polynomial
2. **Proof of correct chunking:** i.e., ciphertexts encrypt small enough chunks

## Preliminaries

### Notation

We use **additive notation** for group operations: scalar multiplication is denoted $a \cdot G$ (rather than $G^a$), group addition is $A + B$ (rather than $A \cdot B$), and the identity element is $\mathcal{O}$ (rather than $1$).
We denote the generators of $\mathbb{G}_1$ and $\mathbb{G}_2$ as $\Gone$ and $\Gtwo$, respectively.

The Groth21 scheme does **not** need pairing-friendly groups (it can be that $\Gr_1 = \Gr_2$), but we describe it as if it used pairing-friendly groups.
This is more general and in line with DFINITY's implementation over BLS12-381 which has Type-III pairings.

- $\term{\lambda}$ - the security parameter (should be 128)
    + We work over groups of size $\sizeof{\Gr_1} \equiv 2^{2\lambda}$
- $\emph{t}$ - threshold (need $t$ shares to reconstruct)
- $\emph{n}$ - number of players / shares
- $\term{B}=2^{\term{b}}$ - each share is split into a chunk $< B$
    - But Groth's *approximate* range proof will give a worse guarantee; see [below](#correct-chunking-zkp).
    - $B=2^{40}$ should be practical for baby-step giant step ($2^{20} \times .5$ $\mu$s = ~0.5 secs)
        + However, Groth21's approximate range proof means we will have to compute DLs much bigger than $B$
- $\emph{m}$ - the \# of chunks we split a field element share into; typically set to $2\lambda/b$
- Groth21-specific parameters:
    - $\term{\ell}$ - number of approximate range proof repetitions
    - $\term{E}$ - size of a Fiat-Shamir challenge; set as $E = 2^{\lceil{\lambda}/{\ell}\rceil}$
        - Repeating $\ell$ times reduces the risk of fraud on entry $(i, j)$ to $\le E^{-\ell}$
    - $\term{S}$ - the range that the random Groth sums will be in; should be $\emph{S} = nm(B-1)(E-1)$
    - $\term{Z}=2\ell S = 2\ell nm (E-1)(B-1)$ - the size of the range of the sum after **blinding** (see [$\ProveChunk$](#nizk-provechunk))
        - The decrypted chunk is guaranteed to be in $[1-Z, Z-1]$
            + **TODO:** What about $\Delta$?
        - So the max range of a discrete log is $(Z-1)-(1-Z)+1= 2Z-1$
            - The receiver needs to compute $E-1$ discrete logs from a range of size $2Z-1$.
            - The cost of this computation is $(E-1)\cdot \sqrt{2Z-1}$. 
                * This means that we will need to use a much smaller $B$.
                * We can do slightly better by using batched BSGS DL algorithms

{: .todo}
I am not sure if this is right. It's been a while. See [Chunky full benchmarks](/chunky#full-benchmarks) too, for a slightly different note on DLs.

### Public key encryption

$\mathsf{PKE.KeyGen}(1^\lambda)\rightarrow(\term{\dk},\term{\ek})$:

- $\dk \randget \Zp$
- $\ek\gets \dk \cdot \Gone$
- (Also includes a ZKPoK but ignoring here)

## Groth21 ZK building blocks

### ZKP for "correct secret sharing"
{: #correct-sharing-zkp}

#### Overview

- Public inputs:
    - $n$ encryption keys $\ek_i$
    - $n$ ElGamal ciphertexts $\term{R},(\term{C_i})_{i\in[n]}$ (with the same randomness)
    - Feldman commitment $(\term{A_k})_{k\in[0,t)}$ to polynomial coefficients $a_i$'s that define a polynomial $\term{a(X)}$
- Private inputs:
    - ElGamal shared randomness $\term{r}$
    - Encrypted messages $(\term{s_i})_{i\in[n]}$
- Relation:
    - $A_k = a_k \cdot \Gtwo,\forall k\in[0,t)$, where $a(X) = \sum_{k\in[0,t)} a_k X^k$
    - $R = r \cdot \Gone$
    - $C_i = r \cdot \ek_i + s_i \cdot \Gone$, $\forall i\in[n]$
    - $s_i = a(i)$

#### Algorithms

$\ProveSh
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
A_0,\ldots,A_{t-1},
C_1,\ldots,C_n,R;\\\\
s_1,\ldots,s_n,r
\end{pmatrix}\rightarrow \pi_S$:

Let $a_k$ denote the scalar such that $A_k = a_k \cdot \Gtwo$; then, the relation being proved is that:

$$s_i = \sum_{k\in[0,t-1)} a_k i^k$$

- Derive **Fiat-Shamir** challenge $x$ from the public statement
- $(\term{\alpha},\term{\rho}) \randget \Zp^2$
- $\term{Y}\gets \rho \cdot \left(\sum_{i=1}^n x^i \cdot \ek_i\right) + \alpha \cdot \Gone$
- // note: we can think of this 4-round protocol as a 3-round one, where $\left(x,\sum_{i=1}^n x^i \cdot \ek_i\right)$ is part of the public statement (and $\sum_{i=1}^n s_i x^i$ is part of the witness?)
- $\term{F}\gets \rho \cdot \Gone$
- $\term{A}\gets \alpha \cdot \Gtwo$

- Derive **Fiat-Shamir** challenge $x'$ from transcript so far (i.e., public statement and $F,A,Y$)
- $\term{z_r} \gets \rho + x'r$
- $\term{z_a}\gets \alpha + x'\sum_{i=1}^n s_i x^i$
- **return** $(F,A,Y,z_r,z_a)$

$\VerSh
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
A_0,\ldots,A_{t-1},
C_1,\ldots,C_n,R;\pi_S
\end{pmatrix}\rightarrow \\{0,1\\}$:

- Parse $\pi_S$
- **assert** $x' \cdot R + F \stackrel{?}{=} z_r \cdot \Gone$
- **assert** $x' \cdot \left(\sum_{k=0}^{t-1} \left(\sum_{i\in[n]} i^k x^i\right) \cdot A_k\right) + A \stackrel{?}{=} z_a \cdot \Gtwo$ (over $\mathbb{G}_2$)

{: .smallnote}
Correctness holds because:
\begin{align}
x' \cdot \left(\sum_{k=0}^{t-1} \left(\sum_{i\in[n]} i^k x^i\right) \cdot A_k\right) + A
&= \alpha \cdot \Gtwo + x' \cdot \sum_{k=0}^{t-1} \left(\sum_{i=1}^n i^k x^i\right) \cdot A_k\\\\\
&= \alpha \cdot \Gtwo + x' \cdot \sum_{i=1}^n x^i \cdot \left(\sum_{k=0}^{t-1} i^k \cdot A_k\right)\\\\\
&= \alpha \cdot \Gtwo + x' \cdot \sum_{i=1}^{n} (s_i x^i) \cdot \Gtwo\\\\\
&= \alpha \cdot \Gtwo + x' \cdot \left(\sum_{i=1}^{n} s_i x^i\right) \cdot \Gtwo\\\\\
&= \left(\alpha + x'\sum_{i=1}^{n}s_i x^i\right) \cdot \Gtwo\\\\\
&= z_a \cdot \Gtwo
\end{align}

- **assert** $x' \cdot \left(\sum_{i=1}^{n} x^i \cdot C_i\right) + Y \stackrel{?}{=} z_r \cdot \left(\sum_{i=1}^{n} x^i \cdot \ek_i\right) + z_a \cdot \Gone$ (over $\mathbb{G}_1$)

{: .smallnote}
Correctness holds because:
\begin{align}
x' \cdot \left(\sum_{i=1}^{n} x^i \cdot C_i\right) + Y
&= x' \cdot \sum_{i=1}^{n} x^i \cdot (r \cdot \ek_i + s_i \cdot \Gone) + \rho \cdot \left(\sum_{i=1}^n x^i \cdot \ek_i\right) + \alpha \cdot \Gone\\\\\
&= x' \cdot \sum_{i=1}^{n} (r x^i) \cdot \ek_i + x' \cdot \sum_{i=1}^{n} (s_i x^i) \cdot \Gone + \rho \cdot \left(\sum_{i=1}^n x^i \cdot \ek_i\right) + \alpha \cdot \Gone\\\\\
&= (rx') \cdot \left(\sum_{i=1}^{n} x^i \cdot \ek_i\right) + \left(x' \sum_i s_i x^i\right) \cdot \Gone + \rho \cdot \left(\sum_{i=1}^n x^i \cdot \ek_i\right) + \alpha \cdot \Gone\\\\\
&= (\rho+x'r) \cdot \left(\sum_{i=1}^{n} x^i \cdot \ek_i\right) + \left(\alpha + x'\sum_i s_i x^i\right) \cdot \Gone\\\\\
&= z_r \cdot \left(\sum_{i=1}^{n} x^i \cdot \ek_i\right) + z_a \cdot \Gone
\end{align}

- **return** 1

#### Performance

- **Prover time:**
    - size-$(n+1)$ $\mathbb{G}_1$ MSM for $Y$
    - 1 scalar mul in $\mathbb{G}_1$ for $F$
    - 1 scalar mul in $\mathbb{G}_2$ for $A$
    - (ignored: one degree-$n$ polynomial evaluation at a random point)
- **Verifier time:**
    - size-$(2n+4)$ $\mathbb{G}_1$ MSM (combining first check for $F$ with third check for $Y$)
    - size-$(t+2)$ $\mathbb{G}_2$ MSM (second check for $A$)
- **Proof size:**
    - 2 field elements in $\Zp$ ($z_r, z_a$)
    - 2 group elements in $\mathbb{G}_1$ ($F,Y$)
    - 1 group element in $\mathbb{G}_2$ ($A$)

### ZKP of "correct chunking"
{: #correct-chunking-zkp}

Uses **public parameters** $\emph{\ell},\emph{E},\emph{S},\emph{Z}$.

#### Overview

- Public inputs:
    - $n$ encryption keys $\ek_i$
    - $nm$ ElGamal ciphertexts $(\term{R_j})_{j\in[m]},(\term{C_{i,j}})_{i\in[n],j\in[m]}$
- Private inputs:
    - ElGamal shared randomness $(\term{r_j})_{j\in[m]}$
    - Encrypted messages $(\term{s_{i,j}})_{i\in[n],j\in[m]}$
- Relation:
    - $\forall j\in[m], R_j = r_j \cdot \Gone$
    - $\forall i\in[n],j\in[m]$, $C_{i,j} = r_j \cdot \ek_i + s_{i,j} \cdot \Gone$
    - $\forall i\in[n],j\in[m],\exists \term{\Delta_{i,j}}\in [1,E-1]$, such that $\Delta_{i,j}\cdot s_{i,j}\in [1-Z,Z-1]$

#### Algorithms

$\ProveChunk
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
R_1,\ldots,R_m,
C_{1,1}\ldots,C_{n,m};\\\\
r_1,\ldots,r_m,
s_{1,1},\ldots,s_{n,m}
\end{pmatrix}\rightarrow \pi_C$:
{: #nizk-provechunk}

- $\term{\ek_0} \randget \mathbb{G}_1$
- **do**:
    - $(\term{\sigma_1},\ldots,\sigma_\ell) \randget [-S,Z-1]^\ell$ (blinders)
    - $(\term{\beta_1},\ldots,\beta_\ell) \randget \Zp^\ell$
    - $\forall k\in[\ell]$: (encrypting them)
        - $B_k \gets \beta_k \cdot \Gone$
        - $C_k \gets \beta_k \cdot \ek_0 + \sigma_k \cdot \Gone$
    - Derive **Fiat-Shamir** challenges $e_{1,1,1},\ldots,e_{n,m,\ell}\in[0,E)$ from transcript so far (i.e., public statement and $\ek_0,B_1,C_1,\ldots,B_\ell, C_\ell$)
    - $\forall k \in[\ell],$ $z_{s,k} \gets \sum_{i\in[n],j\in[m]}e_{i,j,k}\cdot s_{i,j} + \sigma_k$ (random subset sum plus blinders)

{: .warning}
**WARNING:** Groth says *"some sums would require slightly faster or slower computation, so we may use constant time algorithms to prevent timing leaks."* This is worrisome and would need to be carefully implemented.

- **until** $\forall k\in[\ell],$ $z_{s,k} \in [0,Z-1]$ (expected \# of iterations is 2; see below)
    - Groth says *"The risk of landing outside the range in [the $\ell$ runs that compute all $z_{s,k}$'s] is $\le (\ell S)/Z=(\ell S)/(2\ell S)=\frac{1}{2}$"*
    - If the failure probability is $S/Z$, then the success probability is $p=1-\frac{1}{2}=1/2$. To get a success, the expected \# of trials is $1/p=2$.

{: .todo}
*"If failure occurs on $\lambda$ tries then abort."* Why should this abort instead of repeating until success?

- $(\delta_0,\ldots,\delta_n) \randget \Zp^n$ (begin $\Sigma$ protocol)
- $\forall i\in[0,n], D_i \gets \delta_i \cdot \Gone$
- $Y\gets \sum_{i=0}^n \delta_i \cdot \ek_i$

- Derive **Fiat-Shamir** challenge $x\in\\{0,1\\}^\lambda$ from transcript so far (i.e., public statement and $\ek_0,B_1,C_1,\ldots,B_\ell, C_\ell, e_{1,1,1},\ldots,e_{m,n,\ell },D_0,\ldots,D_n,Y$)
- $\forall i\in[n],z_{r,i} \gets \sum_{j\in[m],k\in[\ell]} e_{i,j,k}\cdot r_j \cdot x^k+\delta_i$
- $z_\beta \gets \sum_{k=1}^\ell \beta_k x^k+\delta_0$
- $\pi_C \gets \begin{pmatrix}
\ek_0,
(B_1,\ldots,B_\ell), (C_1,\ldots,C_\ell),
(D_0,\ldots,D_n), 
Y,\\\\
(z_{s,1},\ldots,z_{s,\ell}),
(z_{r,1},\ldots,z_{r,n}),
z_\beta
\end{pmatrix}$

$\VerChunk
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
R_1,\ldots,R_m,
C_{1,1}\ldots,C_{n,m}; \pi_C
\end{pmatrix}\rightarrow \\{0,1\\}$:

- **parse** $\pi_C$
- **assert** $\forall k\in[\ell], z_{s,k} \in [0,Z-1]$
- **assert:**

\begin{align}
&\forall i\in[n],\ \sum_{j=1}^m \left(\sum_{k=1}^\ell e_{i,j,k}\cdot x^k\right) \cdot R_j + D_i \stackrel{?}{=} z_{r,i} \cdot \Gone\\\\\
&\sum_{k=1}^\ell x^k \cdot B_k + D_0 \stackrel{?}{=} z_\beta \cdot \Gone\\\\\
&\sum_{k=1}^\ell x^k \cdot \left( \sum_{i=1}^n \sum_{j=1}^m e_{i,j,k} \cdot C_{i,j}
\right) + \sum_{k=1}^\ell x^k \cdot C_k + Y\\\\\
&\quad\stackrel{?}{=} \sum_{i=1}^n z_{r,i} \cdot \ek_i + z_\beta \cdot \ek_0 + 
\left(\sum_{k=1}^\ell z_{s,k}\cdot x^k\right) \cdot \Gone
\end{align}

### Reorganized verifier

Pick random $\gamma_i$'s:

\begin{align}
&\forall i\in[n],\ \sum_{j=1}^m \left(\sum_{k=1}^\ell e_{i,j,k}\cdot x^k\right) \cdot R_j + D_i \stackrel{?}{=} z_{r,i} \cdot \Gone\Leftrightarrow\\\\\
&\sum_{i\in[n]}\left(\gamma_i \cdot \sum_{j=1}^m \left(\sum_{k=1}^\ell e_{i,j,k}\cdot x^k\right) \cdot R_j + \gamma_i \cdot D_i - (z_{r,i}\gamma_i) \cdot \Gone\right)\stackrel{?}{=} \mathcal{O}\Leftrightarrow\\\\\
&\sum_{j=1}^m \left(\sum_{i\in[n]}\gamma_i\sum_{k=1}^\ell e_{i,j,k}\cdot x^k\right) \cdot R_j + 
\sum_{i\in[n]} \gamma_i \cdot D_i - \left(\sum_{i\in[n]}z_{r,i}\gamma_i\right) \cdot \Gone \stackrel{?}{=} \mathcal{O}
\end{align}

#### Performance

- **Prover time:**
    - $\ell$ $\mathbb{G}_1$ scalar muls for $B_k$'s
    - $\ell$ size-2 $\mathbb{G}_1$ MSMs for $C_k$'s
        - To avoid recomputing these, we first check that the $\sigma_k$'s yield in-range $z_{s,k}$'s before computing $B_k$ and $C_k$
    - $n$ $\mathbb{G}_1$ scalar muls for $D_i$'s
    - size-$n$ $\mathbb{G}_1$ MSM for $Y$
- **Slightly-optimized verifier time:**
    - (ignored: $m$ multiplications modulo $p$, for computing $x,\ldots,x^\ell$)
    - size-$(m+n+1)$ $\mathbb{G}_1$ MSMs for checking the $D_i$'s ($\pi_C$); via [reorganized verifier](#reorganized-verifier)
    - size-$(\ell+2)$ $\mathbb{G}_1$ MSM for checking $D_0$ ($\pi_C$)
        - **Note**: batch with previous one, no, since scalars are big?
    - $\ell=32$ size-$nm$ $\mathbb{G}_1$ MSMs, but with small scalars $e\_{i,j,k} \le E = 2^8$ (for each MSM of $C\_{i,j}$'s with $e\_{i,j,k}$'s)
    - a size-$\ell$ $\mathbb{G}_1$ MSM for linear combination of $C\_{i,j}$ MSMs with $x^k$
    - size-$(\ell+1+n+2)=(\ell+n+3)$ $\mathbb{G}_1$ MSM for the remaining of the last (third) verifier equation: i.e., scalar muls on $C_k$'s, $Y$, $\ek_i$'s, $\ek_0$ and $\Gone$
        - **Note**: can batch with previous ones, no, since scalars are big?
- **Optimized verifier time:**
    - size-$[(m+n+1) + (\ell+2) + (\ell) + (\ell+n+3)]=(m+2n+3\ell+5)$ $\mathbb{G}_1$ MSM for $\pi_C$ (batched checks)

{: .info}
Three scalars share the same $\Gone$ base, so we could subtract 2 from this formula (but it won't make a difference in practice).

- **Proof size** (according to Groth[^Grot21e]):
    - $\ell$ small integers in $[0, Z)$ (the $z_{s,k}$'s)
    - $n+1$ field elements in $\Zp$ (the $z_{r,i}$'s and $z_\beta$)
    - $2\ell+n+3$ group elements in $\mathbb{G}_1$
        - $2\ell$ for $B_k$'s and $C_k$'s
        - $n+1$ for $D_i$'s
        - $\ek_0$ and $Y$

## Groth21 PVSS without forward-secure encryption

### Algorithms

Parameters: (1) $\emph{\lambda}$ is the security parameter, typically set to 128 (in Groth[^Grot21e], it is the size of a field element and set to 256); (2) the parameter $\emph{\ell}$ should be picked to optimize performance.

{: .todo}
Investigate optimal $\ell$ via benchmarking.

$\pvss.\setup(1^\lambda, \emph{B}=2^{\emph{b}},\ell) \rightarrow (\prk,\vk)$:

- $\emph{m}\gets 2\lambda/b$ (the \# of chunks we split a field element share into)
- $\emph{E}\gets 2^{\lceil \lambda/\ell\rceil}$ (the probability of ciphertext $C_{i,j}$ falling outside the range $=E^{-\ell} = 2^{-\lambda}$)
- $\emph{S}=nm(B-1)(E-1)$ (a parameter that arises in the [proof of correct chunking](#correct-chunking-zkp))
- $\emph{Z}=2\ell S$ (when decrypting shares, the worst case range to compute DLs in will be $[1-Z, Z-1]$)

$\pvss.\deal(t, n, {\ek_1,\ldots,\ek_n}, a_0) \rightarrow \trx$:

- $(a_1,\ldots,a_{t-1}) \randget \Zp^{t-1}$
- $(A_0,\ldots,A_{t-1})\gets(a_0 \cdot \Gtwo,\ldots,a_{t-1} \cdot \Gtwo)$
- $s_i \gets p(i), \forall i\in[n]$, where $p(X) \gets \sum_{i=0}^{t-1} a_i X^i$
- $(r_1,\ldots,r_m)\randget\Zp^m$
- $(R_1,\ldots,R_m)\gets(r_1 \cdot \Gone,\ldots,r_m \cdot \Gone)$
- $\forall i\in[n],j\in[m]$:
    - Let $s_{i,j}\in[0,B)$ denote the decomposition of $s_i = \sum_{j=1}^{m} s_{i,j}B^{j-1}$
    - $C_{i,j}\gets r_j \cdot \ek_i + s_{i,j} \cdot \Gone$
- $r\gets \sum_{j=1}^{m} r_{j}B^{j-1}$ (**note:** this will be the shared ElGamal randomness that encrypts all $s_i$'s)
- $R\gets r \cdot \Gone$
- $\forall i\in[n]$:
    - $C_i\gets r \cdot \ek_i + s_i \cdot \Gone$

{: .todo}
Isn't it faster for the verifier to reconstruct $C_i$'s from $C_{i,j}$'s?

- $\pi_S\gets \ProveSh
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
A_0,\ldots,A_{t-1},
C_1,\ldots,C_n,R;\\\\
s_1,\ldots,s_n,r
\end{pmatrix}$
- $\pi_C\gets \ProveChunk
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
R_1,\ldots,R_m,
C_{1,1}\ldots,C_{n,m};\\\\
r_1,\ldots,r_m,
s_{1,1},\ldots,s_{n,m}
\end{pmatrix}$
- $\trx\gets \begin{pmatrix}
  (C_{1,1},\ldots,C_{n,m}),
  (R_1,\ldots,R_m),
  (A_0,\ldots,A_{t-1}),\\\\
  \pi_S,\pi_C
  \end{pmatrix}$

$\pvss.\verify(\trx, t, n, {\ek_1,\ldots,\ek_n}) \rightarrow \\{0,1\\}$:

- Parse $\trx$ (as per $\pvss.\deal$)
- $\forall i\in[n], C_i \gets \sum_{j=1}^m B^{j-1} \cdot C_{i,j}$
- $R\gets \sum_{j=1}^{m} B^{j-1} \cdot R_{j}$
- $\VerSh
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
A_0,\ldots,A_{t-1},
C_1,\ldots,C_n,R;\pi_S
\end{pmatrix}$
- $\VerChunk
\begin{pmatrix}
\ek_1,\ldots,\ek_n,
R_1,\ldots,R_m,
C_{1,1}\ldots,C_{n,m};\pi_C
\end{pmatrix}$
- **return** 1

$\pvss.\decrypt(\trx, t, n, i,\dk_i) \rightarrow s_i$:

- Parse $\trx$ (as per $\pvss.\deal$)
- **for** $j\in[m]$:
    - $h_{i,j}\gets C_{i,j} - \dk_i \cdot R_j$
    - **for** $\Delta_{i,j}\in [1,E-1]$:
        - try to compute DL on $\Delta_{i,j}^{-1} \cdot h_{i,j}$ (should be equal to $s_{i,j} \cdot \Gone$)

{: .todo}
If $\Delta_{i,j}\cdot s_{i,j}\in [1-Z,Z-1]$ then the range for the DL computation on $\Delta_{i,j}^{-1} \cdot h_{i,j}$ will be getting smaller and smaller as we increase $\Delta_{i,j}$, no?

### Asymptotic performance

{: .warning}
**Note:** These are for the **non-forward-secure** PVSS variant, to fairly compare to our (future) PVSS construction.

#### Transcript size

- $\ell$ small integers in $[0,Z)$ (from $\pi_C$)
- $2 + (n+1)\ \sizeof{\Zp}$ (from $\pi_S$ and from $\pi_C$)
- $(nm+m)+ 2 + (2\ell+n+3)\ \sizeof{\mathbb{G}_1}$ (from the ElGamal ciphertexts, from $\pi_S$, and from $\pi_C$)
- $t+1$ $\sizeof{\mathbb{G}_2}$ (from Feldman commitment and from $\pi_S$)

{: .info}
The ZKP overheads for $\pi_S$ are in the [correct sharing section](#correct-sharing-zkp) and for $\pi_C$ in the [correct chunking section](#correct-chunking-zkp).

{: .todo}
Add sizes for $n=1{,}000$ and $m=10$ (assuming right parameterization).

#### Prover time

In $\Zp$:

1. degree $m-1$ poly eval on point $B$ (for computing $r$)
2. degree-$n$ poly eval at a random $\Zp$ point (for $\pi_S$)

In $\mathbb{G}_1$:

1. $m+1$ **scalar muls** (from chunked ElGamal $R_j$'s and $R$)
2. $nm$ size-2 **MSMs** (where 1 scalar is $<B$) (from chunked ElGamal $C_{i,j}$'s)
3. $n$ size-2 **MSMs** (from ElGamal $C_i$'s)
4. size-$(n+1)$ **MSM** (for $\pi_S$)
5. 1 **scalar mul** (for $\pi_S$)
6. $\ell+n$ **scalar muls** (for $\pi_C$)
7. size-$n$ **MSM** (for $\pi_C$)
8. $\ell$ size-2 $\mathbb{G}_1$ **MSMs** (for $\pi_C$)

In $\mathbb{G}_2$:

1. $t$ **scalar muls** (from Feldman commitment)
2. 1 **scalar mul** (for $\pi_S$)

#### Verifier time

**In $\mathbb{G}_1$:**

- $n+1$ size-$m$ **MSMs** (where scalars are $B^0\ldots B^{m-1}=2^{2\lambda}$, so first ones are small) for recomputing the $n$ ElGamal $C_i$'s and $R$

**In $\mathbb{G}_2$:**

(See the [correct sharing ZKP performance section](#correct-sharing-zkp).)

#### Share decryption time

***Chunk* decryption** could involve computing **at most** $\emph{E}-1$ DLs in a range of size $2\emph{Z}-1$.

**Share decryption** involves $\sizeof{\F}/\log_2{\emph{B}}$ chunk decryptions.

**Honest-case $\mathbb{G}_1$:**

1. $\sizeof{\F}/\log_2{B} \times \sqrt{B}$ group ops

**Malicious case $\mathbb{G}_1$:**

1. $\sizeof{\F}/\log_2{B} \times (E-1) \times \sqrt{2Z-1}$ group ops

{: .todo}
It will not get this bad because the range of the DLs will get smaller as $\Delta_{i,j}$ increases. Plus, it's unclear how many chunks in a share a malicious dealer will be able to "inflate" in size.

## Implementations

- Sourav's implementation: [e2e-vss on GitHub](https://github.com/sourav1547/e2e-vss)
- DFINITY's implementation: [ni_dkg on GitHub](https://github.com/dfinity/ic/tree/c9879cb1ad485accd438d5560748a0d0ddcba83f/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg)

### DFINITY's PVSS parameterization (${\lambda},{\ell}, {E}, {B}, {S}, {Z}$)
{: #dfinity-parameterization}

- $\emph{\lambda}$ = `SECURITY_LEVEL` = 256 ([source](https://github.com/dfinity/ic/blob/714c85c6a4245fb5b39e76f5c8003e6d90e49c4d/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg/fs_ni_dkg/nizk_chunking.rs#L18))
- $\emph{\ell}$ = `NUM_ZK_REPETITIONS` = 32 ([source](https://github.com/dfinity/ic/blob/714c85c6a4245fb5b39e76f5c8003e6d90e49c4d/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg/fs_ni_dkg/nizk_chunking.rs#L24))
- $\log_2{\emph{E}}$ = `CHALLENGE_BITS = SECURITY_LEVEL / NUM_ZK_REPETITIONS` $= 8$ ([source](https://github.com/dfinity/ic/blob/714c85c6a4245fb5b39e76f5c8003e6d90e49c4d/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg/fs_ni_dkg/nizk_chunking.rs#L27))
    - $E=2^8=256$
    - `CHALLENGE_MASK` $= E-1= 255$ ([source](https://github.com/dfinity/ic/blob/714c85c6a4245fb5b39e76f5c8003e6d90e49c4d/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg/fs_ni_dkg/nizk_chunking.rs#L34))
- $\emph{B}$ = `CHUNK_SIZE` $= 2^{16}$ ([source](https://github.com/dfinity/ic/blob/714c85c6a4245fb5b39e76f5c8003e6d90e49c4d/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg/fs_ni_dkg/chunking.rs#L11); i.e., the cardinality of the range)
    - number of chunks $\emph{m}=\sizeof{\F} / \log_2{B} = 256/16 = 16$
    - `CHUNK_BYTES` = 2 bytes = 16 bits
    - `CHUNK_MIN = 0`
    - `CHUNK_MAX` $= 2^{\mathsf{CHUNK\_SIZE}} - 1$
- $\emph{S}$ = `ss` = `n * m * (CHUNK_SIZE - 1) * CHALLENGE_MASK` $= nm(B-1)(E-1)$ ([source](https://github.com/dfinity/ic/blob/714c85c6a4245fb5b39e76f5c8003e6d90e49c4d/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg/fs_ni_dkg/nizk_chunking.rs#L210))
    - e.g., for $n=100$ and $m=256/16=16$, we'd get $S=100\cdot 16(2^{16}-1)\cdot 255$ = 26,738,280,000 (a 35-bit number)
- $\emph{Z}$ = `zz` $= 2\ell S$ ([source](https://github.com/dfinity/ic/blob/714c85c6a4245fb5b39e76f5c8003e6d90e49c4d/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg/fs_ni_dkg/nizk_chunking.rs#L211))
    - e.g., for the same $n,m$ as above, this is $Z=$ 1,711,249,920,000 (a 41-bit number)

**Implications on computing DLs:**

Due to the approximate guarantees of the [proof of correct chunking](#correct-chunking-zkp), ***chunk* decryption** could involve computing **at most** $E-1$ DLs in a range of size $2Z-1$. So, computing **at most** 255 DLs of 42-bit numbers. Note that **share decryption** involves $256/\log_2(B)=256/16=16$ *chunk* decryptions.
- We'd need to consider **average-case**, **best-case** and **worst-case** share decryption times in our evaluation?
    - Even in the **best-case**, will we be better because we'd have fewer chunks than Groth? The answer is **no**!
        - Groth uses $B=2^{16}$ and should(?) need to run a 16-bit DL on all 16 chunks: $2^{16/2} \times 0.5$ microsecond $\times$ 16 = 2.05 millisecs
        - Say we use a bigger chunk size $B=2^{37}$ and run a 37-bit DL on all 7 chunks: $2^{37/2} \times 0.5$ microsecond $\times$ 7 = 1.30 secs
        - So, bigger chunks does **not** give us an advantage (in the **best case**), because the share decryption time when using $B=2^b$ bits per chunk will be $f(b)=2^{b/2} \cdot (256 / b)$.
        - We'd clearly want to use *smaller*, **not** bigger $b$!
        - In fact, the optimal chunk size that minimizes the share decryption time $f(b)$ is $b=2/\ln{2}\approx 3$ bits.
        - I think this explains why Groth sets his chunk size to 16, which is bigger than the optimal 3: he is accepting higher share decryption time for smaller transcripts and thus faster proving, faster verification.
    - We'd definitely do better in the worst-case: an adversarial prover could potentially force the share decryption time to be much higher: e.g., 255 runs of 42-bit(?) DL on each of the 16 chunks. (We'd need to understand how bad it can get though... Maybe the prover can only increase some of the encrypted chunks, not all)

### Sourav's implementation

Sourav used the same parameterization as [DFINITY's above](#dfinity-parameterization).

These benchmarks were run in 2024, or earlier:
```
groth/deal-t=660/n=1024 time: [3.6432 s 3.6925 s 3.7592 s]
groth/verify-t=660/n=1024 time: [2.1861 s 2.2049 s 2.2291 s]
```

## References

For cited works, see below 👇👇

{% include refs.md %}
