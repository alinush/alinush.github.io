---
tags:
 - encryption
title: Encryption
#date: 2020-11-05 20:45:59
#published: false
permalink: encryption
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** This is how it all started: folks wanted to "encrypt." What does that mean?

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\pke{\mathsf{PKE}}
\def\msg{m}
\def\ctxt{C}
\def\pk{\mathsf{pk}}
\def\sk{\mathsf{sk}}
\def\kgen{\mathsf{KGen}}
\def\enc{\mathsf{Enc}}
\def\dec{\mathsf{Dec}}
$</div> <!-- $ -->

## Introduction

In a (vanilla) **public-key encryption (PKE)** scheme, a **message** can be encrypted under a **public key**, resulting in a **ciphertext** that hides this message.
To decrypt, a corresponding **secret key**, which the public key was derived from, can be applied to the ciphertext, yielding back the original message.

More formally, a PKE is a set of [three algorithms](#public-key-encryption-scheme), as described below.
(For fancier variants of encryption schemes, see [this post](/ibe).)

## Public-key encryption scheme

### $\mathsf{PKE}.\mathsf{KGen}(1^\lambda) \rightarrow (\mathsf{sk}, \mathsf{pk})$

Generates a public key $\pk$ and its associated secret key $\sk$.

{: .smallnote}
$\lambda$ denotes a security parameter such that, _very roughly speaking_, decrypting without the secret key requires at least $2^\lambda$ operations.
Note that this implies recovery of the $\sk$ from $\pk$ also takes at least $2^\lambda$ operations.
Typically, $\lambda\ge 128$, precluding any practical attacks.

### $\mathsf{PKE}.\mathsf{Enc}(\mathsf{pk}, m; r) \rightarrow C$

Encrypts a message $m$ using randomness $r$ under public key $\pk$, yielding a ciphertext $C$.

{: .smallnote}
The randomness $r$ is needed to achieve the strongest notion of security, called [semantic security](https://en.wikipedia.org/wiki/Semantic_security).

### $\mathsf{PKE}.\mathsf{Dec}(\mathsf{sk}, C) \rightarrow m$

Decrypts the message $m$ from the ciphertext $C$ using the secret key $\sk$.

### Correctness

Roughly speaking, A PKE is said to be correct if for any $(\sk,\pk)$ honestly-generated via $\pke.\kgen(1^\lambda)$, for any message $m$ and any randomness $r$, we have:
\begin{align}
m = \pke.\dec(\sk,\pke.\enc(\pk,m; r))
\end{align}

## References

For cited works, see below 👇👇

{% include refs.md %}
