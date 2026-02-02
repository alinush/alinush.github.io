---
tags:
 - accumulators
 - trusted setup
 - Merkle
 - RSA
title: Are there cryptographic accumulators without trusted setup?
#date: 2020-11-05 20:45:59
published: true
#sidebar:
#    nav: cryptomat
---

{: .info}
**tl;dr:** Yes, there are: Merkle-based, RSA-or-class-group based and lattice-based ones.

<!--more-->

<p hidden>$$
\def\Adv{\mathcal{A}}
\def\Badv{\mathcal{B}}
\def\vect#1{\mathbf{#1}}
$$</p>

---

## RSA accumulators over class groups

Practically, the only (somewhat-fast) accumulators *without* trusted setup (and constant-sized proofs) are RSA accumulators[^Bd93] instantiated _with great care_[^BKSW20] over class groups[^Lipm12].

## Merkle-based accumulators

Theoretically 😄, if you relax your definition of "accumulators" by:

 1. Removing quasi-commutativity[^Bd93].
 2. Allowing for logarithmically-sized proofs (instead of constant-sized proofs)

...then, naturally you can use a Merkle prefix tree (a.k.a., a Merkle trie) to represent a set and obtain an accumulator.

Another approach is to either use (1) a binary search tree or (2) a tree with sorted leaves, where each internal node stores the minimum and the maximum element in its subtree[^BLL00].

Similarly, you can also use the rather beautiful Utreexo construction[^Dryj19], which is also Merkle-based but does not support non-membership proofs.

## Lattice-based accumulators

Even more theoretically 😆, assuming you don't care about performance at all, you might use a lattice-based accumulator[^PSTY13],[^JS14],[^LLNW16],[^LNWX17]. Some of them do not need a trusted setup, like [^PSTY13].

Even better, the recent lattice-based vector commitments by Peikert et al.[^PPS21e] can be turned into an accumulator. (Interestingly, I think accumulator proof sizes here could be made "almost" $O(\log_k{n})$-sized, for arbitrary $k$, if one used their lattice-based Verkle construction which, AFAICT, requires a trusted setup.)

## RSA moduli of unknown complete factorization (UFOs)

One last theoretical idea is to generate an RSA group with a modulus $N$ of unknown factorization using the _"RSA UFO"_ technique by Sander[^Sand99]. Unfortunately, such $N$ are too large and kill performance.
Specifically, instead of the typical 2048-bit or 4096-bit, RSA UFO $N$'s are hundreds of thousands of bits (or larger?). Improving this would be a great avenue for future work.

{% include refs.md %}
