---
tags:
title: Polynomial differentiation tricks
#date: 2020-11-05 20:45:59
#published: false
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** This post describes some useful differentiation tricks when dealing with polynomials in cryptography.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Notation

 - Let $\F$ denote a finite field that admits an $n$th primitive root of unity $\omega$.
 - We use "Lagrange basis" or "FFT basis" to refer to the representation of a polynomial $p(X)$ as its evaluations $p(\omega^0),p(\omega^1),\ldots,p(\omega^{n-1})$ at all the $n$th roots of unity.

## Interpolating $f(X)/g(X)$ in Lagrange basis

In cryptosystems, we are often tasked with interpolating a polynomial $h(X) = f(X)/g(X)$ in the Lagrange basis (i.e., with computing all $h(\omega^i)$'s and doing an inverse FFT).
Unfortunately, sometimes we get stuck because: 
\begin{align}
g(\omega^i) &= 0,\forall i\in[0,n)
\end{align}
...which would give $h(\omega^i) = f(\omega^i) / g(\omega^i) = f(\omega^i)/0$, which is undefined.

{: .note}
This situation arises in Groth16's computation of its [quotient polynomial $h(X)$](/2025/01/25/Groth16.html#computing-hx). There, even the denominator $f$ is zero at all $\omega^i$'s.

The following theorem can (sometimes) be applied to compute $h(\omega^i) = f'(\omega^i)/g'(\omega^i)$, where $f'$ and $g'$ are the derivatives:

{: .theorem}
$\forall f,g,h\in \F[X],\forall u\in \F$, if $f(X) = g(X)h(X)$ and $g(u) = 0$, then $f'(u) = g'(u) h(u)$, where $f'$ and $g'$ are the formal derivatives of $f$ and $g$, respectively.

**Proof:**
Begin by differentiating $f(X)$:
\begin{align}
f'(X) 
    &= \left(g(X)h(X)\right)'\\\\\
    &= g'(X)h(X) + g(X)h'(X)
\end{align}
Next, evaluate the above expression at $u$:
\begin{align}
f'(u) &= g'(u)h(u) + \underbrace{g(u)}_{\ =\ 0}h'(u)\Leftrightarrow\\\\\
f'(u) &= g'(u)h(u)
\end{align}

**Note:** I say the theorem can be applied _sometimes_ because $g'$ may still have a root at $u$, in which case you may have to repeatedly apply the theorem on $f',g',h$.

{: .note}
Such differentiation tricks are useful in many settings:
Lagrange coefficients for threshold crypto[^TCZplus20].
Log derivatives[^Habo22e].
Lagrange polynomials for VCs[^Drake20Kate]$^,$[^TABplus20].
Faster pre-computation of all KZG proofs[^CJLplus24e].

## References

For cited works, see below 👇👇

{% include refs.md %}
