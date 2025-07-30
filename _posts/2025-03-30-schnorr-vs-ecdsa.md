---
tags:
title: Schnorr vs. ECDSA
#date: 2020-11-05 20:45:59
permalink: schnorr-vs-ecdsa
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** It's 2025. Do you know why [Schnorr signatures](/schnorr) are always better than [ECDSA](/ecdsa)?

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

For a while I've wanted to summarize my understanding of why Schnorr signatures should always be preferred over ECDSA, which are unfortunately used a lot in cryptocurrencies.

Feel free to suggest other (dis)advantages and similarities!

## Preliminaries

There are a few commonly-ocurring variants of Schnorr signatures:
 - [$(R,s)$-Schnorr](/schnorr#the-schnorr-signature-scheme), henceforth **"vanilla Schnorr"**
 - [$(e,s)$-Schnorr](/schnorr#alternative-e-s-formulation)
 - [EdDSA](/schnorr#eddsa), with its popular [Ed25519](/schnorr#ed25519) instantiation

There are also variants of ECDSA:
 - [Vanilla ECDSA](/ecdsa#the-ecdsa-signature-scheme), the most common one
 - [Deterministic ECDSA](/ecdsa#fn:deterministic-ecdsa)
 - [Modified ECDSA](/ecdsa#batch-verification)

{: .warning}
As a result, our discussion below focuses on **vanilla Schnorr** versus **vanilla ECDSA**.
 
## Advantages

### Thresholdizable

Vanilla Schnorr admits a much more efficient protocol for $t$-out-of-$n$ threshold signatures, compared to ECDSA.

Example of threshold protocols:
 - The well-known 4-round robust Schnorr[^SS01] (less efficient)
 + Yehuda's 3-round threshold Schnorr with identifiable abort[^Lind22e] (more efficient)
 + 2-round FROST[^KG20] (even more efficient)

{: .note}
Of course, if you're looking for the the fastest threshold protocol, you should go for our [threshold BLS](/threshold-bls)!

### Batch verification

Vanilla Schnorr, as well as the Ed25519 variant, both support efficient batch verification!

In contrast, vanilla ECDSA does **not** allow for a faster batch verification algorithm, due to the ECDSA conversion function.
(A [modified ECDSA](/ecdsa#batch-verification) variant does support it, but most legacy systems do not use it.)

### No NSA

The [history of (EC)DSA](/ecdsa#history) is a bit suspicious, with some worrisome NSA involvment.

In contrast, Schnorr signatures were invented by [Claus P. Schnorr](https://en.wikipedia.org/wiki/Claus_P._Schnorr), a German computer scientist.
(Presumably with no ties to the NSA or other three-letter agencies?)
 
Furthermore, ECDSA is most often used over NIST curves. 
It doesn't have to be, but it is. 
Some folks suspect these curves could be backdoored[^safe-curves].

### Hintless pubkey recovery

Like ECDSA, vanilla Schnorr also supports [pubkey recovery](/schnorr#pubkey-recovery) but **without** any hints, which are required in ECDSA (and complicate development[^trust-me])!

{: .warning}
Variations like $(e,s)$-Schnorr or Ed25519 do **not** support pubkey recovery!

### Simpler, faster & safer

Vanilla Schnorr is arguably **slighyly simpler** to implement, since ECDSA requires:

 - efficient modular inversion to compute $k^{-1}$ (see $\mathsf{ECDSA.Sign}$ [here](http://localhost:4000/ecdsa#algorithms)) and $s^{-1}$ (see $\mathsf{ECDSA.Verify}$ [here](http://localhost:4000/ecdsa#algorithms))
 - ensuring that $k,r$ and $s$ are not zero during signing
 - ensuring that $r$ and $s$ are not zero during verification

As a result, Schnorr is **slightly faster** than ECDSA, especially in the batched setting, due to ECDSA's reliance on field inversions

Schnorr is also arguably **slightly safer** to implement, since ECDSA's use of inversion has actually been exploited in practice (see [here](/ecdsa#fn:eea-side-channel)).

{: .note}
The EdDSA RFC[^eddsa-rfc] also argues, albeit without any justification, that EdDSA (slightly different than vanilla Schnorr) is less susceptible to side-channel attacks.

### Cleaner security proof

This is a nuanced topic, but the cryptographic analysis of Schnorr signatures is much more straightforward than ECDSA's.

A few reasons why:
 - ECDSA security reductions typically make non-standard assumptions about the [conversion function](#the-ecdsa-conversion-problem)
 - ...or: work in the generic group model (GGM)
 - ...or: introduce strange assumptions like the _semi-discrete logarithm (SDLP)_ problem
 + In fact, algebraic security reduction for ECDSA _"can only exist if the security reduction is allowed to program the conversion function"_[^HK23e]

{: .note}
A good summary of ECDSA's (lack of?) provable security (under a realistic model) is given by Eike Kiltz in a PKC'21 presentation[^kiltz] and his recent works[^FKP16]$^,$[^HK23e].

## Similarities

### Signature size

For most choices of underlying elliptic curves $\mathbb{G}\bydef E(\F_q)$ where $p\bydef \|E(\F_q)\|$ is the order of $\Gr$, both schemes have the same signature sizes, since $p\approx q$:
 - ECDSA has two field elements in $\Zp$: $r$ and $s$
 - Vanilla Schnorr has a $\Gr$ element $R$ and a $\Zp$ element $s$

{: .note}
Perhaps if one were to do ECDSA over curves like BLS12-381, where $q \approx 2^{381}$ but $p \approx 2^{256}$, the signature size of ECDSA would be slightly smaller (i.e., $32 + 32$ bytes for ECDSA, compared to $48 + 32$ bytes for vanilla Schnorr).
But, on the other hand, the $(e,s)$-Schnorr variant would have only $32 + 32$ bytes, even over BLS12-381.

### Malleability

Both schemes can be tricky to implement such that they are non-malleable.
(See [this dicussion](/ecdsa#non-malleable-algorithms) for non-malleable ECDSA.)

### Feeble against nonce bias

Both are vulnerable to attacks if their "nonces" are biased (see [here](/schnorr#pitfall-2-biased-nonces-r) and [here](/ecdsa#implementation-caveats)).

Both are fixable via deterministic signing though (e.g., EdDSA and Ed25519 are not vulnerable).

## Disadvantages

I can't think of anything else besides the fact that Ed25519, the most popular Schnorr variant these days, does **not** actually support public key recovery, due to its hashing of the public key as part of the Fiat-Shamir transform.

Can you think of any disadvantages of **vanilla** Schnorr over **vanilla** ECDSA?

## Conclusion

Schnorr. Always!

There are other aspects that I did not have time to look enough into but the reader may want to consider:

 1. Daniel J. Bernstein argues that [Ed25519 is more robust against implementation failures](https://blog.cr.yp.to/20191024-eddsa.html)

Your thoughts or comments are welcome on [this thread](https://x.com/alinush407/status/1913592499228299395).

## References

For cited works, see below 👇👇

{% include refs.md %}

[^eddsa-rfc]: [Edwards-Curve Digital Signature Algorithm (EdDSA)](https://www.rfc-editor.org/rfc/rfc8032#section-1), RFC 8032, by S. Josefsson, January 2017 
[^kiltz]: "[How provably-secure are (EC)DSA signatures?](https://www.youtube.com/watch?v=96I2wHr8uKE)", by Eike Kiltz, invited talk at PKC 2021
[^safe-curves]: [SafeCurves: choosing safe curves for elliptic-curve cryptography](https://safecurves.cr.yp.to/rigid.html), Daniel J. Bernstein, 2013
[^trust-me]: One of the most frequent cryptography questions I got in my work at Aptos Labs was around using ECDSA's pubkey recovery feature.
