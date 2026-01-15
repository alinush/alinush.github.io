---
tags:
 - encryption
 - identity-based encryption (IBE)
title: Identity-based encryption
#date: 2020-11-05 20:45:59
#published: false
permalink: ibe
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\msg{m}
\def\ctxt{C}
\def\pk{\mathsf{pk}}
\def\sk{\mathsf{sk}}
\def\kgen{\mathsf{KGen}}
\def\enc{\mathsf{Enc}}
\def\dec{\mathsf{Dec}}
% IBE
\def\ibe{\mathsf{IBE}}
\def\id{\mathsf{id}}
\def\mpk{\mathsf{mpk}}
\def\msk{\mathsf{msk}}
\def\dk{\mathsf{dk}}
\def\derive{\mathsf{Derive}}
$</div> <!-- $ -->

{: .info}
**tl;dr:** Encrypt to a phone number or an email address, rather than under the recipient's public key.

<!--more-->

## Introduction

{: .warning}
This post assumes familiarity with (vanilla) [public-key encryption (PKE)](/encryption).

In an **identity-based encryption (IBE)** scheme, a **message** is encrypted under two things: (1) the **master public key (MPK)** and (2) an _identity string_ (e.g., a phone number), resulting in a **ciphertext**.
To decrypt, a **decryption key** can be revealed given (1) the **master secret key (MSK)** and (2) the identity string.
Then, the decryption key can be applied to the ciphertext yielding back the original message. 

The entity that generates the MPK and MSK and, crucially, protects the secrecy of the MSK is called a **key-issuing authority (KIA)**.
Obviously, the KIA can decrypt _anything_, since given any identity $\id$, it is able to derive the decryption key for that identity.
This makes IBE not always applicable since it centralizes trust in the KIA.
However, the KIA can be decentralized: it can be implemented as $t$-out-of-$n$ distributed system, so that at least $t$ nodes must collude in order to maliciously reconstruct a decryption key.

We describe an IBE scheme more formally, as a set of [four algorithms](#identity-based-encryption-scheme), below.

## Identity-based encryption scheme

### $\mathsf{IBE}.\mathsf{KGen}(1^\lambda) \rightarrow (\mathsf{msk}, \mathsf{mpk})$

Generates a master public key $\mpk$ and its associated master secret key $\msk$.

### $\mathsf{IBE}.\mathsf{Enc}(\mathsf{mpk}, \mathsf{id}, m; r) \rightarrow C$

Encrypts a message $m$ under identity $\id$ and master public key $\mpk$ using randomness $r$, yielding a ciphertext $C$.

### $\mathsf{IBE}.\mathsf{Derive}(\mathsf{msk}, \mathsf{id}) \rightarrow \dk$

Derives a decryption key $\dk$ for the identity $\id$ using the master key $\msk$.
This $\dk$ can be used to decrypt messages encrypted under $\mpk$ and $\id$.

### $\mathsf{IBE}.\mathsf{Dec}(\mathsf{dk}, C) \rightarrow m$

Decrypts the message $m$ from the ciphertext $C$ using the decryption key $\dk$.

### Correctness

Roughly speaking, an IBE is said to be **correct** if for any $(\msk,\mpk)$ honestly-generated via $\ibe.\kgen(1^\lambda)$, for any message $m$, any identity $\id$ and any randomness $r$, we have:
\begin{align}
m = \ibe.\dec(\ibe.\derive(\msk, \id), \ibe.\enc(\mpk, \id, m; r))
\end{align}

## Threshold IBE

**Threshold-issuance IBE** or, more simply, **threshold IBE** distributes the master secret key $\msk$ in $t$-out-of-$n$ fashion amongst $n$ **players**.

Most algorithms change, except for $\ibe.\enc$, which remains the same.

### $\mathsf{IBE}.\mathsf{DistKGen}(1^\lambda, t, n) \rightarrow \left(\left(\mathsf{msk}\_i,\mathsf{mpk}_i\right)\_{i\in[n]}, \mathsf{mpk}\right)$

Runs a distributed key generation protocol that outputs:
 - a master public key $\mpk$ for **all** players
 - the master public key shares $(\mpk_i)_{i\in[n]}$, also for **all** players.
 - the master secret key share $\msk_i$ to _each_ player $i$

### $\mathsf{IBE}.\mathsf{Derive}(\mathsf{msk}_i, \mathsf{id}) \rightarrow \mathsf{dk}\_i$

Derives a **decryption key share** $\dk$ for the identity $\id$ using the master key share $\msk_i$.
This $\dk_i$ can be used to threshold decrypt messages encrypted under $\mpk$ and $\id$.

### $\mathsf{IBE}.\mathsf{Dec}(\mathsf{dk}_i, C) \rightarrow (d_i, \pi_i)$

Derives a decryptions share $d_i$ from the ciphertext $C$ using the decryption key share $\dk_i$.
Optionally, returns a ZKP $\pi_i$ that $d_i$ is the correct decryption share obtained from $C$ and $\msk_i$.
This ZKP can be verified against $C$ and $\mpk_i$.

{: .note}
Alternatively, you can also imagine having an $\ibe.\dec(\msk_i, \id, C) \rightarrow (d_i, \pi_i)$ algorithm that operates more directly.

### $\mathsf{IBE}.\mathsf{Agg}\left((d\_i,\pi\_i)\_{i\in S}\right) \rightarrow m$

Aggregates the $\|S\|$ decryption shares $d_i$, assuming $t$ of them are valid and $\|S\|\ge t$, yielding back the decrypted message $m$.


## References

For cited works, see below 👇👇

{% include refs.md %}
