---
tags: 
 - polynomial commitments
 - polynomials
 - sumcheck
 - mle
 - derivatives
title: Papamanthou-Shi-Tamassia (PST) multivariate polynomial commitments
#date: 2020-11-05 20:45:59
#published: false
permalink: pst
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---


{% include pairings.md %}
{% include mle.md %}
{% include time-complexities.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\crs#1{\textcolor{green}{#1}}
$</div> <!-- $ -->

{: .info}
**tl;dr:** The 1st multivariate polynomial commitment scheme based on a non-trivial generalization of [KZG](/kzg).

<!--more-->

## Introduction

PST polynomial commitments[^PST13], originally published as an eprint in 2011[^PST13e], are a beautiful generalization of [KZG](/kzg) univariate polynomial commitments to the multivariate setting.

## Preliminaries

{% include pairings-prelims.md %}
{% include time-complexities-prelims-pairings.md %}

## Algorithms

### $\mathsf{PST}.\mathsf{Setup}(\mathcal{G}, d_1,d_2,\ldots,d_\ell) \rightarrow (\ck, \prk,\vk)$

Return the public parameters:
\begin{align}
\ck &\gets
\left(\crs{\one{\tau_1^{\alpha_1} \tau_2^{\alpha_2} \cdots \tau_\ell^{\alpha_\ell}}}\right)\_{\alpha_1\in[0,d_1],\ldots,\alpha_\ell\in[0,d_\ell]}
\\\\\
\prk &\gets
\left(\crs{\one{\tau_i^{\alpha_i} \tau_{i+1}^{\alpha_{i+1}} \cdots \tau_\ell^{\alpha_\ell}}}\right)\_{i\in[\ell],\alpha_i\in[0,d_1),\alpha_{i+1}\in[0,d_{i+1}],\ldots,\alpha_\ell\in[0,d_\ell]}
\\\\\
\vk &\gets
\left(\crs{\two{\tau_i}}\right)\_{i\in[\ell]}
\\\\\
\end{align}

{: .todo}
Double check this, but I think the max degrees in the $\prk$ are $d_i - 1$ instead of $d_i$ due to the division by $X_i$ when computing $q_i$.

### $\mathsf{PST}.\mathsf{Commit}(\mathsf{ck}, f) \rightarrow C$

Parse the commitment key:
\begin{align}
\left(\crs{\one{\tau_1^{\alpha_1} \tau_2^{\alpha_2} \cdots \tau_\ell^{\alpha_\ell}}}\right)\_{\alpha_1\in[0,d_1],\ldots,\alpha_\ell\in[0,d_\ell]} \parse \ck
\end{align}

Assume that the polynomial $f$ looks like:
\begin{align}
f(X_1, X_2, \ldots, X_\ell) 
 &= \sum_{\alpha_1\in[0,d_1]}\sum_{\alpha_2\in[0,d_2]}\ldots \sum_{\alpha_\ell\in[0,d_\ell]} f_{\alpha_1, \alpha_2, \ldots,\alpha_\ell} \cdot X_1^{\alpha_1} X_2^{\alpha_2} \cdots X_\ell^{\alpha_\ell}\\\\\
% &\stackrel{\mathsf{def}}{=} \sum_{\boldsymbol{\alpha}\in[0,d]^\ell} f_{\boldsymbol{\alpha}} \cdot \boldsymbol{X}^{\boldsymbol{\alpha}},\ \text{where}\ \begin{cases}
%  \boldsymbol{\alpha} &\stackrel{\mathsf{def}}{=} [\alpha_1,\alpha_2,\ldots,\alpha_\ell]\\\\\
%  \boldsymbol{X}^{\boldsymbol{\alpha}} &\stackrel{\mathsf{def}}{=} X_1^{\alpha_1} X_2^{\alpha_2} \cdots X_\ell^{\alpha_\ell}
%\end{cases}
\end{align}

Commit to it as:
\begin{align}
C\gets \one{f(\tau_1, \tau_2,\ldots,\tau_\ell)}
 &= \sum_{\alpha_1\in[0,d_1]}\sum_{\alpha_2\in[0,d_2]}\ldots \sum_{\alpha_\ell\in[0,d_\ell]} f_{\alpha_1, \alpha_2, \ldots,\alpha_\ell} \cdot \crs{\one{\tau_1^{\alpha_1} \tau_2^{\alpha_2} \cdots \tau_\ell^{\alpha_\ell}}}
\end{align}

### $\mathsf{PST}.\mathsf{Open}(f, \boldsymbol{a}, z)\rightarrow \pi$

Compute quotient polynomials $q_1(X_1,\ldots,X_\ell), \ldots, q_\ell(X_\ell)$ such that:
\begin{align}
f(X_1,X_2,\ldots,X_\ell) = f(a_1,a_2, \ldots, a_\ell) + \sum_{i\in[\ell]} q_i(X_i,\ldots,X_\ell) (X_i - a_i) 
\end{align}

{: .todo}
Give algorithm for computing $q_i$'s and mention that whether we start with $X_1$ or with $X_\ell$, has no bearing. 

Return the proof:
\begin{align}
\pi \gets \left(\one{q_i(\tau_i,\ldots,\tau_\ell)}\right)_{i\in[\ell]}
\end{align}

### $\mathsf{PST}.\mathsf{Verify}(\vk, C, \boldsymbol{a}, z; \pi)\rightarrow \\{0,1\\}$

Parse the VK and the proof:
\begin{align}
\left(\crs{\two{\tau_i}}\right)\_{i\in[\ell]} \parse \vk\\\\\
(\pi_i)_{i\in[\ell]}\parse \pi\\\\\
\end{align}

Check the proof:
\begin{align}
\textbf{assert}\ \pair{C - \one{z}}{\two{1}} \equals \sum_{i\in[\ell]} \pair{\pi_i}{\two{\tau_i} - \two{a_i}}
\end{align}

### Efficiency

## TODOs

{: .todo}
Is this knowledge-sound in the AGM?

## References

For cited works, see below 👇👇

{% include refs.md %}
