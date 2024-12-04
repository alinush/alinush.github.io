---
layout: article
title: Please solve!
key: page-please-solve
aside:
  toc: true
permalink: /please-solve
#article_header:
#  type: cover
#  image:
#    src: /pictures/pitesti.jpg
---

These are great research problems to solve that I wish I had time to work more on.

## Efficient homomorphic Merkle trees

A homomorphic Merkle tree has an extremely useful property: given a change $\Delta$ to one of its leaves $\ell$, every node in the tree can be updated homomorphically, knowing only the change $\Delta$ and the leaf $\ell$. In particular, the tree's root can be updated homorphically too, which can be very useful!

In contrast, a non-homomorphic tree such as a SHA2-based one, requires first updating that node's child, which in turn requires the child's child to be updated and so on.

Homomorphic Merkle trees are great for stateless cryptocurrencies and, in general, make data outsourcing and sharding more efficient. (Maybe I will expand on this in a blog post later on, since it may not be immediately obvious why.)

The state of the art construction is by Papamanthou et al.[^PSTY13] from lattices.
However, its efficiency is not great.
In particular, when parameterized to instantiate a depth-256 prefix tree, it is likely very inefficient.
(Some performance numbers were initialy explored in an earlier version of Edrax[^CPZ18].)

**Open problem 1:** Devise a homomorphic Merkle tree construction that can support a large number of updates per second in one core (e.g., tens of thousands).

**Open problem 2:** Solve open problem 1 such that the Merkle tree can have up to $2^{256}$ leaves.

## Compress AMT proofs to KZG proofs

In my PhD thesis[^Tome20] (and a later paper[^TCZplus20]), we presented a different, tree-based mechanism to compute KZG polynomial commitment proofs.
It was dubbed _authenticated multipoint evaluation trees (AMTs)_.
I also described the AMT construction in this [blog post](http://localhost:4000/2020/03/12/towards-scalable-vss-and-dkg.html).

The advantage[^allproofs] of our $\log{n}$-sized AMT proofs is that, unlike $O(1)$-sized KZG proofs, they are **maintainable**.
Specifically, if one computes $n$ AMT proofs for, say, root-of-unity evaluation points $(\omega^0, \omega^1, \omega^2, \ldots, \omega^{n-1})$, then if the polynomial changes at one of those roots of unity, then one can efficiently update **all proofs** in $O(\log{n})$ time!

In contrast, to update all KZG proofs, this would require $O(n)$ time.

Maintainability is very important in some applications, as we later argued in Hyperproofs[^SCPplus22].
In the case of both AMT and Hyperproofs, maintainability unfortunately comes at the cost of no longer being able to efficiently aggregate proofs.
(At least not without inner-product arguments (IPAs) or SNARKs.)
In contrast, KZG proofs were efficiently aggregatable[^TABplus20]$^,$[^GRWZ20] but not maintainable.

**Open problem 1:** Devise a mechanism to convert an AMT proof to a KZG proof, thereby compressing it. Or prove such a mechanism cannot exist under certain hardness assumptions.

**Open problem 2:** Devise a mechanism to aggregate AMT proofs that does not rely on expensive primitives like IPAs or SNARKs.

**Open problem 3:** Devise either an _authenticated dictionary_ or a _vector commitment_ scheme that:
 1. has **efficiently**-aggregatable proofs
 1. is maintainable
 1. is homomorphic, both for proofs and commitments
 1. lacks a trusted setup (or has public parameters sublinearly-sized in the max dictionary size)

(Note that this is slightly harder than the [homomorphic Merkle tree](#efficient-homomorphic-merkle-trees) problem, which only requires bullets 1 and 2.)

[^allproofs]: At the time, we devised AMTs for another reason: we wanted to compute proofs faster than $O(n^2)$ time and the FK technique[^FK20] for computing $n$ KZG proofs in $n\log{n}$ time was not known yet.


## PVSS for field elements

**Open problem:** Can we achieve more efficient constructions than Groth'21[^Grot21e] and class group ones[^CD23e]$^,$[^KMMplus23e]? In order of importance: faster verification, faster dealing and smaller transcript size.

---

{% include refs.md %}
