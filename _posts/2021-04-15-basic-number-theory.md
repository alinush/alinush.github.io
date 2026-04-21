---
type: note
tags:
 - math
 - number theory
title: Basic number theory
#published: false
sidebar:
    nav: cryptomat
---

<!-- TODO: totient; gcd's -->

## Multiplicative inverses modulo $m$

The multiplicative group of integers modulo $m$ is defined as:
\begin{align}
    \Z_m^* = \\{a\ |\ \gcd(a,m) = 1\\}
\end{align}
But why?
This is because Euler's theorem says that:
\begin{align}
\gcd(a,m) = 1\Rightarrow a^{\phi(m)} = 1
\end{align}
This in turn, implies that every element in $\Z_m^\*$ has an inverse, since:
\begin{align}
a\cdot a^{\phi(m) - 1} &= 1
\end{align}
Thus, for a prime $p$, all elements in $\Z_p^\* = \\{1,2,\dots, p-1\\}$ have inverses.
Specifically, the inverse of $a \in \Z_p^*$ is $a^{p-2}$.

## Finding primitive roots mod $p$

Suppose you have $\Zp^\* = \\{1,2,3,\ldots,p-2,p-1\\}$: i.e., the group of integers mod $p$, where $p$ is a prime.

How do you find a **generator** $g$ for it? (a.k.a., primitive roots)
\begin{align}
    \langle g\rangle \bydef \\{g^0, g^1, g^2,\ldots,g^{p-2}\\}= \Zp^*
\end{align}

First, you factor its order $p-1$ as 
\begin{align}
p-1=\prod_i q_i^{e_i},\ \text{where}\ q_i\ \text{are primes}
\end{align}

Second, you simply **brute-force**: you pick a potential candidate generator $g$ and ensure:
\begin{align}
    \forall i, g^\frac{p-1}{q_i} \ne 1 \pmod p
\end{align}
If all these checks pass, then $g$ is a generator.
