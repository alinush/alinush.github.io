---
tags: 
 - accumulators
 - aggregation
 - RSA
 - hidden-order groups
title: RSA Accumulators
#published: false
sidebar:
    nav: cryptomat
permalink: rsa-accumulators
---

An **RSA accumulator** is an _authenticated set_ built from cryptographic assumptions in hidden-order groups such as $\mathbb{Z}_N^*$.
RSA accumulators enable a **prover**, who stores the full set, to convince any **verifier**, who only stores a succinct **digest** of the set, of various set relations such as (non)membership, subset or disjointness.
For example, the prover can prove membership of elements in the set to verifiers who have the digest.

<!--more-->

<p hidden>$$
\def\Adv{\mathcal{A}}
\def\Badv{\mathcal{B}}
\def\GenGho{\mathsf{GenGroup}_?}
\def\Ghosz{|\Gho|}
\def\Ghoid{1_{\Gho}}
\def\primes{\mathsf{Primes}}
\def\QRn{\mathsf{QR}_N}
\def\multirootexp{\mathsf{MultiRootExp}}
\def\rootfactor{\mathsf{RootFactor}}
\def\vect#1{\mathbf{#1}}
$$</p>

The _digest_ of the set is often referred to as the _accumulator_ of the set.
<!-- TODO: Link to RSA assumptions post -->

RSA accumulators were introduced by _Benaloh and de Mare_[^Bd93] and later extended by _Li et al._[^LLX07] with non-mmebership proofs.
Recently, Boneh et al.[^BBF18] extended RSA accumulators with many new features.

{: .warning}
This post is not a full treatment of RSA accumulators, but will be extended over time.

## Digest (or accumulator) of a set

Let $H$ be a collision-resistant hash function that maps its input to prime numbers.
Let $g$ be the generator of a hidden-order group $\Gho$ where the Strong RSA problem is hard.
<!-- TODO: reference assumptions -->
Let $T = \\{b_1, b_2, \dots, b_n\\}$ and let $e_i = H(b_i)$ be the _prime representative_ of $b_i$.

The accumulator of $T$ is:

$$a = g^{\prod_{i\in[n]} e_i}$$

Note that this can be computed in $O(n)$ exponentiations in $\Gho$.

## Membership witnesses

To prove that $b_i$ is in the accumulator, a _membership witness_ can be computed: 

$$w_i = g^{\prod_{j\in[n]\setminus\{i\}} e_j} = a^{1/e_i}$$

Note that the witness is simply the accumulator of the set $T \setminus \\{b_i\\}$ and is just an $e_i$th root of $a$!

{: .warning}
Unfortunately, computing this root cannot be done using an exponentiation by $1/e_i$ because $e_i$ cannot be inverted without knowing the order of the group $\Gho$.
Instead, computing $w_i$ has to be done by exponentiating $g$ by the $n-1$ different $e_i$'s and thus takes $O(n)$ time, which can be slow.
We explain [below](#precomputing-all-membership-witnesses-fast) how this can be done in $O(\log{n})$ amortized time per witness.

To verify the witness against the accumulator $a$, one checks if:

$$a \stackrel{?}{=} w_i^{e_i}$$

In other words, one simply "adds back" $b_i$ to the set accumulated in $w_i$ and checks if the result equals $a$.
This takes one exponentiation in $\Gho$.

Membership witnesses can be easily generalized into _batch membership witnesses_.
For example, if one wants to prove that all $(b_i)_{i\in I}$ are in the accumulator, they can compute:

$$w_I = g^{\prod_{i\in[n]\setminus I} e_i} = a^{1/ \prod_{i\in I} e_i}$$

The verification proceeds analogously but takes $O(\vert I \vert)$ exponentiations:

$$a \stackrel{?}{=} w_i^{\prod_{i\in I}e_i}$$

## Precomputing all membership witnesses fast

Computing all $n$ membership witnesses naively takes $O(n^2)$ exponentiations in $\Gho$, which does not scale well.
Fortunately, _Sander et al._[^SSY01] give a divide-and-conquer approach for computing all witnesses which takes $O(n\log{n})$ exponentiations in $\Gho$. 

The key observation is that half of the witnesses require computing $g^{\prod_{i\in[1,n/2]} e_i}$ while the other half require computing $g^{\prod_{i\in[n/2+1,n]} e_i}$.
If done naively, these computations would be repeated many times unnecessarily.
But one could compute the witnesses recursively in a tree-like fashion as follows ($n=8$ in this example):

<div align="center"><img style="width:100%" src="/pictures/rsa-membwit-precomp.png" /></div>

{: .info}
**Intuition:**
You can think of each node as (1) a set of elements and (2) its _batch membership witness_ w.r.t. the accumulator $a$. 
Then, this algorithm simply splits the set into two halves and disaggregates the witness into witnesses for the two halves.
This repeats until witnesses for individual elements are obtained at the bottom.

In other words, this algorithm computes every $e_i$th root of $a$ (i.e., $g^{e_1 \dots e_{i-1} e_{i+1} \dots e_{n}}$) for all $i\in[n]$.
The time to compute a tree of size $n$ leaves can be defined recursively as $T(n) = 2T(n/2) + O(n)$ because the amount of work done at the root of a size-$n$ subtree is $O(n)$ exponentiations plus the time to recurse on its two children.
This gives $T(n) = O(n\log{n})$ exponentiations.

Boneh et al.[^BBF18] baptised this algorithm as $$\rootfactor$$.
Specifically, 

$$\rootfactor(g, (e_i)_{i\in[n]}) = (w_i)_{i\in[n]} = (a^{1/e_i})_{i\in[n]} = \left((g^{\prod_{j\in[n]} e_j})^{1/e_i}\right)_{i\in[n]}$$

<!-- **TODO:** Future post: update membership, aggregate membership, non-membership witnesses + update, subset relations, disjointness relations -->

## More to come

There is so much more to be said about RSA accumulators!
Hopefully, we will update this post over time with:

 - Accumulator updates
 - Membership witness updates
 - Cross-incremental (dis)aggregation of membership witnesses[^TXN20e]
 - Non-membership witnesses
    + Updates
    + Aggregation
 - Disjointness witnesses[^Tome20]
 - Subset witnesses[^Tome20]
 - Leveraging the trapdoor (RSA factorization) to compute witnesses and accumulators faster
    + And when it should _not_ be used
 - Instantiating RSA accumulators over class groups

[^Bd93]: **One-Way Accumulators: A Decentralized Alternative to Digital Signatures**, by Benaloh, Josh and de Mare, Michael, *in EUROCRYPT '93*, 1994
[^BBF18]: **Batching Techniques for Accumulators with Applications to IOPs and Stateless Blockchains**, by Dan Boneh and Benedikt Bünz and Ben Fisch, *in Cryptology ePrint Archive, Report 2018/1188*, 2018, [[URL]](https://eprint.iacr.org/2018/1188)
[^LLX07]: **Universal Accumulators with Efficient Nonmembership Proofs**, by Li, Jiangtao and Li, Ninghui and Xue, Rui, *in Applied Cryptography and Network Security*, 2007
[^SSY01]: **Blind, Auditable Membership Proofs**, by Sander, Tomas and Ta-Shma, Amnon and Yung, Moti, *in Financial Cryptography*, 2001
[^TXN20e]: **Authenticated Dictionaries with Cross-Incremental Proof (Dis)aggregation**, by Alin Tomescu and Yu Xia and Zachary Newman, *in Cryptology ePrint Archive, Report 2020/1239*, 2020, [[URL]](https://eprint.iacr.org/2020/1239)
[^Tome20]: **How to Keep a Secret and Share a Public Key (Using Polynomial Commitments)**, by Tomescu, Alin, 2020, [[URL]](https://alinush.github.io/papers/phd-thesis-mit2020.pdf)
