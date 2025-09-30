---
tags: 
 - elliptic curves
 - math
title: Elliptic curves
article_header:
  type: cover
  image:
    src: /pictures/cost12/plot-over-r.png
#date: 2020-11-05 20:45:59
published: false
#sidebar:
#    nav: cryptomat
---

{: .info}
**tl;dr:** Everything I wanted to know, but was afraid to ask (about elliptic curves).

<!--more-->

<p hidden>$$
\def\ecid{\mathcal{O}}
$$</p>

## History

## Preliminaries

 - finite fields $\Fq$ of prime order $q$
    + $e_*$ is the multiplicative identity element in $K$, typically denoted by 1
    + $e_+$ is the additive identity element in $K$, typically denoted by 0
    + the smallest $n>0$, such that $\underbrace{e\_* + e\_* + \cdots + e\_*}\_{n\ \text{times}} = e\_+$ is called the **field characteristic**.
 - TODO: (full?) algebraic closure of a finite field $K$
    + TODO: Clarify the difference between $K$ and $\bar{K}$ (the algebraic closure of $K$), because points on the curve come from the latter.
        + Wicher said it's kind of like the real numbers: not every polynomial has a root in $\mathbb{R}$, so the _algebraic closure_ of $\mathbb{R}$ are the complex numbers $\mathbb{C}$, where every polynomial has a root.
        + Somehow the "every polynomial has a root over $\bar{K}$" property is a useful one for algebraic geometry / elliptic curves in particular
    - example: for $\mathbb{Q}$, the full algebraic closure $\bar{\mathbb{Q}}$ includes $\sqrt{-2}$.
 - TODO: $\mathbb{A}^n(K)$ = affine $n$-spaces over field $K$
 - TODO: quadratic extensions

## Scratchpad

The **general Weierstrass equation**:

\begin{align}
\label{eq:general-weierstrass}
E : y^2 + a_1 xy + a_3 y = x^3 + a_2 x^2 + a_4 x + a_6
\end{align}

The **short Weierstrass equation**:
\begin{align}
\label{eq:short-weierstrass}
E : y^2 = x^3 + a x + b
\end{align}

How?
Assume the field characteristic is not 2 or 3.
(TODO: Why?)
Then, with [a few substitutions](/pictures/cost12/short-weierstrass.png), we arrive at Equation $\ref{eq:short-weierstrass}$.

If $(a_1, \ldots, a_6)$ come from $K$, then $E$ is said to be **defined over** $K$, which is denoted as $E / K$.

An **elliptic curve group** (over a field $K$) is defined as:
\begin{align}
E(K) = \\{(x,y)\in \mathbb{A}^2(K) : y^2 = x^3 + ax + b\\} \cup \\{\ecid\\}
\end{align}

Here, $\ecid$ denotes the identity element of $E(K)$, also called the **point at infinity**.
Note that $\ecid$ is a "special case" point that is defined artificially; it does not have any $(x,y)$ coordinates (as we'll see later).

TODO: note that we typically just have $(x,y)\in K^2$?

TODO: $E = E(\bar{K})$ is typically used to refer to the same group defined over the full algebraic closure of $K$.

We'll initially denote the elliptic curve group operation by $\oplus$ (and its inverse by $\ominus$), but at a later point we will replace it with $+$ (and $-$, respectively).

Note that the identity element of $E(K)$ denoted by $\ecid$ is a "special case" point; it is defined artificially.

For any $P\in E(K)$, we denote $\underbrace{P \oplus P \oplus \cdots \oplus P}\_{n\ \text{times}} \bydef [n]P$.

{: .info}
A [note on **(non)singular** elliptic curves](/pictures/cost12/singular.png), whose future relevance I am unsure of.

 - TODO: group law explanation; plus, link to [picture](/pictures/cost12/group-law.png)
 - TODO: Why is the 3rd intersection point flipped over in the additional law?

## Acknowledgements

Most screenshots in this post (and most of my understanding of elliptic curves) come from Craig Costello's _"Pairings for beginners."_[^Cost12].

---

{% include refs.md %}
