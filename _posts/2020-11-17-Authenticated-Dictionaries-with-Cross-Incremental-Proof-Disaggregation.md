---
tags: 
 - RSA
 - vector commitments (VCs)
 - authenticated dictionaries
 - accumulators 
 - aggregation 
 - papers
 - stateless validation
 - hidden-order groups
title: Authenticated Dictionaries with Cross-Incremental Proof (Dis)aggregation
date: 2020-11-26 00:00:00
#published: false
#sidebar:
#    nav: cryptomat
---

{: .info}
**tl;dr:** We build an authenticated dictionary (AD) from Catalano Fiore vector commitments that has constant-sized, aggregatable proofs and supports a stronger notion of cross-incremental proof disaggregation.
Our AD could be used for stateless validation in cryptocurrencies with smart contract execution.
In a future post, we will extend this AD with stronger security, non-membership proofs and append-only proofs, which makes it applicable to transparency logging.

This is joint work with my brilliant (ex-)labmates from MIT, [Alex (Yu) Xia](https://twitter.com/SuperAluex) and [Zack Newman](https://github.com/znewman01).

**Authenticated dictionaries (ADs)** are an important cryptographic primitive which lies at the core of cryptocurrencies such as _Ethereum_ and of transparency logs such as _Certificate Transparency (CT)_.
Typically, ADs are constructed by Merkleizing a lexicographically-ordered data structure such as a binary search tree, a prefix tree or a skip list.
However, our work takes a different, more algebraic direction, building upon the [Catalano-Fiore (CF) vector commitment (VC) scheme](/catalano-fiore).
This has the advantage of giving us _constant-sized_ proofs which are updatable and aggregatable, with a novel notion of **cross-incrementality**.
Importantly, this combination of feautres is not supported by Merkle trees or any other previous VC scheme.

<!--more-->

In a nutshell, in this post, we:

 - Extend CF with a larger index space to accommodate dictionary keys, obtaining an authenticated dictionary,
 - Extend our AD to support updating proofs and digests after removing keys from the dictionary,
 - Introduce a novel notion of **cross-incremental proof (dis)aggregation** w.r.t. different ADs

In a future post, we will explain how we:
 
 - Strengthen our AD's security to handle more adversarial settings such as transparency logs,
 - Add proofs of non-membership,
 - Add append-only proofs.

Our algebraic approach is not novel in itself and we relate to the previous line of work that explores building ADs from non-Merkle techniques in **our full paper**[^TXN20e].
You can also see a quick comparison in our [zkStudyClub slides](https://github.com/alinush/authdict-talk/raw/zkstudyclub/talk.pdf).

## Preliminaries

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

We often use the following notation:

 - $\lambda$ denotes the security parameter of our schemes
 - $[n] = \\{1,2,\dots, n\\}$
 - We denote a vector using a **bolded** variable $\vect{v} = [v_1, \dots, v_n]$
 - $\Gho$ denotes the hidden-order group our constructions use 
    + e.g., $$\Gho = \ZNs =\{a \mathrel\vert \gcd(a,N) = 1\}$$
 - Let $D$ be a dictionary over a set of keys $K$ that maps each key $k\in K$ to its value $v = D(k)$
 - We sometimes use $k\in D$ to indicate that key $k$ has some value in the dictionary
 - We sometimes use $(k,v)\in D$ notation to indicate that key $k$ has value $v$ in the dictionary
 - We sometimes use $D' = D\setminus K$ to refer to the new dictionary $D'$ obtained after removing all keys in $K$ (and their values) from the dictionary $D$

This post assumes knowledge of:

 - Greatest common divisor (GCD) of two integers $x, y$ denoted by $\gcd(x,y)$
 - The Extended Euclidean Algorithm (EEA) for computing Bezout coefficients $x,y\in \Z$ such that $ax + by = \gcd(a,b)$
 - [RSA accumulators](rsa-accumulators)
    - An RSA accumulator for a set $$T = \{b_1, \dots, b_n\}$$ of elements where each $b_i$ can be hashed to a _prime representative_ $e_i$ is $$a = g^{\prod_{i \in [n]} e_i}$$.
    - An RSA _membership witness_ for $b_i$ is just $$w_i = a^{1/e_i} = g^{\prod_{j\in[n], j\ne i} e_j}$$.
    - To verify it, just check $w_i^{e_i} = a$.
    + Recall all RSA membership witnesses can be computed using an algorithm by _Sander et al._[^SSY01] baptised as $$\rootfactor$$ by _Boneh et al._[^BBF18].
    + Specifically, $$\rootfactor(g, (e_i)_{i\in[n]}) = (w_i)_{i\in[n]} = (a^{1/e_i})_{i\in[n]} = \left((g^{\prod_{j\in[n]} e_j})^{1/e_i}\right)_{i\in[n]}$$
 - [Catalano-Fiore Vector Commitments](/catalano-fiore)
    + Let $H$ be a collision-resistant hash function that maps a vector position $i$ to an $\ell+1$ bit prime $e_i$ such that $2^\ell < e_i < 2^{\ell+1}$
    - The digest of a vector $\vect{v} = [v_1, \dots, v_n]$ is $d(\vect{v}) = (S, \Lambda)$ where:
        + $S = g^{\prod_{i\in[n]} e_i}$ (i.e., an RSA accumulator over all vector indices $i$)
        - $\Lambda = \prod_{i\in [n]} (S^{1/e_i})^{v_i}$
        - Note that $\Lambda$ is a multi-exponentiation, where:
            + The bases are RSA witness $S^{1/e_i}$ for $i$, 
            + The exponents are the elements $v_i$!
    - A proof $\pi_I = (S_I, \Lambda_I)$ for an $I$-subvector $(v_i)_{i\in I}$ is just the digest of $\vect{v}$ without the positions $i\in I$ in it.
        - $S_I = S^{1/\prod_{i\in I} e_i}$ (i.e., an RSA accumulator over all indices except the ones in $I$)
        - $\Lambda_I = \prod_{i\in[n]\setminus I} (S_I^{1/e_i})^{v_i}$
        - Again, note that $\Lambda_I$ is a multi-exponentiation, where:
            + The bases are RSA witnesses $S_I^{1/e_i}$ for each $i\in[n]\setminus I$ (but w.r.t. $S_I$)
            + The exponents are elements $v_i$ for all $i\in[n]\setminus I$
    - Digests and proofs are [updatable](/catalano-fiore#updating-digest)
    - Proofs are [incrementally _(dis)aggregatable_](/catalano-fiore#disaggregating-proofs)

## Authenticated dictionary (AD) schemes

First, forget about _authenticated dictionaries_ and let's talk about good old plain _dictionaries_!
Dictionaries are a set of **key-value pairs** such that each **key** is mapped to one **value**.
(We stick to one value per key here, but one could define dictionaries to have multiple values per key too.)
The keys are elements of a **key space** which, for our purposes, is the set of strings of length $2\lambda$ bits.

{: .info}
**Example:** Your phone's contacts list is a dictionary: it maps each contact's phone number (i.e., the key) to that contact's name (i.e., the value).
Similarly, your French-to-English dictionary maps each French word (i.e., the key) to its English counterpart (i.e., the value).

Second, what does it mean to _authenticate_ a dictionary?
The idea is to outsource storage of the dictionary to a **prover** while allowing one or more **verifiers** to correctly **look up** the values of keys in the dictionary.
For this to work, the verifiers must be able to somehow verify the values of keys claimed by the prover.
It should be clear that if the verifiers store nothing, there is nothing they can verify these claims against.
Thus, verifiers must store _something_.
Since the goal is to outsource storage of the data structure, verifiers will only store a succinct representation of the dictionary called a **digest**.
Importantly, while the dictionary might be very large (e.g., the contacts list of a social butterfly), the digest will actually be constant-sized (e.g., 32 bytes).

Third, how do verifiers look up in authenticated dictionaries? 
Verifiers simply ask the prover for a key's value!
Then, the prover replies with the value together with a **lookup proof** that the verifier checks against the digest!

{: .info}
**Example:** Some of you might be familiar with Merkle prefix trees.
Consider a "sparse" prefix tree that maps each key to a unique leaf.
This is best explained by Laurie and Kasper[^LK15] but, simply put, each key is hashed to a unique path in the tree whose leaf stores that key's value.
The _digest_ is the Merkle root hash of this Merkle prefix tree.
A _lookup proof_ is the Merkle sibling path to the key's value in the prefix tree.

## Our updatable AD for stateless validation


We start with a **simple observation**: the CF VC scheme can be repurposed into an authenticated dictionary scheme by treating the vector indices as the dictionary's keys[^obs1].
Recall that CF VCs use a collision-resistant hash function $H$ that maps a vector position $i$ to an $(\ell+1)$-bit prime $e_i$ such that $2^\ell < e_i < 2^{\ell+1}$.

We let $e_k = H(k)$ for each key $k$ in the dictionary.
Then, the dictionary's digest is:
\begin{align}
    S &= g^{\prod_{k\in D} e_k}\\\\\
    c &= \prod_{(k,v) \in D} (S^{1/e_k})^v
\end{align}
Note that this is just a CF commitment to a "very sparse" vector, with indices in the key space of the dictionary
(The key space is of size $2^{2\lambda}$ since it contains all strings of length $2\lambda$ bits.)
In other words, the dictionary's key is the vector's index while the key's value is the vector element at that index.
Because of this, all the properties of CF VCs carry over to our authenticated dictionary: constant-sized public parameters, incremental proof (dis)aggregation, proof updates and proof precomputation.

Nonetheless, we further enhance this AD by making it more updatable and more (dis)aggregatable.
We call the resulting AD an **updatable authenticated dictionary (UAD)**.

{: .info}
Note that ADs cannot be obtained in this fashion from any VC scheme.
For example, [KZG-based VCs](/asvc) do not support a sparse set of vector indices (but nonetheless other techniques[^Feis20Multi] can be used there).
However, some schemes like Catalano-Fiore[^CF13e] and Boneh et al's VC[^BBF18] do support sparse indices.
Indeed, Boneh et al.[^BBF18] also build an AD on top of their VC scheme, but it is not as (dis)aggregatable as ours.

### Updating the digest after removals

One new feature we add is updating the digest after a key and its value are _removed_ from the dictionary.
This is very easy to do thanks to the versatility of CF VCs.
First, recall that the proof for $(k,v)$ is just the digest of the dictionary $D$ but without $(k,v)$ in it.
Thus, if we remove $(k,v)$ from $D$, the new digest is just the proof for $(k,v)$!
If we do multiple removals, we can simply [aggregate](/catalano-fiore#aggregating-proofs) the proofs of all removed keys, which is just the digest of $D$ without those keys in it.
Thus, the new digest after multiple removals is simply this aggregated proof!

### Updating proofs after removals

We also have to add support for updating proofs after a key (and its value) is _removed_ from the dictionary.
Let's say we want to update an aggregated proof $\pi_K$ for a set of keys $K$ after removing a single key $\hat{k}$ with proof $\pi_{\hat{k}}$.
Recall that $\pi_K$ is the digest of $D\setminus K$.
Since the updated dictionary will be $$D\setminus \{\hat{k}\}$$, the updated proof $\pi_K'$ must be the digest of $$(D\setminus \{\hat{k}\}) \setminus K$$, which is just $$D\setminus (\{\hat{k}\}\cup K)$$.

So we must find a way to go from the digest of $D\setminus K$ and of $$D\setminus\{\hat{k}\}$$ to the digest of $$D\setminus (\{\hat{k}\}\cup K)$$.
Well, the digest of $$D\setminus (\{\hat{k}\}\cup K)$$ is nothing but the aggregated proof for $K$ and $\hat{k}$.
Thus, the updated proof for $K$ is simply the aggregation of the old proof for $K$ with the proof for the removed $\hat{k}$.
Naturally, if multiple keys are being removed, then we just aggregate $\pi_K$ with the proofs for each removed key.

{: .warning}
One thing we've glanced over was that if $$K = \{\hat{k}\}$$, then this proof update doesn't really work, since we'd be updating the proof for $\hat{k}$ after removing $\hat{k}$ itself.
This doesn't make sense unless we updated $\hat{k}$'s lookup proof into a non-membership proof, which we have not defined yet, but will do so in a future post.
\
\
We've also glanced over having $\hat{k}\in K$.
But this is not problematic since, in this case, we have $$D\setminus K = D\setminus (\{\hat{k}\}\cup K)$$, so the updated proof $\pi_K' =\pi_K$.

### Cross-incremental proof aggregation

Our paper's main contribution is _cross-incremental proof aggregation_ for our AD, a technique for **incrementally** aggregating lookup proofs _across different dictionaries_.
Recall that we can already (incrementally) aggregate two proofs, one for a set of keys $K_1$ and another for $K_2$, into a single proof for the set of keys $K_1\cup K_2$.
For this to work though, these two proofs must be w.r.t. the same dictionary digest $d$.
However, in some applications, we'll be dealing with proofs $\pi_i$, each for a set of keys $K_i$ but w.r.t. their own digest $d_i$.
This raises the question of whether such proofs can also be _cross-aggregated_?
Gorbunov et al.[^GRWZ20e] answer this question positively for vector commitments and our work extends this to authenticated dictionaries.

{: .info}
**Example:** In stateless validation for smart contracts[^GRWZ20e], the $i$th's smart contract's memory is represented as a dictionary with digest $d_i$.
When this $i$th contract is invoked, the transaction will need to include the subset of memory locations $K_i$ that were accessed by the execution together with their proof $\pi_i$.
When multiple transactions are processed, each proof $\pi_i$ will be w.r.t. a different $d_i$.
Importantly, instead of including each $\pi_i$ in the mined block, we would ideally like to _cross-aggregate_ all $\pi_i$'s into a single proof $\pi$.

#### Proof-of-knowledge of co-prime roots

The key ingredient behind our incremental cross-aggregation is the **proof-of-knowledge of co-prime roots (PoKCR)** protocol by Boneh et al.[^BBF18]
Recall that PoKCR can be used to convince a verifier who has $\alpha_i$'s and $x_i$'s, that the prover _knows_ $w_i$'s such that:

$$\alpha_i = w_i^{x_i},\ \text{for each}\ i\in[n]$$

Importantly, this protocol requires that the $x_i$'s are pairwise co-prime:

$$\gcd(x_i, x_j) = 1,\forall i,j\in[n], i\ne j$$

To prove knowledge of the $w_i$'s, the prover simply gives the verifier:

$$W=\prod_{i\in [n]} w_i$$

To verify knowledge of $w_i$'s, the verifier (who has $\alpha_i$'s and $x_i$'s) computes $$x^* = \prod_{i\in[n]} x_i$$ and checks if: 

$$W^{x^*} \stackrel{?}{=} \prod_{i\in [n]} \alpha_i^{x^*/x_i}$$

The trick for the verifier is to do this computation efficiently, since the right-hand side (RHS) involves $n$ exponentiations, each of size $O(\ell n)$ bits.
If done naively, this would take $O(\ell n^2)\ \Gho$ operations. 
Fortunately, Boneh et al.[^BBF18] give an $O(\ell n\log{n})$ time algorithm to compute this RHS denoted by:

$$\multirootexp((\alpha_i, x_i)_{i\in [n]}) = \prod_{i\in [n]} \alpha_i^{x^*/x_i}$$

We refer you to Figure 1 in our paper[^TXN20e] for the $\multirootexp$ algorithm, which simply leverages the recursive nature of the problem.
In fact, the algorithm recurses in a manner very similar to [$\rootfactor$](rsa-accumulators#precomputing-all-membership-witnesses-fast).

Importantly, Boneh et al. give an _extractor_ that the PoKCR verifier can use to actually recover the $w_i$'s from the $x_i$'s, $\alpha_i$'s and $W$.
This is what makes the protocol a proof of _knowledge_.
One of our contributions is speeding up the extraction of _all_ $w_i$'s from $O(\ell n^2\log{n})\ \Gho$ operations down to $O(\ell n\log^2{n})$[^obs2].
For this, we refer you to our full paper[^TXN20e].

#### Using PoKCR for incrementally cross-aggregating lookup proofs

Suppose we have a lookup proof $\pi_i$ for a set of keys $K_i$ in a dictionary $D_i$ with digest $d_i = (A_i, c_i)$, where $A_i$ is the RSA accumulator over all keys in the dictionary and $c_i$ is the multi-exponentiation of RSA witnesses (i.e., the part of the proof previously denoted using $\Lambda$).
Note we are changing notation slightly for ease of presentation.

The main observation is that we can aggregate several proofs $\pi_i = (W_i, \Lambda_i)$ w.r.t. different digests $d_i$ via PoKCR because $W_i$ and $\Lambda_i$ are actually prime roots of certain group elements.
To see this, recall from the [preliminaries](#preliminaries) that:

\begin{align}
    W_i &= A_i^{1/e_{K_i}}\\\\\
    \Lambda_i &= \left(\prod_{(k,v)\in D_i\setminus K_i} (A_i^{1/e_k})^{v}\right)^{1/e_{K_i}}
\end{align}

Clearly, $W_i$ is an $e_{K_i}$-th root of $A_i$, which the verifier has.
But what about $\Lambda_i$?
Let $v_k$ be the value of each $k\in K_i$ and rewrite $\Lambda_i$ as:
\begin{align}
    \Lambda_i &= \left(\prod_{(k,v)\in D_i\setminus K_i} (A_i^{1/e_k})^{v}\right)^{1/e_{K_i}}\\\\\
         	  &= \left(\frac{\prod_{(k,v)\in D_i} (A_i^{1/e_k})^{v}}{\prod_{k\in K_i} (A_i^{1/e_k})^{v_k}}\right)^{1/e_{K_i}}\\\\\
              &= \left(c_i / \prod_{k\in K_i} (A_i^{1/e_k})^{v_k}\right)^{1/e_{K_i}}\\\\\
\end{align}
Thus, if we let $$\alpha_i = c_i / \prod_{k\in K_i} (A_i^{1/e_k})^{v_k}$$, then $\Lambda_i$ is an $e_{K_i}$-th root of $\alpha_i$.
Note that the verifier can compute $\alpha_i$ from $c_i, W_i$ and $K_i$ (as we describe later).

To summarize, we have $m$ proofs $\pi_i = (W_i, \Lambda_i)$ each w.r.t. its own $d_i = (A_i, c_i)$ such that, for all $i\in [m]$:
\begin{align}
    W_i^{e_{K_i}} &= A_i\\\\\
    \Lambda_i^{e_{K_i}} &= \alpha_i
\end{align}

We are almost ready to aggregate with PoKCR, but we cannot yet.
This is because the $e_{K_i}$'s must be pairwise co-prime for PoKCR to work!
However, this is not necessarily the case, since we could have a key $k$ that is both in $K_i$ and in $K_j$ which means $e_{K_i}$ and $e_{K_j}$ will have a common factor $e_k = H(k)$.

Fortunately, we can quickly work around this by using a different hash function $H_i$ for each dictionary $D_i$.
This way, the prime representatives for $k\in K_i$ are computed as $e_k = H_i(k)$, while the prime representatives for $k\in K_j$ are computed as $e_k = H_j(k)$.
As long as one cannot find any pair $(k,k')$ with $H_i(k) = H_j(k')$, all the $e_{K_i}$'s will be pairwise co-prime.
This means we can aggregate all $m$ proofs as:
\begin{align}
    W &= \prod_{i\in[m]} W_i\\\\\
    \Lambda &= \prod_{i\in [m]} \Lambda_i
\end{align}

Importantly, we can do this aggregation  _incrementally_: whenever a new proof arrives, we simply multiply it in the previously cross-aggregated proof.

#### Verifying cross-aggregated lookup proofs

Suppose a verifier gets a cross-aggregated proof $\pi = (W,\Lambda)$ for a bunch of $K_i$'s w.r.t. their own $d_i = (A_i, c_i),\forall i\in[m]$.
How can he verify $\pi$?
First, the verifier checks the PoKCR that, for each $i\in[m]$, there exists $W_i$ such that $A_i = W_i^{e_{K_i}}$:

$$W^{e^*} \stackrel{?}{=} \multirootexp((A_i, e_{K_i})_{i\in [m]}) = \prod_{i\in [m]} A_i^{e^*/e_{K_i}}$$

Here, $e^*=\prod_{i\in[m]} e_{K_i}$ and each $e_{K_i} = \prod_{k\in K_i} H_i(k)$.
Importantly, the verifier can recover the $W_i$'s using the PoKCR extractor (see Section 3.1 in our full paper[^TXN20e]).

Second, the verifier checks the PoKCR for each $\alpha_i = \Lambda_i^{e_{K_i}}$.
For this, the verifier must first compute each $\alpha_i = c_i / \prod_{k\in K_i} (A_i^{1/e_k})^{v_k}$, where $v_k$ is the value of each $k \in K_i$ and $e_k = H_i(k)$.
The difficult part is computing all $A_i^{1/e_k}$'s, but this can be done via $\rootfactor(W_i, (e_k)_{k\in K_i})$.
Once the verifier has the $\alpha_i$'s, he can check:

$$\Lambda^{e^*} \stackrel{?}{=} \multirootexp((\alpha_i, e_{K_i})_{i\in [m]}) = \prod_{i\in [m]} \alpha_i^{e^*/e_{K_i}}$$

If both PoKCR checks pass, then the verifier is assured the proof verifies.
Not only that, but the verifier can also disaggregate the cross-aggregated proof as we explain next.

#### Disaggregating cross-aggregated proofs

Since the cross-aggregated proof $\pi = (W,\Lambda)$ is a PoKCR proof, this mean the PoKCR extractor can be used to recover the original proofs $(\pi_i)_{i\in[m]}$ that $\pi$ was aggregated from.
How?

Well, we already showed how the verifier must extract the $W_i$'s in the original proofs, which he needs for reconstructing the $\alpha_i$'s to verify the $\Lambda$ part of the cross-aggregated proof.
In a similar fashion, the verifier can also extract all the $\Lambda_i$'s aggregated in $\Lambda$.
This way, the verifier can recover the original proofs.
Note that this implies cross-aggregated proofs are _updatable_ by:

 1. Cross-disaggregating them into the original lookup proofs, 
 2. Updating these lookup proofs,
 3. And cross-reaggregating them back.

## Conclusion

To conclude, we show that generalizing CF to a larger key-space results in a versatile _authenticated dictionary (AD)_ scheme that supports updating proofs and digests and supports aggregating proofs across different dictionaries in an incremental fashion.
In a future post, we strengthen the security of this construction, which makes it applicable to more adversarial applications such as transparency logging.
As always, see our full paper for details[^TXN20e].

[^AR20]: **KVaC: Key-Value Commitments for Blockchains and Beyond**, by Shashank Agrawal and Srinivasan Raghuraman, *in Cryptology ePrint Archive, Report 2020/1161*, 2020, [[URL]](https://eprint.iacr.org/2020/1161)
[^BBF18]: **Batching Techniques for Accumulators with Applications to IOPs and Stateless Blockchains**, by Dan Boneh and Benedikt Bünz and Ben Fisch, *in Cryptology ePrint Archive, Report 2018/1188*, 2018, [[URL]](https://eprint.iacr.org/2018/1188)
[^BCPR14]: **On the Existence of Extractable One-way Functions**, by Bitansky, Nir and Canetti, Ran and Paneth, Omer and Rosen, Alon, *in Proceedings of the Forty-sixth Annual ACM Symposium on Theory of Computing*, 2014, [[URL]](http://doi.acm.org/10.1145/2591796.2591859)
[^Bd93]: **One-Way Accumulators: A Decentralized Alternative to Digital Signatures**, by Benaloh, Josh and de Mare, Michael, *in EUROCRYPT '93*, 1994
[^LLX07]: **Universal Accumulators with Efficient Nonmembership Proofs**, by Li, Jiangtao and Li, Ninghui and Xue, Rui, *in Applied Cryptography and Network Security*, 2007
[^ct]: **Certificate Transparency**, by Google, [[URL]](https://www.certificate-transparency.org/)
[^CF13e]: **Vector Commitments and their Applications**, by Dario Catalano and Dario Fiore, *in Cryptology ePrint Archive, Report 2011/495*, 2011, [[URL]](https://eprint.iacr.org/2011/495)
[^CFGplus20e]: **Vector Commitment Techniques and Applications to Verifiable Decentralized Storage**, by Matteo Campanelli and  Dario Fiore and Nicola Greco and  Dimitris Kolonelos and  Luca Nizzardo, 2020, [[URL]](https://eprint.iacr.org/2020/149)
[^Feis20Multi]: **Multi-layer hashmaps for state storage**, by Dankrad Feist, 2020, [[URL]](https://ethresear.ch/t/multi-layer-hashmaps-for-state-storage/7211/print)
[^FDPplus14]: **Hey, NSA: Stay Away from My Market! Future Proofing App Markets against Powerful Attackers**, by Fahl, Sascha and Dechand, Sergej and Perl, Henning and Fischer, Felix and Smrcek, Jaromir and Smith, Matthew, *in Proceedings of the 2014 ACM SIGSAC Conference on Computer and Communications Security*, 2014, [[URL]](https://doi.org/10.1145/2660267.2660311)
[^GRWZ20e]: **Pointproofs: Aggregating Proofs for Multiple Vector Commitments**, by Sergey Gorbunov and Leonid Reyzin and Hoeteck Wee and Zhenfei Zhang, 2020, [[URL]](https://eprint.iacr.org/2020/419)
[^LGGplus20]: **Aardvark: A Concurrent Authenticated Dictionary with Short Proofs**, by Derek Leung and Yossi Gilad and Sergey Gorbunov and Leonid Reyzin and Nickolai Zeldovich, *in Cryptology ePrint Archive, Report 2020/975*, 2020, [[URL]](https://eprint.iacr.org/2020/975)
[^LK15]: **Revocation Transparency**, by Ben Laurie and Emilia Kasper, 2015, [[URL]](https://www.links.org/files/RevocationTransparency.pdf)
[^LM18]: **Subvector Commitments with Application to Succinct Arguments**, by Russell W.F. Lai and Giulio Malavolta, *in Cryptology ePrint Archive, Report 2018/705*, 2018, [[URL]](https://eprint.iacr.org/2018/705)
[^obs1]: We were not the first to make this observation; see the work by Agrawal and Raghuraman[^AR20]
[^obs2]: See Section 3.1 in our full paper[^TXN20e]
[^obs3]: With the exception of the first KVC of Boneh et al.[^BBF18], which actually satisfies strong key binding, while their second construction is faster but only satisfies weak key binding.
[^obs4]: Technically, they are given an _append-only_ guarantee for the new digest w.r.t. the previous digest. However, the append-only guarantee still does not promise anything about the correctness of the digest. See our original AAD paper for how append-only guarantees are formalized[^TBPplus19].
[^SSY01]: **Blind, Auditable Membership Proofs**, by Sander, Tomas and Ta-Shma, Amnon and Yung, Moti, *in Financial Cryptography*, 2001
[^TBPplus19]: **Transparency Logs via Append-Only Authenticated Dictionaries**, by Tomescu, Alin and Bhupatiraju, Vivek and Papadopoulos, Dimitrios and Papamanthou, Charalampos and Triandopoulos, Nikos and Devadas, Srinivas, *in ACM CCS'19*, 2019, [[URL]](https://doi.org/10.1145/3319535.3345652)
[^TXN20e]: **Authenticated Dictionaries with Cross-Incremental Proof (Dis)aggregation**, by Alin Tomescu and Yu Xia and Zachary Newman, *in Cryptology ePrint Archive, Report 2020/1239*, 2020, [[URL]](https://eprint.iacr.org/2020/1239)
