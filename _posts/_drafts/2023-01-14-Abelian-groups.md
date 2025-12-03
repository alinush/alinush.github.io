---
tags: 
 - math
title: Abelian groups
#date: 2020-11-05 20:45:59
published: false
permalink: groups
#sidebar:
#    nav: cryptomat
---

{: .info}
**math tl;dr:** An Abelian (or commutative) group $(S, \odot)$ consits of a set $S$ and a **binary operation** $\odot$ such that:
(1) $\odot : S \times S \rightarrow S$ (or, in other words, $\forall a,b\in S,\exists c\in S$, such that $a \odot b = c$)
(2) $\odot$ is **commutative** (or, $\forall a,b\in S$, we have $a \odot b = b \odot a$),
(3) $\odot$ is **associative** (or, $\forall a,b,c$ in $S$, we have $a \odot (b \odot c) = (a \odot b) \odot c$),
(4) $\exists$ **identity element** $e\in S$ such that $\forall a \in S$, we have $e\odot a = a\odot e = a$, 
(5) $\forall a\in S$, $\exists$ an **inverse element**, denoted $a^{-1} \in S$, such that $a \odot a^{-1} = e$, where $e$ is the identity element.

<!--more-->

<p hidden>$$
\def\Adv{\mathcal{A}}
\def\Badv{\mathcal{B}}
\def\vect#1{\mathbf{#1}}
$$</p>

## Introduction

Abelian groups are one of the most commonly used ingredients for cooking up a cryptosystems.

**tl;dr:** Put simply, an **Abelian** (or commutative) **group** is a **set** $S$ of **elements** endowed with an **operation**: i.e., one can take any two elements from $S$, combine them with the operation and get back an element in the group.
This is referred to as $S$ being **closed under this operation**.
Importantly, this operation commutes, is invertible and associative.
We'll go into details later!

Understanding the details is crucial for cryptography, since today's most efficient cryptography relies on groups:

 - key-exchange schemes, such a Diffie-Hellman (DH)[^DH76],
 - public-key encryption schemes, such as RSA[^RSA78] or [ElGamal](/elgamal)
 - digital signature schemes, such as [Schnorr](/schnorr) or [BLS](/threshold-bls),
 - polynomial commitment schemes, such as [KZG](2020/05/06/kzg-polynomial-commitments.html)[^KZG10]

(Well some of these cryptosystems, additionally rely on [pairings](/pairings) across Abelian groups.)

### Motivation

If you're reading this post, chances are you've encountered one or more flavors of this notation:
\begin{align}
    &aG\\\\\
    &[a]G\\\\\
    &g^a\\\\\
    &g^a \pmod p\\\\\
    &g^{a \bmod q}\\\\\
    &g^{a \bmod q} \pmod p\\\\\
    &g^{a \bmod p-1} \pmod p
\end{align}
Or, you've read somewhere that a Schnorr signature on a message $m$ under secret key $x$ and public key $g^x$ is $(R, s)$ where:
\begin{align}
    R = g^r \qquad s = \left(r + H(g, g^x, R, m) \cdot x\right) \bmod q
\end{align}
But then someone else told you that the PK is actually denoted by $xP$ and the signature $(R, s)$ is in fact:
\begin{align}
    R = rP \qquad s = r + H(x, xP, R, m) \cdot x
\end{align}

So what is happening?

 - Why do people always exponentiate things in cryptography?

 - Why does so much different notation arises in cryptography?

 - What does this notation mean anyway?

 - Do you need to understand it to do cryptography? (Yes.)

 - Why are people always computing things modulo $q$, or $p$, or $p-1$?

The answer lies in understanding the details of _Abelian groups_.

## Preliminaries

 - You know how to multiply integers.
    + So you clearly know how to add them.
 + You remember basic properties of addition and multiplication:
    + Commutativity
    - There exists an identity element (e.g., $0 + a = a + 0 = 0$)
    - There exist inverses for each element (e.g., $a + (-a) = (-a) + a = 0$)
 - As a result you know that when you multiply an integer $g$ with itself $a$ times, you get $g^a$.
 - You know that $\forall a \in S$ means _"for all elements $a$ in set $S$"_.
 - You know that $\exists a \in S$ means _"there exists (at least) an element $a$ in set $S$"_.
 - You know how to divide an integer $a$ by another integer $b$ and obtain a quotient $Q$ and a **remainder** $r$ such that $a = Q\cdot b + r$ and $0 \le r < b$.
     - You also know that one can denote the remainder $r$ above as $r = a \bmod b$.
     - Computing $a \bmod b$ is often referred to as _"reducing $a$ modulo $b$"_ or as a _"reduction modulo $b$"_
 - Probably, you know about greatest common divisors (GCDs). We'll see.

<!-- ## Addition modulo a prime $q$

Since you know how to add numbers, let us reason about adding numbers "with a twist."

If you're a normal person, you just add two integers like you were taught in 1st grade:

$$c = a + b$$

and call it a day.

But, for reasons that will become clear over time, cryptographers often prefer to reduce the result modulo a prime $q$.

$$c' = (a + b) \bmod q$$

{: .info}
Recall from the [preliminaries](#preliminaries) what reduction modulo $q$ means: you compute $(a+b)$, divide it by $q$ and take the remainder to be the result $c'$.
For example, $(8 + 4) \bmod 5 = 12 \bmod 5 = 2$ because the remainder of dividing 12 by 5 is 2.

In fact, this operation (i.e., addition modulo a prime $q$), applied over the set of integers $\Zq \bydef \\{0,1,2,\ldots, q-1\\}$ gives us the **first example of an Abelian group**

This group is denoted by $(\Zq, +)$, which nicely indicates that:
1. the set of elements is $\Zq$
2. the operation is addition modulo $q$ (i.e., $+$)

We also more simply denote the group as $\Zq$.

Note that $\Zq$ satisfies all the four properties of an Abelian group we hinted at in the [introduction](#introduction).

$\Zq$ is a set of $q$ elements $\Zq \stackrel{\mathsf{def}}{=} \\{0,1,2,\ldots,q-1\\}$.

#### Property 1: $\Zq$ is closed under addition $\bmod q$

Specifically, for any $a\in \Zq$ and for any $b\in \Zq$, we know that $(a+b) \bmod q$ will also land back in $\Zq$ because the remainder of division by $q$ is always a number from $0$ to $q-1$.

#### Property 2: $a + b \bmod q$ is commutative

Clearly, since $(a + b) \bmod q = (b + a) \bmod q$.

#### Property 3: $0$ is an identity

There exists an identity element $e \in \Zq$ such that:

$$(a + e) \bmod q = (e + a) \bmod q = a, \forall a \in \Zq$$

Clearly, that element is $0 \in \Zq$ since:

$$(a + 0) \bmod q = (0 + a) \bmod q = a,\forall a \in Zq$$

{: .todo}
Uniqueness of identity element.

#### Property 4: Addition modulo $q$ is associative.

The notation can become cumbersome unless we do a small trick: let us use $\odot$ to denote addition modulo $q$.
Specifically:
\begin{align}
a \odot b \stackrel{\mathsf{def}}{=} (a + b) \bmod q
\end{align}

What we need to show is that associativity holds: i.e., for any elements $a,b,c$ from $\Zq$, we have:
\begin{align}
(a \odot b) \odot c = a \odot (b \odot c)
\end{align}

The cumbersome way of denoting this would have been:
\begin{align}
(((a + b) \bmod q) + c) \bmod q = (a + ((b + c) \bmod q)) \bmod q
\end{align}

#### Property 5: Each element $a$ has an inverse $-a = q - a$

Addition modulo $q$ is invertible.

In other words, any element $a$ in $\Zq$ has an inverse, denoted by $-a$, such that $(a \odot (-a)) = 0$, where $0\in \Zq$ is the identity element [from above](#property-3-0-is-an-identity).

For $\Zq$, we can define the inverse of any element as:

$$\forall a\in\Zq, -a \stackrel{\mathsf{def}}{=} (q - a) \bmod q$$

$q-a$ is indeed an inverse for $a$ because:
\begin{align}
(a \odot (-a)) \bmod q
    &= (a + (q - a)\bmod q) \bmod q\\\\\
    &= (a + (-a + q)\bmod q) \bmod q\\\\\
    &= (((a + (-a)) \bmod q) + q) \bmod q\\\\\
    &= (0 + q) \bmod q\\\\\
    &= q \bmod q\\\\\
    &= 0 \in \Zq
\end{align}

Importantly, the inverse is in $\Zq$ because we have $0 \le -a < q \Leftrightarrow 0 \le q - a < q$.

{: .todo}
Uniqueness of inverses.

## A more complicated example: Multiplication modulo a prime $p$

{: .todo}
Explain.
-->

## Generators of prime-order subgroups of $(\Zps, \cdot)$

Since $p$ is prime, it follows that $p - 1 = \prod_i q_i$, where the $q_i$'s are primes, not necessarily distinct.
(Most commonly in cryptography, $p - 1 = 2q$ for some prime $q$.)

By [Cauchy's theorem](https://en.wikipedia.org/wiki/Cauchy%27s_theorem_(group_theory)), there will exist a subgroup $G_i$ of order $q_i$ of $\Zps$.

For $q_i = 2$, the only subgroup $\\{1, p-1\\}$ and the generator is $p-1$, since $\\{(p-1)^0,(p-1)\\} = \\{1, p-1\\}$.

This is because such size-2 subgroups will be of the form $\\{1,x\\}$.
Since the order is $2$, it must be that $x^2 = 1 \bmod p$ and $x \ne 1$, since $1$ is already in the subgroup.
But $x^2 - 1 = 0 \bmod p$ has either 1 or $-1 \bmod p \bydef p-1$ as solutions.
So $x$ can only be $-1$.

For other $q_i$'s there are two options.

**Option 1:** You make sure they are not of any other order (brute-force).

**Option 2:** You pick a candidate generator $g$ randomly and check $g^{p-1}/q_i \ne 1 \bmod p$ (see this [screenshot](/pictures/generators-mod-p.png)).

## TODOs

{: .todo}
Give **easier** examples of groups.
See [wiki](https://en.wikipedia.org/wiki/Abelian_group).
Replace the above definition by one or more of these examples.

{: .todo}
List the 4 laws more explicitly.

{: .todo}
Examples of non-associative, but commutative groups
See [this](https://math.stackexchange.com/questions/56016/are-the-axioms-for-abelian-group-theory-independent).

{: .todo}
Explain why so many primes everywhere? Why $\Zp$? Why $\ZNs$? 
The answer lies in which groups admit hard problems like DL.

{: .todo}
Additive notation versus multiplicative notation.
 
{: .todo}
Why things cycle in the exponent modulo $p$, or modulo $\phi(N)$, etc.
 
{: .todo}
Subgroups.
 
{: .todo}
Generators.

{: .todo}
Why we see both the $q$ and the $p$ for $g^{a \bmod q} \bmod p$ (e.g., Schnorr's description of his signature scheme).

{: .todo}
How do you find generators for RSA subgroups?

{: .todo}
Explain the three most common groups:
$\Zps$,
$\ZNs$,
and [elliptic curves](/elliptic-curves).


---

{% include refs.md %}
