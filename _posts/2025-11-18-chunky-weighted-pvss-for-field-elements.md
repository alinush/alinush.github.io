---
tags:
title: "Chunky: Weighted PVSS for field elements"
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
\def\dekart{\mathsf{DeKART}^\mathsf{FFT}}
\def\setup{\mathsf{Setup}}
\def\commit{\mathsf{Commit}}
\def\prove{\mathsf{Prove}}
\def\verify{\mathsf{Prove}}
%
\def\maxTotalWeight{W_\mathsf{max}}
\def\totalWeight{W}
\def\threshWeight{t}
%
\def\trs{\mathsf{trs}}
\def\pp{\mathsf{pp}}
\def\pid{\mathsf{pid}}
\def\ssid{\mathsf{ssid}}
\def\dk{\mathsf{dk}}
\def\ek{\mathsf{ek}}
\def\ssk{\mathsf{ssk}}
\def\spk{\mathsf{spk}}
\def\pvssSetup{\mathsf{PVSS.Deal}}
\def\pvssDeal{\mathsf{PVSS.Deal}}
\def\pvssVerify{\mathsf{PVSS.Verify}}
\def\pvssDecrypt{\mathsf{PVSS.Decrypt}}
$</div> <!-- $ -->

{% include defs-pairings.md %}
{% include defs-time-complexities.md %}

## Preliminaries

Assuming familiarity with:

 - Chunked verifiable ElGamal encryption of field elements via ZK range proofs (e.g., see the DeKART paper[^BDFplus25e])
 - PVSS, as an abstract cryptographic primitive
    + In particular, the notion of a PVSS **transcript** will be used a lot
 - Batched ZK range proofs
    + We will use [univariate DeKART](/dekart) here

Pairing-friendly groups notation:
{% include prelims-pairings.md %}
 - We often use capital letters like $G$ or $H$ to denote group elements in $\Gr_1$
 - We often use $\widetilde{G}$ or $\widetilde{H}$ letters to denote group elements in $\Gr_2$

Time-complexity notation:
{% include prelims-time-complexities.md %}

PVSS notation:
 - Let $\term{n}$ denote the number of players
 - Let $\term{M}$ denote the maximum number of shares a player can have 

### Chunked'n'batched ElGamal encryption

#### $E.\mathsf{KeyGen}_H()\rightarrow (\mathsf{dk},\mathsf{ek})$

Generate the key-pair:
\begin{align}
\dk &\randget\F\\\\\
\ek &\gets \dk \cdot H
\end{align}

#### $E.\mathsf{Enc}\_{G,H}\left(\\{\mathsf{ek}\_i\\}\_{i\in[n]}, \\{s\_{i,j}\\}\_{i\in[n],j\in[m]}; \\{r\_j\\}\_{j\in[m]}\right) \rightarrow \left(\\{C\_{i,j}\\}\_{i,j},\\{R\_j\\}\_j\right)$

$\forall i\in[n],\forall j\in[m]$, compute:
\begin{align}
C_{i,j} &\gets s_{i,j} \cdot G + r_j \cdot \ek_i\\\\\
R_j &\gets r_j \cdot H
\end{align}

#### $E.\mathsf{Dec}\_{G}\left(\mathsf{dk}\_i, \\{C\_{i,j}\\}_{j\in[m]}\right) \rightarrow \\{s\_{i,j}\\}_j$

$\forall j\in[m]$, compute:
\begin{align}
s_{i,j} &\gets \log_G\left(C_{i,j} - \dk_i\cdot R_j\right)\\\\\
        &= \log_G\left((s_{i,j} \cdot G + r_j \cdot \ek_i) - \dk_i\cdot (r_j \cdot H)\right)\\\\\
        &= \log_G\left(s_{i,j} \cdot G + r_j \cdot \ek_i - r_j \cdot \ek_i\right)\\\\\
        &= \log_G\left(s_{i,j} \cdot G\right)
\end{align}

### Univariate DeKART batched ZK range proofs

#### $\dekart_b.\setup(n; \mathcal{G})\rightarrow (\mathsf{prk},\mathsf{ck},\mathsf{vk})$

Sets up the ZK range proof to prove batches of size $\le n$, returning a proving key, a commitment key and a verification key.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfsetupn-mathcalgrightarrow-mathsfprkmathsfckmathsfvk).)

#### $\dekart_b.\commit(\ck,z_1,\ldots,z_{n}; \rho)\rightarrow C$

Returns a commitment $C$ to a vector of $n$ values using randomness $\rho$.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfcommitckz_1ldotsz_n-rhorightarrow-c).)

#### $\dekart_b.\prove(\mathsf{prk}, C, \ell; z_1,\ldots,z_{n}, \rho)\rightarrow \pi$

Returns a ZK proof $\pi$ that the $n$ values committed in $C$ are all in $[0, b^\ell)$.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfprovemathsfprk-c-ell-z_1ldotsz_n-rhorightarrow-pi).)

#### $\dekart_b.\verify(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

Verifies that the $n$ values committed in $C$ are all in $[0, b^\ell)$.
(See implementation [here](/dekart#mathsfdekart_bmathsffftmathsfverifymathsfvk-c-ell-pirightarrow-01).)

## Building a DKG from a non-malleable PVSS

Our goal is to get a **weighted DKG**[^DPTX24e] for field elements amongst the validators of a proof-of-stake blockchain, such that the **DKG (final, shared) secret** $\term{z}$ is only reconstructable by a fraction $> \term{f}$ of the stake (e.g., $f = 0.5$ or 50%).

To do this, each validator $i$ will **"contribute"** to $z$ by picking their own secret $\term{z_i} \in \F$ and dealing it to the other validators via $\term{\pvssDeal}$ in a **non-malleable** fashion.
The DKG secret will be set to $z \bydef \sum_{i\in Q} z_i$, where $\term{Q}$ is the set of validators who correctly dealt their $z_i$ via $\pvssDeal$.

Crucially, $Q$ must be large "enough": i.e., it must have "enough" validators to guarantee that no malicious subset of them can learn (or can bias the choice of) $z$.
For example, we could assume only 33% of the stake is malicious and require that $Q$ have more stake than that.
In an abundance of caution, in Aptos, we require that $Q$ contains $>$ 66% of the stake.

{: .note}
The DKG is parameterized by $\sizeof{Q}$ and by $f$.
Since typically in a DKG the same set of validators will deal a secret amongst themselves, $\sizeof{Q}$ and $f$ are typically set to the same value.
Otherwise, if $f > \sizeof{Q}$, then the validators in $Q$ which are fewer than required by $f$ could reconstruct the secret, which defeats the point. 
Or, if $\sizeof{Q} > f$, then you are requiring more validators to contribute than needed for secrecy, since $f < \sizeof{Q}$ can reconstruct.


_First_, to ensure that $\sizeof{Q}$ is large "enough", we require that, in the DKG protocol, each validator **digitally-sign** their dealt PVSS transcript in a [domain-separated fashion](/domain-separation) (part of the domain separator will be the current consensus epoch number).
Without such authentication, $Q$ could be filled with transcripts from one malicious validator impersonating the other ones.
Therefore, that malicious validator would have full knowledge of the final DKG secret $z$.
No es bueno.

**Implication:** The DKG protocol needs to be carefully crafted to sign the PVSS transcripts.
If done right, the validators' public keys used for consensus signature can be safely reused as **signing public keys** for the transcript.

_Second_, we require that PVSS transcripts obtained from $\pvssDeal$ be **non-malleable**.
To see why this is necessary consider the following scenario:
 - two validators $i$ and $j$ have enough stake to make $Q = \\{i,j\\}$ large enough
 - $j$ by itself does not have enough stake
 - $i$ deals $z_i \in \F$ and signs the transcript
 - $j$ removes $i$'s signature and mauls $i$'s transcript to deal $-z_i + r$ for some $r\randget\F$ it knows
 - $j$ signs this mauled transcript
   + $\Rightarrow j$ would have full knowledge of the final DKG secret $z = z_i + (- z_i + r) = r$.

**Implication:** The PVSS transcript will include a **zero-knowledge signature of knowledge (ZKSoK)** of the dealt secret $z_i$ over the signing public key used to sign the transcript.
This way, the dealt secret cannot be mauled without rendering the transcript invalid.
Furthermore, nor can validator $j$ bias the final DKG secret $z$ by appropriating validator $i$'s transcript as their own (i.e., by stripping validator $i$'s signature from the transcript and adding their own).

## Non-malleable weighted PVSS algorithms

Notation:

 - Let $\term{\maxTotalWeight}$ denote the maximum total weight $\Leftrightarrow$ maximum # of shares that we will ever want to deal in the PVSS
 - Let $\term{\ell}$ denote the **chunk bit-size** (e.g., $\ell=32$ for 32-bit chunks)
 - Let $\term{m} = \ceil{\log_2{\sizeof{\F}} / \ell}$ denote the **number of chunks per share**
 - Let $\term{B}\bydef 2^\ell$ denote the **maximum value of a chunk** (e.g., $B=2^{32}$ for 32-bit chunks)

The algorithms below describe **Chunky**, a weighted PVSS where only subsets of players with combined weight $> \threshWeight$ can reconstruct the shared secret.

### $\mathsf{PVSS}.\mathsf{Setup}(\ell, W_\mathsf{max}; \mathcal{G}) \rightarrow \mathsf{pp}$

Recall that $\emph{\maxTotalWeight}$ is the max. total weight, $\emph{\ell}$ is the # of bits per chunk and $\emph{m}$ is the number of chunks a share is split into.

**Step 1:** Set up the chunked'n'batched ElGamal encryption:
\begin{align}
\term{G},\term{H} &\randget \Gr_1
\end{align}

**Step 2:** Set up the ZK range proof to batch prove that $\le \maxTotalWeight\cdot m$ chunks are all $\ell$-bit wide: 

\begin{align}
(\prk,\ck,\vk) \gets \dekart_2.\setup(\maxTotalWeight\cdot m; \mathcal{G})
\end{align}

Note that DeKART assumes that the field $\F$ admits a $2^\kappa$-th primitive root of unity where $2^\kappa$ is the smallest power of two $\ge \maxTotalWeight\cdot m + 1$.
(The ZK range proof needs FFTs of size $\maxTotalWeight\cdot m$.)

Return the public parameters:
\begin{align}
\pp \gets (\ell, \maxTotalWeight, G, H, \prk,\ck,\vk)
\end{align}

### $\mathsf{PVSS}.\mathsf{Deal}\_\mathsf{pp}\left(t, \\{w_i\\}\_{i\in[n]}, \\{\mathsf{ek}_i\\}\_{i\in [n]}, a_0, \mathsf{ssid}\right) \rightarrow \mathsf{trs}$

{: .smallnote}
$a_0$ is the dealt secret.
<!--$\pid\in [n]$ is the dealer's player ID.-->
$w_i$'s are the weights of each player, including the dealer's (i.e., $w_\pid$).
$\ssid$ is a session identifier, which will be set to the consensus epoch number in which the DKG is taking place and calls this PVSS deal algorithm.

Parse public parameters:
\begin{align}
(\ell, \maxTotalWeight, G, H, \prk,\ck,\vk)\parse\pp
\end{align}

Compute the **total weight** and assert that the public parameters can accomodate it:
\begin{align}
\term{W} &\gets \sum_i w_i\\\\\
\textbf{assert}\ W &\le \maxTotalWeight
\end{align}

Find a $2^\kappa$-th **root of unity** $\term{\omega} \in \F$ such that we can efficiently compute FFTs of size $W$ (i.e., smallest $2^\kappa \ge W$).

Pick the degree-$\threshWeight$ random secret sharing polynomial:
\begin{align}
\term{a_1,\ldots,a_t} &\randget \F\\\\\
\term{f(X)} &\bydef \emph{a_0} + a_1 X + a_2 X^2 + \ldots + a_t X^\threshWeight\\\\\
\emph{a_0}, \term{s_1, s_2,\ldots, s_W} &\gets f(0), f(\omega^0),f(\omega^1),\ldots,f(\omega^{W-1})
\end{align}

_Note:_ The $s_i$'s would be computed fast in $\Fmul{O(W\log{W})}$ via an FFT. 

Return the transcript:
\begin{align}
\trs \gets ?
\end{align}

### $\mathsf{PVSS}.\mathsf{Verify}\_\mathsf{pp}\left(\mathsf{trs}, t, \\{w_i\\}_{i\in[n]}, \\{\mathsf{ek}_i\\}\_{i\in[n]}, \mathsf{ssid}\right) \rightarrow \\{0,1\\}$

### $\mathsf{PVSS}.\mathsf{Decrypt}\_\mathsf{pp}\left(\mathsf{trs}, \mathsf{dk}, i\right) \rightarrow \\{s_{i,j}\\}_j \in \F$ 

{: .smallnote}
$i\in[n]$ is the ID of the player who is decrypting their share(s) from the transcript.

## References

For cited works, see below 👇👇

{% include refs.md %}
