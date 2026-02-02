---
tags:
 - basics
 - mle
 - polynomials
 - Lagrange
title: Multilinear polynomials and multilinear extensions (MLEs)
#date: 2020-11-05 20:45:59
#published: false
permalink: mle
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Forget univariate. Forget FFTs. Multilinear polynomials are the bomb!

{% include mle.md %}

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\b{\boldsymbol{b}}
\def\binS{\bin^s}
$</div> <!-- $ -->

## Preliminaries

### Binary vectors

We often need to go from a number $b \in [0,2^s)$ to its binary representation as a vector $\b\in\binS$, and viceversa:
\begin{align}
\b = [b_0,\ldots,b_{s-1}],\ \text{s.t.}\ b = \sum_{i\in[s)} b_i 2^i
\end{align}

{: .note}
When, clear from context, we switch between the number $b$ and its binary vector representation $\b$.

## Multilinear polynomials

A **multilinear polynomial** $f$ is a polynomial in multiple variables $X_0,X_1,\ldots X_{s-1}$ such that the degree of each variable $X_i \le 1$.
More verbosely, it is a **degree-1 multivariate polynomial in $s$ variables**.

We typically denote all the variables as a vector $\X\bydef(X_0,\ldots,X_{s-1})$.

This means that $f$ can be expressed as:
\begin{align}
f(\X) \bydef \sum_{\b\in\binS} c_\b \prod_{i\in[s)} X_i^{b_i}
\end{align}

Note that the $c_\b$'s are the polynomial's **coefficients**.

## Lagrange polynomials

We want to define a multilinear polynomial $\eq$ such that:
\begin{align}
\forall \X,\b\in\binS,
\term{\eq(\X;\b)} &\bydef \begin{cases}
1,\ \text{if}\ \X = \b\\\\\
0,\ \text{if}\ \X \ne \b
\end{cases}\\\\\
\end{align}

How?
\begin{align}
\label{eq:lagrange}
\term{\eq(\X;\b)} &\bydef \prod_{i\in[s)}\left(b_i X_i + (1 - b_i) (1 - X_i)\right)\\\\\
%&\bydef \term{\eq(X_1,\ldots, X_s; b_1,\ldots,b_s)}\\\\\
&\bydef \term{\eq_\b(X_0,\ldots, X_{s-1})},\b\in\binS\\\\\
&\bydef \term{\eq_b(X_0,\ldots, X_{s-1})},b\in[2^s)\\\\\
\end{align}

<!--It is useful to note that:
\begin{align}
\eq_\b(\X) = \eq_\X(\b)
\end{align}-->

{: .note}
We use $b\in[2^s)$ and $\b\in\binS$ interchangeably, when clear from context.
We mostly use $\eq_b(\X)$ and do not explicitly include the number of variables $s$, which is clear from context.

{: .note}
<details>
<summary>
<em>👇 Why does this work? 👇</em>
</summary>
Try and evaluate $\eq(X;\b)$ at $\X = \b$ by evaluating each product term $b_i X_i + (1-b_i)(1-X_i)$ at $X_i = b_i$!
<br /><br/>

It would yield $b_i^2 + (1-b_i)^2$, which is always equal to 1 for $b_i\in\{0,1\}$.
So all product terms are 1 when $\X=\b$.
<br /><br/>

Next, try to evaluate at $X=\b'$ when $\b'\ne\b$.
In this case, there will be an index $i\in [s)$ such that $b'_i \ne b_i \Rightarrow b_i' = (1-b_i)$.
So, evaluating the $i$th product term at $(1-b_i)$ yields $b_i(1-b_i) + (1-b_i)(1-(1-b_i)) = b_i(1-b_i)+(1-b_i)b_i=2b_i(1-b_i)$ which is always 0.
Therefore, the product is zero when $\X\ne \b$.
</details>

### Computing all Lagrange evaluations fast

In many MLE-based protocols (e.g., [sumchecks](/sumcheck) or PCSs like [Hyrax](/hyrax) or [KZH](/kzh)), it is often necessary to **efficiently** compute all $n=2^\ell$ evaluations $(\eq(\x, \i))_{\i\in\\{0,1\\}^\ell}$ of the Lagrange polynomials for an arbitrary point $\x\in\F^\ell$!

This can be done in $n$ $\F$ multiplications using a tree-based algorithm, best illustrated with an example (for $\ell = 3$):
```
                               1                                 <-- level 0 / root
                         /           \                               (no muls)
                      /                 \    
                   /                       \  
                /                             \
           (1 - x_0)                          x_0                <-- level 1
        /             \                 /             \              (no muls)
   (1 - x_1)          x_1          (1 - x_1)          x_1        <-- level 2
    /     \         /     \         /     \         /     \          (2 muls)
(1-x_2)   x_2   (1-x_2)   x_2   (1-x_2)   x_2   (1-x_2)   x_2    <-- level 3 / leaves
                        [ end of tree ]                              (4 muls)
   .       .       .       .       .       .       .       .         
   .       .       .       .       .       .       .       .
   .       .       .       .       .       .       .       .
eq_0(x) eq_1(x) eq_2(x) eq_3(x) eq_4(x) eq_5(x) eq_6(x) eq_7(x)  <-- results
```

The algorithm works in two phases:
 - **Phase 1:** Compute all negations $(1-x_k),\forall k\in[\ell)$ in $\ell=\log_2{n}$ field additions. (Additions are cheap, so in practice we can ignore this cost.)
    - Now, all the nodes in the tree above are computed.
 - **Phase 2:** Starting with level 2 and going down to level $\ell$, multiply each node with its parent and overwrite that node with the result.
    - Now, all the nodes in the tree above are updated to contain the product of the values of all ancestor nodes.
    + Therfore, the $i$th leaf will have the desired $\eq_i(\x)$ value
        + For example, the $\eq_0(\x)$ leaf will be set to its actual $(1-x_0)(1-x_1)(1-x_2)$ value.
    + This will result in $2^{k-1}$ field multiplications (and $2^{k-1}$ additions) for each level $k$, if done wisely (see note below)

In general, for $n=2^\ell$, the number of field multiplications (and field additions) can be upper bounded by $T(n) = n/2 + T(n/2) = n-2$ with $T(2) = 0$ ending the recurrence, since once we reach level $k = 1$ of size $n=2^k = 2$, no multiplications are happening anymore, as depicted above.

e.g., for $n=8$, it is $4 + 2 + 0 = 6$.

However, let's not split hairs and call it $n$ $\F$ multiplications (and $n$ $\F$ additions)!

{: .note}
As hinted above, we can get away with only $2^{k-1}$ multiplications per level: instead of doing two multiplications per node (i.e., one for $\mathsf{parent}\cdot (1-x_i)$ and one for $\mathsf{parent}\cdot x_i$), we only do one multiplication to compute $\mathsf{parent}\cdot x_i$ followed by subtraction from $\mathsf{parent}$ to obtain $\mathsf{parent}\cdot (1-x_i)$.
(Here, $\mathsf{parent}$ denotes the parent node in the tree, which stores the product computed so far. e.g., for $i = 2$, an example of a parent node is $(1-x_0)x_1$.)


{: .todo}
I wonder whether the negation here is problematic, performance-wise? Would $(x_k - 1)$ help a lot here?

## Multilinear extensions (MLEs)

Given a **vector** $\vect{V} = (V_0, \ldots V_{n-1})$, where $n = 2^\ell$, it can be represented as a multilinear polynomial with $\ell$ variables by interpolation via the Lagrange polynomials from above:
\begin{align}
\label{eq:mle}
\tilde{V}(\X) \bydef \sum_{i\in [n)} V_i \cdot \eq_i(\X)
\end{align}
This way, if $\i=[i_0,\ldots,i_{s-1}]$ is the binary representation of $i$, we have:
\begin{align}
\tilde{V}(\i) = V_i,\forall i \in [n)
\end{align}

{: .definition}
$f$ is often called the **multilinear extension (MLE)** of $\vect{V}$.

{: .note}
Using the [time complexities from above](#computing-all-lagrange-evaluations-fast), notice that evaluating a size-$n$ MLE $f$ at an arbitrary point $(\x,\y)$ will involve (1) $n$ $\F$ multiplications and $n$ $\F$ additions to compute all the $\eq_i(\x)$ evaluations and (2) $n$ $\F$ multiplications and $n$ $\F$ additions to compute Eq. \ref{eq:mle}.
The total time will be $2n$ $\F$ multiplications and $2n$ $\F$ additions.

{: .todo}
Contrast this with evaluating polynomials in [Lagrange basis](/lagrange-interpolation) using the efficient formulas over root of unity?

## Conclusion and acknowledgements

Big thanks to [Ron Rothblum](https://csaws.cs.technion.ac.il/~rothblum/) for pointing out several optimizations that are possible (which I am looking into and will integrate here):

1. For computing all $n=2^\ell$ Lagrange $\eq(\x,\i)_{\i\in\\{0,1\\}^\ell}$ evaluations for an arbitrary $\x\in \F^\ell$, Proposition 1 of [Roth24e][^Roth24e] gives a $n$ $\F$ multiplications algorithm.
    + Also, it gives a way to stream the computation (but, AFAICT, so does a careful walk through the tree depicted above) 
    - **Q:** What about additions?
    - (A previous version of this blog required $2n$ $\F$ multiplications.)
2. Remark 1.? from [ARR25e][^ARR25e] can reduce the MLE evaluation time from $2n$ $\F$ multiplications to $n$! 🤯
    - **Q:** What about additions?

### Links

 - [Multilinear Polynomials and Tensor Products](https://hackmd.io/@tcoratger/BJ2NhofyZe), Thomas Coratger

## References

For cited works, see below 👇👇

{% include refs.md %}
