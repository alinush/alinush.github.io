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
sidebar:
    nav: cryptomat
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

## Preliminaries

We assume familiarity with:
 - PVSS, as an abstract cryptographic primitive.
    + In particular, the notion of a **PVSS transcript** will be used a lot.
 - [Digital signatures](/signatures)
    + i.e., sign a message $m$ as $\sigma \gets \sig.\sign(\sk, m)$ and verify via $\sig.\verify(\pk, \sigma, m)\equals 1$
 - [ElGamal encryption](/elgamal)
 - Batched range proofs (e.g., [DeKART](/dekart))
 - ZKSoKs (i.e., [$\Sigma$-protocols](/sigma) that implicitly sign over a message by feeding it into the Fiat-Shamir transform).
 - The SCRAPE low-degree test

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

### The ElGamal-to-KZG NP relation

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

### The SCRAPE low-degree test

{: .todo}
Explain!

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

**Step 1:** Verify that the committed shares encode a degree-$\threshWeight$ polynomial via the SCRAPE LDT[^CD17]:
\begin{align}
\term{\alpha} &\randget \F\\\\\
\textbf{assert}\ &\scrape.\lowdegreetest(\\{(0, \widetilde{V}\_0)\\} \cup \\{(\chi\_{i,j}, \widetilde{V}\_{i,j})\\}\_{i,j}, \threshWeight, W; \emph{\alpha}) \equals 1
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
| **Chunky 2** | $\GmulTwo{W}$        | $\vmsmTwo{2W+1}$                                   | ${} + W \|\Gr_2\|$     |

{: .note}
The $\Sigma$-protocol verifier extra work will be of the form $\psi(\mathbf{\sigma}) \equals \mathbf{A} + e\cdot [\widetilde{V}_{i,j}]_{i,j}$ and can be done in a size-$(2W+1)$ MSM because the group elements in $\psi(\mathbf{\sigma})$ will all have the same base $\widetilde{G}$.

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
[^vaba]: This can be viewed through the lens of collecting $f+1$ attestations in validated Byzantine agreement (VABA).

{% include refs.md %}
