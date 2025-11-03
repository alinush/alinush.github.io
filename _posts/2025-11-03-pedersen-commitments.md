---
tags:
title: Pedersen commitments
#date: 2020-11-05 20:45:59
#published: false
permalink: pedersen
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Pedersen commitments[^Pede91Comm] are one of the most important cryptographic primitives for a beginner to understand, in my opinion.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Algorithms

### $\mathsf{CM.Gen}(\mathbb{G}) \rightarrow \mathsf{ck}$

Pick two random group elements in $\Gr$ as the commitment key:
\begin{align}
G \randget\Gr\\\\\
H \randget\Gr\\\\\
\end{align}

{: .note}
It is crucial that this is done correctly such that nobody knows $\tau$ such that $H = \tau G$.

Return:
\begin{align}
\ck \gets (G, H)
\end{align}

### $\mathsf{CM.Commit}(\ck, m; r) \rightarrow C$
Parse the commitment key:
\begin{align}
(G, H)\parse \ck
\end{align}

Commit:
\begin{align}
    C \gets m G + rH
\end{align}

{: .warning}
The randomness $r$ must be picked freshly for every $m$!
Committing to different messages $m_1$ and $m_2$ using the same randomness $r$ would leak!
i.e., Given a commitment $m_1 G + rH$ and another commitment $m_2 G + rH$ with the same randomness, one can subtract and obtain $(m_1 - m_2)G$ which leaks the difference!

## Security

### Binding

We are going to loosely define **binding** as the property that guarantees no adversary that is given a correctly set up $\ck$ and a commitment $C$ can find two different openings $(m_1, r_1)$ and $(m_2, r_2)$ such that they both commit as $C$.

It is easy to show by contradiction that such an adversary $\Adv$ would yield another adversary $\Badv$ that can solve discrete logorithms on random $(G, H)$ instances.

**Proof:**
Suppose that
\begin{align}
\exists m_1 \ne m_2, \exists r_1 \ne r_2\ \text{s.t.}\ m_1 G + r_1 H &= m_2 G + r_2 H\Rightarrow\\\\\
(m_1 - m_2) G + (r_1 - r_2) H &= 0\Rightarrow\\\\\
(r_1 - r_2) H &= (m_2 - m_1) G\Rightarrow\\\\\
H &= \frac{m_2 - m_1}{r_1 - r_2}G\Rightarrow\\\\\
\orange{\tau} &= \frac{m_2 - m_1}{r_1 - r_2}
\end{align}

## Conclusion

This post has an associated tweet:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I think Pedersen commitments are a gentle starting point for teaching cryptography to anyone!<br><br>A **commitment** is a sealed envelope with a message m in it such that:<br>1. no one can tell what m is in it (hiding)<br>2. no one can open it to a different m (binding)<br><br>Pedersen below 👇 <a href="https://t.co/OVQ76kXAFF">pic.twitter.com/OVQ76kXAFF</a></p>&mdash; alin.apt (@alinush) <a href="https://twitter.com/alinush/status/1985458124426526792?ref_src=twsrc%5Etfw">November 3, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


## References

For cited works, see below 👇👇

{% include refs.md %}
