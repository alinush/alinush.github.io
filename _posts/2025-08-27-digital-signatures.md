---
tags:
 - basics
 - digital signatures
title: Digital signatures
#date: 2020-11-05 20:45:59
#published: false
permalink: signatures
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Digital signatures are one of the most important cryptographic primitives today.
They are used to establish HTTPS connections with your favorite website, to securely download software updates, to provably send emails to others, to sign legal electronic documents, or to transact on a cryptocurrency like Bitcoin.

<!--more-->


<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\keygen{\mathsf{KeyGen}}
\def\sign{\mathsf{Sign}}
\def\verify{\mathsf{Verify}}
$</div> <!-- $ -->

## Algorithms

A **digital signature scheme** is a tuple of three _algorithms_, defined below.
Think of these as the "API interface" of a digital signature scheme like RSA or BLS.

$\mathsf{KeyGen}(1^\lambda) \rightarrow (\sk, \pk)$

Generates a **key-pair:** a **secret key** $\sk$ and its associated **public key** $\pk$.

$\mathsf{Sign}(m, \sk) \rightarrow \sigma$

Signs a **message** $m$ using the secret key $\sk$, producing a **signature** $\sigma$.

$\mathsf{Verify}(m, \pk, \sigma) \rightarrow \\{0,1\\}$

Verifies the signature $\sigma$ on $m$ under the public key $\pk$, returning 1 for success and 0 otherwise.

### Examples

This blog has several examples of digital signatures schemes that instantiate the algorithms above.
[Schnorr](/schnorr) and [ECDSA](/ecdsa) are the most popular ones used today (2025).
But we also cover more esoteric schemes like [BBS+](/bbs) or [PS](/pointcheval-sanders).

## Correctness

Intuitively, we say a digital signature scheme is _"correct"_ if any signature $\sigma$ obtained via $\sign(m,\sk)$ will verify successfully under $\verify(m,\pk,\sigma)$, assuming $(\sk,\pk)$ were obtained by running $\keygen$.

{: .todo}
Define.

## Security

There is an entire zoo of security notions for digital signatures, depending on the intended usage.
Below, we give the strongest notion, which most applications need (e.g., certificates for HTTPS, secure email, and cryptocurrencies).

### Existential unforgeability under chosen message attack (EUF-CMA)

{: .todo}
Define.

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## References

For cited works, see below 👇👇

{% include refs.md %}
