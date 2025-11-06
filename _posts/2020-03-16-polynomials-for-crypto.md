---
tags: 
 - basics
 - polynomials
title: Basics of Polynomials for Cryptography
date: 2020-03-16 10:38:00
permalink: polynomials
sidebar:
    nav: cryptomat
---

A **polynomial** $\phi$ of **degree** $d$ is a vector of $d+1$ **coefficients**:

\begin{align}
    \phi &= [\phi_0, \phi_1, \phi_2, \dots, \phi_d]
\end{align}

For example, $\phi = [1, 10, 9]$ is a degree 2 polynomial.
Also, $\phi' = [1, 10, 9, 0, 0, 0]$ is also a degree 2 polynomial, since the zero coefficients at the end do not count.
But $\phi'' = [1, 10, 9, 0, 0, 0, 1]$ is a degree 6 polynomial, since the last non-zero coefficient is $\phi_6 = 3$.

_"A list of numbers? That makes no sense!"_
Don't panic!
You are probably more familiar to polynomials expressed as function of a variable $X$:
\begin{align}
    \phi(X) &= \phi_0 + \phi_1\cdot X + \phi_2\cdot X^2 + \cdots + \phi_d\cdot X^d\\\\\
            &= \sum_{i=0}^{d+1} \phi_i X^i
\end{align}

For example, $\phi = [1, 10, 9]$ and $\phi(X) = 9X^2 + 10X + 1$ are one and the same thing.

**Note:** The degree is defined as the index $i$ of the last non-zero coefficient: $\deg(\phi)=i$ s.t. $\forall j > i, \phi_j = 0$.

## The basics of polynomials

### Roots of polynomials

We say $z$ is a _root_ of $\phi(X)$ if $\phi(z) = 0$.
In this case, $\exists q(X)$ such that $\phi(X) = q(X)(X-z)$.

But what if $z$ is also a root $q(X)$?
We can capture this notion as follows: we say $z$ has a _multiplicity_ $k$ if $\exists q'(X)$ such that $\phi(X) = q'(X) (X-z)^k$.

<!-- TODO

### Evaluating polynomials

### Adding and subtracting polynomials

### Multiplying polynomials
-->

### The polynomial remainder theorem

This theorem says that:

\begin{align}
\phi(a) = y\Leftrightarrow \exists q(X), \phi(X) &= q(X)(X-a) + \phi(a)
\end{align}

This property is leveraged by certain cryptosystems[^kzg-eval-proofs].

### Dividing polynomials

Division of polynomials conceptually resembles division of integers.

Specifically, dividing a polynomial $a(X)$ by $b(X)$ gives a **quotient** $q(X)$ and a **remainder** $r(X)$ such that:

$$a(X) = q(X) b(X) + r(X)$$

Importantly, $\deg{r} < \deg{b}$ and, if $\deg{a} \ge \deg{b}$, then $\deg{q} = \deg{a} - \deg{b}$.
Otherwise, $q(X) = 0$.

## TODOs

{: .todo}
Discrete Fourier Transform (DFT), maybe in its own post?

{: .todo}
Multipoint evaluations, reuse from [AMT post](/amt#polynomial-multipoint-evaluations)?

{: .todo}
Reed-Solomon error-correction algorithm(s?).

{% include refs.md %}

[^kzg-eval-proofs]: Evaluation proofs in [KZG polynomial commitments](kzg#evaluation-proofs) leverage the polynomial remainder theorem.
