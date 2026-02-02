---
tags:
 - hidden-order groups
 - assumptions
 - RSA
title: Cryptographic Assumptions in Hidden-Order Groups
#date: 2020-11-05 20:45:59
#published: false
sidebar:
    nav: cryptomat
---

<!--
**TODO:**

 - Define $\QRn$
     + Include Quadratic Residuosity Assumption (QRA) (see [here](https://en.wikipedia.org/wiki/Quadratic_residuosity_problem) and [here](https://crypto.stanford.edu/pbc/notes/numbertheory/qr.html))
 - Define **generic group model (GGM)** and **generic adversary**[^DK02] 
 - _Blum integers_ as defined by Hastad et al.[^HSS93]
 - One-more RSA assumptions
-->

In this post, we summarize some of the cryptographic hardness assumptions used in **hidden-order groups**.

<!--more-->

<p hidden>$$
\def\Adv{\mathcal{A}}
\def\Badv{\mathcal{B}}
\def\GenGho{\mathsf{GenGroup}_?}
\def\Ghosz{|\Gho|}
\def\Ghoid{1_{\Gho}}
\def\primes#1{\mathsf{Primes}_{#1}}
\def\QRn{\mathsf{QR}_N}
$$</p>

## Terminology and notation

We try to describe these assumptions in terms of a generic hidden-order group $\Gho$ of order $\Ghosz$.
We denote the identity element in such a group by $\Ghoid$.

Sometimes, we specifically refer to the RSA group $\Gho=\ZNs$.
Specifically, let $N = pq$ be the product of two sufficiently-large prime integers $p, q$.
Then, $$\ZNs = \{0 < a < N \mathrel| \gcd(a, N) = 1\}$$ is the multiplicative group of integers co-prime with $N$.
Recall that the size or _order_ of this group is given by the totient function: $|\ZNs| = \phi(N) = (p-1)(q-1)$.

Other times we might also refer to the _class group of imaginary quadratic orders_ introduced by Buchmann and Williams[^BW88].

{: .warning}
When we say _"Assumption $A$ implies assumption $B$"_ this means that _"for $A$ to hold, $B$ must hold"_.
Or, put differently, this means that _"$A$ can be broken given an algorithm that breaks $B$"_.
For example, to say that _"the Strong RSA assumption implies the order assumption (OA)"_ is the same thing as saying _"the Strong RSA problem reduces to the order problem"_, which is the same thing as saying _"given an algorithm for solving the order problem, one can solve the Strong RSA problem."_


All of our probability clauses $\Pr[\dots]=\negl(\lambda)$ below would more formally be stated as "for all _polynomial probabilistic time (PPT)_ adversaries $\Adv$, there exists a negligible function $\negl(\cdot)$ such that $\Pr[\dots] = \negl(\lambda)$.

## Assumptions

### Factoring

$$\Pr
\begin{bmatrix}
    p, q \xleftarrow{\$}\primes{\poly(\lambda)},\\
    N = pq : \\
    (p,q) \leftarrow \Adv(N) \\
\end{bmatrix} \leq \negl(\lambda)$$

<!--
**TODO:**

 - Eh, I'm actually not sure about how to precisely formalize the length of $p$ and $q$.
 - Factoring $n$ knowing $e$ and $d$[^Bone99] in more detail via [StackExchange explantion](https://crypto.stackexchange.com/questions/78330/factoring-n-in-rsa-knowing-e-and-d) and [other SE answer](https://crypto.stackexchange.com/a/43228/21296)
    + Implementation in [cryptopp](https://github.com/weidai11/cryptopp/blob/CRYPTOPP_8_2_0/rsa.cpp#L160)
-->

### Discrete logarithm

$$\Pr
\begin{bmatrix}
    \Gho \leftarrow \GenGho(\lambda),\\
    (g,h) \xleftarrow{\$} \Gho \times \Gho,\\
    \ell \leftarrow \Adv(\Gho, g, h) : \\
    g^{\ell} = h
\end{bmatrix} \leq \negl(\lambda)$$


_Bach_[^Bach84] shows that factoring $N$ reduces to computing discrete logs in $\ZNs$.

<!--
**TODO:**
 - Is this a trivial reduction?
 - What's the difference between restating the assumption as picking $\ell$ randomly and computing $h=g^{\ell}$. Most likely no difference except we'd have to ensure $\ell=O(\poly(\lambda))$
-->

### The RSA assumption (RSA)

Introduced by Rivest, Shamir and Adleman in their seminal 1978 paper on public-key cryptosystems[^RSA78].

<!--
**TODO:** Eh, need to bound the size of $\ell$ to be at most $\poly(\lambda)$.
But is there a different class of assumptions based on such restrictions?
-->

$$\Pr
\begin{bmatrix}
    \Gho \leftarrow \GenGho(\lambda),\\
    (g, \ell) \xleftarrow{\$} \Gho \times \Z\ \text{s.t.}\ \gcd(\ell, \Ghosz)=1\\
    u \leftarrow \Adv(\Gho, g, \ell) : \\
    g^{1/\ell} = u
\end{bmatrix} \leq \negl(\lambda)$$

<!--
**TODO:**

 - Must $\ell$ be prime or not? BBHM02 assumes prime.
 - Do we need to enforce the $\gcd$ check or does picking $\ell$ randomly suffice?
-->

{: .warning}
When $\Gho=\ZNs$, we cannot have $\ell=2$ because it would not be co-prime with $\phi(N) = (p-1)(q-1)$ and $f(x) = x^\ell = x^2$ would not be a permutation.
But if the subgroup of quadratic residues $\QRn$ is used, then $\ell = 2$ can be used (see [here](https://crypto.stackexchange.com/a/65986/21296)).
So it is best not to restrict the definition above.

### Strong RSA assumption

This assumption says that, given a random $g\in \Gho$, it is hard to find _any root_ of it: i.e., an integer $\ell$ in $\Z$ and a group element $u$ such that $g^{1/\ell} = u$.
Note that this generalizes the RSA assumption, which gives the adversary not only $g$, but also the root $\ell$ that should be computed.

$$\Pr
\begin{bmatrix}
    \Gho \leftarrow \GenGho(\lambda),\\
    g\xleftarrow{\$} \Gho,\\
    (u,\ell) \leftarrow \Adv(\Gho, g) : \\
    g^{1/\ell} = u\ \text{and}\ \ell > 1
\end{bmatrix} \leq \negl(\lambda)$$

**Strong RSA assumption implies RSA assumption:**
If RSA assumption doesn't hold then Strong RSA doesn't either.
To see this, consider a Strong RSA adversary $\Adv$ that gets a random $g$ as input.
Since RSA doesn't hold, there exists an RSA adversary $\Badv$ that given such a random $g$ and random $\ell\in \Z$ with $\gcd(\ell, \Ghosz) = 1$, outputs $u$ such that $g^{1/\ell} = u$.
Note that $\Adv$ can use $\Badv$ to break Strong RSA!
Specifically, $\Adv$ simply picks a random $\ell$ which, with overwhelming probability is co-prime with $\Ghosz$ (or else $\Adv$ can factor $N$ <!--**TODO: cite**-->).
Next, $\Adv$ calls $\Badv$ with $g$ and $\ell$, obtaining $u$ such that $g^{1/\ell} = u$ with non-negligible probability.
Finally, $\Adv$ simply outputs $(u,\ell)$, breaking Strong RSA with non-negligible probability.

<!--
**TODO:**

 - Again, what restrictions apply to $\ell$? Seems like $\ell > 2$ in RSA groups (though not sure how I would compute $u^{1/2}$ for random $u$.
 - I believe [LM18] considers composite $\ell$ as a different assumption.
    + Yes, and they show Strong RSA implies their assumption.
-->

### The order assumption (OA)

This assumption says that, given a random $g\in \Gho$, it is hard to find any multiple of its order: i.e., an integer $\ell$ such that $g^\ell = \Ghoid$
This is known as the **order problem.**

{: .warning}
The earliest reference I could find to the order problem is in a paper by _Gary L. Miller_[^Mill76], which shows it to be equivalent to factoring (under the Extended Riemann Hypothesis).

$$\Pr
\begin{bmatrix}
    \Gho \leftarrow \GenGho(\lambda),\\
    g\xleftarrow{\$} \Gho,\\
    \ell \leftarrow \Adv(\Gho, g) : \\
    \ell \ne 0 \wedge g^\ell = \Ghoid
\end{bmatrix} \leq \negl(\lambda)$$

_Biehl et al._ highlight that _"The order problem can only be difficult if the order of random elements in G is large with a very high probability."_[^BBHM02]

**DL assumption implies OA:**
_Biehl et al._[^BBHM02] also give a reduction from the order problem to the discrete logarithm (DL) problem.
Specifically, given an order problem instance $g$, if one can compute the DL $x$ of $g$ relative to $g^{-1}$ such that $g^x = g^{-1}$, then this gives a solution to the order problem as $g^{x+1} = \Ghoid$.

**Strong RSA assumption implies OA:**
This is shown by Boneh et al.[^BBF18] in Lemma 3.
Suppose there is a **generic** adversary $\Adv$ who, given a (random) order problem $g$, solves it by outputting an $\ell$ such that $g^\ell = \Ghoid$.
Then, there exists an adversary $\Badv$ that uses $\Adv$ to solve a random Strong RSA problem $g$.
Specifically, $\Badv$ uses $\Adv$ to break the order problem $g$ and find the $\ell$ mentioned above.
Then, $\Badv$ picks an odd prime $e$ that does not divide $\ell$ and outputs $u = g^{e^{-1} \bmod \ell}$ as the Strong RSA solution.
Note that $e^{-1} \bmod \ell$ is notation for the multiplicative inverse of $e$ modulo $\ell$ (i.e., $e e^{-1} \equiv 1 \pmod \ell$).
This inverse exists since $\gcd(e, \ell)=1$ (because $e$ is prime and does not divide $\ell$).
The Extended Euclidean Algorithm (EEA) can be used to obtain the inverse $a = e^{-1} \bmod \ell$ by finding $(a,b)$ such that:
<!-- TODO: Is \bmod \ell the right notation to use here? Or should we use \pmod \ell? This is what confused me initially. -->

$$ae + b\ell = 1 \Rightarrow a = (1 - b\ell)/e$$

Also, note that $u^e = g$ and so $(u, e)$ is a solution to the Strong RSA problem $g$:

$$u^e = (g^{e^{-1} \bmod \ell})^e = (g^\frac{1-b\ell}{e})^e = g^{1-b\ell} = g/(g^{\ell})^b= g$$

**RSA assumption implies OA:**
_Bieh et al._[^BBHM02] give a reduction from the RSA problem to the order problem[^reduction].
Specifically, given an RSA instance $(g, e)$ such that $e$ does not divide $\Ghosz$, if one can compute a multiple $\ell$ of the order of $g$ such that $g^\ell = \Ghoid$, then one can break the RSA instance as follows.
We have two cases.

 - _First case:_ If $e$ does not divide $\ell$, then we can break the assumption just like we broke Strong RSA above: output $u = g^{e^{-1} \bmod \ell}$. 
 - _Second case:_ If $e$ divides $\ell$, then we can let $\ell' = \ell / e$. Importantly, since $e$ does not divide the order of $\Gho$, then $\ell'$ is still a multiple of the order of $g$[^ellprime]. Thus, we can output $u = g^{e^{-1} \bmod \ell'}$ as before.

<!-- **TODO:** Why do they specifically use class groups in BBHM02, since RSA \QRn subgroups should also work, no?-->

**OA implies factoring assumption:**
We have to show that order problem reduces to factoring.
Well, if you have a factoring oracle, you can factor $N=pq$, compute $\phi(N)= (p-1)(q-1)$ and then factor $\phi(N)$ as well.
Next, given an order problem $g$, you know that $g^{\phi(N)} = \Ghoid$.
If only multiples of the order are desired, then the problem is solved.
Otherwise, if the actual order is required, then we know the order has to be a divisor of $\phi(N)$, the order of $\ZNs$.
Thus, one can repeatedly divide out the divisors of $\phi(N)$ from the exponent and check if the result is still $\Ghoid$.
For details, see [this post](https://math.stackexchange.com/questions/1025578/is-there-a-better-way-of-finding-the-order-of-a-number-modulo-n) or see Algorithm 4.79 in Chapter 4 of the Handbook of Applied Cryptography[^MvV96Ch4Pubkey].

**Factoring assumption implies OA:**
_Miller_[^Mill76] shows that one can factor $N$ if one can compute the order of random group elements in $\ZNs$ (see Theorem 4).
_Shor_[^Shor97] explains this reduction succinctly (see Section 5).
<!--
But the OA assumption asks for multiples of the order, not for the order itself, so the reduction might not have access to the order.
However, the RSA paper[^RSA78] says Miller's result reduction actually works with any multiple of the order.
(However, I'm not sure I fully see this in Miller's paper.)
-->

**OA in class groups:**
_Hamdy and Moller_[^HM00] explain how to solve the order problem in class groups whose class number is smooth.

<!--
Questions and answers:

 - Is $\ell$ the actual order or a multiple of the order?
    + Seems like both work, so assuming multiple for generality.
 - Is [CF13e] referring to this assumption in their security proof?
    + Yes. They cite [HSS93], but [Mill76] would've been the right reference AFAICT.
 - How does the _Hastad et al._[^HSS93] result, which proves most elements in $\ZNs$ are of high order, relate to this assumption?
    + Well, if a significant fraction weren't of high order, then the random $g$ whose order must be found would be easy to solve.
-->

<!--
**TODOs:**
 - Strong RSA holds implies OA holds, seems to generalize the rsa.cash statement that Strong RSA implies OA when N is a product of safe primes. Is it true though? Maybe they are saying OA doesn't hold outside of $N$ = product of safe primes, so neither does Strong RSA.
-->

### Adaptive root assumption (ARA)

This assumption was introduced by Wesolowski[^Weso19], who initially called it the _"root finding game"_.

$$\Pr
\begin{bmatrix}
    \Gho \leftarrow \GenGho(\lambda),\\
    (g, \mathsf{state}) \xleftarrow{\$} \Adv_0(\Gho),\\
    \ell \xleftarrow{\$} \primes{\lambda}, \\
    u \leftarrow \Adv_1(\mathsf{state}, g,\ell): \\
    g^{1/\ell} = u\ \text{and}\ g\ne \Ghoid
\end{bmatrix} \leq \negl(\lambda)$$

<!--
**TODO:**

 - How does the length of the primes affect this assumption? $\lambda$ versus $2\lambda$ versus 3?
-->

### The low-order assumption (LOA)

This assumption was first formalized by Boneh et al[^BBF18A] in order to prove the security of Pietrzak[^Piet18e]'s _verifiable delay function (VDF)_ in _any_ hidden order group.
(In contrast, Pietrzak proved his VDF secure in the subgroup of quadratic residues modulo a composite $N$ where this assumption holds unconditionally.)
Informally, the assumptions says that the **low-order problem** is "hard" to solve: i.e., given a group $\Gho$ of hidden-order, it is hard to find $g\in \Gho$ and $\ell \ne 0$ such that $g^{\ell} = \Ghoid$.
<!-- In other words, it is hard to find the order of any element in $\Gho$. -->

$$\Pr
\begin{bmatrix}
    \Gho \leftarrow \GenGho(\lambda),\\
    (g, \ell) \leftarrow \Adv(\Gho) : \\
    g^\ell = \Ghoid, g \ne \Ghoid\ \text{and}\ \ell < 2^{\poly(\lambda)}
\end{bmatrix} \leq \negl(\lambda)$$

{: .warning}
**Distinction:** LOA differs from the order assumption (OA) since the LOA adversary gets to choose both $g$ and $\ell$ such that $g^\ell = 1$. In contrast, in OA, the adversary was given a random $g$ and needed to find an $\ell$.

<!--
**TODO:**

 - it seems like the RSA paper mentions that any multiple of $\phi(N)$ can be used to factor $N$.
     + Does this immediately imply the low-order assumption must hold in these groups, because if you find $g, x$ such that $g^x = \Ghoid$ for a random group element, then $x$ must be a multiple of $\|\ZNs\| = \phi(N)$, no? Or it could be a multiple of any divisor of $\phi(N) = (p-1)(q-1)$ too I think?
 - How come low-order assumption doesn't imply factoring assumption?
-->

**Adaptive root assumption implies LOA:**
Boneh et al.[^BBF18A] show that LOA holds in _generic groups_[^DK02], because breaking it implies breaking the adaptive root assumption, which holds generically (see Section 4).

_Seres and Burcsi_[^SB20] explain that LOA is stronger than factoring arbitrary $N$ because in $\QRn$ all elements are of high order, so factoring $N$ will not help.
However, for particular kinds of $N$, they show that factoring reduces to LOA.

## Other notes

_Hohenberger_[^Hoh03] introduces the notion of a _pseudo-free group_ and _Rivest_[^Rive04] shows that if $\ZNs$ is pseudo-free, then $\ZNs$ satisfies Strong RSA and DL.

_Rabin_[^Rabi79] shows that solving polynomial congruences $\phi(x) \equiv 0 \pmod N$ is as hard as factoring $N$ (see Section 5).
He also shows that an algorithm, which given $(y,N)$, computes quadratic residues $x$ such that $x^2 = y \pmod N$ can be used to factor $N$ (see Theorem 1).

_Shor_[^Shor97] shows that finding the order $\ell$ of a random element $g$ in $\ZNs$ (i.e., $g^\ell = 1$) can be done using a _quantum computer_ in polynomial time. 
(Shor specifically requires $\ell$ to be the _order_: i.e., the smallest such integer.)
Then, Shor uses a reduction by _Miller_[^Mill76] to factor $N$, given the quantum oracle for solving the order problem.
Stephanie Blanda gives an [intuitive explanation](https://blogs.ams.org/mathgradblog/2014/04/30/shors-algorithm-breaking-rsa-encryption/).

_Theorem:_ For all $a < N$, $\exists r\in \Z$, such that $a^r = 1 \pmod N$ iff. $\gcd(a, N)=1$ (see [here](https://proofwiki.org/wiki/Integer_has_Multiplicative_Order_Modulo_n_iff_Coprime_to_n)).
<!-- TODO: Eh, why did I write this down again? -->

#### Acknowledgements

Big thanks to _Munshi Rejwan Ala Muid_ for pointing out a typo in the _"Strong RSA assumption implies OA"_ subsection.

[^ellprime]: One way to see why $g^{\ell'} = \Ghoid$ is to note that $g^{\ell} = g^{\ell' e} = \Ghoid$ and, since $e$ does not divide $\Ghosz$ and $e$ is prime, it follows that $\gcd(e, \Ghosz)$ = 1. Thus, $e$ can be inverted. Raising $g^{\ell' e} = \Ghoid$ to the inverse $e^{-1}$ gives $g^{\ell'} = \Ghoid$.
[^reduction]: A _reduction_ from the RSA problem to the order problem is an algorithm that solves the RSA problem given an oracle for solving the order problem.
[^Bach84]: **Discrete logarithms and factoring**, by Eric Bach, 1984, [[URL]](https://www2.eecs.berkeley.edu/Pubs/TechRpts/1984/CSD-84-186.pdf)
[^Bone99]: **Twenty Years of Attacks on the RSA Cryptosystem**, by Dan Boneh, 1999, [[URL]](https://crypto.stanford.edu/~dabo/pubs/papers/RSA-survey.pdf)
[^BBF18]: **Batching Techniques for Accumulators with Applications to IOPs and Stateless Blockchains**, by Dan Boneh and Benedikt Bünz and Ben Fisch, *in Cryptology ePrint Archive, Report 2018/1188*, 2018, [[URL]](https://eprint.iacr.org/2018/1188)
[^BBF18A]: **A Survey of Two Verifiable Delay Functions**, by Dan Boneh and Benedikt Bünz and Ben Fisch, *in Cryptology ePrint Archive, Report 2018/712*, 2018, [[URL]](https://eprint.iacr.org/2018/712)
[^BBHM02]: **A Signature Scheme Based on the Intractability of Computing Roots**, by Biehl, Ingrid and Buchmann, Johannes and Hamdy, Safuat and Meyer, Andreas, *in Designs, Codes and Cryptography*, 2002, [[URL]](https://doi.org/10.1023/A:1014927327846)
[^BW88]: **A Key-Exchange System Based on Imaginary Quadratic Fields**, by Johannes Buchmann and Hugh C. Williams, *in Journal of Cryptology*, 1988
[^DK02]: **Generic Lower Bounds for Root Extraction and Signature Schemes in General Groups**, by Damg\aard, Ivan and Koprowski, Maciej, *in Advances in Cryptology --- EUROCRYPT 2002*, 2002
[^Hoh03]: **The Cryptographic Impact of Groups with Infeasible Inversion**, by Susan Rae Hohenberger, *Master's Thesis, MIT*, 2003
[^HSS93]: **The discrete logarithm modulo a composite hides 0(n) Bits**, by J. Håstad and A.W. Schrift and A. Shamir, *in Journal of Computer and System Sciences*, 1993, [[URL]](http://www.sciencedirect.com/science/article/pii/002200009390038X)
[^HM00]: **Security of Cryptosystems Based on Class Groups of Imaginary Quadratic Orders**, by Hamdy, Safuat and M\"oller, Bodo, *in Advances in Cryptology --- ASIACRYPT 2000*, 2000
[^MvV96Ch4Pubkey]: **Public-Key Parameters**, by Menezes, Alfred J and van Oorschot, Paul C and Vanstone, Scott A, *in Handbook of Applied Cryptography*, 1996, [[URL]](http://cacr.uwaterloo.ca/hac/about/chap4.pdf)
[^Mill76]: **Riemann's hypothesis and tests for primality**, by Gary L. Miller, *in Journal of Computer and System Sciences*, 1976, [[URL]](http://www.sciencedirect.com/science/article/pii/S0022000076800438)
[^Piet18e]: **Simple Verifiable Delay Functions**, by Krzysztof Pietrzak, *in Cryptology ePrint Archive, Report 2018/627*, 2018, [[URL]](https://eprint.iacr.org/2018/627)
[^Rabi79]: **Digitalized Signatures and Public-key Functions as Intractable as Factorization**, by Rabin, M. O., 1979
[^Rive04]: **On the Notion of Pseudo-Free Groups**, by Rivest, Ronald L., *in Theory of Cryptography*, 2004
[^RSA78]: **A method for obtaining digital signatures and public-key cryptosystems**, by R. L. Rivest and A. Shamir and L. Adleman, *in Communications of the {ACM}*, 1978, [[URL]](https://doi.org/10.1145%2F359340.359342)
[^Shor97]: **Polynomial-Time Algorithms for Prime Factorization and Discrete Logarithms on a Quantum Computer**, by Shor, Peter W., *in SIAM Journal on Computing*, 1997, [[URL]](https://doi.org/10.1137/S0097539795293172)
[^SB20]: **A Note on Low Order Assumptions in RSA groups**, by István András Seres and Péter Burcsi, *in Cryptology ePrint Archive, Report 2020/402*, 2020, [[URL]](https://eprint.iacr.org/2020/402)
[^Weso19]: **Efficient Verifiable Delay Functions**, by Wesolowski, Benjamin, *in Advances in Cryptology -- EUROCRYPT 2019*, 2019
