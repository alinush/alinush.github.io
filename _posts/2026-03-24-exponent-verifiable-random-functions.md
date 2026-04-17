---
tags:
 - verifiable random functions (VRFs)
 - exponent VRFs (eVRFs)
title: Exponent verifiable random functions (eVRFs)
#date: 2020-11-05 20:45:59
published: false
permalink: evrf
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** An eVRF is a VRF that does not reveal its pseudorandom output $y$ in the clear, but instead provides $Y = y \cdot G$ (i.e., $y$ "in the exponent") together with a proof that $Y$ is correct. Useful for one-round distributed key generation and two-round threshold signing.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\kgen{\mathsf{KeyGen}}
\def\eval{\mathsf{Eval}}
\def\verify{\mathsf{Verify}}
\def\evrf{\mathsf{eVRF}}
\def\prf{\mathsf{PRF}}
\def\vrf{\mathsf{VRF}}
\def\Sim{\mathsf{Sim}}
\newcommand{\FF}{\mathbb{F}}
\newcommand{\GG}{\mathbb{G}}
\newcommand{\ZZ}{\mathbb{Z}}
$</div> <!-- $ -->

## Introduction

A **pseudorandom function (PRF)** is a keyed function $F(k,x)$ whose outputs are indistinguishable from random to anyone who does not know the key $k$.

A **verifiable random function (VRF)** adds public verifiability: it associates a public **verification key** $\vk$ with the secret key $k$, and the evaluation algorithm outputs not only the pseudorandom value $y = F(k,x)$ but also a proof $\pi$ that $y$ was computed correctly.

An **exponent VRF (eVRF)**[^BHL24e] is a variant that does _not_ reveal the PRF output $y$ in the clear.
Instead, it provides $Y = y \cdot G$ where $G$ is a generator of some finite cyclic group $\GG$, together with a proof $\pi$ that $Y$ was generated correctly from $\vk$ and $x$.
The term "exponent" comes from multiplicative notation where $Y = g^y$.

eVRFs are useful in settings where the discrete log problem is hard over $\GG$ and a party needs to generate a pseudorandom value $r$ and send $R = r \cdot G$ to other parties.
Using an eVRF, the receiving parties can verify that $R$ is consistent with an initially-committed key $k$, _without learning $r$ itself_.

We formalize eVRFs below, following [^BHL24e].
We first give the [game-based definition](#game-based-definition) and then describe the [ideal functionality](#ideal-functionality).

## Preliminaries: VRFs

Before defining eVRFs, we recall the definition of a (simulatable) VRF.

A **simulatable VRF** with respect to domain/range ensemble $\\{(\mathcal{X}\_\lambda, \mathcal{Y}\_\lambda)\\}\_{\lambda \in \mathbb{N}}$ and function-family ensemble $\mathcal{H}$ is a triple of oracle-aided PPT algorithms $(\kgen, \eval, \verify)$ such that for every $\lambda \in \mathbb{N}$ and $h \in \mathcal{H}\_\lambda$:

- $\kgen^h(1^\lambda) \rightarrow (k, \vk)$
- $\eval^h(1^\lambda, k, x) \rightarrow (y, \pi)$. We let $\eval_1(1^\lambda, k, x) \rightarrow y$ denote the first output only.
- $\verify^h(1^\lambda, \vk, x, y, \pi) \rightarrow \\{0,1\\}$

A VRF is **secure** if:

- **Correctness.** For all PPT $A$:
$$\Pr\left[\neg\verify^h(\vk, x, y, \pi)\right] \le \mathsf{negl}(\lambda)$$
where $h \leftarrow \mathcal{H}\_\lambda$, $(k,\vk) \leftarrow \kgen^h(1^\lambda)$, $x \leftarrow A^{h,\eval^h_k}(1^\lambda, \vk)$, and $(y,\pi) \leftarrow \eval^h_k(x)$.

- **Pseudorandomness.** $(\kgen, \eval_1)$ is a secure PRF with respect to the domain/range ensemble $\\{(\mathcal{X}\_\lambda, \mathcal{Y}\_\lambda)\\}\_{\lambda \in \mathbb{N}}$ and $\mathcal{H}$.

- **Verifiability.** For all PPT $A$: if $h \leftarrow \mathcal{H}\_\lambda$ and $\left(\vk, x, (y_0, \pi_0), (y_1, \pi_1)\right) \leftarrow A^h(1^\lambda)$, then:
$$\Pr\left[y_0 \neq y_1 \;\wedge\; \left(\forall i \in \\{0,1\\}: \verify(\vk, x, y_i, \pi_i) = 1\right)\right] \le \mathsf{negl}(\lambda)$$

- **Simulatability.** There exists a PPT $\Sim$ such that for all $x \in \mathcal{X}\_\lambda$:
$$\left(\vk, k, x, \Sim^h(\vk, x, y)\right) \;\overset{c}{\approx}\; \left(\vk, k, x, \eval^h(k, x)\right)$$
for $h \leftarrow \mathcal{H}\_\lambda$, $(k,\vk) \leftarrow \kgen^h(1^\lambda)$, and $y \leftarrow \eval^h_1(k,x)$.

## Game-based definition

Let $\\{(\mathcal{X}\_\lambda, \mathcal{Y}\_\lambda)\\}\_{\lambda \in \mathbb{N}}$ be an ensemble of domains/ranges, where each $\mathcal{Y}\_\lambda$ is a finite cyclic group with a specified generator $G\_\lambda$.

An **exponent verifiable random function (eVRF)** with respect to this ensemble and a function-family ensemble $\mathcal{H}$ is a triple of oracle-aided PPT algorithms $(\kgen, \eval, \verify)$ such that for every $\lambda \in \mathbb{N}$ and $h \in \mathcal{H}\_\lambda$:

### $\evrf.\kgen^h(1^\lambda) \rightarrow (k, \vk)$

Generates a secret key $k$ and a public verification key $\vk$.

### $\evrf.\eval^h(1^\lambda, k, x) \rightarrow (y, Y, \pi)$

On input the secret key $k$ and an input $x \in \mathcal{X}\_\lambda$, outputs:
 - a pseudorandom value $y \in \ZZ_{|\mathcal{Y}\_\lambda|}$,
 - a group element $Y \in \mathcal{Y}\_\lambda$,
 - a proof $\pi$.

We define two auxiliary algorithms:
 - $\eval_1(1^\lambda, k, x) \rightarrow y$: outputs only the first component (the scalar).
 - $\eval_2(1^\lambda, k, x) \rightarrow (Y, \pi)$: outputs only the second and third components (the group element and proof).

### $\evrf.\verify^h(1^\lambda, \vk, x, Y, \pi) \rightarrow \{0,1\}$

Verifies that $Y$ is consistent with $\vk$ and $x$.

### Consistency

For every PPT $A$:

$$\Pr\left[y \cdot G_\lambda \neq Y \;:\;
\begin{array}{l}
h \leftarrow \mathcal{H}_\lambda,\; (k,\vk) \leftarrow \kgen^h(1^\lambda) \\\\
x \leftarrow A^{h, \eval^h(k,\cdot)}(1^\lambda, \vk),\; (y, Y, \pi) \leftarrow \eval^h(k,x)
\end{array}
\right] \le \mathsf{negl}(\lambda)$$

In other words, $Y$ must equal $y \cdot G$ (or $g^y$ in multiplicative notation).

### Pseudorandomness

$(\kgen, \eval_1)$ is a secure PRF with respect to the domain/range ensemble $\\{\left(\mathcal{X}\_\lambda, \ZZ\_{|\mathcal{Y}\_\lambda|}\right)\\}\_{\lambda \in \mathbb{N}}$ and $\mathcal{H}$.

That is, the scalar $y$ is pseudorandom, even given oracle access to $\eval$.

### Simulatable verifiability

$(\kgen, \eval_2, \verify)$ is a simulatable VRF with respect to the ensemble $\\{(\mathcal{X}\_\lambda, \mathcal{Y}\_\lambda)\\}\_{\lambda \in \mathbb{N}}$ and $\mathcal{H}$.

That is, the group element $Y$ and proof $\pi$ form a simulatable VRF.

{: .note}
Putting it together: the scalar output $y$ is pseudorandom (like a PRF), the group element $Y = y \cdot G$ is a verifiable commitment to $y$ (like a VRF), and the proof $\pi$ is simulatable. The key insight is that $y$ itself is _never revealed_ to the verifier---only $Y$ and $\pi$ are.

## Ideal functionality

The game-based definition above is useful for _constructing_ eVRFs.
For _applications_ (e.g., threshold signing), it is more convenient to work with an **ideal functionality** $\mathcal{F}\_\mathsf{eVRF}$[^BHL24e].

Let $(\mathcal{X}, \mathcal{Y})$ be a domain/range pair where $\mathcal{Y}$ defines a group $\GG$ of order $q$ with generator $G$.
The eVRF ideal functionality $\mathcal{F}\_\mathsf{eVRF}^{\mathcal{X},\mathcal{Y}}$ (or just $\mathcal{F}\_\mathsf{eVRF}$) is defined as follows:

**1. Initialize.** Upon receiving $(\mathsf{init}, i, \*)$ from party $P_i$:

   - **(a)** If $P_i$ is **honest**: receive a value $\mathsf{sid}$ from the ideal adversary, verify it is unique, and store $(\mathsf{sid}, i)$.
   - **(b)** If $P_i$ is **corrupted**: receive $(\mathsf{init}, i, \mathsf{sid}, f)$ where $f$ is a deterministic polynomial-time computable function. Verify that $\mathsf{sid}$ has not been stored, then store $(\mathsf{sid}, i, f)$.

   Send $(\mathsf{init}, i, \mathsf{sid})$ to all parties.

**2. Evaluate.** Upon receiving $(\mathsf{eval}, i, \mathsf{sid}, x)$ from $P_i$, where $x \in \mathcal{X}$:

   - If $(\mathsf{sid}, i)$ or $(\mathsf{sid}, i, f)$ is not stored, then ignore.
   - **(a)** If $P_i$ is **honest**: if no tuple $(\mathsf{sid}, i, x, y, Y)$ exists with this $x$, then choose a random $y \leftarrow \ZZ_q$, compute $Y \leftarrow y \cdot G$, and store $(\mathsf{sid}, i, x, y, Y)$.
     Send $(\mathsf{eval}, i, \mathsf{sid}, x, y, Y)$ to party $P_i$ and $(\mathsf{eval}, i, \mathsf{sid}, x, Y)$ to all parties.
   - **(b)** If $P_i$ is **corrupted**: compute $Y \leftarrow f(x) \cdot G$ and send $(\mathsf{eval}, i, \mathsf{sid}, x, Y)$ to all parties.

{: .smallnote}
For honest parties, the output $y$ is _truly random_ and independent of the key (unlike the game-based definition where $y = \eval_1(k,x)$). This is what makes the ideal functionality useful for proving security of applications: no information about $y$ leaks beyond $Y = y \cdot G$.

### Equivalence

The game-based definition implies the ideal functionality.
Specifically, any eVRF $EF = (\kgen, \eval, \verify)$ satisfying the game-based definition, when combined with a zero-knowledge proof of knowledge of the secret key, gives a protocol $\pi_{EF}$ that UC-realizes $\mathcal{F}\_\mathsf{eVRF}$ in the $\mathcal{F}\_\mathsf{zk}$-hybrid model[^BHL24e].

## References

For cited works, see below

{% include refs.md %}
