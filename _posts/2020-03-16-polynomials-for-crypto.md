---
tags: polynomials
title: Basics of Polynomials for Cryptography
date: 2020-03-16 10:38:00
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

### Lagrange interpolation

Given $n$ pairs $(x_i, y_i)\_{i\in[n]}$, one can compute or _interpolate_ a degree $\le n-1$ polynomial $\phi(X)$ such that:
$$\phi(x_i)=y_i,\forall i\in[n]$$ 

Specifically, the _Lagrange interpolation_ formula says that:
\begin{align}
\label{eq:lagrange-formula}
\phi(X) &= \sum_{i\in[n]} y_i \cdot \lagr_i(X),\ \text{where}\ \lagr_i(X) = \prod_{j\in[n],j\ne i} \frac{X-x_j}{x_i-x_j} 
\end{align}

This formula is intimidating at first, but there's a very simple intuition behind it.
The key idea is that $\lagr_i(X)$ is defined so that it has two properties:

 1. $\lagr_i(x_i) = 1,\forall i\in[n]$ 
 2. $\lagr_i(x_j) = 0,\forall j \in [n]\setminus\{i\}$

You can actually convince yourself that $\lagr_i(X)$ has these properties by plugging in $x_i$ and $x_j$ to see what happens.

{: .warning}
**Important:** The $\lagr_i(X)$ polynomials are dependent on the set of $x_i$'s only (and thus on $n$)! Specifically each $\lagr_i(X)$ has degree $n-1$ and has a root at each $x_j$ when $j\ne i$!
In this sense, a better notation for them would be $\lagr_i^{[x_i, n]}(X)$ or $\lagr_i^{[n]}(X)$ to indicate this dependence.

Furthermore, consider the following example with $n=3$ pairs.
Then, by the Lagrange formula, we have:

$$\phi(X) = y_1 \lagr_1(X) + y_2 \lagr_2(X) + y_3 \lagr_3(X)$$

Next, by applying the two key properties of $\lagr_i(X)$ from above, you can easily check that $\phi(x_i) = y_i,\forall i\in[3]$:
\begin{align}
\phi(x_1) &=  y_1 \lagr_1(x_1) + y_2 \lagr_2(x_1) + y_3 \lagr_3(x_1) = y_1 \cdot 1 + y_2 \cdot 0 + y_3 \cdot 0 = y_1\\\\\
\phi(x_2) &=  y_1 \lagr_1(x_2) + y_2 \lagr_2(x_2) + y_3 \lagr_3(x_2) = y_1 \cdot 0 + y_2 \cdot 1 + y_3 \cdot 0 = y_2\\\\\
\phi(x_3) &=  y_1 \lagr_1(x_3) + y_2 \lagr_2(x_3) + y_3 \lagr_3(x_3) = y_1 \cdot 0 + y_2 \cdot 0 + y_3 \cdot 1 = y_3
\end{align}

An **important detail** is that the degree of the interpolated $\phi(X)$ is $\le n-1$ and not necessarily exactly equal to $n-1$.
To see this, consider interpolating the polynomial $\phi(X)$ such that $\phi(i) = i$ for all $i\in [n]$.
In other words, $x_i = y_i = i$.

The inspired reader might notice that the polynomial $\phi(X) = X$ could satisfy our constraints.
But is this what the Lagrange interpolation will return?
After all, the interpolated $\phi(X)$ is a sum of degree $n-1$ polynomials $\lagr_i(X)$, so could it have degree 1?
Well, it turns out, yes, because things cancel out.
To see, this take a simple example, with $n=3$:
\begin{align}
\phi(X) &=\sum_{i\in [3]} i \cdot \lagr_i(X) = \sum_{i\in [3]} i \cdot \prod_{j\in[3]\setminus\{i\}} \frac{X - j}{i - j}\\\\\
    &= 1\cdot \frac{X-2}{1-2}\frac{X-3}{1-3} + 2\cdot \frac{X-1}{2-1}\frac{X-3}{2-3} + 3\cdot\frac{X-1}{3-1}\frac{X-2}{3-2}\\\\\
    &= \frac{X-2}{-1}\frac{X-3}{-2} + 2\cdot \frac{X-1}{1}\frac{X-3}{-1} + 3\cdot \frac{X-1}{2}\frac{X-2}{1}\\\\\
    &= \frac{1}{2}(X-2)(X-3) - 2(X-1)(X-3) + \frac{3}{2}(X-1)(X-2)\\\\\
    &= \frac{1}{2}[(X-2)(X-3) + 3(X-1)(X-2)] - 2(X-1)(X-3)\\\\\
    &= \frac{1}{2}[(X-2)(4X-6)] - 2(X-1)(X-3)\\\\\
    &= (X-2)(2X-3) - 2(X-1)(X-3)\\\\\
    &= (2X^2 - 4X - 3X + 6) - 2(X^2 - 4X +3)\\\\\
    &= (2X^2 - 7X + 6) - 2X^2 + 8X - 6\\\\\
    &= X
\end{align}

#### Computation overhead of Lagrange interpolation

If done naively, interpolating $\phi(X)$ using the Lagrange formula in Equation \ref{eq:lagrange-formula} will take $O(n^2)$ time.

However, there are known techniques for computing $\phi(X)$ in $O(n\log^2{n})$ time.
We described **part of** these techniques in a [previous blog post](/2020/03/12/scalable-bls-threshold-signatures.html#our-quasilinear-time-bls-threshold-signature-aggregation), but for the full techniques please refer to the _"Modern Computer Algebra"_ book[^vG13ModernCh10].

<!-- TODO: 
# The Discrete Fourier Transform (DFT) 
Should have its own article.

# Multipoint evaluations
-->

{% include refs.md %}

[^kzg-eval-proofs]: Evaluation proofs in [KZG polynomial commitments](/2020/05/06/kzg-polynomial-commitments.html#evaluation-proofs) leverage the polynomial remainder theorem.
