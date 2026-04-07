---
tags:
 - polynomials
 - verifiable secret sharing (VSS)
 - distributed key generation (DKG)
 - kzg
 - polynomial commitments
 - fast fourier transform (FFT)
title: A Step Closer To Scalable Verifiable Secret Sharing (and Distributed Key Generation)
date: 2021-01-12 14:00:00
published: false
---
{: .info}
**tl;dr:** We apply a new proof precomputation technique by Feist and Khovratovich[^FK20] to further scale $(t,n)$ _Verifiable Secret Sharing (VSS)_ protocols to $\Theta(n\log{n})$ time sharing phase, $\Theta(n)$ dealer communication and $O(n)$ time share verification (during reconstruction phase).
\
\
This is an improvement over our [previous work][prevpost], which has a $\Theta(n\log{t})$ time sharing phase, $\Theta(n\log{t})$ dealer communication and $O(n\log{t})$ time share verification (during reconstruction).
These improvements carry over to _distributed key generation (DKG)_ protocols too.
Furthermore, these improvements are concrete too, not just asymptotic.

<!--more-->
This post is a _continuation to our [previous post](/amt)_ on scaling VSS and DKG protocols using _AMT proofs_.
Throughout this post, we'll refer to proofs computed using the Feist and Khovratovich[^FK20] technique as _FK proofs_.
Similarly, we'll refer to the resulting VSS and DKG protocols as _FK VSS_ and _FK DKG_, respectively.

A prototype implementation of FK-based VSS and DKG benchmarks is available on the `fk` branch of `libpolycrypto` on GitHub [here](https://github.com/alinush/libpolycrypto/tree/fk).

## Preliminaries

Let $[n]=\\{1,2,3,\dots,n\\}$.
Let $p$ be a sufficiently large prime that denotes the order of our groups.

In this post, beyond basic group theory for cryptographers[^KL15] and basic polynomial arithmetic, I will assume you are familiar with a few concepts:

 - **Bilinear maps**[^GPS08]. Specifically, $\exists$ a bilinear map $e : \Gr_1 \times \Gr_2 \rightarrow \Gr_T$ such that:
    - $\forall u\in \Gr_1,v\in \Gr_2, a\in \Zp, b\in \Zp, e(u^a, v^b) = e(u,v)^{ab}$
    - $e(g_1,g_2)\ne 1_T$ where $g_1,g_2$ are the generators of $\Gr_1$ and $\Gr_2$ respectively and $1_T$ is the identity of $\Gr_T$
 - **KZG**[^KZG10] **polynomial commitments** (see [previous post][prevpost]),
 - The **Fast Fourier Transform (FFT)**[^CLRS09] applied to polynomials. Specifically,
    - Suppose $\Zp$ admits a primitive _root of unity_ $\omega$ of order $n$ (i.e., $n \mid p-1$)
    - Let $$H=\{1, \omega, \omega^2, \omega^3, \dots, \omega^{n-1}\}$$ denote the set of all $n$ $n$th roots of unity
    - Then, FFT can be used to efficiently evaluate any polynomial $\phi(X)$ at all $X\in H$ in $\Theta(n\log{n})$ time
        - i.e., compute all $$\{\phi(\omega^{i-1})\}_{i\in[n]}$$
 - **$(t,n)$ Verifiable Secret Sharing (VSS)** via Shamir Secret Sharing, specifically _eVSS_[^KZG10] (see [previous post][prevpost]),
 - **$(t,n)$ Distributed Key Generation (DKG)** via VSS (see [previous post][prevpost]).

### Faster VSS

![eVSS vs. AMT VSS vs. FK VSS in terms of dealing time](/pictures/fkvss-deal-times.png){: .align-center}

{: .info}
The $x$-axis is $\log_2(t)$ where $t$ is the threshold, which doubles for every tick.
They $y$-axis is the dealing time in seconds.
The graph shows that our AMT-based VSS outscales eVSS for large $t$ and performs better even at the scale of hundreds of players.

### Faster DKG

Since in a DKG protocol, each player performs a VSS with all the other players, the results from above carry over to DKG protocols too.
In fact, the DKG dealing time (per-player) doesn't differ much from the VSS dealing time, especially as $t$ gets large.
Thus, the improvement in DKG dealing times is perfectly illustrated by the graph above too.

## Remaining questions

Our $(t,n)$ VSS/DKG protocols require $t$-SDH public parameters.
Thus, the non-trivial problem of generating $t$-SDH public parameters remains.
In some sense, we make this problem worse because our scalable protocols require a large $t$.
We hope to address this in future work.

### References

[^Bold03]: **Threshold Signatures, Multisignatures and Blind Signatures Based on the Gap-Diffie-Hellman-Group Signature Scheme**, by Boldyreva, Alexandra, *in PKC 2003*, 2002
[^BLS04]: **Short Signatures from the Weil Pairing**, by Boneh, Dan and Lynn, Ben and Shacham, Hovav, *in Journal of Cryptology*, 2004
[^BT04]: **Barycentric Lagrange Interpolation**, by Berrut, J. and Trefethen, L., *in SIAM Review*, 2004
[^CLRS09]: **Introduction to Algorithms, Third Edition**, by Cormen, Thomas H. and Leiserson, Charles E. and Rivest, Ronald L. and Stein, Clifford, 2009
[^CPZ18]: **Edrax: A Cryptocurrency with Stateless Transaction Validation**, by Alexander Chepurnoy and Charalampos Papamanthou and Yupeng Zhang, *in Cryptology ePrint Archive, Report 2018/968*, 2018
[^FK20]: **Fast amortized Kate proofs**, by Dankrad Feist and Dmitry Khovratovich, 2020, [[pdf]](https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf)
[^GAGplus19]: **SBFT: A Scalable and Decentralized Trust Infrastructure**, by G. Golan Gueta and I. Abraham and S. Grossman and D. Malkhi and B. Pinkas and M. Reiter and D. Seredinschi and O. Tamir and A. Tomescu, *in 2019 49th Annual IEEE/IFIP International Conference on Dependable Systems and Networks (DSN)*, 2019, [[PDF]](https://arxiv.org/pdf/1804.01626.pdf).
[^GJKR07]: **Secure Distributed Key Generation for Discrete-Log Based Cryptosystems**, by Gennaro, Rosario and Jarecki, Stanislaw and Krawczyk, Hugo and Rabin, Tal, *in Journal of Cryptology*, 2007
[^GPS08]: **Pairings for cryptographers**, by Steven D. Galbraith and Kenneth G. Paterson and Nigel P. Smart, *in Discrete Applied Mathematics*, 2008
[^KL15]: **Introduction to Modern Cryptography**, by Jonathan Katz and Yehuda Lindell, 2007
[^KZG10]: **Constant-Size Commitments to Polynomials and Their Applications**, by Kate, Aniket and Zaverucha, Gregory M. and Goldberg, Ian, *in ASIACRYPT '10*, 2010
[^Shamir79]: **How to Share a Secret**, by Shamir, Adi, *in Commun. ACM*, 1979
[^TCZplus20]: **Towards Scalable Threshold Cryptosystems**, by Alin Tomescu and Robert Chen and Yiming Zheng and Ittai Abraham and Benny Pinkas and Guy Golan Gueta and Srinivas Devadas, *in 2020 IEEE Symposium on Security and Privacy (SP)*, 2020, [[PDF]](/papers/dkg-sp2020.pdf).
[^Tome20]: **How to Keep a Secret and Share a Public Key (Using Polynomial Commitments)**, by Tomescu, Alin, 2020
[^vG13ModernCh10]: **Fast polynomial evaluation and interpolation**, by von zur Gathen, Joachim and Gerhard, Jurgen, *in Modern Computer Algebra*, 2013

[prevpost]: /amt
