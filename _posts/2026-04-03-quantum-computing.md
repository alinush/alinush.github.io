---
type: note
tags:
 - post-quantum
 - Shor
title: Quantum computing
#date: 2020-11-05 20:45:59
#published: false
permalink: quantum
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** What has happened in quantum computing over the years.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## A history

In 2001, Vandersypen et al. claimed an "experimental realization" of Shor's quantum factoring algorithm[^VSBplus01].
Their results demonstrate feasibility of building very small, highly specialized quantum circuits.
Specifically, they show a quantum circuit tailored for factoring 15, **but** in designing this circuit they leveraged knowledge of its factorizaton (i.e., $3\times5 = 15$).
Naturally, the relevance of these results has been questioned, most notably by Smolin et al.[^SSV13] who write:

> While there is no objection to having a classical compiler help design a quantum circuit (indeed, probably all quantum computers will function in this way), it is not legitimate for a compiler to know the answer to the problem being solved. To even call such a procedure compilation is an abuse of language.

Others, have been less gentle and mocked this kind of "experimental realization"[^GN25e].

{: .todo}
There might've been full runs that factor 15 [after](https://x.com/dallairedemers/status/2041565238357848527?s=46).

{: .todo}
Google's results: Willow, error-correction, new ECDLP algorithm.
Oratomic's result.
This result[^FFEB26].
[Craig Gidney's post](https://algassert.com/post/2500) and his past paper on Shor.

## Some interesting readings

 - [Lecture 14: Skepticism of quantum computing](https://scottaaronson.com/democritus/lec14.html), Scott Aaronson, Fall 2006
 - [Reasons to believe II: quantum edition](https://scottaaronson.blog/?p=124), Scott Aaronson, September 8th, 2006
 - [Mistake of the Week: "X works on paper, but not in the real world"](https://scottaaronson.blog/?p=148), Scott Aaronson, October 26th, 2006
    + Scott does away with the well-known _"in theory, theres no difference between theory and practice; in practice, there is."_ quote, saying _"In theory, there's no difference between theory and practice even in practice."_ (Otherwise, the theory is wrong and thus no longer a theory.)
 - [NSA and IETF: Can an attacker simply purchase standardization of weakened cryptography](https://blog.cr.yp.to/20251004-weakened.html), Daniel J. Bernstein, October 2025
 - [Factoring is not a good benchmark to track Q-day](https://bas.westerbaan.name/notes/2026/04/02/factoring.html), Bas Westerbaan, April 2nd, 2026
 - [Bitcoin and Quantum Computing](https://nehanarula.org/2026/04/03/bitcoin-and-quantum-computing.html), Neha Narula, April 3rd, 2026

## Blockchain space responses (chronological)

 - March 2nd, 2022: Algorand [announced](https://medium.com/algorand/algorand-state-proofs-707d64038e35) future support for [state proofs](https://dev.algorand.co/concepts/protocol/state-proofs/) using [Falcon digital signatures](https://github.com/algorand/falcon)
 - September 7th, 2022: [Algorand Protocol Upgrade Introduces State Proofs for Trustless Cross Chain Communication and 5x Faster Performance](https://medium.com/algorand/algorand-protocol-upgrade-introduces-state-proofs-for-trustless-cross-chain-communication-51b4cc21a9f3), _by Algorand_
 - October 15th, 2025: [EIP-8051: Precompile for ML-DSA signature verification](https://eips.ethereum.org/EIPS/eip-8051), _by 	Renaud Dubois and Simon Masson_
 - November 3rd, 2025: [Technical Brief: Quantum-resistant transactions on Algorand with Falcon signatures](https://algorand.co/blog/technical-brief-quantum-resistant-transactions-on-algorand-with-falcon-signatures), _by Larkin Young_
 - December 9th, 2025: [AIP-137: Post-quantum Aptos accounts via SLH-DSA-SHA2-128s signatures](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-137-post-quantum-aptos-accounts-via-slh-dsa-sha2-128s.md), _by Alin Tomescu_
 - January 14th, 2026: [Announcing Project Eleven’s Series A](https://blog.projecteleven.com/posts/announcing-project-elevens-series-a), _by Project 11_
    + Mentions a [Solana testnet with ML-DSA support](https://x.com/SolanaFndn/status/2000948477568934084?s=20)
 - February 1st, 2026: [PR for "SIMD-0461: enabling falcon signature verification as a precompile"](https://github.com/solana-foundation/solana-improvement-documents/pull/461), _by [zz-sol](https://github.com/zz-sol)_

## TODOs

 - [The threshold theorem](https://en.wikipedia.org/wiki/Threshold_theorem) and the reasonableness of its assumptions
 - What do we know about CRQC's ability to break hash functions? e.g., BHT, Grover search. Is there a proof that you cannot do better asymptotically?
    + What do we know about quantum algorithms that attack the _structure_ of the hash function, rather than the idealized hash function?
 - There are many different approaches to building QCs. What are the universal metrics that we should be looking for to judge them?(# of "stable" logical qubits is a popular one, but deeply inadequate)

## References

For cited works, see below 👇👇

{% include refs.md %}
