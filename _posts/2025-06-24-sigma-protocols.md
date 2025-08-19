---
tags:
 - zero-knowledge proofs (ZKPs)
 - sigma protocols
title: $\Sigma$-protocols
#date: 2020-11-05 20:45:59
#published: false
permalink: sigma
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A quick note on the most commonly-occuring variant of $\Sigma$-protocols, inspired from the Boneh-Shoup textbook!

<!--more-->

<!-- Here you can define LaTew macros -->
<div style="display: none;">$
\def\P{\mathcal{P}}
\def\V{\mathcal{V}}
\def\str{\mathsf{str}}
\def\binL{\{0,1\}^{2\lambda}}
\def\Rlin{\mathcal{R}_\mathsf{lin}}
$</div> <!-- $ -->

## Introduction

Skipping over 30+ years of $\Sigma$-protocol design and jmping right into the (most?) useful generalization from the Boneh-Shoup[^BS23] textbook.
(Actually, I think the most useful one may be the preimage of a homomorphism one...)

## Preliminaries

 - $[m]\bydef\\{1,\ldots,m\\}$
 - $\bigwedge_{i \in [m]} C_i \bydef C_1 \wedge C_2\wedge\ldots C_m$ denotes the "logical and" of multiple statements $C_i$
 - $\lambda$ denotes a security parameter; typically $\lambda = 128$ bits of security
 - $\F$ is a finite field of prime order $p \approx 2^{2\lambda}$
 - $\Gr$ is a group where computing discrete logs is hard, also of prime order $p$
 - We are using additive group notation for $\Gr$ (e.g., $P_1 + P_2\in\Gr$ and $a\cdot P\bydef \underbrace{P+P+\ldots+P}_{a\ \text{times}}\in \Gr$). 
 - $\N$ denotes all the natural numbers

## $\Sigma$-protocols for linear relations

Consider a **linear check** on group elements $G_j\in\Gr$ of the following form:
\begin{align}
U \equals
\sum_{j\in [n]} w_j \cdot G_j 
\end{align}

Denote the "logical and" of a bunch of such checks w.r.t. the same $w_j$ scalars by: 
\begin{align}
\term{\phi(w_1,\ldots,w_n)} \bydef \left\\{
\bigwedge_{i\in[m]}\left( \term{U_i} \equals \sum_{j\in[n]} \term{w_j}\cdot \term{G_{i,j}}\right)
\right\\}
\end{align}

Boneh and Shoup[^BS23] remind us that it is very easy to build $\Sigma$-protocols for this general class of **arbitrary linear relations** defined below:
\begin{align}
\term{\Rlin}\begin{pmatrix}
    (G\_{i,j})\_{i\in[m],j\in[n]}, (U\_i)\_{i\in[m]}
    \textbf{;}\\\\\
    w_1,\ldots,w_n\end{pmatrix} = 1
    \Leftrightarrow
    \phi(w_1,\ldots,w_1) \equals 1
\end{align}

{: .note}
i.e., a $\Sigma$-protocol whereby a **prover** $\P_\phi$ can convince a **verifier** $\V_\phi$, in zero-knowledge, that it knows secret $w_i$'s such that $\phi(w_1,\ldots,w_n)=1$ follows. 

A $\Sigma$-protocol for $\Rlin$ follows below:

<table style="border-collapse: collapse; border: 1px solid grey; table-layout: fixed; width: 532px;">
<tr><td style="border: none;">
  $\underline{\P_\phi\begin{pmatrix}(G_{i,j})_{i\in[m],j\in[n]}, (U_i)_{i\in[m]}\textbf{;}\\\, (w_i)_{i\in[n]}\end{pmatrix}}$
</td><td style="border: none; text-align: right;">
  $\underline{\V_\phi\begin{pmatrix}(G_{i,j})_{i\in[m],j\in[n]},\\\ (U_i)_{i\in[m]}\end{pmatrix}\rightarrow \{0,1\}}$
</td></tr>

<tr><td style="border: none; text-align: left;" colspan="2">
  $\term{\alpha_j} \randget\F, \forall j\in[n]$<br />
  $\term{A_i}\gets  \sum_{j\in[n]} \alpha_j\cdot G_{i,j},\forall i\in[m]$<br />
</td></tr>

<tr><td style="border: none; text-align: center;" colspan="2">
  $\xrightarrow{\hspace{1.5em}\mbox{$A_1,\ldots, A_m$}\hspace{1.5em}}$
</td></tr>

<tr><td style="border: none; text-align: right;" colspan="2">
  $\term{e} \randget \F$<br/>
</td></tr>

<tr><td style="border: none; text-align: center;" colspan="2">
  $\xleftarrow{\hspace{1.5em}\mbox{$e$}\hspace{1.5em}}$
</td></tr>

<tr><td style="border: none; text-align: left;" colspan="2">
  $\term{\sigma_j} \gets \alpha_j + e\cdot w_j,\forall j\in[n]$<br />
</td></tr>

<tr><td style="border: none; text-align: right;" colspan="2">
  $A_i + e \cdot U_i \equals \sum_{j\in[n]}\sigma_j\cdot G_{i,j},\forall i\in[m]$<br/>
</td></tr>
</table>

### Notes

 - Prover time:
    + $m$ size-$n$ MSMs in $\Gr$
    + $n$ additions in $\F$
    + $n$ multiplications in $\F$
 - Proof size:
    - $m$ $\Gr$ group elements
    - $n$ $\F$ field elements
 - Verifier time:
    - size-$(m(n+1))$ MSM in $\Gr$ (see [here](#faster-verifier))

{: .note}
This protocols works across _different groups_: i.e., when $U_i, G_{i,j}\in \Gr_i$ and the $\Gr_i$'s are different but of the same prime order $p$!
(However, the faster verification optimization [described below](#faster-verifier) will be affected.)

### Examples of formulas $\phi$

Boneh and Shoup[^BS23] give a few examples of popular $\Sigma$-protocols viewed through this lens of proving the $\Rlin$ relation:

 - [Schnorr](/schnorr) proofs use $\phi(\sk) = \left\\{\pk \equals \sk \cdot G\right\\}$, where $\sk\in\F$ is the secret key and $\pk\in\Gr$ is the public key
 - Okamoto signatures[^Okam93] use $\phi(\sk_1,\sk_2) = \left\\{\pk \equals \sk_1 \cdot G_1 + \sk_2\cdot G_2\right\\}$, where $(\sk_1,\sk_2)\in\F^2$ is the secret key and $\pk\in\Gr$ is the public key
 - Discrete log equality proofs (a.k.a. Chaum-Pedersen[^CP92] proofs) use $\phi(w_1, w_2) = \left\\{ H_1 = w_1\cdot G_1 \wedge H_2 = w_2\cdot G_2 \right\\}$

### Faster verifier

In practice, the verifier would use a **multi-scalar multiplication (MSM)** to check all the $A_i + e\cdot U_i \equals \sum_{j\in[n]} \sigma_j \cdot G_{i,j}$ equations faster.

How? Using a well-known **random-linear combination trick**.

The verifier picks **random**, $\lambda$-bit wide $\beta_i$'s.
The $i$th equation can be multipled on both sides by $\beta_i$:
\begin{align}
\beta_i \cdot \left(A_i + e \cdot U_i\right) &\equals \beta_i \left(\sum_{j\in[n]}\sigma_j\cdot G_{i,j}\right)\Leftrightarrow\\\\\
\beta_i \cdot \left(A_i + e \cdot U_i + \sum_{j\in[n]}\sigma_j\cdot G_{i,j}\right) &\\equals 0\\\\\
\beta_i \cdot A_i + (\beta_i \cdot e) \cdot U_i + \sum_{j\in[n]}(\beta_i \cdot \sigma_j)\cdot G_{i,j} &\\equals 0
\end{align}
Then, all such equations can be combined into a single one:
\begin{align}
\sum_{i\in [m]}\left( \beta_i\cdot A_i + (\beta_i \cdot e) \cdot U_i\right) + \sum_{i\in[m],j\in[n]}\left( (\beta_i \cdot \sigma_j) \cdot G_{i,j}\right) &\\equals 0
\end{align}
One can show that, except with negligible probability, this batched check is $\approx$ as sound as the original check.

{: .note}
The check above is now a single size-$(nm + m)$ MSM!


## Implementation pitfalls

### Secure deserialization

In reality, $\Sigma$-protocol proofs are sent over the network to the verifier.

Thefore, a crucial security-sensitive aspect is not captured in academic descriptions like the one above:
**the verifier must correctly-deserialize the received proof**!

Here's a few pro tips below.

1. In your elliptic curve library, make sure your group element deserialization routine checks two things: 
   - The deserialized point satisfies the elliptic curve equation
   - The deserialized point lies in the subgroup of prime order $p = \|\F\| = \|\Gr\|$
       + Otherwise, there may be big security issues (e.g., see [here](/schnorr#fn:devalence))

2. Carefully-handle field element deserialization too:
   - A conservative approach: always reject bytes that encode a number $\ge p$ or $< 0$, since field elements are in $[0, p)$.

### Fiat-Shamir transform (for $\mathcal{R}_\mathsf{lin}$'s $\Sigma$-protocol)

**tl;dr:** Hash everything _but_ nothing more: i.e., a description of $\Gr$ (e.g., _"Edwards 25519"_), the prime order $p$, the sizes $n,m$, the formula $\phi$, all the $G_{i,j}$'s, all the $U_i$'s, all the messages so far (i.e., the $A_i$'s), and any application-specific context $\mathsf{ctx}$.

Specifically:
\begin{align}
\mathsf{ctx} &\gets \text{"withdrawal protocol / Aptos confidential assets"}\\\\\
e &\gets H\_\mathsf{FS}(\mathsf{desc}(\Gr), p, n, m, \phi, (G\_{i,j})\_{i\in[m],j\in[n]}, (U\_i, A\_i)\_{i\in[m]}, \mathsf{ctx})
\end{align}
where $H_\mathsf{FS}$ is a cryptographic hash function:
\begin{align}
H\_\mathsf{FS} : \str \times \N^3 \times \Phi \times \Gr^{mn} \times \Gr^{2m}\times \str\rightarrow \binL
\end{align}
and (informally) $\Phi$ is the set of all possible formulas like $\phi$.

However, even this description can be **dangerously misleading**.
It tends to assume folks know how to instantiate a collision-resistant $H\_\mathsf{FS}$ given a more general collision-resistant hash function $H : \\{0,1\\}^\*\rightarrow \binL$ that just hashes bits.

Unfortunately, in practice, folks often implement this wrong.

For example, folks **mis**implement a hash function $H_2 : \str \times \str \rightarrow \binL$ that hashes two variable-length strings $s_1,s_2 \in \str$ by concatenating the two strings and hashing the result as $H(s_1 \concat s_2)$, using a general hash function $H$ for bits.

As a result, the hash of $s_1 = \text{"a"}$ and $s_2 = \text{"bc"}$ will collide with that of $s_1' = \text{"ab"}$ and $s_2' = \text{"c"}$ will collide, since they are both $H_2(\text{"a"},\text{"bc"})=H_2(\text{"ab"},\text{"c"})=H(\text{"abc"})$.

{: .warning}
$\Rightarrow$ Just use the [spongefish library](https://github.com/arkworks-rs/spongefish), really[^CO25e].

{: .warning}
Be sure to not hash unecessary stuff.
e.g., don't hash arbitrary stuff "just for safety", since this may open up grinding attack vectors.

{: .warning}
You'd find out the hard way, but don't hash the secret witness (e.g., the $w_i$'s), because both the prover **and** the verifier need to be able to compute the hash, and the verifier doesn't have the witness, since $\Sigma$-protocols are ZK!

## Extra resources

 - Composing $\Sigma$-protocols can also be tricky. Hope to expand on it later.
 - ZKProof workshop $\Sigma$-protocols proposal[^KO21] with [slides here](https://docs.zkproof.org/pages/standards/slides-w4/sigma.pdf)
 - Ivan Damgaard's write-up[^Dam10]
 - Section 19.5.4 in Boneh and Shoup's textbook[^BS23] further generalizes $\Rlin$ as a group homomorphism
 - $\Sigma$-protocols from VSS[^ZCYW23e]
 - Compressed $\Sigma$-protocols[^AC20e]

## References

For cited works, see below 👇👇

{% include refs.md %}
