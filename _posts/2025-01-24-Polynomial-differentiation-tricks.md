---
tags:
 - polynomials
 - derivatives
title: Polynomial differentiation tricks
#date: 2020-11-05 20:45:59
#published: false
permalink: differentiation-tricks
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** This post describes some useful differentiation tricks when dealing with polynomials in cryptography.

<!--more-->

{% include time-complexities.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Notation

 - Let $[n)\bydef \\{0,1,\ldots,n-1\\}$
 - Let $\F$ denote a finite field of prime order $p$.
 - Let $\omega$ denote a primitive $n$th root of unity.
 - Let $\mathbb{H} \bydef \\{\omega^0,\omega^1,\ldots,\omega^n\\}$ denote all the $n$th roots of unity 
 - We often use "Lagrange basis" or "FFT basis" to refer to the representation of a polynomial $p(X)$ as its evaluations $p(\omega^0),p(\omega^1),\ldots,p(\omega^{n-1})$ at all the $n$th roots of unity in $\mathbb{H}$.
{% include time-complexities-prelims.md %}

## Interpolating $f(X)/g(X)$ in Lagrange basis

In cryptosystems, we are often tasked with interpolating a polynomial $h(X) = f(X)/g(X)$ in the Lagrange basis (i.e., with computing all $h(\omega^i)$'s and doing an inverse FFT).
Unfortunately, sometimes we get stuck because: 
\begin{align}
g(\omega^i) &= 0,\forall i\in[n)
\end{align}
...which would give $h(\omega^i) = f(\omega^i) / g(\omega^i) = f(\omega^i)/0$, which is undefined.

{: .note}
This situation arises in Groth16's computation of its [quotient polynomial $h(X)$](/groth16#computing-hx). There, even the denominator $f$ is zero at all $\omega^i$'s.

The following theorem can (sometimes) be applied to compute $h(\omega^i) = f'(\omega^i)/g'(\omega^i)$, where $f'$ and $g'$ are the derivatives:

{: .theorem}
$\forall f,g,h\in \F[X]$ s.t. $f(X) = g(X)h(X)$, if $g(u) = 0$ for some $u\in\F$, then $f'(u) = g'(u) h(u)$, where $f'$ and $g'$ are the formal derivatives of $f$ and $g$, respectively.

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

## Evaluating Lagrange polynomial derivatives over $\mathbb{H}$

Recall that the $i$th Lagrange polynomial w.r.t. $\mathbb{H}$ is:
\begin{align}
\label{eq:lagr}
\term{\lagr_i(X)} 
    &\bydef \frac{(X^n - 1)}{(X-\omega^j) \cdot \left.(X^n - 1)'\right|\_{X=\omega^i}}\\\\\
    &\bydef \frac{(X^n - 1)}{(X-\omega^j) \cdot \left.(nX^{n - 1})\right|\_{X=\omega^i}}\\\\\
    &= \frac{(X^n - 1)}{(X-\omega^i)\cdot n(\omega^i)^{n-1}}\\\\\\
    &= \frac{(X^n - 1)\cdot\omega^i}{(X-\omega^i)\cdot n}
     = \emph{\frac{\omega^i}{n} \cdot \frac{X^n - 1}{X-\omega^i}}\\\\\\
\end{align}

Now, consider taking the derivative of $\lagr_i(X)$:
\begin{align}
\emph{\lagr_i'(X)}
    &= \frac{\omega^i}{n} \cdot \left(\frac{X^n - 1}{X-\omega^i}\right)'\\\\\\
    &= \frac{\omega^i}{n} \cdot \frac{(X^n - 1)'(X-\omega^i) - (X^n-1)}{(X-\omega^i)^2}\\\\\\
    &= \emph{\frac{\omega^i}{n} \cdot \frac{nX^{n - 1}(X-\omega^i) - (X^n-1)}{(X-\omega^i)^2}}\\\\\\
\end{align}

### Case 1: Evaluate $\lagr_i'(\omega^j)$ for $j\ne i$

Just plug in $\omega^j$ in the expression above:
\begin{align}
\label{eq:lagr_diff_ij}
\emph{\lagr_i'(\omega^j)}
    &= \frac{\omega^i}{n} \cdot \frac{n(\omega^j)^{n - 1}(\omega^j-\omega^i) - ((\omega^j)^n-1)}{(\omega^j-\omega^i)^2}\\\\\\
    &= \frac{\omega^i}{n} \cdot \frac{n(\omega^j)^{n - 1}(\omega^j-\omega^i)}{(\omega^j-\omega^i)^2}\\\\\\
    &= \omega^i \cdot \frac{(\omega^j)^{n - 1}}{\omega^j-\omega^i}
    = \omega^i \cdot \frac{\omega^{-j}}{\omega^j-\omega^i}
    = \emph{\frac{\omega^{i-j}}{\omega^j-\omega^i}}
\end{align}

If we flip $i$ and $j$, we'd get:
\begin{align}
\label{eq:lagr_diff_ji}
\lagr_j'(\omega^i)
    = \frac{\omega^{j-i}}{\omega^i-\omega^j}
\end{align}
{: .note}


### Case 2: Evaluate $\lagr_i'(\omega^i)$

We will leverage the fact that, by definition of Lagrange interpolation:
\begin{align}
    \sum_{j\in[n)} \lagr_j(X) = 1
\end{align}
(One easy way to see this is that Lagrange interpolation from $n$ evaluations (all equal to 1) is supposed to return the lowest-degree polynomial that is 1 everywhere. But this is exactly the constant 1 polynomial!)

Differentiating the above expression, we get:
\begin{align}
    \sum_{j\in[n)} \lagr_j'(X) = 0
\end{align}

Plugging in $X=\omega^i$, this gives us an expression for $\lagr_i'(\omega^i)$:
\begin{align}
\sum_{j\in[n)} \lagr_j'(\omega^i) &= 0\Leftrightarrow\\\\\
\lagr_i'(\omega^i) + \sum_{j\in[n), j\ne i} \lagr_j'(\omega^i) &= 0\Leftrightarrow\\\\\
\lagr_i'(\omega^i) 
    &= - \sum_{j\in[n), j\ne i} \lagr_j'(\omega^i)\\\\\
    &= - \sum_{j\in[n), j\ne i} \lagr_j'(\omega^i)
\end{align}

Swapping in the expression for $\lagr_j'(\omega^i)$ from Eq. \ref{eq:lagr_diff_ji}, we get:
\begin{align}
\lagr_i'(\omega^i)
    &= - \sum_{j\in[n), j\ne i} \frac{\omega^{j-i}}{\omega^i-\omega^j}
     = - \frac{1}{\omega^i}\sum_{j\in[n), j\ne i} \frac{\omega^j}{\omega^i-\omega^j}\\\\\
    &= - \frac{1}{\omega^i}\sum_{j\in[n), j\ne i} \omega^j\cdot \frac{1}{\omega^j(\omega^{i-j}-1)}
     = - \frac{1}{\omega^i}\sum_{j\in[n), j\ne i} \frac{1}{\omega^{i-j}-1}\\\\\
    &= \frac{1}{\omega^i}\sum_{j\in[n), j\ne i} \frac{1}{1-\omega^{i-j}}
\end{align}

Next, note that $\\{(i-j) \bmod n : j \ne i\\} = \\{1,2,\ldots n-1\\}$[^round-the-clock].
As a result, the set $(\omega^{(i-j) \bmod n})\_{j\in[n],j\ne i}$ in the denominator is $(\omega^j)\_{j\in[n-1]}$.
Therefore, the expression becomes:
\begin{align}
\lagr_i'(\omega^i)
    &= \frac{1}{\omega^i}\sum_{j\in[n-1]} \frac{1}{1-\omega^j}
\end{align}
The sum in the above expression can be shown equal to $(n-1)/2$ for all $n$. This will leave us with:
\begin{align}
\label{eq:lagr_diff_ii}
\emph{\lagr_i'(\omega^i)}
    &= \emph{\frac{n-1}{2\omega^i}}
\end{align}

The proof follows below.

#### Subcase 1: $n-1$ is even

In this case, we can "pair" every $\frac{1}{1-\omega^j}$ with $\frac{1}{1-\omega^{-j}}$ (e.g., 1 with $n-1$, 2 with $n-2$ and so on).
Such a pair will sum to 1 and there are $(n-1)/2$ of them.
\begin{align}
\frac{1}{1-\omega^j} + \frac{1}{1-\omega^{-j}} 
    &= \frac{(1-\omega^{-j}) + (1-\omega^j)}{(1-\omega^j)(1-\omega^{-j})}\\\\\
    &= \frac{2-\omega^{-j}-\omega^j}{ 1 - \omega^j -\omega^{-j} + \omega^{j-j})}\\\\\
    &= \frac{2-\omega^{-j}-\omega^j}{2 - \omega^j -\omega^{-j}} = 1\\\\\
\end{align}
Therefore, the sum is $(n-1)/2$.

#### Subcase 2: $n-1$ is odd
In this case, almost everything pairs up: we get $(n-2)/2$ pairs (instead of $(n-1)/2$).
Except we are left with an unpaird middle term: $\frac{1}{1-\omega^{n/2}} = \frac{1}{1-(-1)} = 1/2$.
So the sum equals $(n-2)/2 + 1/2 = (n-1)/2$, same as before.

## Opening a Lagrange-basis KZG commitment at a root of unity

When using [KZG](/kzg) to commit to polynomials, we often prefer to work in the [Lagrange basis](#preliminaries) (e.g., [Groth16](/groth16), [DeKART](/dekart)).
In this setting, we have the $n$ evaluations of a KZG-committed polynomial $\phi(X)$:
\begin{align}
    \phi(\omega^0),\ldots,\phi(\omega^{n-1})
\end{align}
...and we are _sometimes_ interested in opening this polynomial at **one of the roots of unity** $\omega^i$ by KZG-committing to a quotient polynomial $q(X)$:
\begin{align}
    \label{eq:qx}
    q(X)\bydef \frac{\phi(X) - \phi(\omega^i)}{X-\omega^i}
\end{align}
For this, it would be sufficient to compute all $q(\omega^j)_{j\in[n)}$ and then commit as usual via $\sum\_{j\in[n)} q(\omega^j)\cdot L\_j$, where $L_j$ is a commitment to the $i$th Lagrange polynomial from Eq. \ref{eq:lagr} (part of the KZG structured reference string).

**The problem** is we can only use the expression from Eq. $\ref{eq:qx}$ to compute $q(\omega^j)$ when $j\ne i$.
For $j=i$, we would GET $\left.\frac{\phi(X) - \phi(\omega^i)}{X-\omega^i}\right|_{X=\omega^i} = \frac{\phi(\omega^i) - \phi(\omega^i)}{\omega^i-\omega^i} = 0/0$.
So, we'd be missing one evaluation: $q(\omega^i)$.

**The solution** is to use the same [theorem from before](#interpolating-fxgx-in-lagrange-basis) for dealing with $0/0$ which tells us that:
\begin{align}
q(\omega^i) 
    &= \left.\frac{(\phi(X) - \phi(\omega^i))'}{(X-\omega^i)'}\right|\_{X=\omega^i}\\\\\
    &= \left.\frac{\phi'(X))}{1}\right|\_{X=\omega^i}\\\\\
    &= \phi'(\omega^i)
\end{align}
By [Lagrange interpolation](/lagrange-interpolation#barycentric-formula), we know that:
\begin{align}
\phi(X) = \sum_{j\in[n)} \phi(\omega^j) \cdot \lagr_j(X)
\end{align}
Therefore, if we differentiate we get:
\begin{align}
\phi'(X) 
    &= \sum_{j\in[n)} \phi(\omega^j) \cdot \lagr_j'(X)\\\\\
\end{align}

Now, we can evaluate $\phi'(X)$ at $\omega^i$ by swapping in the expression for the Lagrange derivatives from Eq. \ref{eq:lagr_diff_ji} and \ref{eq:lagr_diff_ii}:
\begin{align}
\term{\phi'(\omega^i)}
    &= \sum_{j\in[n)} \phi(\omega^j) \cdot \lagr_j'(\omega^i)\\\\\
    &= \phi(\omega^i)\cdot\lagr_i\(\omega^i) + \sum_{j\in[n),j\ne i} \phi(\omega^j) \cdot \lagr_j'(\omega^i)\\\\\
    &= \emph{\phi(\omega^i)\cdot \frac{n-1}{2\omega^i} + \sum_{j\in[n),j\ne i} \phi(\omega^j) \cdot \frac{\omega^{j-i}}{\omega^i-\omega^j}}
\end{align}
As a result, we can now compute $q(\omega^i)=\phi'(\omega^i)$ in $\Fmul{n}$ and we can get all other $q(\omega^j)$'s via Eq. \ref{eq:qx} in $\Fmul{n-1}$. (If done right.)

{: .note}
"Done right" means precomputing (1) all $(\lagr_i'(\omega_j))_{j\in[n)}$ and (2) all inverses like $\frac{1}{\omega^i-\omega^j}$ that arise in Eq. \ref{eq:qx}.

## Other applications

Such differentiation tricks are useful in many settings:
Lagrange coefficients for threshold crypto[^TCZplus20].
Log derivatives[^Habo22e].
Lagrange polynomials for VCs[^Drake20Kate]$^,$[^TABplus20].
Faster pre-computation of all KZG proofs[^CJLplus24e].

## References

For cited works, see below 👇👇

[^round-the-clock]: We are just "going around the clock" modulo $n$, starting with $i-0, i-1, \ldots, i-(n-1)$, except skipping $i-i = 0$.

{% include refs.md %}
