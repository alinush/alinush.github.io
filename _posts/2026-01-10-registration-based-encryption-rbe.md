---
tags:
 - registration-based encryption (RBE)
title: Registration-based encryption (RBE)
#date: 2020-11-05 20:45:59
published: false
permalink: rbe
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** An alternative to [identity-based encryption (IBE)](/ibe) that avoids the key-escrow problem. Users generate their own keys and _register_ them with a transparent **key curator** who maintains a short public digest. No trusted party ever holds a master secret key.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\msg{m}
\def\ctxt{C}
\def\kgen{\mathsf{Gen}}
\def\enc{\mathsf{Enc}}
\def\dec{\mathsf{Dec}}
\def\reg{\mathsf{Reg}}
\def\upd{\mathsf{Upd}}
\def\rbe{\mathsf{RBE}}
\def\id{\mathsf{id}}
\def\digest{D}
\def\crs{\mathsf{crs}}
\def\KC{\mathsf{KC}}
$</div> <!-- $ -->

## Introduction

{: .warning}
This post assumes familiarity with (vanilla) [public-key encryption (PKE)](/encryption) and [identity-based encryption (IBE)](/ibe).

In an [IBE](/ibe) scheme, a **key-issuing authority** holds a master secret key $\mathsf{msk}$ that lets it derive a decryption key for _any_ identity.
This is the **key-escrow problem**: the authority can decrypt all ciphertexts.

**Registration-based encryption (RBE)**[^GHMR18] eliminates this problem by replacing the trusted authority with a **key curator (KC)** that holds _no secrets_.
Each user independently generates its own public/secret key pair and then _registers_ its public key with the KC.
The KC simply aggregates registered public keys into a short, maintainable **public digest** $\digest$.

Similar to IBE, which encrypts under an identity $\id$ and master public key, in an RBE, you encrypt under the identity $\id$ and the _current_ public digest $\digest$:
\begin{align}
    \ctxt \gets \enc(\crs, D, \id, m; r),\ \text{where}\ r\ \text{denotes the randomness and}\ \crs\ \text{a common reference string}
\end{align}
Since $\digest$ evolves every time a new user registers, the $\digest$ used at encryption time may differ from the $\digest$ that existed when the recipient registered.
To bridge this gap, the recipient obtains **auxiliary update information** from the KC that connects its secret key to the public digest used in the ciphertext.
Combined with the user's own secret key, this update information enables decryption.

{: .note}
The original RBE paper[^GHMR18] uses the term _"public parameters"_ for what we call the _public digest_ $\digest$.
We prefer _digest_ because, in some RBE constructions (e.g., those based on vector commitments), the digest is literally a commitment over users' registered keys.
In that setting, the vector commitment scheme itself may have its own _public parameters_ (e.g., powers-of-tau), so using "public parameters" for both would be confusing.

We formalize RBE as a set of [five algorithms](#rbe-scheme) below, following [^GHMR18].

## RBE scheme

### $\rbe.\kgen(1^\lambda) \rightarrow (\pk, \sk)$

A user locally generates its own public/secret key pair $(\pk, \sk)$.

{: .smallnote}
Note: these are the user's _own_ keys, not encryption or decryption keys.
The key generation is performed by the registering party, not by any authority.

### $\rbe.\reg^{[\aux]}(\crs, \digest, \id, \pk) \rightarrow \digest'$

The (deterministic) registration algorithm takes as input the common reference string $\crs$, the current public digest $\digest$, a registering identity $\id$ and its public key $\pk$.
It outputs the updated public digest $\digest'$, reflecting $(id, \pk)$ being added to the old digest $\digest$.

The algorithm has _read and write_ access to the auxiliary information $\aux$ held by the KC.
(The system is initialized with $\digest = \bot$ and $\aux = \bot$.)

{: .smallnote}
The KC is **transparent**: the $\reg$ algorithm is deterministic and the KC holds no secret state[^GHMR18].
Depending on the construction, the $\crs$ can be generated transparently or via trusted setup.

### $\rbe.\enc(\crs, \digest, \id, \msg; r) \rightarrow \ctxt$

Encrypts using randomness $r$ a message $\msg$ under the identity $\id$ registered in the digest $\digest$, yielding a ciphertext $\ctxt$.

{: .smallnote}
The encryptor does _not_ need the recipient's public key; only $\digest$ and $\id$ are required, very similar to [IBE.Enc](/ibe#mathsfibemathsfencmathsfmpk-mathsfid-m-r-rightarrow-c-1) where $\digest$'s role is filled in by the master public key.

### $\rbe.\upd^{\aux}(\digest, \id) \rightarrow u$

The (deterministic) update algorithm takes as input the current public digest $\digest$ and an identity $\id$, and has _read-only_ access to $\aux$.
It outputs an **update** $u$ that helps $\id$ decrypt its messages.

{: .smallnote}
The update information $u$ is _public_: any user can request it without authentication.
Ideally, the user with identity $\id$ needs to request updates at most $O(\log n)$ times in its lifetime, where $n$ is the total number of registered users.

### $\rbe.\dec(\sk, u, \ctxt) \rightarrow \msg$ (or $\bot$, or $\mathsf{GetUpd}$)

Decrypts the message $\msg$ from the ciphertext $\ctxt$ using the secret key $\sk$ and the update information $u$.
Returns $\bot$ on a syntax error, and $\mathsf{GetUpd}$ if a more recent update is needed for decryption.

### Correctness

Roughly speaking, an RBE scheme is **correct** if, for _any_ adversary that adaptively registers identities and requests encryptions/decryptions, the following holds:
after identity $\id^\*$ is honestly registered with key pair $(\pk^\*,\sk^\*)$, for any message $\msg$ and any ciphertext $\ctxt \leftarrow \rbe.\enc(\crs, \digest, \id^\*, \msg)$, decrypting with a sufficiently recent update $u \leftarrow \rbe.\upd^{\aux}(\digest, \id^\*)$ yields back the message:
\begin{align}
\msg = \rbe.\dec(\sk^\*, u, \ctxt)
\end{align}

More precisely, correctness is defined via a game $\mathsf{Comp}\_{\mathsf{Adv}}(\kappa)$ between an adversary and a challenger[^GHMR18].
The adversary controls the order of registrations and the timing of encryptions/decryptions, and correctness requires:
$$\Pr[\text{Adv wins in } \mathsf{Comp}_{\mathsf{Adv}}(\kappa)] = \mathsf{negl}(\kappa)$$

### Compactness

The public digest $\digest$ and updates $u$ are **compact**:
$$|\digest|, |u| \le \mathsf{poly}(\kappa, \log n)$$
where $n$ is the number of registered users and $\kappa$ is the security parameter.

### Efficiency

 - The running time of each invocation of $\reg$ and $\upd$ is at most $\mathsf{poly}(\kappa, \log n)$.
 - The _total_ number of updates identity $\id^\*$ needs to request is at most $O(\log n)$ for every $n$ during the game.

{: .note}
A relaxation called **weakly-efficient RBE (WE-RBE)**[^GHMR18] allows the registration time to be $\mathsf{poly}(\kappa, n)$ while keeping all other requirements the same.

### Security (IND-ID-CPA)

RBE security guarantees that no PPT adversary can distinguish between encryptions of two messages to a _registered_ identity, even if the adversary:
 - controls which identities are registered and their public keys, and
 - obtains the secret keys of _all other_ registered identities.

Formally, security is defined via a game $\mathsf{Sec}\_{\mathsf{Adv}}(\kappa)$[^GHMR18]:

1. **Initialization.** The challenger sets $\digest = \bot$, $\aux = \bot$, $\mathcal{D} = \varnothing$, $\id^\* = \bot$, samples $\crs$, and sends $\crs$ to the adversary.

2. **Registration phase.** The adversary adaptively:
   - **(a)** Registers non-target identities $(\id, \pk)$ of its choosing. The challenger runs $\digest := \reg^{[\aux]}(\crs, \digest, \id, \pk)$ and adds $\id$ to $\mathcal{D}$.
   - **(b)** Registers the target identity: the adversary sends $\id^\* \notin \mathcal{D}$. The challenger samples $(\pk^\*, \sk^\*) \leftarrow \kgen(1^\kappa)$, registers $\id^\*$, and sends $\pk^\*$ to the adversary.

3. **Challenge.** The challenger samples a random bit $b \leftarrow \\{0,1\\}$, computes $\ctxt \leftarrow \enc(\crs, \digest, \id^\*, b)$, and sends $\ctxt$ to the adversary.

4. **Guess.** The adversary outputs $b'$ and wins if $b' = b$.

We call an RBE scheme **secure** if:
$$\Pr[\text{Adv wins in } \mathsf{Sec}_{\mathsf{Adv}}(\kappa)] < \frac{1}{2} + \mathsf{negl}(\kappa)$$

{: .smallnote}
Because the KC is transparent (no secret state), the adversary can compute updates on its own and does _not_ need an explicit $\upd$ oracle[^GHMR18].

## References

For cited works, see below

{% include refs.md %}
