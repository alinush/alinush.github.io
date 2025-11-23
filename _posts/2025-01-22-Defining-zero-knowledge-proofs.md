---
tags:
 - zero-knowledge proofs (ZKPs)
title: (Defining) zero-knowledge proofs
permalink: zkps
#date: 2020-11-05 20:45:59
#published: false
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A **zero-knowledge proof (ZKP)** system for an NP relation $R$ allows a **prover**, who has a **statement** $\mathbf{x}$ and a **witness** $\mathbf{w}$ to convince a **verifier**, who only has the statement $\mathbf{x}$, that $R(\mathbf{x}; \mathbf{w}) = 1$.
Importantly, the **proof** leaks _nothing_ about the secret witness $\mathbf{w}$. 
(e.g., a ZKP can be used to convince a verifier that the prover knows the solution $\mathbf{w}$ to a Sudoku puzzle $\mathbf{x}$, without leaking anything about the solution!)

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\relgen{\mathcal{R}}
\def\allrels{\relgen_\lambda}
$</div> <!-- $ -->

{% include defs-zkp.md %}

## Introduction

This blog post formalizes zero-knowledge proof (ZKP) systems, mostly deferring to Groth's formalization from [Grot16][^Grot16].

{: .note}
For a more mild, high-level introduction to ZKPs via a Sudoku puzzle example, see [these slides](https://docs.google.com/presentation/d/1b2FoHN983iA_ZkiISMCKa0JqlE40CeqaqNxWjWiJQjE/edit?usp=sharing).

### Preliminaries

 - We assume familiarity with the NP computational class and its [NP relation](/np-relations) characterization
 - Let $\negl(\cdot)$ denote a [negligible function](https://en.wikipedia.org/wiki/Negligible_function)
 - We denote NP relations by $R$
 - We denote an NP statement by $\stmt$ and a witness by $\witn$
 - We often denote $R(\stmt;\witn) = 1$ as $(\stmt, \witn)\in R$.
 - We use $(x\|\| y)\gets (\Adv\|\|\mathcal{X})(a)$ to denote that an algorithm $\Adv$ on input $a$ returns $x$ **and** another algorithm $\mathcal{X}$ on the same input $a$, _and the same random coins as $\Adv$_, returns $y$
 - We denote the set of all relations outputted by a relation generator $\relgen$ by $\allrels\bydef \mathsf{Image}(\relgen)$

## Algorithms

A zero-knowledge proof (ZKP) system is a tuple of algorithms:

 - a **relation generator**, used to formalize the fact that the ZKP works for all NP relations
 - a setup algorithm, used to generate the **proving key** and **verifying key** for an NP relation
 - a proving algorithm
 - a proof verification algorithm
 - a proof simulation algorithm

We describe each algorithm in detail below.

### $\mathcal{R}(1^\lambda) \rightarrow (R,\mathsf{aux})$
A **relation generator** that, given a security parameter $\lambda$ returns a binary relation $R(\stmt; \witn)$ decidable in polynomial time, together with some **auxiliary information** $\mathsf{aux}$[^aux].
The set of all possible binary relations it can output (i.e., its _image_) is denoted by $\allrels$.

{: .warning}
A recent impossibility result[^BCPR14]$^,$[^BP15] requires that the relation generator be **benign**. Otherwise, [knowledge-soundness](#knowledge-soundness) cannot be achieved.

{: .note}
Groth points out[^Grot16] that for ZKPs built from bilinear groups (e.g., [Groth16](/groth16)), it is natural to let the bilinear group be returned via $\mathsf{aux}$.

### $\mathsf{ZKP}.\mathsf{Setup}(1^\lambda, R) \Rightarrow (\mathsf{prk},\mathsf{vk},\mathsf{td})$  
Derives a **proving key** $\prk$ and its associated **verifying key** $\vk$ from the NP relation $R$.
Provers will use the (large) $\prk$ to create proofs.
Verifiers will use the (succinct) $\vk$ to verify proof.
Also, derives a **trapdoor** $\td$ (a.k.a., toxic waste) which can be used to simulate (fake) zero-knowledge proofs.

### $\mathsf{ZKP}.\mathsf{Prove}(\mathsf{prk}, \mathbf{x}; \mathbf{w}) \Rightarrow \pi$  
Computes a zero-knowledge proof $\pi$ for $R(\stmt;\witn) = 1$ using the proving key $\prk$.

### $\mathsf{ZKP}.\mathsf{Verify}(\mathsf{vk}, \mathbf{x}; \pi) \Rightarrow \\{0,1\\}$  
Verifies a zero-knowledge proof $\pi$ against the verifying key $\vk$.
The proof argues that the prover knows some witness $\witn$ such that $R(\stmt;\witn) = 1$, without leaking any information about $\witn$.

### $\mathsf{ZKP}.\mathsf{Sim}(\mathsf{td}, \mathbf{x}) \Rightarrow \pi$
Creates a zero-knowledge proof $\pi$ for $\stmt$, given **only** the simulation trapdoor $\td$.
This is referred to as **simulating a proof** [without access to a valid witness].
The simulated proof argues that the prover knows some witness $\witn$ such that $R(\stmt;\witn) = 1$, even though the prover does not actually know such a witness; it just has access to the trapdoor $\td$.
Importantly, the distribution of simulated proofs is indistinguishable from the distribution of honestly-generated proofs via $\zkpProve$.

{: .note}
The existence of a $\zkpSim$ algorithm is actually used to formalize the [zero-knowledge](#zero-knowledge) property of a ZKP system.

## Perfect correctness

**Correctness** says that any proof $\pi$ returned by $\zkpProve$ should verify via $\zkpVerify$.

{: .definition}
[**Perfect correctness**]:
$\forall$ security parameters $\lambda\in \mathbb{N}$, 
$\forall$ relations $R\in\allrels$, 
$\forall (\stmt,\witn) \in R$,
\begin{align}
\Pr\left[\begin{array}%
    (\prk,\vk,\cdot)\gets\zkpSetup(1^\lambda, R),\\\\\
    \pi\gets \zkpProve(\prk, \stmt; \witn) :\\\\\ 
    \zkpVerify(\vk,\stmt;\pi) = 1
\end{array}\right] = 1
\end{align}

The definition above can be relaxed by only requiring that the probability is non-negligible (i.e., $1-\negl(\lambda)$) instead of 1.

## Knowledge-soundness

Intuitively, **knowledge-soundness** says that if a proof verifies for a statment $\stmt$, then the prover knows a witness $\witn$ such that $R(\stmt; \witn) = 1$.
One way this is formalized is by saying that, for any adversary $\Adv$, there exists an **extractor** $\mathcal{X}_\mathcal{A}$
(potentially-specialized for $\Adv$[^bb-ext]) such that if $\Adv$ produces a valid proof $\pi$ for $\stmt$ then the extractor, given $\Adv$, the statement $\stmt$ and proof $\pi$ as input, produces a valid witness $\witn$.
(In fact, the opposite is what is typically formalized: that it is **not** possible for the adversary to output a valid proof whose witness cannot be extracted.)

{: .definition}
[**Computational knowledge-soundness**]:
$\forall$ security parameters $\lambda\in \mathbb{N}$, 
$\forall$ polynomial-time (non-uniform) adversaries $\Adv$,
$\exists$ a polynomial-time (non-uniform) **extractor** $\mathcal{X}\_\Adv$,
such that:
\begin{align}
\Pr\left[\begin{array}%
    (R,\mathsf{aux}) \gets \relgen(1^\lambda),\\\\\
    (\prk,\vk,\cdot)\gets\zkpSetup(1^\lambda, R),\\\\\
    \left((\stmt,\pi)\|\|\witn\right)\gets \left(\Adv\|\|\mathcal{X}\_\Adv\right)(\prk,\vk,R,\mathsf{aux}) :\\\\\ 
    (\stmt,\witn)\notin R \wedge \zkpVerify(\vk,\stmt;\pi) = 1
\end{array}\right] = \negl(\lambda)
\end{align}

{: .note}
Recall the $\left(\Adv\|\|\mathcal{X}\_\Adv\right)(\prk,\vk,R,\mathsf{aux})$ notation from the [preliminaries](#preliminaries).

{: .todo}
Describe **computational soundness** and explain where it suffices.

## Zero-knowledge

The notion of a _zero-knowledge_ proof  was first proposed by Goldwasser, Micali and Rackoff[^GMR85] and later generalized to any NP language by Goldreich, Micali and Wigderson[^GMW86].

The key idea around defining _zero-knowledge_ is to show that there exists a $\zkpSim$ algorithm, similar to the $\zkpProve$ proving algorithm albeit with a bit more **power**, that can produce proofs with the _same statistical distribution_ for any statement $\stmt$ but without actually knowing a witness $\witn$.

This is formalized by arguing that no adversary can distinguish between proofs produced via $\zkpProve$ and those produced via $\zkpSim$.

For the purpose of this blog post, the simulator's extra **power** will be that it knows the trapdoor $\td$ behind the proving key $\prk$.

{: .definition}
[**Perfect zero-knowledge**]:
$\forall$ security parameters $\lambda\in \mathbb{N}$, 
$\forall (\stmt,\witn) \in R$, where $(R,\mathsf{aux})\gets \relgen(1^\lambda)$,
$\forall$ adversaries $\Adv$,
\begin{align}
\Pr\left[\begin{array}%
    (\prk,\vk,\td)\gets\zkpSetup(1^\lambda, R),\\\\\
    \pi\gets \zkpProve(\prk, \stmt; \witn) 
    :\\\\\ 
    \Adv(\prk,\vk,\td,\mathsf{aux};\pi) = 1
\end{array}\right]
= 
\Pr\left[\begin{array}%
    (\prk,\vk,\td)\gets\zkpSetup(1^\lambda, R),\\\\\
    \pi\gets \zkpSim(\td, \stmt)
    :\\\\\ 
    \Adv(\prk,\vk,\td,\mathsf{aux};\pi) = 1
\end{array}\right]
\end{align}

{: .note}
The adversary is even given the trapdoor $\td$.
Note that because we say "for all $(\stmt,\witn,\Adv)$" this means the adversary _can_ have access to $(\stmt,\witn)$.

### The many flavors of zero-knowledge

 > _"The very notion of a zero-knowledge proof is interesting only in case the assertion being proved to be valid is hard to verify in probabilistic polynomial time"_ --Oded Goldreich (Why? Otherwise, membership of $\mathbf{x} \in L$ is easily-verifiable in polynomial time.)

There are many ways of defining the zero-knowledge property of a ZKP scheme.

 - **Interactive:** Some proof systems are **interactive**. 
   Their zero-knowledge property is defined in terms of the existence of a simulator who, unlike a dishonest verifier, need not interact with the prover.
   This gives the simulator a bit more power to forge proofs.
 - **HVZK + Fiat-Shamir**: Some interactive proof systems (e.g., Bulletproofs[^BBBplus18]) satisfy a relaxed version of zero-knowledge, called **honest-verifier zero-knowledge (HVZK)**, where the verifier cannot be malicious and must follow the protocol.
   Such schemes are then converted to non-interactive ZKP schemes via the Fiat-Shamir (FS)[^FS87] transform.

<!--
 - Other proof systems may not have a trapdoorable reference string at all. (Which? What extra power does the simulator have?)

{: todo}
Rex's definition where the simulator generates the non-trapdoored CRS.
-->

---

[^aux]: The auxiliary information helps model adversarial relation generators and circumvent impossibility results[^BCPR14]$^,$[^BP15] around them.
[^bb-ext]: This order of quantifiers ($\forall \Adv$, $\exists$ an extractor) implies that the extractor gets full access to the adversary's state and its randomly-tossed coins, if any. A stronger property would be _black-box extraction_ which say $\exists \mathcal{X},\forall \Adv$ **and** the extractor $\mathcal{X}$ only gets oracle access to $\Adv$ (e.g., cannot rewind it; does not see its "code" or state). There is quite a zoo of notions here to be unpacked.

{% include refs.md %}
