---
tags:
 - digital signatures
 - distributed key generation (DKG)
 - BLS
 - aggregation
 - multilinear maps
title: "What the Smurf? Silent-setup & unique threshold signatures!"
#date: 2020-11-05 20:45:59
permalink: smurf
published: true
sidebar:
    nav: cryptomat
---

{: .info}
**tl;dr:** This blog post investigates whether _threshold_ **verifiable unpredictable functions (VUFs)** can be efficiently instantiated in the **silent setup** setting, which avoids the need for an interactive, expensive and often complex [distributed key generation (DKG)](/amt) phase.
We show that (1) silent setup threshold VUFs are possible from multilinear maps and (2) efficient constructions are as hard to obtain as $n$-party non-interactive key exchange; so **very hard**.
Lastly, we focus on a more general **multiverse** setting, which captures the threshold setting.

<!--more-->

<p hidden>$$
\def\ak{\mathsf{ak}}
$$</p>

Why do we care about **threshold verifiable unpredictable functions (VUFs)**?
Because the most efficient designs for distributed randomness beacons[^vdf] rely on them!
Yet, all practical threshold VUFs require an expensive DKG phase between the beacon nodes (e.g., BLS[^BLS01]).
This DKG must be run (1) when the beacon is first deployed and (2) when nodes enter or leave the distributed deployment (e.g., via a DKG-like [secret resharing scheme](/2024/04/26/How-to-reshare-a-secret.html)).

Today, several beacon protocols based on threshold VUFs incur this expensive DKG phase (e.g., Aptos Roll[^roll], drand[^drand], Flow[^flow], Sui[^sui]). 
This makes it intriguing (and potentially-useful) to consider the possibility of a **silent setup threshold VUF**: a scheme that avoids the need for a DKG!

In this blog post, we show such a scheme exists, if efficient multilinear maps exist!
In fact, our proposed scheme is slightly stronger: it is a **silent-setup multiverse VUF**, or a **SMURF**, which works in a recently-proposed, more general **multiverse** setting[^BGJplus23] that implicitly captures the threshold setting too.

## Quick idea: BLS with multilinear maps

We modify the **BLS[^BLS01] multisignature scheme** to be a threshold VUF as follows.

Each player $i$ has a secret key $\sk_i$ and a verification key $\vk_i = g^{\sk_i}$, generated locally, as usual.
Player $i$ produces a **signature share** on message $m$ as $\sigma_i = H(m)^{\sk_i} \in \Gr$, as usual.

What is different then?
To **aggregate** a $t$-out-of-$n$ threshold VUF, we will plug the $t$ signature shares as the first inputs to an $n$-multilinear map $e$ and the remaining $n-t$ public keys as the last inputs.

For example, a 2-out-of-3 threshold VUF $\sigma$ over a message $m$ would be aggregated from BLS signature shares $(\sigma_1,\sigma_2)$ as:
\begin{align}
    \label{eq:example-agg}
\sigma 
  &= e_3(\sigma_1, \sigma_2, \pk_3)\\\\\
  &= e_3(H(m)^{\sk_1}, H(m)^{\sk_2}, g^{\sk_3})\\\\\ 
  &= e_3(H(m), H(m), g)^{\sk_1 \cdot \sk_2 \cdot \sk_3}
\end{align}

To **verify** such a threshold VUF, the proof would consist of the actual signature shares $H(m)^{\sk_1}$ and $H(m)^{\sk_2}$.
Verification would involve two steps.
First, validate each signature share using the multilinear map (or via a DLEQ $\Sigma$-protocol proof):
\begin{align}
    \label{eq:example-ver}
    e_3(\sigma_i, g,g) \equals e_3(H(m), \pk_i, g),\forall i\in\\{1,2\\}
\end{align}
Second, **re**-aggregate the signature shares and check they yield the same signature $\sigma$ from Equation \ref{eq:example-agg}.

We fully describe this strawman scheme [below](#non-succinct-smurf) and improve it with succinctness [later](#succinct-smurfs) via an **argument of knowledge** (AoK) of signature shares that satisfy Equation \ref{eq:example-ver} and, when aggregated via Equation \ref{eq:example-agg}, yield the threshold VUF.

{: .warning}
**Note:** We assume symmetric multilinear maps. 
Generalizing this to **a**symmetric ones would be interesting.
(Naively, porting the construction over does not work due to the apparent necessity of defining multiple hash functions $H_i$ into each one of the asymmetric groups $\Gr_i$, which would break the uniqueness of the scheme.)

## Related work

Recently, there has been increased interest in **silent-setup threshold signatures**: i.e., threshold signatures that avoid DKGs[^DCXplus23e]$^,$[^BGJplus23]$^,$[^GJMplus23e]$^,$[^Lee23e].
However, _silent-setup_ **unique** _threshold signatures_ have not received much attention.
(Recall that: unique threshold signature = [threshold VUFs](#unique-signature-schemes-or-verifiable-unpredictable-functions-vufs).)

Part of the reason may be that a silent-setup threshold VUF is actually a **strong primitive**: it implies $n$-party non-interactive key exchange (NIKE).
Specifically, a $1$-out-of-$n$ silent-setup threshold VUF $=$ an $n$-party NIKE[^guru].
Furthermore, a $t$-out-of-$n$ silent-setup threshold VUF = an $(n-t+1)$-party NIKE, because $t-1$ of the SKs can be exposed, which yields a $1$-out-of-$(n-t+1)$ silent VUF.

**Note:** While [the strawman silent-setup threshold signature construction](/2024/05/01/baird-et-al-unique-threshold-signature-scheme.html) from \[BGJ+23\][^BGJplus23] (see [a screenshot here](/pictures/2024-05-08-mts.png)) does satisfy **uniqueness**, it **lacks** silent setup: it still requires a DKG-like protocol for exposing evaluations on a degree-$(n-1)$ polynomial.

## Preliminaries

### Notation

When we write $(a_i)\_{i\in T}$ as an input to an algorithm, it is shorthand for $\left(T, (i, a_i)_{i\in T}\right)$.

### Verifiable unpredictable functions (VUFs)

A **VUF**[^MRV99] is a _unique_ signature scheme.
Note that _uniqueness_ is a stronger property than _deterministic_ signing. 
It means that, an adversary can**not** create two _different_ signatures $\sigma_1 \ne \sigma_2$ such that they are both accepted as valid signatures on a message $m$ under some public key $\pk$.
For example, BLS is a unique signature scheme but Ed25519 is not! 
While Ed25519 supports deterministic signing, it is _not_ a unique scheme because a verifier will glady accept many different signatures for the same message $m$.

### Multilinear maps

{: .info}
**Important:** As of 2024, **practical** multilinear map constructions do not exist[^JLS20e]$^,$[^AFHplus15e].
In other words, the schemes in this blog post are **purely-theoretical** and serve only to indicate the **feasibility** of a SMURF.

An **$n$-multilinear map** $e : \Gr^n \rightarrow \Gr_T$ has the following properties:

 1. $\Gr$ and $\Gr_T$ are both Abelian groups of prime order $p$
 2. $\forall (a_1, \ldots, a_n) \in \Z_p^n, (g_1,\ldots, g_n)\in \Gr^n$, we have $e_n(g_1^{a_1}, \ldots, g_n^{a_n}) = e_n(g_1, \ldots, g_n)^{a_1 \cdots a_n}$
 3. If $g$ is a generator of $\Gr$, then $e_n(g, \ldots, g)$ is a generator of $\Gr_T$.

### Accumulators

An **accumulator scheme** is used to compute a short, collision-resistant **digest** of a set $S$.

$\mathsf{Acc.Commit}(S) \rightarrow d$.
Computes the digest $d$ of the set $S$.

<!-- NOTE: Don't need to verify individual proofs.
$\mathsf{Acc.Commit}(S) \rightarrow \left(d, (\pi_e)_{e\in S}\right)$.
Computes the digest $d$ of the set $S$, together with proofs $\pi_e$ for each element $e\in S$. 

$\mathsf{Acc.Verify}(d, e, \pi_e) \rightarrow \\{0,1\\}$.
Verifies the proof $\pi_e$ that $e$ is an element of the set with digest $d$.
-->

{: .info}
An accumulator scheme is **collision-resistant** if there is no polynomial time adversary that can output two different sets which have the same digest.
As an example, simply sorting the set in a canonical order and hashing the result using a collision-resistant hash function yields an accumulator scheme.

### Arguments of Knowledge (AoKs)

An **AoK** for a relation $\mathcal{R}$ consists of two algorithms:

$\mathsf{AoK.Prove}\_\mathcal{R}(x; w) \rightarrow \pi$.
Generates a proof $\pi$ that $R(x; w) = 1$, given a **public statement** $x$ and a **witness** $w$.
The proof $\pi$ is succinct (i.e., much smaller than $w$), but might still leak information about $w$.

$\mathsf{AoK.Verify}\_\mathcal{R}(x; \pi)\rightarrow \\{0,1\\}$.
Verifies the proof $\pi$ that the prover knows a witness $w$ such that $R(x; w) = 1$.

## SMURFs definition

To avoid mistakes, we formally define a _Silent-setup Multiverse (Verifiable) UnpRedictable Functions_, or a
**SMURF**, as a tuple of algorithms (with correctness and security definitions [in the appendix](#appendix-formalizing-smurfs)):

$\mathsf{SMURF.KeyGen}(1^\lambda) \rightarrow (\sk_i, \vk_i)$. 
**Locally** generates a player's **key pair**: their **secret key** and corresponding **verification key**.

{: .info}
Ideally, $\vk_i$ should be _succinct_ (i.e., its size should be independent of the maximum number of players $n$).

$\mathsf{SMURF.AggPubkey}(t, (\vk\_j)\_{j\in [n]}) \rightarrow (\pk, \ak)$.
Takes the verification keys of $n$ players (generated locally via $\mathsf{SMURF.KeyGen}$) and a threshold $t$.
Aggregates them into:
 - a $t$-out-of-$n$ **public key** $\pk$ which can be used to verify threshold signatures against
 - an **aggregation key** $\ak$ which can be used to aggregate threshold signatures via $\mathsf{SMURF.AggSig}$

{: .info}
The necessity of an aggregation key AK $\ak$ in the definition is _artificial_.
An ideal definition would not require this.
However, because our [succinct SMURF construction](#succinct-smurfs) requires the VKs of all players during aggregation, we rely on an AK to pass in this information.

$\mathsf{SMURF.ShareSign}(\sk_i, m) \rightarrow \sigma_i$. 
Computes a **signature share** $\sigma_i$ over $m$ under $\sk_i$.

$\mathsf{SMURF.ShareVer}(\vk_i, m, \sigma_i) \rightarrow \\{0,1\\}$. 
Verifies the signature share $\sigma_i$ on the message $m$ from the player with VK $\vk_i$.

$\mathsf{SMURF.AggSig}(\ak, m, (\sigma\_i)\_{i\in T}) \rightarrow \sigma$.
Aggregates the signature shares $\sigma_i$ from a subset $T$ of players into a **signature** $\sigma$ that can be verified via $\mathsf{SMURF.Verify}$.

$\mathsf{SMURF.Verify}(\pk, m, \sigma) \rightarrow \\{0,1\\}$. 
Verifies that $\sigma$ is a valid signature on $m$ under $\pk$.

$\mathsf{SMURF.Derive}(\pk, m, \sigma) \rightarrow y$. 
Derives a unique **output** $y$ from the signature $\sigma$.

$\mathsf{SMURF.Eval}(t, (\vk_j)_{j\in[n]}, m) \rightarrow y$. 
Returns the unique output $y$ on message $m$ given a threshold $t$ and the VKs of the $n$ players.

{: .info}
**Note:** We intentionally defined $\mathsf{SMURF.Eval}$ to take the VKs rather than the SKs as input.
This allows us to define unpredictability in the silent setup setting, where it will not be possible to extract the SKs under which the adversary's prediction was made (unlike in the DKG setting), since VKs can be adversarial.
Lastly, even though $\mathsf{SMURF.Eval}$ is not a polynomial-time algorithm, this is not a problem since it is only used for the security definition.

## Non-succinct SMURF 

We construct a non-succinct SMURF from multilinear maps, as [intuited above](#idea-bls-with-multilinear-maps).

Let $g$ be the generator for $\Gr$, which admits an $n$-multilinear map[^higher-than-n] $e$, as defined [above](#preliminaries).
We construct a **non-succinct** SMURF as follows:

$\mathsf{SMURF\_1.KeyGen}(1^\lambda) \rightarrow (\sk_i, \vk_i)$:
 - $\sk_i\randget\Zp$  
 - $\vk_i \gets g^{\sk_i}$

$\mathsf{SMURF\_1.AggPubkey}(t, (\vk\_j)\_{j\in [n]}) \rightarrow (\pk, \ak)$.
 - $\pk \gets \left(t, (\vk\_j)\_{j\in[n]}\right)$
 - $\ak \gets \pk$

$\mathsf{SMURF\_1.ShareSign}(\sk_i, m) \rightarrow \sigma_i$:
 - $\sigma_i \gets H(m)^{\sk_i}$

$\mathsf{SMURF\_1.ShareVer}(\vk_i, m, \sigma_i) \rightarrow \\{0,1\\}$:
 - Return $e_n(\sigma_i, g, \ldots, g) \equals e_n(H(m), \vk_i, g, \ldots, g)$

$\mathsf{SMURF\_1.AggSig}(\ak, m, (\sigma\_i)\_{i\in T}) \rightarrow \sigma$:
 - $\pi \gets (\sigma_i)_{i\in T}$

{: .warning}
Just a naive aggregation here. Will fix this in the [succinct construction below](#succinct-smurfs).

$\mathsf{SMURF\_1.Verify}(\pk, m, \sigma) \rightarrow \\{0,1\\}$:
 - Parse $(\sigma_i)_{i \in T} \gets \pi$
 - Parse $\left(t, (\vk\_j)\_{j\in[n]}\right) \gets \pk$
 - Assert $T$ is a size-$t$ subvector of $[n]$
 - $\forall i\in T$, assert $\mathsf{SMURF\_1.ShareVer}(\vk_i, m, \sigma_i) \equals 1$

{: .warning}
Also a naive verification here, which we fix in the [succinct construction below](#succinct-smurfs).

$\mathsf{SMURF\_1.Derive}(\pk, m, \sigma) \rightarrow y$. 
 - Parse $(\sigma_i)_{i \in T} \gets \pi$
 - Parse $\left(t, (\vk\_j)\_{j\in[n]}\right) \gets \pk$
 - Parse $\\{i_1, \ldots i_t\\} \gets T$
 - Parse $\\{j_1,\ldots,j_{n-t}\\} \gets [n]\setminus T$
 - $y \gets e_n(\sigma_{i_1}, \ldots, \sigma_{i_t}, \vk_{j_1},\ldots,\vk_{j_{n-t}})$

$\mathsf{SMURF\_1.Eval}(t, (\vk_j)_{j\in[n]}, m) \rightarrow y$. 
 - For all $j\in[n]$, compute $\sk_j$ such that $\vk_j = g^{\sk_j}$
    - Note: This is _not_ supposed to be efficient.
 - $y \gets e_n(H(m), \ldots, H(m), g, \ldots, g)^{\prod_{j\in[n]} \sk_j}$
    + Note: $H(m)$ appears $t$ times as an input to $e_n$. 

{: .warning}
Recall that a polynomial time $\mathsf{SMURF.Eval}$ is not necessary, since we only use this algorithm to define security.

## Succinct SMURF

From a **theoretical standpoint**, the [$\mathsf{SMURF\_1}$ construction](#non-succinct-smurf) above is not **succinct**:

1. The public key $\pk$ is $O(n)$-sized
1. The aggregated $\sigma$ is $O(t)$-sized 
1. Verifying $\sigma$ takes $O(t)$ time
1. Deriving the VUF output $y$ takes $O(n)$ time since it involves evaluating the multilinear map.

Fortunately, all of these can be addressed with a [succinct argument of knowledge (AoK)](#arguments-of-knowledge-aoks), often known as a SNARK.
(Note that a zkSNARK is not necessary; we do not need zero-knowledge here.)

Specifically, instead of (1) doing all the signature share verification inside $\mathsf{SMURF_1.Verify}$ and (2) doing all the aggregation work inside $\mathsf{SMURF_1.Derive}$, we will give an AoK of having done this work when aggregating in $\mathsf{SMURF_2.AggSig}$.

We denote the resulting scheme as $\mathsf{SMURF\_2}$.
It has the same $\mathsf{KeyGen}$, $\mathsf{ShareSign}$, $\mathsf{ShareVer}$ and $\mathsf{Eval}$ algorithms as $\mathsf{SMURF\_1}$, except for:

$\mathsf{SMURF\_2.AggPubkey}(t, (\vk\_j)\_{j\in [n]}) \rightarrow (\pk, \ak)$.
 - $d \gets \mathsf{Acc.Commit}\left(\\{\vk\_j\ \vert\ j\in[n]\\}\right)$
 - $\pk \gets \left(t, d\right)$
 - $\ak \gets (\pk, (\vk\_j)\_{j\in[n]})$

{: .info}
We make the PK succinct by converting it to an [accumulator](#accumulators) over the VKs. 
The aggregation key (AK) still needs to maintain all the individual VKs. 
It is an interesting open question whether the AK can be made succinct (and thus eliminated).

$\mathsf{SMURF\_2.AggSig}(\ak, m, (\sigma\_i)\_{i\in T}) \rightarrow \sigma$:
 - Parse $\left((t, d), (\vk\_j)\_{j\in[n]}\right) \gets \ak$
 - Parse $\\{i_1, \ldots i_t\\} \gets T$
 - Parse $\\{j_1,\ldots,j_{n-t}\\} \gets [n]\setminus T$
 - $y \gets e_n(\sigma_{i_1}, \ldots, \sigma_{i_t}, \vk_{j_1},\ldots,\vk_{j_{n-t}})$
 - $\pi \gets \mathsf{AoK.Prove}\_\mathcal{R}(d, m, t, y; T, (\sigma_i)_{i\in T}, (\vk\_i)\_{i\in [n]})$ 
 - $\sigma \gets (y, \pi)$

{: .info}
The new $\mathsf{AggSig}$ proves knowledge of $t$ valid signature shares, against the VKs accumulated in the PK, such that these shares aggregate into a unique output $y$.
More formally, the proof argues knowledge of $\sigma_i$'s and $\vk_i$'s such that $\mathcal{R}(d, m, t, y; T, (\sigma_i)_{i\in T}, (\vk\_i)\_{i\in [n]}) = 1$.
We describe the relation $\mathcal{R}$ in detail [below](#the-relation).

$\mathsf{SMURF\_2.Verify}(\pk, m, \sigma) \rightarrow \\{0,1\\}$:
 - Parse $\left(\cdot, d\right) \gets \pk$
 - Parse $(y, \pi) \gets \sigma$
 - Assert $\mathsf{AoK.Verify}\_\mathcal{R}(d, m, t, y; \pi) \equals 1$

$\mathsf{SMURF\_2.Derive}(\pk, m, \sigma) \rightarrow y$. 
 - Parse $(y, \pi) \gets \sigma$
 - Return $y$

{: .success}
**That's it!** This (theoretical) construction now achieves succinctness.

{: .warning}
We assume the $\mathsf{AoK}$ scheme is succinct and lacks a trusted setup.
However, this $\mathsf{SMURF\_2}$ scheme should still be interesting even if the $\mathsf{AoK}$ scheme requires a trusted setup.
After all, the trusted setup would only need to be redone to support a higher $n$ and would be reusable for any number of players $n_0 < n$.

### The relation

$\mathcal{R}(d, m, t, y; T, (\sigma_i)_{i\in T}, (\vk\_i)\_{i\in [n]}) = 1$ iff.:
 1. $\|T\| \equals t$ and $T\stackrel{?}{\subseteq} [n]$ 
 1. $\mathsf{Commit}(\\{\vk_i\ \vert\ i\in [n]\\}) \equals d$
 1. $\forall i\in T, \mathsf{SMURF\_1.ShareVer}(\vk_i, m, \sigma_i) \equals 1$.
 1. Let $\\{i_1, \ldots i_t\\} \gets T$
 1. Let $\\{j_1,\ldots,j_{n-t}\\} \gets [n]\setminus T$
 1. $e_n(\sigma_{i_1}, \ldots, \sigma_{i_t}, \vk_{j_1},\ldots,\vk_{j_{n-t}}) \equals y$

## Conclusion & future work

If symmetric multilinear maps exist, then there exist SMURFs!
Unfortunately, if efficient SMURFs exist (or even their weaker, threshold variant), then efficient $n$-party non-interactive key exchange (NIKE) exists[^guru].
(This explains why our two SMURF constructions are very similar to an $n$-party NIKE based on multilinear maps[^BS02e].)

**Future work:** 
 1. Proving our SMURF constructions secure.
 1. A SMURF with $O(1)$-sized aggregation keys.

**Acknowledgements:** Thanks to [Valeria Nikolaenko](https://twitter.com/lera_banda), [Joe Bonneau](https://twitter.com/josephbonneau), [Rex Fernando](https://twitter.com/rex1fernando), [Benny Pinkas](https://twitter.com/bennypinkas), [Dan Boneh](https://crypto.stanford.edu/~dabo/) and [Trisha Datta](https://twitter.com/TrishaCDatta) for reading, providing feedback and brainstorming together!

Big thanks to [Guru Vamsi Policharla](https://twitter.com/gvamsip) for pointing out that $t$-out-of-$n$ silent setup VUFs also imply $(n-t+1)$-NIKE.

## Appendix: Formalizing SMURFs

### Correctness definitions

<!-- aware of the thresholdized definition -->
**Correctness:** $\forall$ number of players $n$, $\forall$ thresholds $t\le n$, where $(\sk_j, \vk_j) \gets \mathsf{SMURF.KeyGen}(1^\lambda),\forall j\in[n]$ and $(\pk,\ak) \gets \mathsf{SMURF.AggPubkey}(t, (\vk\_j)\_{j\in[n]})$, for any subset $T\subset[n]$, where $|T| \ge t$, $\forall$ messages $m$, $\sigma_i \gets \mathsf{SMURF.ShareSign}(\sk_i, m),\forall i\in T$, $\sigma \gets \mathsf{SMURF.AggSig}(\ak, m, (\sigma_i)_{i\in T})$ we have:
\begin{align\*}
\forall i\in T,\mathsf{SMURF.ShareVer}(\vk_i, m, \sigma_i) &= 1 \wedge {}\\\\\
\mathsf{SMURF.Verify}(\pk, m, \sigma) &= 1 \wedge {}\\\\\
\mathsf{SMURF.Derive}(\pk, m, \sigma) &= \mathsf{SMURF.Eval}(t, (\vk\_j)\_{j\in [n]}, m)
\end{align\*}

{: .info}
**Note:** This implies that, for a correctly-generated $t$-out-of-$n$ threshold PK from $n$ VKs, if a signature pases verification via $\mathsf{SMURF.Verify}$, then calling $\mathsf{SMURF.Derive}$ on it would yield the same result as calling $\mathsf{SMURF.Eval}$ on the same message, the same $n$ VKs and the same threshold $t$.

<!-- agnostic of the thresholdized definition -->
**Uniqueness:**
For all polynomial time adversaries $\Adv$, for any number of players $n=\poly(\lambda)$, for any threshold $t\le n$, we have:
\begin{align\*}
\Pr\begin{bmatrix}
(\pk, m, (\sigma_i)_{i\in[2]} \gets \Adv(1^\lambda),\\\\\
(y_i \gets \mathsf{SMURF.Derive}(\pk, m, \sigma_i))\_{i\in[2]}
:\\\\\
y_1 \ne y_2 \wedge \forall i\in [2], \mathsf{SMURF.Verify}(\pk, m, \sigma_i) = 1
\end{bmatrix} = \negl(\lambda)
\end{align\*}

{: .info}
_Uniqueness_ says that an adversary is not able to produce two signatures for the same message that both verify against a threshold PK yet derive different outputs.
This particular definition is rather strong, since it allows the adversary to produce the PK adversarially.

### Oracle

In order to define security of a SMURF, we will need to **define** an oracle that the adversary can query as he attempts to break the scheme.
The oracle will allow the adversary to:

 1. Create new players
 2. Corrupt players
 3. Request signature shares from uncorrupted players

This helps formally model the power of the adversary in the multiverse setting in which the SMURF is supposed to remain secure.

**How does the oracle work?** First, the oracle $\mathcal{O}$ maintains some _state_:

 - the total number of players so far $N$, initially zero
 - the list $L$ of players and their key pairs, initially empty
 - the set $H$ of honest players, initially empty
 - the set $M$ of malicious players, initially empty
 - for any message $m$, the set $Q_m$ of players who have been queried for a signature share on $m$ by the adversary; initially, $Q_m = \varnothing,\forall m$

Then, the oracle handles the following requests from the adversary $\Adv$:

$\mathcal{O}.\mathsf{KeyGen}() \rightarrow (i, \pk)$:
 - $(\sk, \pk)\gets \mathsf{SMURF.KeyGen}(1^\lambda)$
 - $i \gets N$ and $N \gets N+1$
 - $L \gets L \cup \\{(i, \sk, \pk)\\}$
 - $H \gets H \cup \\{i\\}$
 - return $(i, \pk)$

{: .info}
This generates a new player numbered $i$, adds it to the list $L$ and marks it as honest in $H$.

$\mathcal{O}.\mathsf{CorruptPlayer}(i) \rightarrow \sk$:
 - if $\exists (i, \sk, \cdot) \in L$, then:
    + $H \gets H \setminus \\{i\\}$
    + $M \gets M \cup \\{i\\}$
    + return $\sk$
 - else:
    + return $\bot$

{: .info}
This checks if player $i$ actually exists and, if so, corrupts it by revealing their SK.
The player is marked as malicious by adding it to $M$ and removing it from $H$.

$\mathcal{O}.\mathsf{ShareSign}(i, m) \rightarrow \sigma_i$:
 - if $\exists (i, \sk, \cdot) \in L$ and $i\in H$, then:
    - $Q_m \gets Q_m \cup \\{i\\}$
    - return $\mathsf{SMURF.ShareSign}(\sk, m)$
 - else:
    + return $\bot$

{: .info}
This returns a signature share $m$ from player $i$, assuming $i$ is honest.
The oracle tracks the set of signature queries by adding $i$ to $Q_m$.

### Security definitions

Now that we've defined the oracle, we can meaningfully define security as follows.

<!-- aware of the thresholdized definition -->
**Unforgeability:**
For all polynomial time adversaries $\Adv$ with oracle access to $\mathcal{O}$:

\begin{align\*}
\Pr\begin{bmatrix}
(t, (\vk_{i\in[n]}), m, \sigma) \gets \Adv^\mathcal{O}(1^\lambda),\\\\\
(\pk,\cdot) \gets \mathsf{SMURF.AggPubkey}(t, (\vk_{i\in[n}))
:\\\\\
\mathsf{SMURF.Verify}(\pk, m, \sigma) = 1 \wedge 
\|Q_m\| < t
\end{bmatrix} = \negl(\lambda)
\end{align\*}


<!-- aware of the thresholdized definition -->
**Unpredictability:**
For all polynomial time adversaries $\Adv$ with oracle access to $\mathcal{O}$:

\begin{align\*}
\Pr\begin{bmatrix}
(t, (\vk_{i\in[n]}), m, y) \gets \Adv^\mathcal{O}(1^\lambda),\\\\\
(\pk,\cdot) \gets \mathsf{SMURF.AggPubkey}(t, (\vk_{i\in[n}))
:\\\\\
\mathsf{SMURF.Eval}(t, (\vk_i)_{i\in[n]}, m) = y \wedge \|Q_m\| < t 
\end{bmatrix} = \negl(\lambda)
\end{align\*}
<!-- the following probability is negligible in $\lambda$: -->
<!-- of $\Adv$ winning the following $\text{GAME}_\Adv^\mathsf{predict}(\lambda, t, n)$ -->

{: .warning}
**Unpredictability** must be defined to prevent _trivial_ instantiations.
Otherwise, for example, the signature $\sigma$ could be any _non-unique_ multiverse signature (e.g., BLS multisignatures with proofs-of-possession) while $\mathsf{SMURF.Derive}$ could always _uniquely_ set the VUF output to $y=\bot$.
Such a trivial scheme is excluded by our **unpredictability** definition.

---

[^drand]: [https://drand.love/](https://drand.love/)
[^flow]: [Flow's DKG](https://developers.flow.com/networks/staking/qc-dkg)
[^guru]: Big thanks to [Guru Vamsi Policharla](https://twitter.com/gvamsip) for this observation during the [3rand workshop](https://hub.supra.com/3rand#home3rand)!
[^higher-than-n]: A multilinear map of size $n' > n$ inputs would also work by forcing the last $n' - n$ inputs to be some predetermined values from a common-reference string.
[^multiverse]: This gets into the recently-introduced notion of a **multiverse signature scheme**, where players can enter and leave as they please, allowing for any subset of the current $N$ players to form a $t$-out-of-$n$ committee (for any $t,n$ with $n \le N$).
[^roll]: **Roll with Move: Secure, instant randomness on Aptos**, by Alin Tomescu and Zhuolun Xiang, 2024, [URL](https://aptoslabs.medium.com/roll-with-move-secure-instant-randomness-on-aptos-c0e219df3fb1)
[^sudoku]: [What is a ZK proof?](https://twitter.com/alinush/status/1661461336797380611), Alin Tomescu
[^sui]: [Sui DKG](https://blog.sui.io/secure-native-randomness-testnet/)
[^vdf]: Although **verifiable delay functions (VDFs)** also give rise to efficient distributed randomness beacons, we do not of VDF-based beacons that are _responsive_: i.e., they produce beacon values as fast as the network speed.

{% include refs.md %}
