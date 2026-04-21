---
tags:
 - PVSS
 - ElGamal
 - range proofs
 - polynomials
 - sigma protocols
 - distributed key generation (DKG)
 - KZG
title: "Chunky: Weighted PVSS and DKG for field elements"
#date: 2020-11-05 20:45:59
#published: false
permalink: chunky
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A work-in-progress weighted PVSS for field elements using chunked [ElGamal](/elgamal) encryption and [DeKART range proofs](/dekart).

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
%
\def\sig{\mathsf{Sig}}
\def\sign{\mathsf{Sign}}
%
\def\dekart{\mathsf{DeKART}^\mathsf{FFT}}
\def\setup{\mathsf{Setup}}
\def\commit{\mathsf{Commit}}
\def\prove{\mathsf{Prove}}
\def\verify{\mathsf{Verify}}
\def\piRange{\pi_\mathsf{range}}
%
\def\idx{\mathsf{idx}}
\def\epoch{\mathsf{epoch}}
%
\def\enc{\mathsf{Enc}}
\def\dec{\mathsf{Dec}}
%
\def\scrape{\mathsf{SCRAPE}}
\def\lowdegreetest{\mathsf{LowDegreeTest}}
%
\def\Retk{\mathcal{R}_\mathsf{e2k}}
\def\Retknew{\mathcal{R}'_\mathsf{e2k}}
\def\ctx{\mathsf{ctx}}
\def\sok{\mathsf{SoK}}
\def\piSok{\pi_\mathsf{SoK}}
\def\piSoknew{\pi_\mathsf{SoK}'}
%
\def\maxTotalWeight{W_\mathsf{max}}
\def\totalWeight{W}
\def\threshWeight{t_W}
\def\threshQ{t_Q}
\def\threshS{t_S}
%
\def\trs{\mathsf{trs}}
\def\pp{\mathsf{pp}}
\def\pid{\mathsf{pid}}
\def\ssid{\mathsf{ssid}}
\def\dk{\mathsf{dk}}
\def\ek{\mathsf{ek}}
\def\ssk{\mathsf{ssk}}
\def\spk{\mathsf{spk}}
%
\def\pvss{\mathsf{PVSS}}
\def\deal{\mathsf{Deal}}
\def\decrypt{\mathsf{Decrypt}}
\def\pvssSetup{\pvss.\mathsf{Setup}}
\def\pvssDeal{\pvss.\deal}
\def\pvssVerify{\pvss.\verify}
\def\pvssDecrypt{\pvss.\decrypt}
%
\def\subtrs{\mathsf{subtrs}}
\def\ssPvss{\mathsf{ssPVSS}}
\def\ssPvssDeal{\ssPvss.\deal}
\def\ssPvssVerify{\ssPvss.\verify}
\def\subtranscript{\mathsf{Subtranscript}}
\def\subaggregate{\mathsf{Subaggregate}}
\def\ssPvssSubtranscript{\ssPvss.\subtranscript}
\def\ssPvssSubaggregate{\ssPvss.\subaggregate}
$</div> <!-- $ -->

{% include defs-pairings.md %}
{% include defs-time-complexities.md %}
{% include defs-zkp.md %}

## Related work

A recent **lattice-based PVSS**[^GHL21e] scheme reduces the overhead of elliptic curve scalar multiplications during dealing and verification by replacing the encryption scheme with a lattice scheme.
Unfortunately, it introduces too much lattice field work, resulting in [an overall slower scheme than Chunky](#ghl21e-benchmarks): up to ~190x slower dealing and ~60x slower verification.
On the other hand, it claims a much smaller 300 KiB transcript for $n=1024$ players[^oneliner].
Because the GHL21e transcript is nearly constant in $n$ (~180-200 KiB in our benchmarks), this only wins at large $n$; at small $n$ (e.g., $n=8$), it is ~13x _larger_ than Chunky.
Furthermore, \[GHL21\][^GHL21e] has post-quantum privacy (not sound, because Bulletproofs), which Chunky does not.
(Assuming it is not used for bootstrapping DL cryptosystems though.)

Groth's NI-DKG[^Grot21e], henceforth **Groth21**, uses chunked ElGamal encryption with Schnorr-style NIZK proofs for correct sharing and correct chunking.
In particular, it uses a novel **relaxed ZK range proof** via rejection sampling.

When parameterized with $\ell=8$-bit chunks, Groth21 achieves slightly slower decryption times than Chunky with $\ell=32$-bit chunks, due to the loose guarantees of its approximate range proofs.
In this regime, it has up to 1.2x slower dealing time, 1.5x to 3x to slower verification, and 1.5x bigger transcripts.

When the goal is merely to PVSS a secret over _any_ field $\F$, our comparison against Groth21 is unfair, since Groth21 can use faster curves: e.g., secp256k1 or Curve25519.
But if the goal is to PVSS a secret over a pairing-friendly curve (e.g., the BLS12-381 curve), this comparison is fair and evidences what Groth21 loses in staying away from pairings.

Groth21's advantage is its _versatility_: it does not require pairings, which means it can be used in more settings.
We note that our [Chunky2](#chunky2) variant does not necessarily require pairings either, except for its use of the [univariate DeKART](/dekart) range proof.
In the future, we believe a sumcheck-based, multivariate variant of DeKART[^BDFplus25e] could be instantiated to avoid the use of pairings.

**Golden PVSS**[^BCK25e] is a novel design based on _exponent VRFs (eVRFs)_.
It features the smallest transcript sizes by elegantly avoiding the typical pitfalls: chunking, hidden-order groups, lattices.
However, its reliance on general-purpose ZKPs and its currently-naive, non-batched, PLONK-based implementation make it very slow in practice.
While this should be addressable with a better combination of eVRF and zkSNARK schemes, it is difficult to predict what speedup it would give.

There is also a very exciting line of work on **class-group-based PVSS**[^KMMplus23e]$^,$[^CD23e].
These schemes can avoid chunking by relying on additively-homomorphic encryption schemes for field elements with efficient decryption[^CL15] (unlike ElGamal).
Not surprisingly, the cgVSS transcript is 2.0-2.9x smaller than Chunky consistently across all $(t, n)$ threshold configurations.
But this comes at a cost: cgVSS transcript verification is 7-13x slower than Chunky.
Dealing time depends on $n$: at $n \le 32$ cgVSS is 1.2-3.6x slower, but at $n \ge 64$ the constant class-group overhead amortizes and cgVSS actually pulls ahead, becoming 1.1-1.6x faster than Chunky.
Nonetheless, in practice, the 2x smaller transcript may make up for the slower verification time in certain settings (e.g., DKGs).

{: .note}
The original cgVSS paper[^KMMplus23e] seems to over-estimate Groth21's execution times.

## Preliminaries

We assume familiarity with:
 - PVSS, as an abstract cryptographic primitive.
    + In particular, the notion of a **PVSS transcript** will be used a lot.
 - [Digital signatures](/signatures)
    + i.e., sign a message $m$ as $\sigma \gets \sig.\sign(\sk, m)$ and verify via $\sig.\verify(\pk, \sigma, m)\equals 1$
 - [ElGamal encryption](/elgamal)
 - Batched range proofs (e.g., [DeKART](/dekart))
 - ZKSoKs (i.e., [$\Sigma$-protocols](/sigma) that implicitly sign over a message by feeding it into the Fiat-Shamir transform).
 - [The SCRAPE low-degree test](#mathsfscrapemathsflowdegreetestmathsfevals-t-n-rightarrow-01)

All of these will be described in more detail in the subsections below.

### Notation

#### Pairing-friendly groups notation
{% include prelims-pairings.md %}
 - We often use capital letters like $G$ or $H$ to denote group elements in $\Gr_1$
 - We often use $\widetilde{G}$ or $\widetilde{H}$ letters to denote group elements in $\Gr_2$

#### Time-complexity notation
{% include prelims-time-complexities-pairings.md %}

#### Other notation

 - $[n]\bydef \\{1,2,\ldots,n\\}$
 - $[n) \bydef \\{0,1,2,\ldots,n-1\\}$

### ElGamal encryption
 
Assuming familiarity with [ElGamal encryption](/elgamal):

#### $E.\mathsf{KeyGen}_H()\rightarrow (\mathsf{dk},\mathsf{ek})$

Generate the key-pair:
\begin{align}
\dk &\randget\F\\\\\
\ek &\gets \dk \cdot H
\end{align}

#### $E.\mathsf{Enc}\_{G,H}\left(\mathsf{ek}, v; r\right) \rightarrow \left(C, R\right)$

Compute:
\begin{align}
C &\gets v \cdot G + r \cdot \ek\\\\\
R &\gets r \cdot H
\end{align}

#### $E.\mathsf{Dec}\_{G}\left(\mathsf{dk}, (C, R)\right) \rightarrow v$

\begin{align}
v &\gets \log_G\left(C - \dk\cdot R\right)\\\\\
        &= \log_G\left((v \cdot G + r \cdot \ek) - \dk\cdot (r \cdot H)\right)\\\\\
        &= \log_G\left(v \cdot G + r \cdot \ek - (r \cdot \dk) \cdot H\right)\\\\\
        &= \log_G\left(v \cdot G + r \cdot \ek - r \cdot \ek\right)\\\\\
        &= \log_G\left(v \cdot G\right) = v\\\\\
\end{align}

{: .note}
Decryption will only work for sufficiently "small" values $v$ such that computing discrete logarithms on $v \cdot G$ is feasible (e.g., anywhere from 32 bits to 64 bits).

### Univariate DeKART batched ZK range proofs
 
Assuming familiarity with batched ZK range proofs[^BBBplus18].
In particular, we will use [univariate DeKART](/dekart) as our range proof scheme, formalized below.

#### $\dekart_b.\setup(N; \mathcal{G})\rightarrow (\mathsf{prk},\mathsf{ck},\mathsf{vk})$

Sets up the ZK range proof to prove batches of size $\le N$, returning a proving key, a commitment key and a verification key.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfsetupn-mathcalgrightarrow-mathsfprkmathsfckmathsfvk).)

#### $\dekart_b.\commit(\ck,z_1,\ldots,z_N; \rho)\rightarrow C$

Returns a commitment $C$ to a vector of $N$ values using randomness $\rho$.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfcommitckz_1ldotsz_n-rhorightarrow-c).)

#### $\dekart_b.\prove(\prk, C, \ell; z_1,\ldots,z_N, \rho)\rightarrow \pi$

Returns a ZK proof $\pi$ that the $N$ values committed in $C$ are all in $[0, b^\ell)$.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfprovemathsfprk-c-ell-z_1ldotsz_n-rhorightarrow-pi).)

#### $\dekart_b.\verify(\vk, C, \ell; \pi)\rightarrow \\{0,1\\}$

Verifies that the $N$ values committed in $C$ are all in $[0, b^\ell)$.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfverifymathsfvk-c-ell-pirightarrow-01).)

### Zero-knowledge Signatures of Knowledge (ZKSoKs)

Assuming familiarity with ZKSoKs[^CL06], which typically consist of two algorithms: 

#### $\sok.\prove(\mathcal{R}, m, \stmt; \witn) \rightarrow \pi$

Returns a ZK proof of knowledge of $\witn$ s.t. $\mathcal{R}(\stmt;\witn) = 1$ and signs the message $m$ in the process.

#### $\sok.\verify(\mathcal{R}, m, \stmt; \pi) \rightarrow \\{0,1\\}$

Verifies a ZK proof of knowledge of some $\witn$ s.t. $\mathcal{R}(\stmt;\witn) = 1$ and that the message $m$ was signed.

### The $\mathcal{R}\_\mathsf{e2k}$ ElGamal-to-KZG NP relation

One of the key ingredients in our PVSS will be a ZK proof of knowledge of share chunks such that they are both ElGamal-encrypted and [KZG-committed](/kzg).

This is captured via the NP relation below:
\begin{align}
\label{rel:e2k}
\term{\Retk}\left(\begin{array}{l}
\stmt = \left(G, H, \ck, \\{\ek\_i\\}\_i,\\{C\_{i,j,k}\\}\_{i,j,k}, \\{R_{j,k}\\}\_{j,k}, C\right),\\\\\
\witn = \left(\\{s\_{i,j,k}\\}\_{i,j,k}, \\{r\_{j,k}\\}\_{j,k}, \rho\right)
\end{array}\right) = 1\Leftrightarrow\\\\\
\Leftrightarrow\left\\{\begin{array}{rl} 
    (C\_{i,j,k}, R_{j,k}) &= E.\enc_{G,H}(\ek_i, s\_{i,j,k}; r\_{j,k})\\\\\
    C& = \dekart_2.\commit(\ck, \\{s\_{i,j,k}\\}\_{i,j,k}; \rho)\\\\\
\end{array}\right.
\end{align}

where the $s_{i,j,k}$'s will be "flattened" as a vector (in a specific order) before being input to $\dekart_2.\commit(\cdot)$.

{: .warning}
We will explain how this flattening works later in the [$\pvssDeal$](#mathsfpvssmathsfdeal_mathsfpplefta_0-t_w-w_i-mathsfek_i_iin-n-mathsfssidright-rightarrow-mathsftrs) algorithm.

### $\mathsf{SCRAPE}.\mathsf{LowDegreeTest}(\mathsf{evals}, t, n) \rightarrow \\{0,1\\}$

Checks that a vector of group-element commitments to polynomial evaluations actually determine a degree-$\le t$ polynomial.
It exploits the fact that Shamir shares form a Reed-Solomon codeword, so their inner product with any **dual codeword** must be zero[^CD17].

**Input:** A list of $(n+1)$ evaluation commitments $\mathsf{evals} = \\{(x_i, V_i)\\}\_{i \in [0, n]}$ where $V_i = a(x_i) \cdot \widetilde{G}$, if honest, and $t$ is the max degree.

**Step 1:** Sample a random degree-$d$ polynomial $f(X) \in \F[X]$ where $d = n - t$:
\begin{align}
f_0, \ldots, f_d &\randget \F\\\\\
f(X) &:= \sum\_{j=0}^{d} f\_j X^j
\end{align}

**Step 2:** Compute Lagrange-like coefficients $\ell_i$ for each evaluation point:
\begin{align}
\ell\_0 &:= 1 / \prod\_{j \in [n]} (x\_0 - x\_j)\\\\\
\forall i \in [n],\quad \ell\_i &:= 1 / \left((x\_i - x\_0) \cdot \prod\_{j \neq i, j \in [n]} (x\_i - x\_j)\right)
\end{align}

**Step 3:** Check that the inner product with the random dual codeword is zero:
\begin{align}
\textbf{assert}\ 0 \equals \ell\_0 \cdot f(x\_0) \cdot V\_0 + \sum\_{i \in [n]} \ell\_i \cdot f(x\_i) \cdot V\_i
\end{align}

{: .note}
Typically, the evaluation domain $(x_1, \ldots, x_n)$ is FFT-friendly, so the $f(x_i)$'s are computable in $\Fmul{O(n\log{n})}$.
$f(x_0)$ may add another $\Fmul{n}$ operations, but since typically $x_0 = 0$, we have $f(x_0) = f_0$. 

{: .info}
**Why it works:** The vector $(\ell_0 \cdot f(x_0), \ell_1 \cdot f(x_1), \ldots, \ell_n \cdot f(x_n))$ is a random codeword from the dual of the Reed-Solomon code $C = \\{(a(x_0), \ldots, a(x_n)) : \deg(a) \le t\\}$.
If the committed values actually lie on a degree-$\le t$ polynomial, the inner product is zero.
If not, it is nonzero with probability $\ge 1 - 1/p$.

## Building a DKG from a PVSS

Our goal is to get a **weighted DKG**[^DPTX24e] for field elements amongst the validators of a proof-of-stake blockchain, such that the **DKG (final, shared) secret** $\term{z}$ is only reconstructable by a fraction $> \term{\threshQ}$ of the stake (e.g., $\threshQ = 0.5$ or 50%).

How?
Each validator $i$ will **"contribute"** to $z$ by picking their own secret $\term{z_i} \in \F$ and dealing it to the other validators via $\term{\pvssDeal}$ in a **non-malleable** fashion such that only a $> \emph{\threshQ}$ fraction of the stake can reconstruct $z_i$.
The DKG secret will be set to $z \bydef \sum_{i\in Q} z_i$, where $\term{Q}$ is the **eligible (sub)set** of validators who correctly dealt their $z_i$.

Crucially, $Q$ must be large "enough": i.e., it must have "enough" validators to guarantee that no malicious subset of them can learn (or can bias the choice of) $z$.
For example, we could assume only 33% of the stake[^aptos-Q] is malicious and require that $Q$ have more stake than that.
We denote the stake of the validators in $Q$ by $\term{\norm{Q}}$.

{: .note}
The DKG is parameterized by $\norm{Q}$ and by $\threshQ$.
Since, typically in a DKG, the same set of validators will deal a secret amongst themselves, $\norm{Q}$ and $\threshQ$ are typically set to the same value.
Otherwise, if $\norm{Q} < \threshQ$, then the validators in $Q$ could reconstruct the secret even though they do not have $> \threshQ$ of the stake, which defeats the point. 
Alternatively, if $\norm{Q} > \threshQ$, then the protocol would be requiring more validators to contribute than needed for secrecy, since $\threshQ < \norm{Q}$ can reconstruct.


_First_, to publicly-prove that $\norm{Q}$ is large "enough", each validator will **digitally-sign** their dealt PVSS transcript in a [domain-separated fashion](/domain-separation) (part of the domain separator will be the current consensus epoch number).
Without such authentication, $Q$ could be filled with transcripts from one malicious validator impersonating the other ones.
Therefore, that malicious validator would have full knowledge of the final DKG secret $z$.
($\Rightarrow$ No es bueno.)

**Implication:** The DKG protocol needs to be carefully crafted to sign the PVSS transcripts.
If done right, the validators' public keys used to sign blockchain consensus messages can be safely reused as **signing public keys** for the transcript.
(If done right.)

_Second_, we require that PVSS transcripts obtained from $\pvssDeal$ be **non-malleable**.
To see why this is necessary consider the following scenario:
 - two validators $i$ and $j$ have enough stake to form an eligible subset $Q = \\{i,j\\}$ with $\norm{Q} > \threshQ$ 
 - $j$ by itself does not have enough stake
 - $i$ deals $z_i \in \F$ and signs the transcript
 - $j$ removes $i$'s signature and mauls $i$'s transcript to deal $-z_i + r$ for some $r\randget\F$ it knows
 - $j$ signs this mauled transcript
   + $\Rightarrow j$ would have full knowledge of the final DKG secret $z = z_i + (- z_i + r) = r$.

**Implication:** The PVSS transcript will include a **zero-knowledge signature of knowledge (ZKSoK)** of the dealt secret $z_i$.
This way, the dealt secret cannot be mauled without rendering the transcript invalid.
Importantly, the ZKSoK signature will include the signing public key of the dealer.
This way, validator $j$ cannot bias the final DKG secret $z$ by appropriating validator $i$'s transcript as their own (i.e., by stripping validator $i$'s signature from the transcript, adding their own signature and leaving the dealt secret $z_i$ untouched).

## Chunky: A weighted, non-malleable PVSS

Notation:

 - Let $\term{n}$ denote the number of players 
    + _Note:_ In our setting, the PoS validators will act as the players
 - Let $\term{\maxTotalWeight}$ denote the **maximum total weight** $\Leftrightarrow$ maximum # of shares that we will ever want to deal in the PVSS
 - Let $\term{\ell}$ denote the **chunk bit-size** (e.g., $\ell=32$ for 32-bit chunks)
 - Let $\term{m} = \ceil{\log_2{\sizeof{\F}} / \ell}$ denote the **number of chunks per share**
 - Let $\term{B}\bydef 2^\ell$ denote the **maximum value of a chunk** (e.g., $B=2^{32}$ for 32-bit chunks)

The algorithms below describe **Chunky**, a weighted PVSS where only subsets of players with combined weight $> \threshWeight$ can reconstruct the shared secret.

### $\mathsf{PVSS}.\mathsf{Setup}(\ell, W_\mathsf{max}; \mathcal{G}, \widetilde{G}) \rightarrow \mathsf{pp}$

Recall that $\emph{\maxTotalWeight}$ is the max. total weight, $\emph{\ell}$ is the # of bits per chunk and $\emph{m}$ is the number of chunks a share is split into.

$\term{\widetilde{G}}\in\Gr_2$ will be the base used to commit to the shares in $\pvssDeal$.

**Step 1:** Set up the ElGamal encryption:
\begin{align}
\term{G},\term{H} &\randget \Gr_1
\end{align}

**Step 2:** Set up the ZK range proof to batch prove that $\le \maxTotalWeight\cdot m$ share chunks are all $\ell$-bit wide: 

\begin{align}
(\prk,\ck,\vk) \gets \dekart_2.\setup(\maxTotalWeight\cdot m; \mathcal{G})
\end{align}

Note that DeKART assumes that the field $\F$ admits a $2^\kappa$-th primitive root of unity where $2^\kappa$ is the smallest power of two $\ge \maxTotalWeight\cdot m + 1$.
(The ZK range proof needs FFTs of size $\maxTotalWeight\cdot m$.)

Return the public parameters:
\begin{align}
\pp \gets (\ell, \maxTotalWeight, G, \widetilde{G}, H, \prk,\ck,\vk)
\end{align}

### $\mathsf{PVSS}.\mathsf{Deal}\_\mathsf{pp}\left(a_0, t_W, \\{w_i, \mathsf{ek}_i\\}\_{i\in [n]}, \mathsf{ssid}\right) \rightarrow \mathsf{trs}$

{: .smallnote}
$a_0$ is the dealt secret.
<!--$\pid\in [n]$ is the dealer's player ID.-->
$w_i$'s are the weights of each player, including the dealer's (i.e., $w_\pid$).
$\ssid$ is a session identifier, which will be set to the consensus epoch number in which the DKG is taking place and calls this PVSS deal algorithm.

Parse public parameters:
\begin{align}
(\ell, \maxTotalWeight, G, \widetilde{G}, H, \prk,\ck,\vk)\parse\pp
\end{align}

Compute the **total weight** and assert that the public parameters can accommodate it:
\begin{align}
\label{eq:W}
\term{W} &\gets \sum_{i\in[n]} w_i\\\\\
\textbf{assert}\ W &\le \maxTotalWeight
\end{align}

Find a $2^\kappa$-th **root of unity** $\term{\omega} \in \F$ such that we can efficiently compute FFTs of size $W$ (i.e., smallest $2^\kappa \ge W$).

**Step 1:** Pick the degree-$\threshWeight$ random secret sharing polynomial and compute the $j$th share of player $i$:
\begin{align}
\term{a_1,\ldots,a_t} &\randget \F\\\\\
\term{f(X)} &\bydef \emph{a_0} + a_1 X + a_2 X^2 + \ldots + a_t X^\threshWeight\\\\\
\label{eq:eval}
\term{s_{i, j}} &\gets f\left(\term{\chi_{i,j}}\right),\forall i\in[n],\forall j\in[w_i]
\end{align}

_Note:_ Assuming that the set of evaluation points $\emph{\\{\chi_{i,j}\\}}$ are _wisely_ set to be the first $W$ roots of unity in $\\{\omega^{i'}\\}\_{i'\in [0,W)}$, then the $s_{i,j}$'s would be quickly-computable in $\Fmul{O(W\log{W})}$ via an FFT. 

**Step 2:** Commit to the shares, $\forall i\in[n],\forall j\in[w_i]$:
\begin{align}
\label{eq:share-commitments}
\term{\widetilde{V}\_{i,j}} &\gets s\_{i,j} \cdot \widetilde{G} \in \Gr\_2\\\\\
\label{eq:dealt-pubkey}
\term{\widetilde{V}_0} &\gets a_0 \cdot \widetilde{G}
\end{align}

**Step 3:** Split each share $s_{i,j}$ into $\emph{m}\bydef \ceil{\log_2{\sizeof{\F}}} / \ell$ chunks $\term{s_{i,j,k}}$, of $\ell$-bits each, such that:
\begin{align}
s_{i,j} 
    &= \sum_{k\in[m]} (2^\ell)^{k-1} \cdot \emph{s_{i,j,k}}\\\\\
    &\bydef \sum_{k\in[m]} \emph{B}^{k-1} \cdot s_{i,j,k}\\\\\
\end{align}

_Note:_ Each $s_{i,j,k} \in [0, B)$, where $B = 2^\ell$.

**Step 4:** $\forall i \in[n], j\in[w_i], k\in[m]$, encrypt the $k$th chunk of the $j$th share of player $i$:
\begin{align}
    \term{r_{j,k}} &\randget \F\ \text{s.t.}\ \sum_{k\in[m]} B^{k-1}\cdot r_{j,k} = 0\\\\\
    \label{eq:share-ciphertexts}
    \term{(C\_{i,j,k}, R_{j,k})} &\gets E.\enc_{G,H}(\ek_i, s\_{i,j,k}; r\_{j,k})\\\\\
        &\bydef \left(\begin{array}{l}
            s\_{i,j,k} \cdot G + r\_{j,k}\cdot \ek_i\\\\\
            r\_{j,k}\cdot H\end{array}\right)
\end{align}

_Observation 1:_ The randomness has been correlated such that:
\begin{align}
\label{eq:correlated}
\sum_{k\in[m]} B^{k-1} \cdot C\_{i,j,k} 
    &= \sum_{k\in[m]} B^{k-1} \cdot (s\_{i,j,k} \cdot G + r_{j,k}\cdot \ek_i)\\\\\
    &= \underbrace{\sum_{k\in[m]} (B^{k-1} \cdot s\_{i,j,k})}\_{s_{i,j}} \cdot G + \underbrace{\sum_{k\in [m]} (B^{k-1} \cdot r_{j,k})}\_{0}\cdot \ek_i\\\\\
    &= s_{i,j} \cdot G + 0 \cdot \ek_i = s_{i,j} \cdot G
\end{align}

_Observation 2:_ Different players $i$ will safely re-use the same $r_{j,k}$ randomness.

_Observation 3:_ $\sizeof{\\{R_{j,k}\\}_{j,k}} = m\cdot \max\_{i\in[n]}{(w\_i)}$

{: .definition}
The **cumulative weight up to (but excluding) $i$** is $\term{W_i}$ such that $\emph{W_1} = 0$ and 
<!-- 
$\term{W_i} = W_{i-1} + w_{i-1}$.
-->
$\emph{W_i} = \sum_{i'\in [1, i)} w_{i'}$. 
(Note that $W \bydef W_{n+1}$.)
This notion helps us "flatten" all the share chunks $s_{i,j,k}$ into an array $\\{z\_{i'}\\}\_{i'\in [W \cdot m]}$, where $z_{i'} \bydef s_{i,j,k}$ with $i'\gets \left(\emph{W_i} + (j-1)\right)\cdot m + k \bydef \term{\idx(i,j,k)}$ (see [appendix](#appendix-the-igets-mathsfidxijk-indexing) for how the indexing was derived).

**Step 5:** Prove that the share chunks are correctly encrypted **and** are all $\ell$-bit long.

First, "flatten" all the shares into a vector. $\forall i\in[n], j\in[w_i],\forall k\in[m]$:
\begin{align}
\term{z_{i'}} \gets s_{i,j, k},\ \text{where}\ i' 
    &\bydef \emph{\idx}(i,j,k)\in[W\cdot m]
\end{align}

Second, KZG commit to the share chunks and prove they are all in range:
\begin{align}
\rho &\randget \F\\\\\
\term{C} &\gets \dekart_2.\commit(\ck, z_1, \ldots, z_{W \cdot m}; \rho)\\\\\
\term{\piRange} &\gets \dekart_2.\prove(\prk, C, \ell, z_1, \ldots, z_{W\cdot m}; \rho) 
\end{align}

**Step 6:** Compute a signature of knowledge of the dealt secret key $a_0$ over the session ID: 
<a id="step-6-deal"></a>
\begin{align}
\term{\ctx} &\gets (\threshWeight, \\{w_i\\}_i, \ssid)\\\\\
\term{\piSok} &\gets \sok.\prove\left(\begin{array}{l}
    \Retk, \emph{\ctx},\\\\\
    \underbrace{G, H, \ck, \\{\ek\_i\\}\_i,\\{C\_{i,j,k}\\}\_{i,j,k}, \\{R\_{j,k}\\}\_{j,k}, C}\_{\stmt},\\\\\
    \underbrace{\\{s\_{i,j,k}\\}\_{i,j,k}, \\{r\_{j,k}\\}\_{j,k}, \rho}\_{\witn}
\end{array}\right)
\end{align}

Return the transcript:
\begin{align}
\label{eq:proof}
\term{\pi}  &\gets \left(C, \piRange, \piSok\right)\\\\\
\label{eq:trs}
\trs &\gets \left(\widetilde{V}\_0, \\{\widetilde{V}\_{i,j}\\}\_{i,j\in[w_i]}, \\{C_{i,j,k}\\}\_{i,j\in[w_i],k}, \\{R\_{j,k}\\}\_{j\in[\max_i{w_i}],k}, \emph{\pi}\right)
\end{align}

### $\mathsf{PVSS}.\mathsf{Verify}\_\mathsf{pp}\left(\mathsf{trs}, t_W, \\{w_i, \mathsf{ek}_i\\}\_{i\in[n]}, \mathsf{ssid}\right) \rightarrow \\{0,1\\}$

Parse public parameters:
\begin{align}
(\ell, \cdot, G, \widetilde{G}, H, \cdot,\cdot,\vk)\parse\pp
\end{align}

Parse the transcript:
\begin{align}
\left(\widetilde{V}\_0, \\{\widetilde{V}\_{i,j}\\}\_{i,j\in[w_i]}, \\{C_{i,j,k}\\}\_{i,j\in[w_i],k}, \\{R\_{j,k}\\}\_{j\in[\max_i{w_i}],k}, \left(C, \piRange, \piSok\right)\right)\parse\trs 
\end{align}

Let the _total weight_ $W$ be defined as before in Eq. \ref{eq:W}.

**Step 1:** Verify that the committed shares encode a degree-$\threshWeight$ polynomial via the _randomized_ SCRAPE LDT[^CD17]:
\begin{align}
\textbf{assert}\ &\scrape.\lowdegreetest(\\{(0, \widetilde{V}\_0)\\} \cup \\{(\chi\_{i,j}, \widetilde{V}\_{i,j})\\}\_{i,j}, \threshWeight, W) \equals 1
\end{align}

_Note:_ Recall that the $\emph{\chi_{i,j}}$'s are the roots of unity used to evaluate the secret-sharing polynomial $f(X)$ during dealing (see Eq. \ref{eq:eval}).

{: .todo}
May need to feed in the size of the evaluation domain to SCRAPE for the super-efficient algorithm.

**Step 2:** Check that ciphertexts encrypt the committed shares:
<a id="step-2-verify"></a>
\begin{align}
\term{\beta_{i,j}} &\randget\\{0,1\\}^\lambda\\\\\
\label{eq:multi-pairing-check}
\textbf{assert}\ 
    &\pair{\sum_{i\in[n],j\in[w_i],k\in[m]} (B^{k-1}\cdot\emph{\beta_{i,j}})\cdot C_{i,j,k}}{\widetilde{G}} 
        \equals
    \pair{G}{\sum_{i\in[n],j\in[w_i]} \emph{\beta_{i,j}}\cdot \widetilde{V}_{i,j}}
\end{align}

<details>
 <summary><b>Q:</b> <i>But how was this derived?</i> <b>A:</b> Click to expand and understand...</summary>
  <p markdown="1" style="margin-left: .3em; border-left: .15em solid black; padding-left: .5em;">
   First, recall from Eq. \ref{eq:correlated} that the randomness has been correlated such that $\sum_k C\_{i,j,k} = s\_{i,j}\cdot G$.
   <br />
   Second, observe that, using a pairing, we can check that the share chunked in the $C\_{i,j,k}$'s is the same as the one committed in $\widetilde{V}\_{i,j}$:
   \begin{align}
        \pair{\sum\_{k\in[m]} B^{k-1}\cdot C\_{i,j,k}}{\widetilde{G}} &\equals \pair{G}{\widetilde{V}\_{i,j}}
   \end{align}
   <br />
   Third, observe that we can batch all these pairing checks into one by taking linear combination of the verification equations using random $\beta_{i,j}$'s:
   \begin{align}
        \sum\_{i,j}\beta\_{i,j}\cdot\pair{\sum\_{k\in[m]} B^{k-1}\cdot C\_{i,j,k}}{\widetilde{G}} &\equals \sum\_{i,j} \beta\_{i,j}\cdot \pair{G}{\widetilde{V}\_{i,j}}\\\\\
   \end{align}
   Moving the sum inside the pairing by leveraging the bilinearity gives exactly Eq. \ref{eq:multi-pairing-check}.
  </p>
</details>

**Step 3:** Verify the range proof:
\begin{align}
\textbf{assert}\ \dekart_2.\verify(\vk, C, \ell; \piRange) \equals 1 
\end{align}

**Step 4:** Verify the SoK:
<a id="step-4-verify"></a>
\begin{align}
\term{\ctx} &\gets (\threshWeight, \\{w_i\\}_i, \ssid)\\\\\
\textbf{assert}\ &\sok.\verify\left(\begin{array}{l}
    \Retk, \emph{\ctx},\\\\\
    \underbrace{G, H, \ck, \\{\ek\_i\\}\_i,\\{C\_{i,j,k}\\}\_{i,j,k}, \\{R\_{j,k}\\}\_{j,k}, C}\_{\stmt};\\\\\
    \piSok
\end{array}\right) \equals 1
\end{align}

### $\mathsf{PVSS}.\mathsf{Decrypt}\_\mathsf{pp}\left(\mathsf{trs}, \mathsf{dk}, i, w_i\right) \rightarrow \\{s_{i,j}\\}_j \in \F$ 

{: .smallnote}
$i\in[n]$ is the ID of the player who is decrypting their share(s) from the transcript.
Recall that $\emph{m}\bydef \ceil{\log_2{\sizeof{\F}} / \ell}$ is the number of chunks per share.

Parse public parameters:
\begin{align}
(\ell, \cdot, G, \cdot, \cdot, \cdot,\cdot,\cdot)\parse\pp
\end{align}

Parse the transcript:
\begin{align}
\left(\cdot, \cdot, \\{C_{i,j,k}\\}\_{i,j\in[w_i],k}, \\{R\_{j,k}\\}\_{j\in[\max_i{w_i}],k},\cdot\right)\parse\trs
\end{align}

**Step 1:** Decrypt all of player $i$'s share chunks $\\{s\_{i,j,k}\\}\_{i,j\in[w_i],k\in[m]}$:
\begin{align}
s_{i,j,k}\gets E.\dec_{G}\left(\dk_i, (C\_{i,j,k}, R\_{j,k})\right)
\end{align}

**Step 2:** Assemble the chunks back into shares:
\begin{align}
s_{i,j}\gets \sum_{k\in[m]} (2^\ell)^{k-1} \cdot s_{i,j,k}
\end{align}

## Weighted DKG protocol

Below, we give a high-level sketch of our $\threshWeight$-out-of-$\\{w_i\\}_{i\in[n]}$ weighted DKG with contributions from $> \emph{\threshQ}$ fraction of the stake.

But first, we have to slightly augment our notion of a non-malleable PVSS, denoted by $\pvss$, into a **signed, subaggregatable and non-malleable PVSS**, denoted by $\term{\ssPvss}$.
This will make building a DKG protocol much easier.

**First,** recall [from before](#building-a-dkg-from-a-pvss) that validators must sign their PVSS transcripts in the DKG protocol.
Thus, the $\term{\ssPvss.\deal}$ and $\term{\ssPvss.\verify}$ algorithms will differ slightly:
1. dealing now takes a **signing secret key** $\term{\sk}$ as input and additionally returns a signature $\term{\sigma}$
2. verification now takes a **signing pubkey** $\term{\pk}$ and the signature $\sigma$ as input

**Second**, we introduce a useful notion of an **aggregatable PVSS subtranscript** $\term{\subtrs}$ which excludes the non-aggregatable components of the PVSS transcript $\emph{\trs}$ from Eq. \ref{eq:trs} (i.e., the proof $\pi$ from Eq. \ref{eq:proof}). 

**Third,** we define a new $\term{\ssPvssSubtranscript}$ algorithm which returns such a $\subtrs$.
In Chunky's case, this will consist of only:

1. The dealt pubkey $\widetilde{V}_0$ as defined in Eq. \ref{eq:dealt-pubkey}
2. The share commitments (i.e., all share commitments $\widetilde{V}\_{i,j}$ as defined in Eq. \ref{eq:share-commitments})
3. The share chunk ciphertexts (i.e., all share ciphertexts $(C\_{i,j,k}, R\_{j,k})$ as defined in Eq. \ref{eq:share-ciphertexts})

**Fourth**, and last, we will also define a $\term{\ssPvssSubaggregate}$ algorithm which takes several subtranscripts $\\{\subtrs_i\\}_i$ and aggregates them into a single $\subtrs$.
This way, two subtranscripts $\subtrs_1$ and $\subtrs_2$ dealing secrets $z_1$ and $z_2$, respectively, can be succinctly combined into a $\subtrs$ dealing $z_1 + z_2$ (such that $\sizeof{\subtrs} = \sizeof{\subtrs_i}, \forall i\in\\{1,2\\}$).

We detail the new algorithms for this signed, subaggregatable, non-malleable PVSS below.
(Note that the $\setup$ and $\decrypt$ algorithms remain the same.)

### $\mathsf{ssPVSS}.\mathsf{Deal}\_\mathsf{pp}\left(\mathsf{sk}, a_0, t_W, \\{w_i, \mathsf{ek}_i\\}\_{i\in [n]}, \mathsf{ssid}\right) \rightarrow (\mathsf{trs},\sigma)$
  
Deal a normal PVSS transcript via [$\pvssDeal$](#mathsfpvssmathsfdeal_mathsfpplefta_0-t_w-w_i-mathsfek_i_iin-n-mathsfssidright-rightarrow-mathsftrs) **but** also sign over it and over the session ID:
\begin{align}
\trs &\gets \pvssDeal(a_0, \threshWeight, \\{w\_i,\ek\_i\\}\_{i\in[n]}, \ssid)\\\\\
(\tilde{V}_0,\cdot,\cdot,\cdot,\cdot)&\parse \trs\\\\\
\sigma &\gets \sig.\sign(\sk, (\tilde{V}_0, \ssid))
\end{align}

### $\mathsf{ssPVSS}.\mathsf{Verify}\_\mathsf{pp}\left(\pk, \mathsf{trs}, \sigma, t_W, \\{w_i, \mathsf{ek}_i\\}\_{i\in[n]}, \mathsf{ssid}\right) \rightarrow \\{0,1\\}$

Do a normal PVSS transcript verification via [$\pvssVerify$](#mathsfpvssmathsfverify_mathsfppleftmathsftrs-t_w-w_i-mathsfek_i_iinn-mathsfssidright-rightarrow-01) **but** also verify the signature over it and the session ID:
\begin{align}
\textbf{assert}\ \pvssVerify(\trs, \threshWeight, \\{w\_i,\ek\_i\\}\_{i\in[n]}, \ssid) &\equals 1\\\\\
(\tilde{V}_0,\cdot,\cdot,\cdot,\cdot) &\parse \trs\\\\\
\textbf{assert}\ \sig.\verify(\pk, \sigma, (\tilde{V}_0, \ssid)) &\equals 1
\end{align}

### $\mathsf{ssPVSS}.\mathsf{Subtranscript}\left(\mathsf{trs}\right) \rightarrow \mathsf{subtrs}$

Parse the transcript as defined in Eq. \ref{eq:trs}:
\begin{align}
\left(\widetilde{V}\_0, \\{\widetilde{V}\_{i,j}\\}\_{i,j\in[w_i]}, \\{C_{i,j,k}\\}\_{i,j\in[w_i],k}, \\{R\_{j,k}\\}\_{j\in[\max_i{w_i}],k}, \cdot \right)\parse\trs 
\end{align}

Return the _aggregatable_ subtranscript:
\begin{align}
\label{eq:subtrs}
\subtrs &\gets \left(\widetilde{V}\_0, \\{\widetilde{V}\_{i,j}\\}\_{i,j\in[w_i]}, \\{C_{i,j,k}\\}\_{i,j\in[w_i],k}, \\{R\_{j,k}\\}\_{j\in[\max_i{w_i}],k}\right)\\\\\
\end{align}

### $\mathsf{ssPVSS}.\mathsf{Subaggregate}_\mathsf{pp}\left(\\{\mathsf{subtrs}\_{i'}\\}\_{i'}\right) \rightarrow \mathsf{subtrs}$

Parse public parameters:
\begin{align}
(\ell, \cdot, \cdot, \cdot, \cdot, \cdot,\cdot,\cdot)\parse\pp
\end{align}

Parse all the _aggregatable_ subtranscripts, for all $i'$:
\begin{align}
\left(\widetilde{V}^{(i')}\_0, \\{\widetilde{V}^{(i')}\_{i,j}\\}\_{i,j\in[w_i]}, \\{C^{(i')}_{i,j,k}\\}\_{i,j\in[w_i],k}, \\{R^{(i')}\_{j,k}\\}\_{j\in[\max_i{w_i}],k}\right)\parse \subtrs\_{i'}\\\\\
\end{align}

Recall that $\emph{n}$ denotes the number of players that a transcript deals to and recall that $\emph{m} = \ceil{\log_2{\sizeof{\F}} / \ell}$ denotes the number of chunks per share.

Aggregate:
\begin{align}
\term{\widetilde{V}\_0} &\gets \sum\_{i'} \widetilde{V}^{(i')}\_0\\\\\ 
\forall i\in[n],j\in[w_i], \term{\widetilde{V}\_{i,j}} &\gets \sum\_{i'} \widetilde{V}^{(i')}\_{i,j}\\\\\
\forall i\in[n],j\in[w_i],k\in[m], \term{\widetilde{C}\_{i,j,k}} &\gets \sum\_{i'} C^{(i')}_{i,j,k}\\\\\
\forall j\in[w_i],k\in[m], \term{\widetilde{R}\_{j,k}} &\gets \sum\_{i'} R^{(i')}\_{j,k}\\\\\
\end{align}

Return the aggregated subtranscript:
\begin{align}
\subtrs &\gets \left(\widetilde{V}\_0, \\{\widetilde{V}\_{i,j}\\}\_{i,j\in[w_i]}, \\{C_{i,j,k}\\}\_{i,j\in[w_i],k}, \\{R\_{j,k}\\}\_{j\in[\max_i{w_i}],k}\right)\\\\\
\end{align}

### DKG overview

A DKG will occur within the context of a consensus epoch $\term{\epoch}$.
All validators know each other's public keys.
Specifically, every validator $i$ has signing pubkey $\term{\pk_{i'}}$ (with signing secret key $\term{\sk_{i'}}$) and encryption key $\ek_i$[^reuse].

**Dealing phase:** Each validator $i'\in[n]$ picks a random secret $\term{z_{i'}}\in\F$ and computes a PVSS transcript that deals it:
\begin{align}
    \emph{z_{i'}} &\randget \F\\\\\
    \term{\ssid\_{i'}} &\gets (i', \emph{\pk\_{i'}}, \emph{\epoch})\\\\\
    \term{\trs\_{i'}, \sigma\_{i'}} &\gets \ssPvssDeal(\emph{\sk_{i'}}, z\_{i'}, \threshWeight, \\{w\_i,\ek\_i\\}\_{i\in[n]}, \emph{\ssid_{i'}})\\\\\
\end{align}

{: .smallnote}
Our current $\ssPvssDeal$ Rust implementation in `aptos-dkg` returns a `chunky::Transcript` struct that will contain both the actual transcript $\trs_{i'}$ and its signature $\sigma_{i'}$.

Then, each validator $i'$ (best-effort) disseminates $(\trs_{i'}, \sigma_{i'})$ to all other validators.
Eventually, each validators $i'$ will have its own view of a set $\term{Q_{i'}}$ of validators who correctly-dealt a (single) transcript, as well as the actual signed transcripts themselves.

**Agreement phase:** In this phase, validators will agree on an aggregated subtranscript $\term{\subtrs}$ obtained from a "large-enough" eligible set $\emph{Q}$ of honest validators.
More formally, the agreed-upon $(Q,\subtrs)$ will have the following three properties:
\begin{align}
   &\norm{Q} > \threshQ\\\\\
   \label{eq:trs-verifies}
   &\forall j' \in Q, \exists (\term{\trs_{j'},\sigma_{j'}}),\ \text{s.t.}\ \ssPvssVerify(\pk_{j'}, \emph{\trs\_{j'}, \sigma_{j'}}, \threshWeight, \\{w\_i,\ek\_i\\}\_{i\in[n]}, (\underbrace{j', \pk\_{j'}, \epoch}\_{\emph{\ssid\_{j'}}})) \goddamnequals 1\\\\\
   \label{eq:subtrs-aggr}
   &\emph{\subtrs} \goddamnequals \ssPvssSubaggregate(\\{\ssPvssSubtranscript(\trs\_{j'})\\}\_{j' \in Q})
\end{align}

{: .note}
Agreement on $Q$ could be reached inefficiently by running a Byzantine agreement phase for each transcript: i.e., validator $i'$ proposes its $(\trs_{i'}, \sigma_{i'})$ and if it collects "enough" **attestations** (e.g., signatures from a fraction $> \term{\threshS}$ of the stake, say, 33%[^vaba]) on it, then $i'$ is accumulated in the set $Q$ so far.
The downside of this approach is high latency: it requires one Byzantine agreement per contributing validator.
For Aptos, specifically, it would also require sending too many [validator TXNs](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-64.md).

**Proposal sub-phase:** To reach agreement on $(Q,\subtrs)$ efficiently, one of the validators (e.g., the consensus leader) sends a **final DKG subtranscript proposal** $(Q, h)$, where $h \gets H(\subtrs)$ and $H(\cdot)$ is a collision-resistant hash function.

Every validator $i'$ will **attest to** (i.e., sign) this proposal if they can verify that the hashed subtranscript in $h$ was actually aggregated from some set $\\{\trs\_{j'}\\}\_{j'\in Q}$ of transcripts that all passed verification as per Eq. \ref{eq:trs-verifies}.

More formally, validator $i'$ will attest to the $(Q, h)$ proposal via a signature $\term{\alpha_{i'}\}\bydef \sig.\sign(\sk_{i'}, (Q, h))$, if and only if:
 1. $\norm{Q} > \threshQ$
 1. $\forall j'\in Q$, validator $i'$ eventually[^eventually] receives a single[^equivocation] $(\trs\_{j'},\sigma\_{j'})$ s.t. $\ssPvssVerify(\pk_{j'}, \trs\_{j'}, \sigma_{j'}, \threshWeight, \\{w\_i,\ek\_i\\}\_{i\in[n]}, (j', \pk\_{j'}, \epoch)) \goddamnequals 1$
 1. $h \equals H(\ssPvssSubaggregate(\\{\ssPvssSubtranscript(\trs_{j'})\\}\_{j'\in Q}))$

**Commit sub-phase:** If the $(Q, h)$ proposal gathers "enough" attestations (i.e., $> \threshS$), the proposing validator sends a(n Aptos validator) TXN with $(Q, \subtrs, \\{\alpha_{j'}\\}_{j'\in \term{S}})$ to the chain, where $\emph{S}$ is the set of validators who attested with $\norm{S} > \threshS$.

(Note that this TXN includes the $\subtrs$ corresponding to the hash in the proposal $(Q,h)$.)

This TXN will be succinct as it only contains:
 1. The aggregated subtranscript $\subtrs$
    - _Note:_ Assuming elliptic curves over 256-bit base fields (e.g., BN254), $\sizeof{\subtrs} \bydef \underbrace{64}\_{\widetilde{V}\_0} + \underbrace{64 \cdot W}\_{\widetilde{V}\_{i,j}\text{\'s}} + \underbrace{32 \cdot W\cdot m}\_{C\_{i,j,k}\text{\'s}} + 32\cdot \underbrace{\max_i{w_i}\cdot m}\_{R\_{j,k}\text{\'s}}$ as per Eq. \ref{eq:subtrs}
    - e.g., for total weight $W = 254$, $m=8$ chunks and $\max_i{w_i} = 5$, the size will be $64 + 64 \cdot 254 + 32 \cdot 254 \cdot 8 + 32 \cdot 5 \cdot 8 =$ 82,624 bytes $=$ 80.6875 KiB
    - If we increase $\max_i{w_i}$ to 7, we get $64 + 64 \cdot 254 + 32 \cdot 254 \cdot 8 + 32 \cdot \emph{7} \cdot 8 =$ 83,136 bytes $=$ 81.1875 KiB
 1. Attestations $\alpha_{j'}$'s from at most all $n$ validators. 
    + e.g., In Aptos, we are using BLS signatures[^BLS01] over BLS12-381 curves[^BLS02e] $\Rightarrow$ since validators are voting by signing over the same proposal $(Q,\subtrs)$, the attestation signatures can be aggregated into a single multi-signature of 48 bytes.

Once this TXN gets included on-chain it is sent to execution, where all (honest) validators will:

 1. check that the attestations in $(Q,\subtrs, \\{\alpha_{j'}\\}_{j'\in S})$ are valid; i.e.,:
    - $h \gets H(\subtrs)$
    - $\textbf{assert}\ \norm{S} > \threshS$
    - $\forall j'\in S, \textbf{assert}\ \sig.\verify(\pk_{j'}, \alpha_{j'}, (Q, h)) \equals 1$
 1. this implies that $\norm{Q} > \threshQ$...
    - ...and that Eqs. \ref{eq:trs-verifies} and \ref{eq:subtrs-aggr} hold
 1. install the subtranscript on-chain, declaring the DKG complete

Now:
 - The final public key whose corresponding secret key is secret-shared is $\widetilde{V}_0$ from $\subtrs$
 - The share commitments $\widetilde{V}\_{i,j}$'s in $\subtrs$ can be made public
    + e.g., if the DKG is for bootstrapping a weighted [threshold BLS signature scheme](/threshold-bls), then $\widetilde{V}\_{i,j}\bydef s\_{i,j}\cdot G$ will act as the verification key for the BLS signature share $H(m)^{s\_{i,j}}$
 - Each player can use $\pvssDecrypt$ to obtain their shares from $\subtrs$ [^dummy]

## Benchmarks

### Aptos mainnet

Single-threaded numbers from my Apple Macbook Pro M4 Max for the setup we expect to use on Aptos mainnet:

| Scheme  | $\ell$ | Setup                        | Transcript size | Deal (ms)      | Serialize (ms) | Sub-aggregate (ms) | Verify (ms)   | Decrypt-share (ms) |
|---------|--------|------------------------------|-----------------|----------------|----------------|----------------|---------------|--------------------|
| Chunky  | 32     | 129-out-of-219 / 136 players | 259.24 KiB      |         373.30 |           0.24 |           1.29 |         63.05 |              10.73 |
| Chunky2 | 32     | 129-out-of-219 / 136 players | 279.78 KiB      | <span style="color:#dc2626">401.96</span> (0.93x) | <span style="color:#dc2626">0.27</span> (0.89x) | <span style="color:#dc2626">1.35</span> (0.96x) | <span style="color:#dc2626">72.45</span> (0.87x) | <span style="color:#dc2626">11.09</span> (0.97x) |


These numbers can be reproduce by cloning [aptos-core](https://github.com/aptos-labs/aptos-core) and doing:
```
git clone https://github.com/aptos-labs/aptos-core
cd aptos-core/crates/aptos-crypto/benches/
./run-pvss-benches.sh
```

### Full benchmarks

{: .warning}
**Limitations:** These benchmarks do not measure the cost of transcript (de)serialization after dealing (and before verification).
This can actually matter a lot in practice too.

{: .warning}
**Groth21:** It is possible that I misunderstand what the average case for Groth21 decryption time looks like (see [my analysis here](#groth21-worst-case)).

{: .warning}
**Parallelization:** *Chunky*, *Groth21* and *cgVSS* run single-threaded. 
But, for *Golden*, we _generously_ run it multi-threded with `GOMAXPROCS=16`, which speeds up MSMs and FFTs significantly.

| Scheme | Curve | Library | Assumptions | Decrypt 1 share time |
|--------|-------|---------|-------------|--------------------|
| **Chunky $(\ell = 32)$** | BLS12-381 | `blstrs` v0.7.1 | pairings, ROM | $m$ DLs of $b=32$ bits |
| Groth21 $(\ell = 8)$ | BLS12-381 | `blstrs` v0.7.1 | DL, ROM | $m$ DLs of $b \in [30,38]$ bits |
| Groth21 $(\ell = 16)$ | BLS12-381 | `blstrs` v0.7.1 | DL, ROM | $m$ DLs of $b \in [37,45]$ bits |
| Groth21 $(\ell = 32)$ | BLS12-381 | `blstrs` v0.7.1 | DL, ROM | $m$ DLs of $b \in [52,60]$ bits |
| Golden | BN254 + BJJ | `gnark` v0.14.0 | DL, ROM | 0.30 ms |
| [GHL21e][^GHL21e] | Curve25519 | `libsodium` v1.0.21 + `NTL` v11.6.0 | lattices, DL, ROM | 0.50 ms |
| cgVSS[^KMMplus23e] | BLS12-381 + CL15 | `blstrs` v0.7.1 + `bicycl` v0.1.0 | class groups, DL, ROM | 10.ms |

<style>
/* Thick top border above every Chunky row to visually separate groups */
#full-benchmarks-table tbody tr:nth-child(7n+1) { border-top: 3px solid #555; }
</style>

{: #full-benchmarks-table}
| Scheme | $t$ | $n$ | Transcript size | Deal (ms) | Verify (ms) |
|--------|-----|-----|-----------------|-----------|-------------|
| **Chunky ($\ell = 32$)** | 3 | 4 | 8.50 KiB | 12.49 | <span style="color:#15803d; font-weight:700">3.63</span> |
| Groth21 ($\ell = 8$) | 3 | 4 | <span style="color:#dc2626">13.09 KiB</span> (1.54x) | <span style="color:#dc2626">21.5</span> (1.72x) | <span style="color:#dc2626">11.1</span> (3.05x) |
| Groth21 ($\ell = 16$) | 3 | 4 | <span style="color:#dc2626">9.34 KiB</span> (1.10x) | <span style="color:#dc2626">15.1</span> (1.21x) | <span style="color:#dc2626">10.4</span> (2.86x) |
| Groth21 ($\ell = 32$) | 3 | 4 | <span style="color:#15803d; font-weight:700">7.46 KiB</span> (0.88x) | <span style="color:#15803d; font-weight:700">11.9</span> (0.95x) | <span style="color:#dc2626">7.9</span> (2.17x) |
| Golden | 3 | 4 | <span style="color:#15803d; font-weight:700">2.66 KiB</span> (3.20x) | <span style="color:#dc2626">4,631</span> (371x) | <span style="color:#dc2626">5.52</span> (1.52x) |
| [GHL21e][^GHL21e] | 3 | 4 | <span style="color:#dc2626">176.69 KiB</span> (20.8x) | <span style="color:#dc2626">5,512</span> (441x) | <span style="color:#dc2626">455</span> (125x) |
| cgVSS[^KMMplus23e] | 3 | 4 | <span style="color:#15803d; font-weight:700">2.95 KiB</span> (2.88x) | <span style="color:#dc2626">44.36</span> (3.55x) | <span style="color:#dc2626">47.46</span> (13.07x) |
| **Chunky ($\ell = 32$)** | 6 | 8 | 12.90 KiB |     19.99 |        <span style="color:#15803d; font-weight:700">4.73</span> |
| Groth21 ($\ell = 8$) | 6 | 8 | <span style="color:#dc2626">20.15 KiB</span> (1.56x) | <span style="color:#dc2626">36.4</span> (1.82x) | <span style="color:#dc2626">18.0</span> (3.81x) |
| Groth21 ($\ell = 16$) | 6 | 8 | <span style="color:#dc2626">13.40 KiB</span> (1.04x) | <span style="color:#dc2626">23.7</span> (1.19x) | <span style="color:#dc2626">16.0</span> (3.38x) |
| Groth21 ($\ell = 32$) | 6 | 8 | <span style="color:#15803d; font-weight:700">10.02 KiB</span> (0.78x) | <span style="color:#15803d; font-weight:700">17.6</span> (0.88x) | <span style="color:#dc2626">10.9</span> (2.30x) |
| Golden | 6 | 8 | <span style="color:#15803d; font-weight:700">5.29 KiB</span> (2.44x) | <span style="color:#dc2626">9,196</span> (460x) | <span style="color:#dc2626">11.02</span> (2.33x) |
| [GHL21e][^GHL21e] | 6 | 8 | <span style="color:#dc2626">178.12 KiB</span> (13.8x) | <span style="color:#dc2626">5,607</span> (280x) | <span style="color:#dc2626">468</span> (98.9x) |
| cgVSS[^KMMplus23e] | 6 | 8 | <span style="color:#15803d; font-weight:700">5.14 KiB</span> (2.51x) | <span style="color:#dc2626">48.48</span> (2.43x) | <span style="color:#dc2626">56.50</span> (11.95x) |
| **Chunky ($\ell = 32$)** | 11 | 16 | 21.71 KiB |     34.61 |       <span style="color:#15803d; font-weight:700">6.69</span> |
| Groth21 ($\ell = 8$) | 11 | 16 | <span style="color:#dc2626">34.27 KiB</span> (1.58x) | <span style="color:#dc2626">64.3</span> (1.86x) | <span style="color:#dc2626">30.7</span> (4.59x) |
| Groth21 ($\ell = 16$) | 11 | 16 | <span style="color:#15803d; font-weight:700">21.52 KiB</span> (0.99x) | <span style="color:#dc2626">41.0</span> (1.18x) | <span style="color:#dc2626">27.3</span> (4.07x) |
| Groth21 ($\ell = 32$) | 11 | 16 | <span style="color:#15803d; font-weight:700">15.15 KiB</span> (0.70x) | <span style="color:#15803d; font-weight:700">28.0</span> (0.81x) | <span style="color:#dc2626">17.5</span> (2.61x) |
| Golden | 11 | 16 | <span style="color:#15803d; font-weight:700">10.50 KiB</span> (2.07x) | <span style="color:#dc2626">18,430</span> (533x) | <span style="color:#dc2626">22.46</span> (3.36x) |
| [GHL21e][^GHL21e] | 11 | 16 | <span style="color:#dc2626">180.94 KiB</span> (8.33x) | <span style="color:#dc2626">6,002</span> (173x) | <span style="color:#dc2626">591</span> (88.3x) |
| cgVSS[^KMMplus23e] | 11 | 16 | <span style="color:#15803d; font-weight:700">9.49 KiB</span> (2.29x) | <span style="color:#dc2626">57.24</span> (1.65x) | <span style="color:#dc2626">67.85</span> (10.14x) |
| **Chunky ($\ell = 32$)** | 22 | 32 | 39.32 KiB |     63.06 |       <span style="color:#15803d; font-weight:700">10.57</span> |
| Groth21 ($\ell = 8$) | 22 | 32 | <span style="color:#dc2626">62.52 KiB</span> (1.59x) | <span style="color:#dc2626">121.8</span> (1.93x) | <span style="color:#dc2626">54.6</span> (5.17x) |
| Groth21 ($\ell = 16$) | 22 | 32 | <span style="color:#15803d; font-weight:700">37.77 KiB</span> (0.96x) | <span style="color:#dc2626">72.6</span> (1.15x) | <span style="color:#dc2626">48.2</span> (4.56x) |
| Groth21 ($\ell = 32$) | 22 | 32 | <span style="color:#15803d; font-weight:700">25.40 KiB</span> (0.65x) | <span style="color:#15803d; font-weight:700">48.2</span> (0.76x) | <span style="color:#dc2626">29.1</span> (2.76x) |
| Golden | 22 | 32 | <span style="color:#15803d; font-weight:700">20.97 KiB</span> (1.87x) | <span style="color:#dc2626">36,790</span> (583x) | <span style="color:#dc2626">51.85</span> (4.91x) |
| [GHL21e][^GHL21e] | 22 | 32 | <span style="color:#dc2626">183.12 KiB</span> (4.66x) | <span style="color:#dc2626">5,735</span> (90.9x) | <span style="color:#dc2626">486</span> (46.0x) |
| cgVSS[^KMMplus23e] | 22 | 32 | <span style="color:#15803d; font-weight:700">18.23 KiB</span> (2.16x) | <span style="color:#dc2626">76.08</span> (1.21x) | <span style="color:#dc2626">89.30</span> (8.45x) |
| **Chunky ($\ell = 32$)** | 43 | 64 | 74.54 KiB |    119.46 |       <span style="color:#15803d; font-weight:700">16.90</span> |
| Groth21 ($\ell = 8$) | 43 | 64 | <span style="color:#dc2626">119.02 KiB</span> (1.60x) | <span style="color:#dc2626">232.2</span> (1.94x) | <span style="color:#dc2626">95.8</span> (5.67x) |
| Groth21 ($\ell = 16$) | 43 | 64 | <span style="color:#15803d; font-weight:700">70.27 KiB</span> (0.94x) | <span style="color:#dc2626">136.4</span> (1.14x) | <span style="color:#dc2626">88.7</span> (5.25x) |
| Groth21 ($\ell = 32$) | 43 | 64 | <span style="color:#15803d; font-weight:700">45.90 KiB</span> (0.62x) | <span style="color:#15803d; font-weight:700">89.0</span> (0.74x) | <span style="color:#dc2626">51.8</span> (3.07x) |
| Golden | 43 | 64 | <span style="color:#15803d; font-weight:700">41.88 KiB</span> (1.78x) | <span style="color:#dc2626">74,098</span> (620x) | <span style="color:#dc2626">148.57</span> (8.79x) |
| [GHL21e][^GHL21e] | 43 | 64 | <span style="color:#dc2626">187.50 KiB</span> (2.52x) | <span style="color:#dc2626">5,896</span> (49.4x) | <span style="color:#dc2626">487</span> (28.8x) |
| cgVSS[^KMMplus23e] | 43 | 64 | <span style="color:#15803d; font-weight:700">35.66 KiB</span> (2.09x) | <span style="color:#15803d; font-weight:700">108.93</span> (1.10x) | <span style="color:#dc2626">131.16</span> (7.76x) |
| **Chunky ($\ell = 32$)** | 86 | 128 | 144.98 KiB |    232.74 |       <span style="color:#15803d; font-weight:700">29.76</span> |
| Groth21 ($\ell = 8$) | 86 | 128 | <span style="color:#dc2626">232.02 KiB</span> (1.60x) | <span style="color:#dc2626">453.6</span> (1.95x) | <span style="color:#dc2626">185.1</span> (6.22x) |
| Groth21 ($\ell = 16$) | 86 | 128 | <span style="color:#15803d; font-weight:700">135.27 KiB</span> (0.93x) | <span style="color:#dc2626">262.1</span> (1.13x) | <span style="color:#dc2626">164.4</span> (5.53x) |
| Groth21 ($\ell = 32$) | 86 | 128 | <span style="color:#15803d; font-weight:700">86.90 KiB</span> (0.60x) | <span style="color:#15803d; font-weight:700">172.1</span> (0.74x) | <span style="color:#dc2626">96.1</span> (3.23x) |
| Golden | 86 | 128 | <span style="color:#15803d; font-weight:700">83.72 KiB</span> (1.73x) | <span style="color:#dc2626">148,814</span> (639x) | <span style="color:#dc2626">519.11</span> (17.4x) |
| [GHL21e][^GHL21e] | 86 | 128 | <span style="color:#dc2626">192.62 KiB</span> (1.33x) | <span style="color:#dc2626">5,965</span> (25.6x) | <span style="color:#dc2626">486</span> (16.3x) |
| cgVSS[^KMMplus23e] | 86 | 128 | <span style="color:#15803d; font-weight:700">70.57 KiB</span> (2.05x) | <span style="color:#15803d; font-weight:700">176.72</span> (1.32x) | <span style="color:#dc2626">216.53</span> (7.28x) |
| **Chunky ($\ell = 32$)** | 171 | 256 | 285.85 KiB |    471.83 |       <span style="color:#15803d; font-weight:700">51.38</span> |
| Groth21 ($\ell = 8$) | 171 | 256 | <span style="color:#dc2626">458.02 KiB</span> (1.60x) | <span style="color:#dc2626">894.1</span> (1.89x) | <span style="color:#dc2626">353.9</span> (6.89x) |
| Groth21 ($\ell = 16$) | 171 | 256 | <span style="color:#15803d; font-weight:700">265.27 KiB</span> (0.93x) | <span style="color:#dc2626">516.1</span> (1.09x) | <span style="color:#dc2626">320.4</span> (6.24x) |
| Groth21 ($\ell = 32$) | 171 | 256 | <span style="color:#15803d; font-weight:700">168.90 KiB</span> (0.59x) | <span style="color:#15803d; font-weight:700">333.0</span> (0.71x) | <span style="color:#dc2626">179.2</span> (3.49x) |
| Golden | 171 | 256 | <span style="color:#15803d; font-weight:700">167.38 KiB</span> (1.71x) | <span style="color:#dc2626">298,193</span> (632x) | <span style="color:#dc2626">1,882.84</span> (36.6x) |
| [GHL21e][^GHL21e] | 171 | 256 | <span style="color:#15803d; font-weight:700">201.81 KiB</span> (1.42x) | <span style="color:#dc2626">6,569</span> (13.9x) | <span style="color:#dc2626">512</span> (9.96x) |
| cgVSS[^KMMplus23e] | 171 | 256 | <span style="color:#15803d; font-weight:700">140.33 KiB</span> (2.04x) | <span style="color:#15803d; font-weight:700">312.63</span> (1.51x) | <span style="color:#dc2626">390.13</span> (7.59x) |
| **Chunky ($\ell = 32$)** | 342 | 512 | 567.60 KiB | 941.18 | <span style="color:#15803d; font-weight:700">93.72</span> |
| Groth21 ($\ell = 8$) | 342 | 512 | <span style="color:#dc2626">910.02 KiB</span> (1.60x) | <span style="color:#dc2626">1,776.7</span> (1.89x) | <span style="color:#dc2626">690.6</span> (7.37x) |
| Groth21 ($\ell = 16$) | 342 | 512 | <span style="color:#15803d; font-weight:700">525.27 KiB</span> (0.93x) | <span style="color:#dc2626">1,032.5</span> (1.10x) | <span style="color:#dc2626">626.4</span> (6.68x) |
| Groth21 ($\ell = 32$) | 342 | 512 | <span style="color:#15803d; font-weight:700">332.90 KiB</span> (0.59x) | <span style="color:#15803d; font-weight:700">649.6</span> (0.69x) | <span style="color:#dc2626">347.9</span> (3.71x) |
| Golden | 342 | 512 | <span style="color:#15803d; font-weight:700">334.72 KiB</span> (1.70x) | <span style="color:#dc2626">596,091</span> (633x) | <span style="color:#dc2626">7,151.19</span> (76.3x) |
| [GHL21e][^GHL21e] | 342 | 512 | <span style="color:#15803d; font-weight:700">220.25 KiB</span> (2.58x) | <span style="color:#dc2626">6,860</span> (7.29x) | <span style="color:#dc2626">522</span> (5.57x) |
| cgVSS[^KMMplus23e] | 342 | 512 | <span style="color:#15803d; font-weight:700">279.88 KiB</span> (2.03x) | <span style="color:#15803d; font-weight:700">582.25</span> (1.62x) | <span style="color:#dc2626">726.68</span> (7.75x) |
| **Chunky ($\ell = 32$)** | 683 | 1024 | 1,131.10 KiB | 1,825.50 | <span style="color:#15803d; font-weight:700">170.23</span> |
| Groth21 ($\ell = 8$) | 683 | 1024 | <span style="color:#dc2626">1,814.02 KiB</span> (1.60x) | <span style="color:#dc2626">3,478.1</span> (1.91x) | <span style="color:#dc2626">1,366.0</span> (8.02x) |
| Groth21 ($\ell = 16$) | 683 | 1024 | <span style="color:#15803d; font-weight:700">1,045.27 KiB</span> (0.92x) | <span style="color:#dc2626">2,044.7</span> (1.12x) | <span style="color:#dc2626">1,227.3</span> (7.21x) |
| Groth21 ($\ell = 32$) | 683 | 1024 | <span style="color:#15803d; font-weight:700">660.90 KiB</span> (0.58x) | <span style="color:#15803d; font-weight:700">1,292.5</span> (0.71x) | <span style="color:#dc2626">679.5</span> (3.99x) |
| Golden | 683 | 1024 | <span style="color:#15803d; font-weight:700">669.38 KiB</span> (1.69x) | <span style="color:#dc2626">1,179,519</span> (646x) | <span style="color:#dc2626">27,747.90</span> (163x) |
| [GHL21e][^GHL21e] | 683 | 1024 | <span style="color:#15803d; font-weight:700">253.38 KiB</span> (4.46x) | <span style="color:#dc2626">7,879</span> (4.32x) | <span style="color:#dc2626">562</span> (3.30x) |
| cgVSS[^KMMplus23e] | 683 | 1024 | <span style="color:#15803d; font-weight:700">558.96 KiB</span> (2.02x) | <span style="color:#15803d; font-weight:700">1,170.40</span> (1.56x) | <span style="color:#dc2626">1,418.00</span> (8.33x) |


To reproduce the **Chunky** numbers:
```bash
# clone repo
git clone https://github.com/aptos-labs/aptos-core

# checkout branch
cd aptos-core/
git checkout alin/chunky-blstrs

# run benches
cd crates/aptos-crypto/benches/
./run-pvss-benches.sh
```

### Golden notes

To reproduce the **Golden** numbers, clone [`alinush/fy`](https://github.com/alinush/fy) and run:
```bash
cd fy/
# Transcript size only (one row per (t, n)):
go test ./golden/ -run TestPrintTranscriptSize -v -timeout 2h

# Full benchmark (transcript size + deal/verify/serialize/decrypt-share).
GOMAXPROCS=16 go test ./golden/ -run TestPrintBenchmarks -v -timeout 2h
```

{: .smallnote}
To benchmark custom $(t, n)$ pairs, comma-separate them as "t:n" via, say:
`GOMAXPROCS=16 GOLDEN_SIZES=6:8,11:16 go test ./golden/ -run TestPrintBenchmarks -v`

#### Why is Golden dealing so slow?

Golden is the only scheme in the table that relies on a SNARK: for every recipient, the dealer produces a [gnark](https://github.com/Consensys/gnark) PLONK proof attesting that an eVRF-derived pad was computed correctly. Each PLONK proof costs ~1.15 seconds on our machine, and a dealing contains $n$ of them, which is why Deal scales as $\approx 1{,}150\cdot n$ ms. Verification is much cheaper ($\approx 7$ ms/proof) since PLONK verify is fast, and per-recipient share decryption is just one Diffie–Hellman operation plus a scalar subtraction.


### Groth21 notes

To reproduce the **Groth21** numbers:
```bash
# 1. Install Rust (if needed): see https://rustup.rs

# 2. Clone our e2e-vss fork
git clone https://github.com/alinush/groth21-rs
cd groth21-rs/

# 3. Run the benchmarks (single-threaded).
#    RAYON_NUM_THREADS=1 is belt-and-suspenders; the Cargo.toml also pins blst
#    to its `no-threads` build so blst's internal Pippenger MSM doesn't secretly
#    spawn a thread pool.
RAYON_NUM_THREADS=1 ./benches/run-pvss-benches.sh
```
This uses the default 16-bit chunks ($m=16$, $B=2^\ell=2^{16}$). Pass `--features chunks-8bit` to switch to 8-bit chunks ($m=32$, $B=2^8$) instead.

#### How we picked the baseline

Groth21 has two known implementations:

1. [DFINITY's production Rust implementation](https://github.com/dfinity/ic/tree/master/rs/crypto/internal/crypto_lib/threshold_sig/bls12_381/src/ni_dkg), which includes forward-secure binary tree encryption (BTE), epoch-based key updates, and custom-optimized BLS12-381 primitives (windowed Pippenger MSMs, precomputed `mul2` tables).
2. [Sourav Das's `e2e-vss` implementation](https://github.com/sourav1547/e2e-vss), which implements the same Groth21 PVSS protocol but with plain (non-forward-secure) ElGamal encryption and uses the much faster `blstrs` crate for BLS12-381 arithmetic.

Both implementations use identical NIZK proofs (correct sharing and correct chunking, from Sections 6.4 and 6.5 of the paper) and the same chunking parameters: 
 - `NUM_CHUNKS=16` (i.e., $\emph{m}$)
 - `CHUNK_SIZE=65536` (i.e., $\emph{B}$)
 - `NUM_ZK_REPETITIONS=32` (i.e., $\ell$ in their paper, but baptized as $\term{\tau}$ here)

The two implementations differ only in the encryption layer (forward-secure BTE vs. plain ElGamal) and the underlying curve library.

We chose to benchmark Sourav's implementation, after verifying it is the **fastest** of the two.
To confirm this, we modified DFINITY's codebase to:
1. remove the forward-secure BTE layer from encryption, replacing it with vanilla ElGamal, as in `e2e-vss`
2. remove the pairing-based ciphertext integrity checks that are specific to BTE
3. switch the sharing proof from $\mathbb{G}_2$ polynomial coefficient commitments to $\mathbb{G}_1$ commitments, matching `e2e-vss`'s approach, for an apples-to-apples comparison

We then benchmarked both implementations on the same machine, calling the raw cryptographic functions directly (bypassing serialization overhead) with the same parameters ($n \in \\{64, 128, 256, 512, 1024\\}$).
The result: Sourav's implementation was consistently **1.4-1.5x faster** for both dealing and verification.
I suspect this is because `blstrs` includes hand-tuned C and assembly for BLS12-381 that is difficult to beat.

We further improved Sourav's implementation by upgrading `blstrs` from v0.6.1 to v0.7.1 and `blst` from v0.3.11 to v0.3.16, which yielded an additional **~20% faster dealing** and **~2x faster verification**.

#### What Groth21's knowledge soundness proof guarantees about worst-case decryption times
{: #groth21-worst-case}

Groth21's chunking proof is _approximate_: it does not guarantee that each encrypted chunk $s_{i,j}$ lies in $[0, B)$ where $B = 2^\ell = 2^8 = 256$.
Instead, for each $i,j$ it guarantees that there exists a small multiplicative factor $\term{\Delta_{i,j}} \in [1, \term{E})$, where:
 - $\emph{E} = 2^{\lceil \lambda / \term{\tau} \rceil} = 2^8 = 256$
     - $\emph{\tau} = 32$ is the number of parallel ZK repetitions in the chunking proof
     - $\lambda = 256$ is the security level
 - $\emph{\Delta_{i,j}} \cdot s_{i,j}$ lies in the signed range $[1-\term{Z},\,\emph{Z}-1]$, where:

\begin{align}
\label{eq:groth21-Z}
\emph{Z} = 2 \tau n m (B-1)(E-1)
\end{align}

So, decrypting 1 _chunk_ may need up to $E-1 = 255$ baby-step giant-step (BSGS) invocations, each for a range of size $2Z-1$. 
Since a full _share_ has $m = 32$ chunks, this yields **in the worst-case** $\term{k} = m \cdot (E-1) = 8{,}160$ BSGS invocations to decrypt 1 share.
If done naively, this would take $O(k\sqrt{2Z-1})$ time.
But, if we use a **batched BSGS** variant with larger tables, we can reduce this to $O(\sqrt{k (2Z-1)})$ time, a $\sqrt{k} \approx 90\times$ improvement. 

<!--

Plugging in the actual $(n, m, B, E, \tau)$ from the benchmark:

| $n$ | $Z$                                                | $\log_2 (2Z-1)$ | $\sqrt{k}$ | $\ceil{\sqrt{2Z-1}}$ | batched BSGS table # entries $\approx\sqrt{k \cdot (2Z-1)}$) |
|-----|----------------------------------------------------|-----------------|-----------|---------------------------|----------------------------------------|
|   8 | $2 \cdot 32 \cdot 8 \cdot 32 \cdot 255 \cdot 255 \approx 1.07 \cdot 10^9$ | 31.0 | $\sqrt{8{,}160}$ | 46,161 | $\approx 4.17 \cdot 10^6$ |
| 256 | $2 \cdot 32 \cdot 256 \cdot 32 \cdot 255 \cdot 255 \approx 3.41 \cdot 10^{10}$ | 36.0 | same | 261,121 | $\approx 2.36 \cdot 10^7$ |

-->

#### But does the worst-case ever materialize?

Technically, the _worst-case numbers above_ only materialize for an adversarial dealer who evades detection for all of its encrypted chunks.
It is not immediately clear (to me) how much work does a malicious dealer need to do to trigger this worst case.
Or, if it is even possible.

As a result, I will generously assume **the best-case**: that decryption with $\Delta=1$ always succeeds and only a single BSGS invocation is needed per chunk, where each chunk is $\le 2Z-1$[^may-be-larger].

We analyze how big these chunks get, in bits.
We fix the # of range proof repetitions $\tau = 32$ (so $E = 2^{\lceil 256/32 \rceil} = 256$) and the # of chunks $m = \lambda / \ell = 256 / \ell$ with chunks $< B = 2^\ell$.
Applying the formula from Eq. \ref{eq:groth21-Z}, we get the following numbers.

{: .note}
The number of bits needed to represent a number $n > 0$ is $\floor{\log_2{n}}+1 = \ceil{\log_2{(n)} + 1}$.

| $\ell$ | $n$   | $\ceil{\log_2(2Z)}$ | $\log_2(Z/E)$ |
|--------|-------|---------------------|---------------|
| 8      | 4     | 30 bits | 21 bits |
| 8      | 8     | 31 bits | 22 bits |
| 8      | 16    | 32 bits | 23 bits |
| 8      | 32    | 33 bits | 24 bits |
| 8      | 64    | 34 bits | 25 bits |
| 8      | 128   | 35 bits | 26 bits |
| 8      | 256   | 36 bits | 27 bits |
| 8      | 512   | 37 bits | 28 bits |
| 8      | 1024  | 38 bits | 29 bits |
| 16     | 4     | 37 bits | 28 bits |
| 16     | 8     | 38 bits | 29 bits |
| 16     | 16    | 39 bits | 30 bits |
| 16     | 32    | 40 bits | 31 bits |
| 16     | 64    | 41 bits | 32 bits |
| 16     | 128   | 42 bits | 33 bits |
| 16     | 256   | 43 bits | 34 bits |
| 16     | 512   | 44 bits | 35 bits |
| 16     | 1024  | 45 bits | 36 bits |
| 32     | 4     | 52 bits | 43 bits |
| 32     | 8     | 53 bits | 44 bits |
| 32     | 16    | 54 bits | 45 bits |
| 32     | 32    | 55 bits | 46 bits |
| 32     | 64    | 56 bits | 47 bits |
| 32     | 128   | 57 bits | 48 bits |
| 32     | 256   | 58 bits | 49 bits |
| 32     | 512   | 59 bits | 50 bits |
| 32     | 1024  | 60 bits | 51 bits |

The **key takeaway** is that we choose Groth21 with $\ell = 8$ to benchmark against, since it would have the most comparable decryption times to Chunky at $\ell = 32$.

**Notes:**
 - Doubling $n$ adds 1 bit to the BSGS range, since $Z$ is linear in $n$ (see Eq. \ref{eq:groth21-Z}).
 - Doubling $\ell$ from 4 to 8 adds ~3 bits, from 8 to 16 adds ~7 bits, and from 16 to 32 adds ~15 bits
    + Because $m(B-1) = (256/\ell)(2^\ell - 1)$ grows super-linearly in $\ell$ (see Eq. \ref{eq:groth21-Z})

### [GHL21e] notes

To reproduce, clone our [`alinush/cpp-lwevss`](https://github.com/alinush/cpp-lwevss) fork, which rewrites the reference `main.cpp` to benchmark a **fresh PVSS deal** instead of the re-sharing scenario. 
Specifically, it drops the `n−1` dummy "previous dealings", the `t` corresponding decryptions, and the three re-share/one-time-setup proofs (`commit(sk)`, `proveDecryption`, `proveKeyGen`).
Only `proveEncryption`, `proveSmallness`, and `proveReShare` remain, which is what a fresh PVSS dealer actually needs.
```bash
# 1. Install dependencies
brew install gmp ntl libsodium cmake   # macOS
# Debian/Ubuntu: apt install libgmp-dev libntl-dev libsodium-dev cmake

# 2. Clone the fork and build
git clone https://github.com/alinush/cpp-lwevss
cd cpp-lwevss
mkdir -p build && cd build && cmake .. && make -j lwe-pvss-main && cd ..

# 3. Run sequentially (NOT in parallel: memory-bandwidth contention causes noise).
#    (t, n) pairs with t = ceil(2n/3).
for tn in "3 4" "6 8" "11 16" "22 32" "43 64" "86 128" "171 256" "342 512" "683 1024"; do
    set -- $tn
    ./build/lwe-pvss-main $2 $1
done
```

We also include the original numbers from the [GHL21e] paper[^GHL21e] and compare them to Chunky, making sure to be generous and use a higher threshold $t$ for Chunky.

| Scheme  | $\ell$ | Setup                          | Transcript size | Deal (ms)        | Verify (ms)    | Decrypt-share (ms) |
|---------|--------|--------------------------------|-----------------|------------------|----------------|--------------------|
| Chunky  | 32     | 683-out-of-1024 / 1024 players | 1.15 MiB        |         1,972.80 |         252.06 |               3.12 |
| [GHL21e][^GHL21e] | N/A  | 512-out-of-1024 / 1024 players | <span style="color:#15803d; font-weight:700">$\approx$300 KiB</span> (3.93x) | <span style="color:#dc2626">34,000</span> (17.24x) | <span style="color:#dc2626">20,000</span> (79.35x) | <span style="color:#15803d; font-weight:700">1.4</span> (2.23x) |

{: .note}
The C++ implementation uses a faster elliptic curve (Curve25519) compared to us (pairing-friendly BLS12-381).
However, the actual implementation is naive: (likely inefficiently) re-implements Bulletproofs from scratch using `libsodium` and it does not leverage MSMs.
Nonetheless, the paper stresses that _"only about 25-30% of the prover time and about 15% of the verifier time was spent performing scalar-point multiplications on the curve"_, suggesting that MSM/Bulletproof speed-ups would not make a huge difference.
I attempted optimizing their implementation, but it was fairly non-trivial: improvements there would warrant a separate publication.

### cgVSS notes

The share-correctness proof uses polynomial commitments in $\Gr_1$ of BLS12-381; only the encryption layer and the associated ZK proof live in the class group.

To reproduce, clone the [`alinush/cgdkg_artifact`](https://github.com/alinush/cgdkg_artifact) repo which is a small modification of the upstream artifact that:
 - adds a PVSS abstraction in `classgroup/src/pvss.rs`
 - adds PVSS benchmarks in `benches/benchmarks_pvss.rs`
 - swaps the BLS12-381 backend from [`miracl_core`](https://github.com/miracl/core) to [`blstrs`](https://github.com/filecoin-project/blstrs) v0.7.1, to be overly-generous to cgVSS

...and run:

```bash
# macOS/arm64 may need: -L /opt/homebrew/lib -L /opt/homebrew/opt/openssl@3/lib
RAYON_NUM_THREADS=1 cargo bench --bench benchmarks_pvss
```

## Future work

 - It would be intriguing to optimize a Groth16-based approach for PVSS, like the one by Nicholas Gailly [here](https://research.protocol.ai/blog/2022/a-deep-dive-into-dkg-chain-of-snarks-and-arkworks/#benchmarks).

## Acknowledgements

The weighted PVSS in this blog post has been co-designed with Rex Fernando and Wicher Malten at Aptos Labs.
The weighted DKG built on top of the PVSS has been co-designed with Daniel Xiang and Balaji Arun.
Thanks to Ittai Abraham for helping me think through the DKG protocol from the lens of validated Byzantine agreement.
Thanks to Wicher Malten for the initial write-up of **Chunky 2**, which I later modified.

## Appendix: The $i'\gets \mathsf{idx}(i,j,k)$ indexing

It may be easiest to understand the $\idx(i,j,k) = (W_i + (j-1))\cdot m + k$ formula by considering an example.

Say the number of chunks per share is $m = 3$ and that we have $n=4$ players with weights $[ w_1, w_2, w_3, w_4 ] = [2, 1, 3, 2]$

Then, the cumulative weights will be $[ W_1, W_2, W_3, W_4 ] = [ 0, 2, 3, 6 ]$

"Flattening out" the shares, we'd get:
```
Player 1:

    s_{1,1,1}, s_{1,1,2}, s_{1,1,3},
    1          2          3         

    s_{1,2,1}, s_{1,2,2}, s_{1,2,3},
    4          5          6         

Player 2:
    s_{2,1,1}, s_{2,1,2}, s_{2,1,3},
    7          8          9         

Player 3:
    s_{3,1,1}, s_{3,1,2}, s_{3,1,3},
    10         11         12        

    s_{3,2,1}, s_{3,2,2}, s_{3,2,3},
    13         14         15        

    s_{3,3,1}, s_{3,3,2}, s_{3,3,3},
    16         17         18        

Player 4:
    s_{4,1,1}, s_{4,1,2}, s_{4,1,3},
    19         20         21        

    s_{4,2,1}, s_{4,2,2}, s_{4,2,3},
    22         23         24
```

Observations:
 1. Player $i$'s share chunks start at index $W_i\cdot m + 1$.
 2. To get to the chunks of the $j$th share (of player $i$) add $(j-1)\cdot m$ to that.
 3. To get to the $k$th chunk (of the $j$th share of player i) add $k-1$ to that.

So:
\begin{align}
\idx(i,j,k) 
    &= ((W_i \cdot m + 1) + ((j-1) \cdot m) + (k-1)\\\\\
    &= ((W_i \cdot m) + ((j-1) \cdot m) + k\\\\\
    &= (W_i + (j-1)) \cdot m + k\\\\\
\end{align}

For example, when $i = 3, j = 3, k = 2$, we get:
\begin{align}
    (W_i + (j-1)) \cdot m + k
  &= (W_3 + (3-1)) \cdot 3 + 2\\\\\
  &= (3 + 2) \cdot 3 + 2\\\\\
  &= 5 \cdot 3 + 2 = 17
\end{align}
as expected for $s_{3,3,2}$.

## Appendix: Chunky 2

We present a modified version of **Chunky** with a 13% faster verifier, henceforth called **Chunky 2**.

To avoid redundancy, we describe only the modifications we made, rather than restating the entire algorithm from scratch.

The **key idea** is to modify the ElGamal-to-KZG relation $\emph{\Retk}$ from Eq. $\ref{rel:e2k}$ to also prove that the $\widetilde{V}\_{i,j}$ share commitments from Eq. $\ref{eq:share-commitments}$ are computed correctly.
This will speed up [Step 2 in $\pvss.\verify$](#step-2-verify), which checks that what's encrypted in the $C\_{i,j,k}$'s from Eq. \ref{eq:share-ciphertexts} is what's comitted in the $\widetilde{V}\_{i,j}$'s.

The modified $\Retknew$ relation follows below, with changes $\bluedashedbox{\text{highlighted in blue}}$:
\begin{align}
\term{\Retknew}\left(\begin{array}{l}
\stmt = \left(G, H, \ck, \\{\ek\_i\\}\_i,\\{C\_{i,j,k}\\}\_{i,j,k}, \\{R_{j,k}\\}\_{j,k}, C, \bluedashedbox{\\{\widetilde{V}\_{i,j}\\}\_{i,j}}    \right),\\\\\
\witn = \left(\\{s\_{i,j,k}\\}\_{i,j,k}, \\{r\_{j,k}\\}\_{j,k}, \rho\right)
\end{array}\right) = 1\Leftrightarrow\\\\\
\Leftrightarrow\left\\{\begin{array}{rl} 
    (C\_{i,j,k}, R_{j,k}) &= E.\enc_{G,H}(\ek_i, s\_{i,j,k}; r\_{j,k})\\\\\
    C& = \dekart_2.\commit(\ck, \\{s\_{i,j,k}\\}\_{i,j,k}; \rho)\\\\\
    \bluedashedbox{\widetilde{V}\_{i,j}} & = \bluedashedbox{\left( \sum_{k \in [m]} B^{k-1} s\_{i,j,k} \right) \cdot \widetilde{G}}
\end{array}\right.
\end{align}

This modification moves almost all verification work in [Step 2 of $\pvss.\verify$](#step-2-verify) into the dealing algorithm.
Furthermore, it reduces total computation across the dealing and verification algorithms.
We summarize below:

| Scheme       | Proving work         | Verification work                                  | Transcript size change |
|--------------|----------------------|----------------------------------------------------|------------------------|
| Chunky       | 0                    | $\vmsmOne{W\cdot m} + \vmsmTwo{W} + \multipair{2}$ | 0                      |
| **Chunky 2** | $\GmulTwo{W}$        | $\vmsmTwo{2W+1}$                                   | ${} + W \|\Gr\_2\|$     |

{: .note}
The $\Sigma$-protocol verifier extra work will be of the form $\psi(\mathbf{\sigma}) \equals \mathbf{A} + e\cdot [\widetilde{V}\_{i,j}]\_{i,j}$ and can be done in a size-$(2W+1)$ MSM because the group elements in $\psi(\mathbf{\sigma})$ will all have the same base $\widetilde{G}$.

Then, we modify [**Step 6** of the $\pvss.\deal$ algorithm](#step-6-deal) to prove this new relation: 
\begin{align}
\bluedashedbox{\piSoknew} &\gets \sok.\prove\left(\begin{array}{l}
    \bluedashedbox{\Retknew}, \ctx,\\\\\
    G, H, \ck, \\{\ek\_i\\}\_i,\\{C\_{i,j,k}\\}\_{i,j,k}, \\{R\_{j,k}\\}\_{j,k}, C, \bluedashedbox{\\{\widetilde{V}\_{i,j}\\}\_{i,j}},\\\\\
    \\{s\_{i,j,k}\\}\_{i,j,k}, \\{r\_{j,k}\\}\_{j,k}, \rho
\end{array}\right)
\end{align}

Then, we modify [**Step 4** of the $\pvss.\verify$ algorithm](#step-4-verify) to verify the proof from above:
\begin{align}
\textbf{assert}\ &\sok.\verify\left(\begin{array}{l}
    \bluedashedbox{\Retknew}, \ctx,\\\\\
    G, H, \ck, \\{\ek\_i\\}\_i,\\{C\_{i,j,k}\\}\_{i,j,k}, \\{R\_{j,k}\\}\_{j,k}, C, \bluedashedbox{\\{\widetilde{V}\_{i,j}\\}\_{i,j}};\\\\\
    \bluedashedbox{\piSoknew}
\end{array}\right) \equals 1
\end{align}

Lastly, we remove [**Step 2** of the $\pvss.\verify$ algorithm](#step-2-verify), since the check is now performed above.

## References

For cited works, see below 👇👇

[^aptos-Q]: In an abundance of caution, in Aptos, we require that $Q$ contains $>$ 66% of the stake.
[^reuse]: Recall that in Aptos, we will safely reuse the validator signing keys as encryption keys.
[^dummy]: Technically, they have to add a dummy proof to the _subtranscript_, obtaining a proper _transcript_, which they can now feed in to $\pvssDecrypt$ in a type-safe way.
[^eventually]: This may require that each validator $i'$ poll other validators for the transcripts in the proposed set $Q$ that $i'$ is missing.
[^equivocation]: If $i'$ receives two transcripts signed by the same validator $j'$, then that constitute equivocation and would be provable misbehavior. So $i'$ should (or may?) not attest to $Q$ since it includes a malicious player $j'$.
[^oneliner]: The 300 KiB proof size just mentioned in passing in the introduction. It is unclear whether they actually measured it correctly: is this the size of the publicly-verifiable transcript that includes **all** encryptions and proofs for **all** users?
[^vaba]: This can be viewed through the lens of collecting $f+1$ attestations in validated Byzantine agreement (VABA).
[^may-be-larger]: There must be some attacks that induce more work for the adversary: e.g., maybe with a $2^k$ times more work, the adversary can add $k$ bits to the max DL. But I would need to investigate more closely.

{% include refs.md %}
