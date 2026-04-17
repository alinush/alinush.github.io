---
tags:
 - Fiat-Shamir
 - sigma protocols
 - post-quantum
title: "The quantum security of Fiat-Shamir in $\\Sigma$-protocols"
#date: 2020-11-05 20:45:59
published: false
permalink: quantum-fiat-shamir
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Sigma protocols are unconditionally sound, but their non-interactive (Fiat-Shamir) counterparts only have computational soundness.
Against quantum adversaries, $\lambda$-bit Fiat-Shamir challenges give only $\approx\lambda/2$ bits of security (due to Grover search), and the classical ROM soundness proof does not carry over to the quantum ROM (QROM) because rewinding-based extraction breaks on superposition queries.
This post surveys the key results chronologically.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\ROM{\mathsf{ROM}}
\def\QROM{\mathsf{QROM}}
\def\Sig{\Sigma}
\def\Ext{\mathsf{Ext}}
\def\Hash{\mathcal{H}}
$</div> <!-- $ -->

## Background: sigma protocols and Fiat-Shamir

A **3-move sigma protocol** $\Sig$ for a relation $R$ is a public-coin interactive proof with the structure:
1. **Commit**: the prover sends a first message $\alpha$
2. **Challenge**: the verifier sends a random challenge $c \randget \\{0,1\\}^\lambda$
3. **Response**: the prover sends a response $z$

The verifier accepts or rejects based on $(\alpha, c, z)$ and the public statement $x$.

Sigma protocols satisfy **special soundness**: given two accepting transcripts $(\alpha, c, z)$ and $(\alpha, c', z')$ with the same commitment $\alpha$ but different challenges $c \ne c'$, one can efficiently extract a witness $w$ for $x$.
This is an _information-theoretic_ property — it holds against computationally-unbounded adversaries.

The **Fiat-Shamir transform**[^FS87] makes $\Sig$ non-interactive by replacing the verifier's random challenge with a hash: $c = \Hash(x, \alpha)$.
The prover computes the proof $\pi = (\alpha, z)$ entirely on its own, and anyone can verify by recomputing $c = \Hash(x, \alpha)$ and checking the transcript $(\alpha, c, z)$.

### Classical security (ROM)

In the **random oracle model (ROM)**, Fiat-Shamir soundness is _computational_.
An adversary making $q$ random oracle queries can break soundness with probability at most:

$$\Pr[\text{forgery}] \le \frac{q + 1}{2^\lambda}$$

This is because, for each commitment $\alpha$ the adversary tries, the hash $\Hash(x, \alpha)$ returns a uniformly random challenge. Without the witness, the adversary can answer at most one challenge per commitment (by special soundness). So each query succeeds with probability $1/2^\lambda$, and $q$ queries give $q/2^\lambda$.

**Extraction** (knowledge soundness) works via the **forking lemma**: run the adversary once to get an accepting transcript $(\alpha, c, z)$, then _rewind_ it with the oracle reprogrammed at $(\alpha, c)$ to a fresh challenge $c'$. If the adversary succeeds again, you extract via special soundness. This costs an $O(q)$ factor in the reduction.

**Bottom line:** $\lambda$-bit challenges give $\lambda$-bit classical security.

## What goes wrong quantumly?

A quantum adversary can query the hash function in **superposition**:

$$\sum_\alpha \ket{\alpha}\ket{0} \;\longrightarrow\; \sum_\alpha \ket{\alpha}\ket{\Hash(x, \alpha)}$$

This breaks the classical proof in two ways.

### Grover search halves soundness

Grover's algorithm lets a quantum adversary search over commitments $\alpha$ for one whose hash $c = \Hash(x, \alpha)$ yields an accepting transcript, in $O(\sqrt{2^\lambda}) = O(2^{\lambda/2})$ queries. More precisely, $q$ quantum queries succeed with probability:

$$\Pr[\text{forgery}] = O\!\left(\frac{q^2}{2^\lambda}\right)$$

So **$\lambda$-bit challenges give only $\lambda/2$ bits of quantum security** for soundness. This bound is tight — it matches the Grover attack.

### Extraction breaks: no cloning, no rewinding

For **knowledge soundness**, the situation is worse. The classical forking lemma relies on:
1. **Copying** the adversary's state (to rewind it)
2. **Reprogramming** the oracle at a single point
3. **Running** the adversary again with the new oracle

Against a quantum adversary, all three steps fail:
1. The **no-cloning theorem** forbids copying quantum states
2. **Measurement** of a superposition query to find out _which_ $\alpha$ the adversary cares about collapses the superposition and irreversibly disturbs the adversary's state
3. **Reprogramming** the oracle after measurement may be detectable by the adversary on subsequent superposition queries

This means entirely new proof techniques are needed in the QROM.

## Chronological survey of results

### 2013: Dagdelen, Fischlin, Gagliardoni — the first warning

Dagdelen, Fischlin, and Gagliardoni[^DFG13e] gave the first rigorous study of Fiat-Shamir in the QROM. Their main result is a **separation**: there exist (contrived) sigma protocols that satisfy special soundness classically, but whose Fiat-Shamir transform is _insecure_ against quantum adversaries.

The counterexample is artificial — they modify a secure sigma protocol so the commitment leaks information that is useless to a classical adversary but exploitable via superposition queries.

The takeaway: the generic implication

$$\text{special soundness} \implies \text{Fiat-Shamir is sound}$$

which holds in the classical ROM, does **not** hold in the QROM. You need additional structural properties from the sigma protocol.

{: .warning}
This does _not_ mean that natural sigma protocols (Schnorr, etc.) are insecure under Fiat-Shamir. It means the _generic_ theorem fails — each protocol needs a dedicated QROM proof.

### 2015: Unruh — first positive result

Unruh[^Unru14e] gave the first construction of non-interactive zero-knowledge proofs that are _provably_ secure in the QROM.
However, his construction required moving from a 3-move to a **5-move** protocol (adding extra rounds to enable quantum extraction), incurring significant overhead.

This showed that QROM-secure NIZKs are _possible_, but raised the question of whether the standard 3-move Fiat-Shamir transform itself could be proven secure.

### 2018: Kiltz, Lyubashevsky, Schaffner — concrete bounds

Kiltz, Lyubashevsky, and Schaffner[^KLS17e] gave the first **concrete, numerically-meaningful** security bounds for Fiat-Shamir signatures in the QROM.
They focused on Schnorr signatures and lattice-based signatures (Dilithium-style).

Their technique: reduce security to the underlying hard problem via a **lossy identification scheme** paradigm adapted to the quantum setting.
The reduction loses a factor of roughly $O(q_s \cdot q_h)$ where $q_s$ is the number of signing queries and $q_h$ is the number of hash queries — **not tight**, but concrete enough for real-world parameter selection.

This work directly influenced the parameter choices in NIST's post-quantum signature standard (ML-DSA/Dilithium).

### 2019: Don, Fehr, Majenz, Schaffner — measure-and-reprogram

Don, Fehr, Majenz, and Schaffner (DFMS)[^DFMS19e] introduced the **measure-and-reprogram** technique, which became the dominant framework for extraction in the QROM.

The idea:
1. Pick a random query index $i \in [q]$
2. When the adversary makes its $i$-th quantum RO query, **measure** the input register to obtain some value $(x, \alpha)$
3. **Reprogram** $\Hash$ at $(x, \alpha)$ to a fresh random challenge $c'$
4. Let the adversary continue
5. If it produces a valid proof for the same $(x, \alpha)$, you now have two accepting transcripts $\to$ extract via special soundness

The key insight is that this avoids rewinding entirely — extraction happens **online**, at the time of the query.

The cost: a factor of $O(q)$ loss from guessing which query to measure, plus additional loss from the measurement disturbance. They proved **simulation-extractable** security for Fiat-Shamir NIZKs under conditions on the sigma protocol (computational unique responses).

### 2019: Liu and Zhandry — compressed oracles

Independently, Liu and Zhandry[^LZ19e] proved Fiat-Shamir secure in the QROM using a different technique: Zhandry's **compressed oracle**.

Their results come in two parts:
1. **Soundness:** A general QROM proof for Fiat-Shamir using compressed oracles, requiring no special structural assumptions on the sigma protocol beyond the standard ones.
2. **Knowledge soundness (extraction):** New proof techniques for quantum rewinding, requiring additional properties. They define **collapsing sigma protocols** (inspired by Unruh's collapsing hash functions) and give two sufficient conditions: _compatible lossy functions_ and _compatible separable functions_. They show that lattice-based sigma protocols (specifically Lyubashevsky's scheme) satisfy these conditions under SIS/LWE, proving that lattice-based Fiat-Shamir signatures are secure in the QROM without any modifications to the scheme.

The security loss is $O(q^9)$ — looser than DFMS's $O(q)$ — but via a conceptually different route that avoids measure-and-reprogram entirely.

### 2022: DFMS — online extractability

In a follow-up, Don, Fehr, Majenz, and Schaffner[^DFMS21e] formalized the **online-extractability** framework as a general tool.
The core lemma: any quantum adversary that makes $q$ random oracle queries and produces an output related to one of its queries can be "online-extracted" — i.e., a simulator can extract the relevant query input at query time — with a loss factor of $O(q)$.

This unified and strengthened their earlier results, and the measure-and-reprogram lemma became the standard tool for QROM proofs.

### 2023: DFMS — commit-and-open protocols

Don, Fehr, Majenz, and Schaffner[^DFMS22e] extended the framework beyond classical sigma protocols to **commit-and-open** protocols.
This covers MPC-in-the-head constructions (e.g., Picnic-like signatures), broadening the reach of QROM security proofs.

## Summary: the security landscape

| Setting | Soundness | Knowledge soundness |
|---------|-----------|-------------------|
| **Classical ROM** | $O(q/2^\lambda)$ | $O(q/2^\lambda)$ via forking lemma |
| **QROM (attack)** | $O(q^2/2^\lambda)$ — Grover, tight | $O(q^2/2^\lambda)$ — Grover |
| **QROM (proven)** | $O(q^2/2^\lambda)$ — tight | $\approx O(q^3/2^\lambda)$ — extraction overhead |

**Practical rule of thumb:** to get $\lambda$-bit quantum security, use $2\lambda$-bit challenges (i.e., double the challenge length).

## Open problems

1. **Tight knowledge soundness in the QROM.** The proven extraction bound loses an extra $O(q)$ factor beyond the Grover attack. Is this a proof artifact, or is there an adversary that can produce valid Fiat-Shamir proofs but somehow resist witness extraction?

2. **Multi-round Fiat-Shamir.** Modern proof systems (Bulletproofs, STARKs, Plonk) use Fiat-Shamir on multi-round interactive proofs, not just 3-move sigma protocols. The security loss in the QROM grows with the number of rounds, and tight bounds are not known.

{% include refs.md %}
