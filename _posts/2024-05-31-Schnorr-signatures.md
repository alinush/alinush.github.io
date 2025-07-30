---
tags: 
 - digital signatures
 - schnorr
 - sigma protocols
title: "Schnorr signatures: everything you wanted to know, but were afraid to ask!"
#date: 2020-11-05 20:45:59
#published: false
permalink: schnorr
sidebar:
    nav: cryptomat
---

{: .info}
**tl;dr:** Signs $m$ as $\sigma = (R, s)$, where $s = r - H(R, m) \cdot \sk$, $R = g^r$ and $r\randget \Zp$. Verifies this signature against $\pk = g^\sk$ as $R \equals g^s \cdot \pk^{H(R, m)}$.

<!--more-->

## A bit of history

The Schnorr signature scheme was originally introduced by Claus-Peter Schnorr, a German mathematician, in a CRYPTO'89 paper[^Schn89].
In the paper, Schnorr first proposes an _identification scheme_ which he then turns into a signature scheme using the well-known _Fiat-Shamir transform_[^FS87].
The original paper describes the signature scheme assuming a specific choice of Abelian group: a prime-order $q$ subgroup of $\Zps$, where $p$ is a prime. 
Later, in a journal version of the paper[^Schn91], Schnorr suggests any groups where computing discrete logs is hard should suffice, interestingly pointing to class groups and elliptic curve groups[^reference-needed].

Schnorr patented his scheme in 1990.
This was likely the biggest reason why Bitcoin, and the rest of the cryptocurrency space, (unfortunately?) chose ECDSA as its signature scheme, instead of Schnorr, which would have been simpler, slightly more efficient and easier to thresholdize into a $t$-out-of-$n$ scheme.
In 2010, once the patent expired, Schnorr became more popular.

Much like ECDSA, (some variants of) Schnorr signatures support [public key recovery](#pubkey-recovery), which Bitcoin leverages in P2PKH mode[^P2PKH] to keep TXN signatures smaller.
(Bitcoin has leveraged P2PKH since the beginning, it seems[^P2PKH-always].)

Later on, the Bitcoin community proposed[^BIP-340] and adopted an EdDSA-like variant of Schnorr signatures over the secp256k1 curve.

## Preliminaries

 - We assume a group $\Gr$ of prime order $p$ and a finite field $\Zp$
 - Let $g$ denote the generator of $\Gr$
 - We assume a collision-resistant hash function $H : \Gr \times \\{0,1\\}^* \rightarrow \Zp$.

## The Schnorr signature scheme

$\mathsf{Schnorr}$.$\mathsf{KeyGen}(1^\lambda) \rightarrow (\sk, \pk)$:
 - $\sk\randget\Zp$
  - $\pk \gets g^\sk$

$\mathsf{Schnorr}$.$\mathsf{Sign}(m, \sk) \rightarrow \sigma$:
 - $r\randget\Zp$
 - $R \gets g^r$
 - $s \gets (r - H(R, m) \cdot \sk) \bmod p$ 
 - $\sigma\gets (R, s)$

{: .info}
**Note:** It is also possible to use a $+$ instead of a $-$ when computing $s$.
The verification equation can be adjusted to account for it (e.g., see [EdDSA below](#eddsa)).

$\mathsf{Schnorr}$.$\mathsf{Verify}(m, \pk, \sigma) \rightarrow \\{0,1\\}$:
 - $(R, s) \gets \sigma$
 - **assert** $R \equals g^s \cdot \pk^{H(R, m)}$

### Correctness

The scheme is correct if signatures created via $\mathsf{Schnorr.Sign}$ verify correctly via $\mathsf{Schnorr.Verify}$.

Let's see why this holds:
\begin{align}
\label{eq:schnorr-verify}
R &\equals g^s \cdot \pk^{H(R, m)}\Leftrightarrow\\\\\
g^r &\equals g^{r-H(R, m)\cdot \sk} \cdot (g^\sk)^{H(R, m)}\Leftrightarrow\\\\\
g^r &\equals g^{r-H(R, m)\cdot \sk} \cdot g^{H(R, m) \cdot \sk}\Leftrightarrow\\\\\
g^r &\equals g^r
\end{align}

## Pubkey recovery

In most use cases, the signature verifier has the public key $\pk$ of the signer and can simply call $\mathsf{Schnorr}.\mathsf{Verify}(m,\pk, \sigma)$ to check a signature $\sigma$ on a message $m$.
However, in some settings, the verifier might actually not have the public key.
For example, in blockchain settings, the verifier (i.e., the validators/miners) might only have a hash $h$ of the public key (i.e., the address)[^P2PKH].

**Q:** Is it still possbile for such verifiers to still check the signature $\sigma$ on $m$ is correct against the hash $h$ of the public key?

**A:** Yes! There exists a **pubkey recovery algorithm** that returns the public key $\pk$ against which $\mathsf{Schnorr}.\mathsf{Verify}(m,\pk, \sigma)$ succeeds.
Then, the verifier can simply check that the hash of $\pk$ is $h$! 

By reorganizing the verification equation (see Eq. \ref{eq:schnorr-verify}), we can have it "return" the public key under which the signature verifies:
\begin{align}
R &\equals g^s \cdot \pk^{H(R, m)}\Leftrightarrow\\\\\
(R/g^s) &\equals \pk^{H(R, m)}\Leftrightarrow\\\\\
\left(R/g^s\right)^{\left(H(R,m)^{-1}\right)} &\equals \pk
\end{align}

So, the pubkey recovery algorithm is the following:

$\mathsf{Schnorr}$.$\mathsf{PubkeyRecover}(m, \sigma) \rightarrow \pk$:
 - $(R, s) \gets \sigma$
 - $\pk \gets \left(R/g^s\right)^{\left(H(R,m)^{-1}\right)}$

{: .warning}
Pubkey recovery does not work for the [EdDSA](#eddsa) variant of Schnorr, because the public key is hashed in together with the nonce as $H(R, \pk, m)$, to prevent _related key attacks_[^related-key-attacks].
Put differently, the recovery algorithm would need the pubkey itself in order to recover the pubkey as $\left(R/g^s\right)^{\left(H(R,\pk,m)^{-1}\right)}$, which is non-sensical.

## Batch verification

Schnorr signature verification is significantly faster when done **in batch**, rather than individually via $\mathsf{Schnorr.Verify}$.

Specifically, given $(\sigma\_i, m\_i, \pk\_i)\_{i\in [n]}$, one can ensure all signatures verify (i.e., that $\mathsf{Schnorr.Verify}(m\_i, \pk\_i, \sigma\_i) = 1,\forall i\in [n]$) by taking a random linear combination of the verification equations and combining them into one.

More formally, the  **batch verification** algorithm looks like this:

$\mathsf{Schnorr.BatchVerify}((m\_i, \pk\_i, \sigma\_i)\_{i\in[n]}) \rightarrow \\{0,1\\}$:
 - $z\_i \randget \\{0,1\\}^\lambda,\forall i\in[n]$
 - $(R\_i, s\_i) \gets \sigma\_i,\forall i\in[n]$
 - **assert** $\prod_{i \in [n]} R\_i^{-z\_i} g^{s\_i \cdot z\_i} \pk\_i^{H(R\_i, m\_i)\cdot z\_i} \equals 1$

The speed-up comes from using multi-exponentiation algorithms such as Bos-Coster or BDL+12[^BDLplus12] in the last check.

**Note:** When the public keys are the same (i.e., $\pk_i = \pk, \forall i\in[n]$), then the size of the multi-exponentiation can be reduced, which further speeds up the verification:
\begin{align}
\left(\prod_{i \in [n]} R\_i^{-z\_i} g^{s\_i \cdot z\_i}\right) \pk^{\sum_{i\in[n]} H(R\_i, m\_i)\cdot z\_i} \equals 1
\end{align}

{: .warning}
Implementing batch verification so that it returns the same results as individual verification may be trickier than it appears over non-prime order groups like Edwards 25519[^devalence]$^,$[^CGN20e].

## Alternative $(e, s)$ formulation

In this formulation, the signature includes the hash $e = H(R, m)$ instead of $R$.

This may have **advantages** if the hash can be made smaller.
The original Schnorr paper[^Schn89] claims $\lambda$-bit hashes (as opposed to $2\lambda$) are sufficient for $\lambda$-bit security, but not sure if that has changed.

On the other hand, a **disadvantage** is that this formulation:

1. Does **not** allow for more efficient [batch verification](#batch-verification).
2. Does not support [pubkey recovery](#pubkey-recovery) because it lacks the $R$ component.

The scheme follows below:

$\mathsf{Schnorr}'$.$\mathsf{Sign}(m, \sk) \rightarrow \sigma$:
 - $r\randget\Zp$
 - $R \gets g^r$
 - $e \gets H(R, m)$
 - $s \gets (r - e \cdot \sk)\bmod p$
 - $\sigma\gets (e, s)$

$\mathsf{Schnorr}'$.$\mathsf{Verify}(m, \pk, \sigma) \rightarrow \\{0,1\\}$:
 - $(e, s) \gets \sigma$
 - **assert** $e \equals H(g^s \cdot \pk^e, m)$


## EdDSA and Ed25519 formulation

### EdDSA

EdDSA is a Schnorr-based signature scheme designed for groups $\Gr$ of non-prime order $p = h\cdot q$, where $q\approx 2^{2\lambda}$ and $h=8$ (but can be generalized to $h=2^c$, for any $c$[^BCJZ20e]).
EdDSA has a few modifications for security.
In particular, (1) the nonce $r$ is generated **pseudo**-randomly from the SK and the message $m$ and (2) the signing additionally hashes over the public key and (3) EdDSA has been designed so that the SK can be _safely_ reused in Diffie-Hellman (DH) key exchange protocols like X25519.

EdDSA uses multiple hash functions:

 - $H_1 : \\{0,1\\}^{2\lambda} \rightarrow \\{0,1\\}^{4\lambda}$,
 - $H_2 : \\{0,1\\}^{2\lambda} \times \\{0,1\\}^* \rightarrow \\{0,1\\}^{4\lambda}$
 - $H_3 : \Gr \times \Gr \times \\{0,1\\}^* \rightarrow \\{0,1\\}^{4\lambda}$

These are typically instantiated from a single hash function $H : \\{0,1\\}^* \rightarrow \\{0,1\\}^{4\lambda}$ via proper domain separation.

$\mathsf{EdDSA}$.$\mathsf{KeyGen}(1^\lambda) \rightarrow (\sk, \pk)$:
 - $b \gets 2\lambda$
 - $\vec{k} \randget \\{0,1\\}^{b}$
 - $\vec{h} \gets H_1(\vec{k}) \in \\{0,1\\}^{2b}$
 - $a \gets 2^{b-2} + \sum_{3 \le i \le b - 3} 2^i h_i$
 - $\sk \gets (a, (h_b, \ldots h_{2b-1}))$
 - $\pk \gets g^{a}$

{: .info}
What is up with this weird generation of the secret key $a$?
tl;dr is that it allows for _"the same [Ed25519] secrets [to] also be used safely with X25519 if you also need to do a key-exchange."_[^clamping]

$\mathsf{EdDSA}$.$\mathsf{Sign}(m, \sk) \rightarrow \sigma$:
 - Parse $(a, (h_b, \ldots h_{2b-1})) \gets \sk$
 - $r \gets H_2(h_b,\ldots, h_{2b-1}, m) \in \\{0,1\\}^{2b}$
 - $R \gets g^r$
 - $s \gets (r + H_3(R, \pk, m) \cdot a)\bmod q$ 
 - $\sigma\gets (R, s)$

{: .info}
As per [BDL+12][^BDLplus12] the inclusion of $\pk$ in $H_3$ is _"an inexpensive way to alleviate concerns that several public keys could be attacked simultaneously"_.
Another yet-to-be explored advantage is that it prevents an adversary who is given a target signature $\sigma$ from finding a message $m$ and a public key $\pk$ for which it verifies.
For example, this is possible in [plain Schnorr](#the-schnorr-signature-scheme) where, given any $\sigma$, the adversary can pick any message $m$ it wants and compute the PK as $\pk = (g^s / R)^{1/H(R, m)}$. 
(In the future, I hope to expand on why such a security notion may be useful.)

$\mathsf{EdDSA}$.$\mathsf{Verify}(m, \pk, \sigma) \rightarrow \\{0,1\\}$:
 - $(R, s) \gets \sigma$
 - **assert** $g^s \equals R \cdot \pk^{H(R, \pk, m)}$

{: .info}
An alternative version of the verification function multiplies by the cofactor $h$ in the exponent: $g^{h\cdot s} \equals R^h \cdot \pk^{h\cdot H(R, \pk, m)}$.
The subtleties of this are discussed by Henry de Valence[^devalence].

### Ed25519

Ed25519 is just EdDSA over the Edwards 25519 curve with $\lambda=128$ and an appropriate choice of hash function.
This is stated in the EdDSA paper[^BDLplus12]:

 > Our recommended curve for EdDSA is a twisted Edwards curve birationally equivalent to the curve Curve25519 [...]
 > We use the name Ed25519 for EdDSA with this particular choice of curve.

Typically, the most common flavor of Ed25519 is Ed25519-SHA-512 which uses SHA2-512 as its hash function.

## (Mis)implementing Schnorr

Surprisingly, implementing Schnorr signatures can be quite tricky.
Previous work explores the many subtleties in depth[^devalence]$^,$[^CGN20e]$^,$[^BCJZ20e].
Instead of rehashing their explanations, I will summarize three main pitfalls to watch out for.
(Unfortunately, Ed25519 only handles the first one.)

### Pitfall #1: Reusing the nonce $r$

This is the most important **pitfall** to avoid in Schnorr signatures:

{: .error}
**Pitfall:** If an implementation produces two signatures that reuse the same $r$, then **the secret key can be extracted**.
Therefore, it is **crucial** for security that $r$ be sampled randomly.

{: .success}
**Recommendation:** As we [discuss later](#eddsa-and-ed25519-formulation), picking $r$ pseudorandomly based on the message and the secret key obviates this problem.

We showcase the attack below.
Suppose an implementation produces two signatures $\sigma_1 = (R, s_1)$ and $\sigma_2 = (R, s_2)$ on messages $m_1 \ne m_2$, respectively, that reuse the same $r$.
Specifically:
\begin{align}
R &= g^r\\\\\
s_1 &= r + H(R, m_1) \cdot \sk\\\\\
s_2 &= r + H(R, m_2) \cdot \sk
\end{align}
Then, an attacker can extract $\sk$ as follows:
\begin{align}
\frac{s_1 - s_2}{H(R, m_1) - H(R, m_2)} 
    &= \frac{H(R, m_1)\sk - H(R, m_2)\sk}{H(R, m_1) - H(R, m_2)}\\\\\
    &= \frac{\sk(H(R, m_1) - H(R, m_2))}{H(R, m_1) - H(R, m_2)}\\\\\
    &= \sk
\end{align}

{: .info}
For this attack to work, the denominator above must be not zero, which happens with overwhelming probability when $m_1\ne m_2$ and $H$ is collision-resistant. 
This attack works even when using the alternative $(e, s)$ formulation of Schnorr singatures, [described later](#alternative-s-e-formulation).

### Pitfall #2: Biased nonces $r$

{: .error}
**Pitfall:** If an implementation produces signatures whose nonces $r$ are not uniform in $\Zp$, then **the secret key can be extracted**.
Once again, it is **crucial** for security that $r$ be sampled randomly.

{: .success}
**Recommendation:** As we [discuss later](#eddsa-and-ed25519-formulation), picking $r$ pseudorandomly based on the message and the secret key obviates this problem.

We do not showcase the attacks, which rely on solving lattice problems and are similar to attacks on [ECDSA](/ecdsa)[^BH19e].

### Pitfall #3: Non-canonical serialization

{: .error}
**Pitfall:** The description above and, in fact, most academic descriptions, do not distinguish between a group element and its **serialization** into bytes.
(Same applies to field elements.)
Yet developers who implement Schnorr must understand the caveats of (de)serializing these elements to (1) avoid issues such as signature malleability and (2) maintain compatibility with other libraries.

For example, consider the code that deserializes the $s\in \Zp$ component of the Schnor signature.
Typically, naively-written code will not check that the positive integer encoded in the bytes is $< p$.
As a result, such code will accept two _different_ byte representations of the same $s$.
This could allow for one valid Schnorr signature $\sigma$ on $m$ to be **mauled** by an attacker into another *different*-but-still-valid signature $\sigma'$ on $m$.

Such **malleability attacks** might not seem like a big deal: after all, there was already a valid $\sigma$ on $m$, what do we care if someone can create a new $\sigma'$ that's also valid?
Fair enough, but many applications often (incorrectly) assume that a message only has one, unique, valid signature.
In the past, such attacks may have been used to drain money from (poorly-implemented) cryptocurrency exchanges[^DW14].

{: .success}
**Recommendation:** Developers need to ensure that each group (or field) element has a single / unique / canonical serialized representation into bytes **and** that deserialization **only** accepts this canonical representation.
Ristretto255[^ristretto] is a recently-proposed elliptic curve group that offers canonical (de)serialization. 

### Pitfall #4: Using non-prime order groups

{: .error}
**Pitfall:** The description above and, in fact, most academic descriptions, make a **crucial assumption**: that $\Gr$ is a prime-order group.

Yet, [Ed25519](#ed25519), which is the most popular implementation of Schnorr, does **not** use prime-order groups.
Instead, it uses composite order groups where the order is $h\cdot q$ where $q$ is prime and $h = 8$ is the so-called _cofactor_.
This actually creates subtle issues when batch-verifying Schnorr signatures, for example, where signatures that verify individually will not verify as part of a batch[^devalence].

{: .success}
**Recommendation:** If you have the freedom in your application, you should avoid implementing Schnorr over non-prime order groups (i.e., avoid [Ed25519](#Ed25519)) and adopt Schnorr variants like Schnorrkel[^schnorrkel] which use prime-order groups.

## Conclusion

By now, you should be pretty well-versed in Schnorr signatures and a few of their properties: nonce reuse attacks, batch verification, alternative forms, etc.
Nonethless, there is so much more to say about them (e.g., [why you should prefer Schnorr over ECDSA](/schnorr-vs-ecdsa)).
Perhaps this article will grow over time.

### Questions left

 1. What other aspects of Schnorr signatures should this blog post address?
 1. The original Schnorr paper[^Schn89] claims $\lambda$-bit hashes (as opposed to $2\lambda$) are sufficient for $\lambda$-bit security. I believe this analysis remains true?
    + A 2015 paper suggests that such "short" Schnorr signatures could still be secure, but not under the weak "random prefix resistance" property of the hash function[^Brow15e]
 1. What is a good academic reference for the *cleanest* EUF-CMA security proof for (single-signer) Schnorr?
 1. What is the the earliest work that defines Schnorr signatures over elliptic curves?
 1. What is the significance of [PV05][^PV05]

### TODOs

{: .todo}
Give algorithms for non-malleable Schnorr signatures.

{: .todo}
Give algorithms for post-quantum-switching of Ed25519 signatures.

{: .todo}
Discuss some state-of-the-art threshold Schnorr protocols (e.g., Yehuda's[^Lind22e], FROST[^KG20], Sprint[^BHKplus23e], Harts[^BLSW24e]).

{: .todo}
[Trail of Bits](https://www.zkdocs.com/docs/zkdocs/zero-knowledge-protocols/schnorr/) suggests additional checks: $R\ne 1\_\Gr$, the pubkey $\pk\ne 1\_\Gr$, and $s\ne 0$. But I am not sure what they achieve beyond preventing the protocol to run for $\pk=g^0$.
For any other PK whose SK is not known, the protocol remains sound without these checks.

## Conclusion and acknowledgements

Thanks to [Michael Straka](https://x.com/mstrakastrak) for pointing me to (1) the journal version of Schnorr's paper which described potential class group or elliptic curve variants of the scheme and (2) the analysis of "short" Schnorr signatures by Brown[^Brow15e].

---

[^bip-340]: [Schnorr Signatures for secp256k1](https://en.bitcoin.it/wiki/BIP_0340#Default_Signing), Peter Wuille, Jonas Nick, Tim ruffing, 2020
[^clamping]: [An Explainer On Ed25519 Clamping](https://www.jcraige.com/an-explainer-on-ed25519-clamping), Jake Craige
[^devalence]: [It's 255:19AM. Do you know what your validation criteria are?](https://hdevalence.ca/blog/2020-10-04-its-25519am), Henry de Valence
[^P2PKH]: [ECDSA verification, P2PKH uncompressed address](https://en.bitcoin.it/wiki/Message_signing#ECDSA_verification.2C_P2PKH_uncompressed_address)
[^P2PKH-always]: [How did pay-to-pubkey hash come about? What is its history?](https://bitcoin.stackexchange.com/a/73568/24573)
[^reference-needed]: Not sure what the earliest work is that **actually** uses Schnorr signatures over, say, elliptic curves.
[^related-key-attacks]: [Related key attacks in BIP-340](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki#cite_ref-5-0)
[^ristretto]: [https://ristretto.group](https://ristretto.group/why_ristretto.html)
[^schnorrkel]: [Schnorrkel](https://github.com/w3f/schnorrkel)
[^sign-only-with-the-sk]: https://github.com/jedisct1/libsodium/issues/170

{% include refs.md %}
