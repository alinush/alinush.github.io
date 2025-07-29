---
tags:
- bilinear maps (pairings)
- encryption
- math
title: Pairings or bilinear maps
date: 2022-12-31 20:45:59
permalink: pairings
#published: false
sidebar:
    nav: cryptomat
---

<!-- TODO: Add example of pairing (insecure). -->

{: .info}
**tl;dr:** _Pairings_, or _bilinear maps_, are a very powerful mathematical tool for cryptography.
Pairings gave us our most succinct zero-knowledge proofs[^GGPR12e]$^,$[^PGHR13e]$^,$[^Grot16], our most efficient threshold signatures[^BLS01], our first usable identity-based encryption (IBE)[^BF01] scheme, and many other efficient cryptosystems[^KZG10].
In this post, I'll teach you a little about the properties of pairings, their cryptographic applications and their fascinating history.
In fact, by the end of this post, [some of you might want to spend a year or two in jail](#history).

{: .warning}
**Twitter correction:** The [original tweet announcing this blog post](https://twitter.com/alinush407/status/1612518576862408705) stated that _"**S**NARKs would not be possible without [pairings]"_, with the highlighted **S** meant to emphasize the "succinctness" of such SNARKs. However, [thanks to several folks on Twitter](#acknowledgements), I realized this is **not** exactly true and depends on what one means by "succinct." Specifically, "succinct" SNARKs, in the _polylogarithmic proof size_ sense defined by Gentry and Wichs[^GW10], exist from a plethora of assumptions, including discrete log[^BCCplus16] or random oracles[^Mica98]. Furthermore, "succinct" SNARKs, in the sense of $O(1)$ group elements proof size, exist from RSA assumptions too[^LM18]. What pairings do give us, currently, are SNARKs with the smallest, concrete proof sizes (i.e., in # of bytes).

<p hidden>$$
\def\idt{\mathbb{1}_{\Gr_T}}
\def\msk{\mathsf{msk}}
\def\dsk{\mathsf{dsk}}
\def\mpk{\mathsf{mpk}}
$$</p>

## Preliminaries

 - You are familiar with cyclic groups of prime order (e.g., elliptic curves)
 - Let $$\idt$$ denote the identity element of the group $\Gr_T$
 - Let $x \randget S$ denote randomly sampling an element $x$ from a set $S$
 - Recall that $\langle g \rangle = \Gr$ denotes $g$ being a generator of the group $\Gr$

## Definition of a pairing

A _pairing_, also known as a _bilinear map_, is a function $e : \Gr_1 \times \Gr_2 \rightarrow \Gr_T$ between three groups $\Gr_1, \Gr_2$ and $\Gr_T$ of prime order $p$, with generators $g_1 = \langle \Gr_1 \rangle, g_2 = \langle \Gr_2 \rangle$ and $g_T = \langle \Gr_T \rangle$, respectively.

When $\Gr_1 = \Gr_2$, the pairing is called **symmetric**. Otherwise, it is **asymmetric**.

Most importantly, a pairing has two useful properties for cryptography: _bilinearity_ and _non-degeneracy_.
<!--more-->

### Bilinearity

_Bilinearity_ requires that, for all $u\in\Gr_1$, $v\in\Gr_2$, and $a,b\in\Zp$:

$$e(u^a, v^b) = e(u, v)^{ab}$$

{: .warning}
For cryptography purposes, this is the **coolest** property. For example, this is what enables useful applications like [tripartite Diffie-Hellman](#tripartite-diffie-hellman).

### Non-degeneracy

_Non-degeneracy_ requires that:

$$e(g_1, g_2) \ne \idt$$

{: .info}
**Why this property?** We want non-degeneracy because, without it, it is simple (and useless) to define a (degenerate) bilinear map that, for every input, returns $\idt$. Such a map would satisfy bilinearity, but would be completely useless.

### Efficiency

_Efficiency_ requires that there exists a polynomial-time algorithm in the size of a group element (i.e.; in $\lambda = \log_2{p}$) that can be used to evaluate the pairing $e$ on any inputs.

<details>
<summary><b>Why this requirement?</b> It precludes trivial-but-computationally-intractable pairings. <i>(Click to expand.)</i></summary>
<p markdown="1" style="margin-left: .3em; border-left: .15em solid black; padding-left: .5em;">
For example, let $r$ be a random element in $\Gr_T$.
First, the pairing is defined so that $e(g_1, g_2) = r$.
This way, the pairing satisfies _non-degeneracy_.
<br /><br />

Second, given $(u,v)\in \Gr\_1 \times \Gr\_2$, an algorithm could spend exponential time $O(2^\lambda)$ to compute the discrete logs $x = \log\_{g\_1}{(u)}$ and $y = \log\_{g\_2}{(v)}$ and return $e(u, v) = e(g_1^x, g_2^y) = r^{xy}$.
This way, the pairing satisfies _bilinearity_ because:
<br /><br />

\begin{align}
e(u^a, v^b)
    &= e\left((g_1^x)^a, (g_2^y)^b\right)\\\\\
    &= e\left(g_1^{(ax)}, g_2^{(by)}\right)\\\\\
    &= r^{(ax)\cdot (by)}\\\\\
    &= \left(r^{xy}\right)^{ab}\\\\\
    &= e(u, v)^{ab}
\end{align}
</p>
</details>

## History

{: .warning}
This is my limited historical understanding of pairings, mostly informed from [Dan Boneh's account in this video](https://www.youtube.com/watch?v=1RwkqZ6JNeo) and from my own research into the relevant literature. Please email me if you are aware of more history and I can try to incorporate it.

### A mathematician in prison

The history of (cryptographic) pairings begins with a mathematician named **André Weil**[^Wiki22Weil] who, during World War II, is sent to jail for refusing to serve in the French army.
There, Weil, _"managed to convince the liberal-minded prison director to put [him] in an individual cell where [he] was allowed to keep [..] a pen, ink, and paper."_

Weil used his newly-acquired tools to define a pairing across two elliptic curve groups.
**However**, what was **very odd** at that time was that Weil put in a lot of effort to make sure his definition of a pairing is _computable_.
And this extra effort is what made today's pairing-based cryptography possible[^danboneh-shimuranote].

### Go to prison, not to university?

Funnily, Weil's time in jail was so productive that he began wondering if he should spend a few months there every year.
Even better, Weil contemplated if he should **recommend to the relevant authorities that every mathematician spend some amount of time in jail.**
Weil writes:
 
 > I'm beginning to think that nothing is more conducive to the abstract sciences than prison.
 >
 > [...]
 >
 > My mathematics work is proceeding beyond my wildest hopes, and I am even a bit worried - if it's only in prison that I work so well, will I have to arrange to spend two or three months locked up every year? 
 >
 > In the meantime, I am contemplating writing a report to the proper authorities, as follows: _"To the Director of Scientific Research: Having recently been in a position to discover through personal experience the considerable advantages afforded to pure and disinterested research by a stay in the establishments of the Penitentiary System, I take the liberty of, etc. etc."_

You can read all of this and more in his fascinating autobiography, written from his perspective as a mathematician[^Weil92].

Also, you can see Dan Boneh's funny account of this story in his 2015 Simons talk:

<iframe width="560" height="315" src="https://www.youtube.com/embed/1RwkqZ6JNeo?si=_37rPSav99GpYbz0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

### From breaking cryptography to building cryptography

Weil's work was the foundation. 
But three more developments were needed for pairing-based cryptography to rise.

#### First development: Miller's algorithm

In 1985, **Victor Miller** writes up a manuscript showing that Weil's pairing, which actually involves evaluating a polynomial of exponential degree, can in fact be computed efficiently in polynomial time[^Mill86Short].


In December 1984, Miller gave a talk at IBM about elliptic curve cryptography where he claimed that elliptic curve discrete logs were more difficult to compute than ordinary discrete logs over finite fields[^miller-talk].
Miller was challenged by Manuel Blum, who was in the audience, to back up this claim by giving a [reduction](https://en.wikipedia.org/wiki/Reduction_(complexity)): i.e., showing that an algorithm $B$ for solving discrete log on elliptic curves can be efficiently turned into another algorithm $A$ for solving discrete logs in finite fields.
Such a reduction would imply the problem solved by $B$ (i.e., computing elliptic curve discrete logs) is at least as hard, if not harder, than $A$'s problem (i.e., computing finite field discrete logs).

Miller set out to find a reduction by thinking about the only thing that related an elliptic curve group and a finite field: the Weil pairing.
Funnily, what he quickly realized was that, although the Weil pairing gives a reduction, it's in the opposite direction: i.e., it turned out an algorithm $A$ for discrete log in finite fields could be efficiently turned into an algorithm $B$ for discrete logs in elliptic curves with the help of the Weil pairing.
This "unwanted" reduction is easy to see.
Since $e(g^a, g) = e(g,g)^a$, solving discrete log on the elliptic curve element $g_a\in \Gr$ is just a matter of solving it on $e(g,g)^a\in \Gr_T$, which is actually a multiplicative subgroup of a finite field (see [the inner details of pairings](#how-do-pairings-actually-work)).

This almost showed the opposite of what Miller sought to prove, potentially destroying elliptic curve cryptography, but fortunately the degree of the extension field that the Weil pairing mapped into was too large, making this "unwanted" reduction inefficient and thus not a reduction after all.

This whole affair got Miller interested in seeing if the Weil pairing could be computed efficiently, which led to the discovery of his algorithm.
Interestingly, he submitted this manuscript to FOCS, a top theoretical computer science conference, but the paper got rejected and would not be published until much later in the Journal of Cryptology (according to Miller)[^alin-where].


#### Second development: MOV attack

In 1991, **Menezes, Vanstone and Okamoto**[^MVO91] leverage Miller's efficient algorithm for evaluating the Weil pairing to break the discrete logarithm assumption on certain elliptic curves **in sub-exponential time**.
This was quite amazing since, at that time, no sub-exponential time algorithms were known for elliptic curves.

{: .info}
Their attack, called the _MOV attack_, mapped an elliptic curve discrete logarithm challenge $g^a\in \Gr$ into a **target group** as $e(g^a, g)=e(g,g)^a \in \Gr_T$ using the pairing.
Since the target group was a subgroup of a finite field $\mathbb{F}_q^{k}$, this allowed the use of faster, sub-exponential time algorithms for computing the discrete log on $e(g,g)^a$.

#### Third development: Joux's tripartite Diffie-Hellman
So far, pairings only seemed useful for **cryptanalysis.** 
No one knew how to use them for building (instead of breaking) cryptography.

This changed in 2000, when **Joux**[^Joux00] used pairings to implement a 1-round key-exchange protocol between three parties, or [tripartite Diffie-Hellman](#tripartite-diffie-hellman).
Previously, such 1-round protocols were only known between two parties while three parties required 2 rounds.

From there, an abundance of new, efficient cryptography started pouring over:

 - BLS (short) signatures[^BLS01]
 - identity-based encryption[^BF01]
 - additively-homomorphic encryption with support for one multiplication[^BGN05]
 - succinct zero-knowledge proofs[^GGPR12e]

{: .info}
An interesting pattern to notice here is how pairings evolved from a _cryptanalytic tool_ used to break cryptosystems, to a **constructive tool** used to build cryptosystems.
Interestingly, the same pattern also arose in the development of lattice-based cryptography.

## Arithmetic tricks with pairings

There are a few tricks cryptographers often use when dealing with pairings in their proofs of correctness or security of a cryptosystem.

The most obvious trick, **"multiplying in the exponent"**, comes from the bilinearity property.

\begin{align}
e(u^a, v^b) = e(u, v)^{ab}
\end{align}

Bilinearity also implies the following trick:
\begin{align}
e(u, v^b) = e(u, v)^b
\end{align}
Or, alternatively:
\begin{align}
e(u^a, v) = e(u, v)^a
\end{align}

Another trick, which is just an analogous way of defining bilinearity, is:
\begin{align}
e(u, v\cdot w) = e(u, v)\cdot e(u, w)
\end{align}

{: .info}
**Why does this work?** Let $y,z$ denote the discrete logs (w.r.t. $g_2$) of $v$ and $w$, respectively.
Then, we have:
\begin{align}
e(u, v\cdot w) 
    &= e(u, g_2^y \cdot g_2^z)\\\\\
    &= e(u, g_2^{y + z})\\\\\
    &= e(u, g_2)^{y + z}\\\\\
    &= e(u, g_2)^y \cdot e(u, g_2)^z\\\\\
    &= e(u, g_2^y) \cdot e(u, g_2^z)\\\\\
    &= e(u, v)\cdot e(u, w)
\end{align}

Or, alternatively:
\begin{align}
e(u, v / w) = \frac{e(u, v)}{e(u, w)}
\end{align}

## Applications of pairings

### Tripartite Diffie-Hellman

This protocol was introduced by Joux in 2000[^Joux00] and assumes a **symmetric pairing**: i.e., where $$\Gr_1 = \Gr_2 = \langle g\rangle \stackrel{\mathsf{def}}{=} \Gr$$. 

We have three parties Alice, Bob and Charles with secret keys $a, b$, and $c$ (respectively).
They send each other their public keys $g^a, g^b, g^c$ and agree on a shared secret key $k = e(g, g)^{abc}$.[^dhe]

How? 

Consider Alice's point of view.
She gets $g^b$ and $g^c$ from Bob and Charles. 
First, she can use her secret $a$ to compute $g^{ab}$. 
Second, she can use the pairing to compute $e(g^{ab}, g^c) = e(g, g)^{abc} = k$. 

By symmetry, all other players can do the same and agree on the same $k$.

{: .info}
The protocol can be generalized to [**a**symmetric pairings](#asymmetric-pairings) too, where $\Gr_1 \neq \Gr_2$.

### BLS signatures

Boneh, Lynn and Shacham give a very short signature scheme from pairings[^BLS01], which works as follows:

- Assume $\Gr\_2 = \langle g_2 \rangle$ and that there exists a hash function $H : \\{0,1\\}^\* \rightarrow \Gr\_1$ modeled as a random oracle.
 - The secret key is $s \in \Zp$ while the public key is $\pk = g\_2^s \in \Gr\_2$.
 - To sign a message $m$, the signer computes $\sigma = H(m)^s\in \Gr\_1$.
 - To verify a signature $\sigma$ on $m$ under public key $\pk$, one checks if $e(\sigma, g_2) \stackrel{?}{=} e(H(m), \pk)$

Notice that correctly-computed signatures will always verify since:
\begin{align}
e(\sigma, g_2) \stackrel{?}{=} e(H(m), \pk) \Leftrightarrow\\\\\
e(H(m)^s, g_2) \stackrel{?}{=} e(H(m), g_2^s) \Leftrightarrow\\\\\
e(H(m), g_2)^s \stackrel{?}{=} e(H(m), g_2)^s \Leftrightarrow\\\\\
e(H(m), g_2) = e(H(m), g_2)
\end{align}

See the BLS paper[^BLS01] for how to prove that no attacker can forge BLS signatures given access to $\pk$ and a signing oracle.

#### Cool properties of BLS signatures

BLS signatures are quite amazing:

1. They are one of the **simplest** schemes to implement, given access to an elliptic-curve library. 
1. One can **aggregate** many signatures from different public keys on the same message $m$ into a single _multi-signature_ that continues to verify using just 2 pairings. 
1. One can even **aggregate** such signatures across different messages into a single _aggregate signature_.
    + However, such aggregate signatures take $n+1$ pairings to verify. 
1. One can easily and efficiently[^TCZplus20] build a **threshold** BLS signature scheme, where any subset of $\ge t$ out of $n$ signers can collaborate to sign a message $m$ but no less than $t$ can ever produce a valid signature. 
    + Even better, BLS threshold signatures are **deterministic** and give rise to _threshold verifiable random functions (VRFs)_ which are useful for generating randomness on chain.
1. One can define very-efficient **blind**-variants of BLS signatures, where the signer can sign a message $m$ without learning the message $m$.
1. BLS signatures are very **efficient** in practice.
    - As far as I remember, they are the most efficient scheme for (1) multi-signatures, (2) aggregate signatures and (3) threshold signatures
    - For single-signer BLS, they are slower than Schnorr signatures over non-pairing-friendly curves

{: .warning}
If you find yourself confused between the various notions of multi-signatures, aggregate signatures and threshold signatures, see [my slides](https://docs.google.com/presentation/d/1G4XGqrBLwqMyDQce_xpPQUEMOK4lFrneuvGYU3MVDsI/edit?usp=sharing).

### Identity-based encryption (IBE)

In an IBE scheme, one can encrypt directly to a user-friendly email address (or a phone number), instead of a cumbersome public key which is difficult to remember or type-in correctly.

Boneh and Franklin give a very efficient IBE scheme from pairings[^BF01].

For IBE to work, a trusted third-party (TTP) called a **private key generator (PKG)** must be introduced, who will issue secret keys to users based on their email addresses.
This PKG has a **master secret key (MSK)** $\msk \in \Zp$ with an associated **master public key (MPK)** $\mpk = g_2^\msk$, where $\langle g_2 \rangle = \Gr_2$.

The $\mpk$ is made public and can be used to encrypt a message to any user given their email address.
Crucially, the PKG must keep the $\msk$ secret.
Otherwise, an attacker who steals it can derive any user's secret key and decrypt everyone's messages.

{: .warning}
As you can tell the PKG is a central point of failure: theft of the $\msk$ compromises everyone's secrecy.
To mitigate against this, the PKG can be decentralized into multiple authorities such that a threshold number of authorities must be compromised in order to steal the $\msk$.

Let $H_1 : \\{0,1\\}^\* \rightarrow \Gr_1^\*$ and $H_T : \Gr_T \rightarrow \\{0,1\\}^n$ be two hash functions modeled as random oracles.
To encrypt an $n$-bit message $m$ to a user with email address $id$, one computes:
\begin{align}
    \pk_{id} &= e(H_1(id), \mpk) \bydef e(H_1(id), g_2)^{\msk}\in \Gr_T\\\\\
    r &\randget \Zp\\\\\
    \label{eq:ibe-ctxt}
    c &= \left(
        \underbrace{g_2^r}\_{u}, 
        \underbrace{m \xor H_T\left(\left(\pk_{id}\right)^r\right)}\_{v}
    \right) 
    \in \Gr_2\times \\{0,1\\}^n
\end{align}

**Note:** Later on, we'll use $(\pk_{id})^r = e(H_1(id), g_2^{\msk})^r = e(H_1(id), g_2^r)^\msk = e(H_1(id)^\msk, u) \bydef e(\dsk_{id}, u)$, where $\dsk_{id}$ will be the **decryption secret key** for $id$.

To decrypt, the user with email address $id$ must first obtain their **decryption secret key** $\dsk_{id}$ from the PKG.
For this, we assume the PKG has a way of authenticating the user, before handing them their secret key. 
For example this could be done via email.

The PKG computes the user's decryption secret key as:
\begin{align}
    \dsk_{id} = H_1(id)^\msk \in \Gr_1
\end{align}

Now that the user has their decryption secret key, they can decrypt the ciphertext $c = (u, v)$ from Equation $\ref{eq:ibe-ctxt}$ as:
\begin{align}
    m &= v \xor H_T(e(\dsk_{id}, u))
\end{align}

You can see why correctly-encrypted ciphertexts will decrypt successfully, since:
\begin{align}
v \xor H_T(e(\dsk_{id}, u))
    &= \left(m \xor H_T\left((\pk_{id})^r\right)\right) \xor H_T\left(e(H_1(id)^\msk, g_2^r)\right)\\\\\
    &= m \xor H_T\left((\pk_{id})^r\right) \xor H_T\left(e(H_1(id), g_2^\msk)^r\right)\\\\\
    &= m \xor H_T\left((\pk_{id})^r\right) \xor H_T\left(e(H_1(id), \mpk)^r\right)\\\\\
    &= m \xor H_T\left((\pk_{id})^r\right) \xor H_T\left((\pk_{id})^r\right)\\\\\
    &= m
\end{align}

To see why this scheme is secure under chosen-plaintext attacks, refer to the original paper[^BF01].

## How do pairings actually work?

Mostly, I have no idea.
How come?
Well, I never really needed to know.
And that's the beauty of pairings: one can use them in a black-box fashion, with zero awareness of their internals.

Still, let's take a small peek inside this black box. 
Let us consider the popular pairing-friendly _BLS12-381_ curve[^Edgi22], from the family of BLS curves characterized by Barreto, Lynn and Scott[^BLS02e].

{: .warning}
**Public service announcement:**
Some of you might've heard about _Boneh-Lynn-Shacham (BLS)_ signatures. Please know that this is a different BLS than the BLS in _Barretto-Lynn-Scott_ curves. Confusingly, both acronyms do share one author, Ben Lynn. (In case this was not confusing enough, wait until you have to work with BLS signatures over BLS12-381 curves.)

For BLS12-381, the three groups $\Gr\_1, \Gr\_2, \Gr\_T$ involved are:

 - The group $\Gr_1$ is a subgroup of an elliptic curve $E(\F_q) = \left\\{(x, y) \in (\F\_q)^2\ \vert\ y^2 = x^3 + 4 \right\\}$ where $\vert\Gr_1\vert = p$
 - The group $\Gr_2$ is a subgroup of a different elliptic curve $E'(\F_{q^2}) = \left\\{(x, y) \in (\F\_{q^2})^2\ \vert\ y^2 = x^3 + 4(1+i) \right\\}$ where $i$ is the square root of $-1$ and $\vert\Gr_2\vert = p$.
 - The group $\Gr_T$ are all the $p$th roots of unity in $\F_{q^{k}}$, where $k=12$ is called the _embedding degree_

How does the pairing map across these three groups work? Well, the pairing $e(\cdot,\cdot)$ expands to something like:
\begin{align}
\label{eq:pairing-def}
e(u, v) = f_{p, u}(v)^{(q^k - 1)/p}
\end{align}
It's useful to know that computing a pairing consists of two steps:

1. Evaluating the base $f_{p, u}(v)$, also known as a **Miller loop**, in honor of [Victor Miller's work](#history)
2. Raising this base to the constant exponent $(q^k - 1)/p$, also known as a **final exponentiation**.
    - This step is a few times more expensive than the first

For more on the internals, see other resources[^Cost12]$^,$[^GPS08]$^,$[^Mene05].

## Implementing pairing-based crypto

This section discusses various implementation-level details that practitioners can leverage to speed up their implementations.

### Use asymmetric pairings!

The pairing over BLS12-381 is _**a**symmetric_: i.e., $\Gr_1 \ne \Gr_2$ are two **different** groups (of the same order $p$). However, there also exist **symmetric** pairings where $\Gr_1 = \Gr_2$ are the same group.

Unfortunately, _"such symmetric pairings only exist on supersingular curves, which places a heavy restriction on either or both of the underlying efficiency and security of the protocol"_[^BCMplus15e].
In other words, such supersingular curves are not as efficient at the same security level as the curves used in **a**symmetric pairings.

Therefore, practitioners today, as far as I am aware, exclusively rely on **a**symmetric pairings due to their higher efficiency when the security level is kept the same.

### BLS12-381 performance

I will give a few key performance numbers for the BLS12-381 curve implemented in Filecoin's [blstrs](https://github.com/filecoin-project/blstrs) Rust wrapper around the popular [blst](https://github.com/supranational/blst) library.
These microbenchmarks were run on a 10-core 2021 Apple M1 Max using `cargo bench`.

#### Pairing computation times

<!--
	alinush@MacBook [~/repos/blstrs] (master %) $ cargo +nightly bench -- pairing_
	running 4 tests
	test bls12_381::bench_pairing_final_exponentiation     ... bench:     276,809 ns/iter (+/- 1,911)
	test bls12_381::bench_pairing_full                     ... bench:     484,718 ns/iter (+/- 2,510)
	test bls12_381::bench_pairing_g2_preparation           ... bench:      62,395 ns/iter (+/- 4,161)
	test bls12_381::bench_pairing_miller_loop              ... bench:     148,534 ns/iter (+/- 1,203)
-->

As explained in Eq. \ref{eq:pairing-def}, a pairing involves two steps:

 - a Miller loop computation
    - 210 microseconds
 - a final exponentiation
    - 276 microseconds

Therefore, a pairing takes around 486 microseconds (i.e., the sum of the two).

{: .info}
The Miller loop is actually two steps: (1) a G2 point "preparation", which takes 62 microseconds and (2) the actual loop which takes 148 microseconds.

#### Group multiplication times

<!--
alinush@Aptos-MacBook [~/repos/blstrs/benches] (master *) $ cargo bench -- _add

test bls12_381::ec::g1::bench_g1_add_assign            ... bench:         571.84 ns/iter (+/- 15.35)
test bls12_381::ec::g1::bench_g1_add_assign_mixed      ... bench:         443.40 ns/iter (+/- 20.77)
test bls12_381::ec::g2::bench_g2_add_assign            ... bench:       1,505.08 ns/iter (+/- 80.49)
test bls12_381::ec::g2::bench_g2_add_assign_mixed      ... bench:       1,170.71 ns/iter (+/- 12.09)
test bls12_381::ec::gt::bench_gt_add_assign            ... bench:       1,617.53 ns/iter (+/- 44.66)
test bls12_381::scalar::bench_scalar_add_assign        ... bench:           3.06 ns/iter (+/- 0.01)

 -->

 - $\Gr_1$ multiplications (recall we are using multiplicative notation for groups, not additive notation)
   - Normal: 565 nanoseconds (when both points are in projective $(X, Y)$ coordinates)
   - Mixed: 438 nanoseconds (when first point is in projective coordinates, second is in affine $(X, Y, Z)$ coordinates)
       - Faster, because saves one projective-to-affine conversion
 - $\Gr_2$ multiplications
   - Normal: 1,484 nanoseconds
   - Mixed: 1,095 nanoseconds
 - $\Gr_T$ multiplications
   - 1,617 nanoseconds

#### Group exponentiation times

{: .warning}
The $\Gr_T$ microbenchmarks were done by slightly-modifying the `blstrs` benchmarking code [here](https://github.com/filecoin-project/blstrs/blob/e70aff6505fb6f87f9a13e409c080995bd0f244e/benches/bls12_381/ec.rs#L10).
(See the HTML comments of this page for those modifications.)

<!--
	alinush@MacBook [~/repos/blstrs] (master *%) $ git diff
	diff --git a/benches/bls12_381/ec.rs b/benches/bls12_381/ec.rs
	index 639bcad..8dcec20 100644
	--- a/benches/bls12_381/ec.rs
	+++ b/benches/bls12_381/ec.rs
	@@ -167,3 +167,34 @@ mod g2 {
			 });
		 }
	 }
	+
	+mod gt {
	+    use rand_core::SeedableRng;
	+    use rand_xorshift::XorShiftRng;
	+
	+    use blstrs::*;
	+    use ff::Field;
	+    use group::Group;
	+
	+    #[bench]
	+    fn bench_gt_mul_assign(b: &mut ::test::Bencher) {
	+        const SAMPLES: usize = 1000;
	+
	+        let mut rng = XorShiftRng::from_seed([
	+            0x59, 0x62, 0xbe, 0x5d, 0x76, 0x3d, 0x31, 0x8d, 0x17, 0xdb, 0x37, 0x32, 0x54, 0x06,
	+            0xbc, 0xe5,
	+        ]);
	+
	+        let v: Vec<(Gt, Scalar)> = (0..SAMPLES)
	+            .map(|_| (Gt::random(&mut rng), Scalar::random(&mut rng)))
	+            .collect();
	+
	+        let mut count = 0;
	+        b.iter(|| {
	+            let mut tmp = v[count].0;
	+            tmp *= v[count].1;
	+            count = (count + 1) % SAMPLES;
	+            tmp
	+        });
	+    }
	+}
	alinush@MacBook [~/repos/blstrs] (master *%) $ cargo +nightly bench -- mul_assign
	   Compiling blstrs v0.6.1 (/Users/alinush/repos/blstrs)
		Finished bench [optimized] target(s) in 0.75s
		 Running unittests src/lib.rs (target/release/deps/blstrs-349120dc60ef3711)

	running 2 tests
	test fp::tests::test_fp_mul_assign ... ignored
	test scalar::tests::test_scalar_mul_assign ... ignored

	test result: ok. 0 passed; 0 failed; 2 ignored; 0 measured; 115 filtered out; finished in 0.00s

		 Running benches/blstrs_benches.rs (target/release/deps/blstrs_benches-a6732e3e4e5c6a4d)

	running 4 tests
	test bls12_381::ec::g1::bench_g1_mul_assign            ... bench:      72,167 ns/iter (+/- 1,682)
	test bls12_381::ec::g2::bench_g2_mul_assign            ... bench:     136,184 ns/iter (+/- 1,300)
	test bls12_381::ec::gt::bench_gt_mul_assign            ... bench:     497,330 ns/iter (+/- 7,802)
	test bls12_381::scalar::bench_scalar_mul_assign        ... bench:          14 ns/iter (+/- 0)

	test result: ok. 0 passed; 0 failed; 0 ignored; 4 measured; 21 filtered out; finished in 5.30s
-->

 - $\Gr_1$ exponentiations are the fastest
    + 72 microseconds 
 - $\Gr_2$ exponentiations are around 2$\times$ slower
    + 136 microseconds
 - $\Gr_T$ exponentiations are around 3.5$\times$ slower than in $\Gr_2$
    + 500 microseconds 

{: .info}
**Note:** These benchmarks pick the exponentiated base randomly and do **not** perform any precomputation on it, which would speed up these times by $2\times$-$4\times$.

#### Multi-exponentiations

<!--
running 4 tests
test bls12_381::bench_g1_multi_exp                     ... bench:     760,554 ns/iter (+/- 47,355)
test bls12_381::bench_g1_multi_exp_naive               ... bench:  18,575,716 ns/iter (+/- 42,688)
test bls12_381::bench_g2_multi_exp                     ... bench:   1,876,416 ns/iter (+/- 58,743)
test bls12_381::bench_g2_multi_exp_naive               ... bench:  35,272,720 ns/iter (+/- 266,279)
-->

This is a well-known optimization that I'm including for completeness.

Specifically, many libraries allow you to compute a product $\prod_{0 < i < k} \left(g_i\right)^{x_i}$ of $k$ exponentiations much faster than individually computing the $k$ exponentiations and aggregating their product.
For example, [blstrs](https://github.com/filecoin-project/blstrs) seems to be incredibly fast in this regard.

For $\Gr_1$ multiexps:

| $\log_2{n}$ | Total time | Time / element | Speedup over single exp. | Speedup vs prev row. |
|-------------|-------------|----------------|---------------------------|------------------------|
| 0           | 73.55 µs    | 73.55 µs       |                           |                        |
| 1           | 142.99 µs   | 71.50 µs       | 1.02×                     | 1.03×                  |
| 2           | 206.86 µs   | 51.72 µs       | 1.41×                     | 1.38×                  |
| 3           | 334.42 µs   | 41.80 µs       | 1.75×                     | 1.24×                  |
| 4           | 700.69 µs   | 43.79 µs       | 1.67×                     | 0.95×                  |
| 5           | 273.83 µs   | 8.56 µs        | 8.53×                     | 5.12×                  |
| 6           | 389.79 µs   | 6.09 µs        | 11.99×                    | 1.41×                  |
| 7           | 540.48 µs   | 4.22 µs        | 17.29×                    | 1.44×                  |
| 8           | 843.50 µs   | 3.29 µs        | 22.16×                    | 1.28×                  |
| 9           | 1.43 ms     | 2.79 µs        | 26.16×                    | 1.18×                  |
| 10          | 2.22 ms     | 2.17 µs        | 33.67×                    | 1.29×                  |
| 11          | 3.83 ms     | 1.87 µs        | 39.08×                    | 1.16×                  |
| 12          | 6.04 ms     | 1.47 µs        | 49.49×                    | 1.27×                  |
| 13          | 12.66 ms    | 1.55 µs        | 47.23×                    | 0.95×                  |
| 14          | 21.98 ms    | 1.34 µs        | 54.41×                    | 1.15×                  |
| 15          | 38.77 ms    | 1.18 µs        | 61.69×                    | 1.13×                  |
| 16          | 69.67 ms    | 1.06 µs        | 68.67×                    | 1.11×                  |
| 17          | 123.28 ms   | 0.94 µs        | 77.61×                    | 1.13×                  |
| 18          | 232.56 ms   | 0.89 µs        | 82.29×                    | 1.06×                  |
| 19          | 454.43 ms   | 0.87 µs        | 84.22×                    | 1.02×                  |
| 20          | 852.31 ms   | 0.81 µs        | 89.81×                    | 1.07×                  |
| 21          | 1.72 s      | 0.82 µs        | 88.90×                    | 0.99×                  |

For $\Gr_2$ multiexps:

| $\log_2{n}$ | Total time | Time / element | Speedup over single exp. | Speedup vs prev row. |
|-------------|-------------|----------------|---------------------------|------------------------|
| 0           | 138.47 µs   | 138.47 µs      |                           |                        |
| 1           | 310.91 µs   | 155.46 µs      | 0.87×                     | 0.89×                  |
| 2           | 481.56 µs   | 120.39 µs      | 1.13×                     | 1.29×                  |
| 3           | 803.29 µs   | 100.41 µs      | 1.35×                     | 1.20×                  |
| 4           | 1.34 ms     | 83.75 µs       | 1.62×                     | 1.20×                  |
| 5           | 594.61 µs   | 18.58 µs       | 7.32×                     | 4.51×                  |
| 6           | 805.34 µs   | 12.58 µs       | 10.81×                    | 1.48×                  |
| 7           | 1.27 ms     | 9.94 µs        | 13.68×                    | 1.27×                  |
| 8           | 1.95 ms     | 7.63 µs        | 17.83×                    | 1.30×                  |
| 9           | 3.55 ms     | 6.93 µs        | 19.63×                    | 1.10×                  |
| 10          | 6.07 ms     | 5.92 µs        | 22.97×                    | 1.17×                  |
| 11          | 9.96 ms     | 4.87 µs        | 27.95×                    | 1.22×                  |
| 12          | 16.29 ms    | 3.98 µs        | 34.17×                    | 1.22×                  |
| 13          | 30.10 ms    | 3.68 µs        | 36.92×                    | 1.08×                  |
| 14          | 57.11 ms    | 3.49 µs        | 38.97×                    | 1.05×                  |
| 15          | 93.75 ms    | 2.86 µs        | 47.59×                    | 1.22×                  |
| 16          | 179.13 ms   | 2.73 µs        | 49.89×                    | 1.05×                  |
| 17          | 321.09 ms   | 2.45 µs        | 55.47×                    | 1.11×                  |
| 18          | 610.78 ms   | 2.33 µs        | 58.30×                    | 1.05×                  |
| 19          | 1.20 s      | 2.29 µs        | 59.29×                    | 1.02×                  |
| 20          | 2.27 s      | 2.17 µs        | 62.62×                    | 1.06×                  |
| 21          | 4.60 s      | 2.20 µs        | 61.89×                    | 0.99×                  |

#### Group element sizes

 - $\Gr_1$ group elements are the smallest
	+ e.g., 48 bytes for BLS12-381 or 32 bytes for BN254 curves[^BN06Pair]
 - $\Gr_2$ group elements are 2$\times$ larger
    + e.g., 96 bytes on BLS12-381
 - $\Gr_T$ elements are 12$\times$ larger
    + In general, for a pairing-friendly curve with _embedding degree_ $k$, they are $k$ times larger


#### Field operations

 - 2.65 ns / addition in $\F$
 - 14.08 ns / multiplication in $\F$

{: .note}
Multiplication is 5.3x slower than addition in $\F$.
(To rerun these benchmarks, see [this PR](https://github.com/aptos-labs/aptos-core/pull/17177))

#### Other operations
 - Hashing to $\Gr_1$ takes around 50 microseconds (not accounting for the extra time required to hash down larger messages using SHA2-256)

#### Switching between $\Gr_1$ and $\Gr_2$

When designing a pairing-based cryptographic protocol, you will want to carefully pick what to use $\Gr_1$ and what to use $\Gr_2$ for.

For example, in BLS signatures, if you want small signatures, then you would compute the signature $\sigma = H(m)^s \in \Gr_1$ and settle for a slightly-larger public key be in $\Gr_2$.
On the other hand, if you wanted to minimize public key size, then you would let it be in $\Gr_1$ while taking slightly longer to compute the signature in $\Gr_2$.

{: .warning}
Other things will also influence how you use $\Gr_1$ and $\Gr_2$, such as the existence of an isomorphism $\phi : \Gr_2 \rightarrow \Gr_1$ or the ability to hash uniformly into these groups.
In fact, the existence of such an isomorphism separates between two types of asymmetric pairings:  Type 2 and Type 3 (see *Galbraith et al.*[^GPS08] for more information on the different types of pairings)

#### Comparison to non-pairing-friendly elliptic curves

When compared to an elliptic curve that does not admit pairings, pairing-friendly elliptic curves are around two times slower.

For example, the popular prime-order elliptic curve group [Ristretto255](https://ristretto.group/) offers:

<!--
ristretto255/basepoint_mul
                        time:   [10.259 µs 10.263 µs 10.267 µs]

ristretto255/point_mul  time:   [40.163 µs 40.187 µs 40.212 µs]
-->

 - $\approx 2\times$ faster exponentiations of 40 microseconds
	+ which can be sped up to 10 microseconds, using precomputation when the exponentiation base is fixed
 - 32 byte group element sizes

### Multi-pairings

If you recall how a pairing actually works (see Eq. $\ref{eq:pairing-def}$), you'll notice the following optimization:

Whenever, we have to compute the product of $n$ pairings, we can first compute the $n$ Miller loops and do a single final exponentiation instead of $n$.
This drastically reduces the pairing computation time in many applications.
\begin{align}
\prod_i e(u_i, v_i)
    &= \prod_i \left(f_{p, u_i}(v_i)^{(q^k - 1)/p}\right)\\\\\
    &= \left(\prod_i f_{p, u_i}(v_i)\right)^{(q^k - 1)/p}
\end{align}


## Conclusion

This blog post was supposed to be just a short summary of the [three properties of pairings](#definition-of-a-pairing): bilinearity, non-degeneracy and efficiency.

Unfortunately, I felt compelled to discuss their [fascinating history](#history).
And I couldn't let you walk away without seeing a few powerful [cryptographic applications of pairings](#applications-of-pairings).

After that, I realized practitioners who implement pairing-based cryptosystems might benefit from knowing a little about their [internal workings](#how-do-pairings-actually-work), since some of these details can be leveraged to speed up [implementations](#implementation-details).

## Acknowledgements

I would like to thank Dan Boneh for helping me clarify and contextualize the history around Weil, as well as for [his 2015 Simons talk](https://www.youtube.com/watch?v=1RwkqZ6JNeo), which inspired me to do a little more research and write this historical account.

Big thanks to:

 - [Lúcás Meier](https://twitter.com/cronokirby), [Pratyush Mishra](https://twitter.com/zkproofs), [Ariel Gabizon](https://twitter.com/rel_zeta_tech) and [Dario Fiore](https://twitter.com/dariofiore0) for their enlightening points on what "succinct" (S) stands for in **S**NARKs[^GW10] and for reminding me that SNARKs with $O(1)$ group elements proof size exist from RSA assumptions[^LM18].
 - [Sergey Vasilyev](https://twitter.com/swasilyev) for pointing out typos in the BLS12-381 elliptic curve definitions. 
 - [@BlakeMScurr](https://twitter.com/BlakeMScurr) for pointing out an incorrect reference to Joux's work[^Joux00].
 - [Conrado Guovea](https://twitter.com/conradoplg) for pointing me to Victor Miller's account of how he developed his algorithm for evaluating the Weil pairing (discussed [here](#first-development-millers-algorithm)).
 - [Chris Peikert](https://twitter.com/ChrisPeikert) for pointing out that there are plenty-fast IBE schemes out there that do not rely on pairings[^DLP14e].

**PS:** Twitter threads are a pain to search through, so if I missed acknowledging your contribution, please kindly let me know.

---

[^dhe]: Typically, there will be some key-derivation function $\mathsf{KDF}$ used to derive the key as $k = \mathsf{KDF}(e(g,g)^{abc})$.

[^danboneh-shimuranote]: Thanks to Dan Boneh, who contrasted Weil's definition with a different one by Shimura from his classic book on modular forms. While Shimura's definition makes it much easier to prove all the properties of the pairing, it defines a pairing of order $n$ as a **sum of $n$ points of order $n^2$**. This makes it hopelessly non-computable. Weil's definition, on the other hand, involves an evaluation of a very concrete function -- there are no exponential-sized sums -- but requires much more work to prove all its pairing properties.

[^miller-talk]: Miller tells this story himself in [a talk he gave at Microsoft Research](https://www.youtube.com/watch?v=yK5fYfn6HJg&t=2901s) on October 10th, 2010.

[^alin-where]: I am unable to find any trace of Miller's published work on this beyond the manuscript Boneh published in[^Mill86Short]. Any pointers would be appreciated.

{% include refs.md %}
