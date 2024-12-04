---
tags:
title: Quadratic Arithmetic Programs (QAPs) and Rank-1 Constraint Systems (R1CS)
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
**tl;dr:** A **quadratic arithmetic program (QAP)**, a **Rank-1 Constraint System (R1CS)**, and an [NP relation](/2025/01/21/NP-relations.html) are equivalent ways of representing a hard problem (or computation) whose solution can be verified in polynomial-time.
In particular, R1CS is just a reformulation of QAPs as linear equations and, these days, it is used widely when formalizing computations that can be "proved in zero-knowledge."

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\mat#1{\mathbf{#1}}
%
\def\gu{\textcolor{magenta}{u}}
\def\rv{\textcolor{red}{v}}
\def\bw{\textcolor{blue}{w}}
%
\def\relqap{\mathcal{R}_\mathsf{QAP}}
$</div> <!-- $ -->

{% include zkp.md %}

This blog post explains two different characterizations of NP, which are useful when building [zero-knowledge proof systems](/2025/01/22/Defining-zero-knowledge-proofs.html): 

 - a **Rank-1 constraint system (R1CS)**: i.e., a set of three R1CS matrices $\mat{U},\mat{V},\mat{W}$ encoding an [NP relation](/2025/01/21/NP-relations.html) $R$
 - an equivalent **quadratic arithmetic program (QAP)**: a set of polynomials $(\gu_j(X),\rv_j(X),\bw_j(X))_{i\in[0,m]}$ encoding an NP relation $R$

## Notation

 - We use [linear algebra notation](/2025/01/20/Basics-of-linear-algebra.html)
    - In particular, $\circ$ denotes a [Hadamard product](/2025/01/20/Basics-of-linear-algebra.html#hadamard-products)!

## History

QAPs were first introduced by _Gennaro et al._[^GGPR13] in their groundbreaking result on NIZKs without PCPs. 
They were later reformulated by _Setty et al._[^SBVplus12e], who observed that the $n$ polynomial equations in a QAP can be rewritten as a bunch of matrix-vector products:
Later on, _Ben-Sasson et al._[^BCTV14] baptized this reformulation as R1CS.

## Rank-1 Constraint Systems (R1CS)

Any NP relation $R(\stmt; \witn)$ can (more or less[^technically]) be represented as a **Rank-1 Constraint System (R1CS)**: a set of quadratic equations that encode the same checks done by $R$.

{: .note}
This is not exactly an easy claim to understand.
First, remember that NP relations represent the NP class of computations.
Second, remember that [arithmetic] circuit satisfiability is NP-complete.
Therefore, any NP relation has an arithmetic circuit representation.
Third, recall that arithmetic circuits can only add and multiply.
As we'll see, R1CS systems allow one to encode a circuit's additions and multiplications.

Denote the public statement by:
\begin{align}
\label{eq:statement}
\stmt \bydef (a_1, a_2, \ldots, a_\ell)^\top\in\F^\ell
\end{align}
Denote the private witness by:
\begin{align}
\label{eq:witness}
\witn \bydef (a_{\ell+1}, a_{\ell+2},\ldots,a_m)^\top\in F^{m-\ell}
\end{align}
Concatenate the public statement with the private witness **and** with $a_0 = 1$ and denote it by:
\begin{align}
\label{eq:a}
\vec{a} \bydef (1,\underbrace{a_1,a_2,\ldots,a_\ell}\_\stmt,\underbrace{a_{\ell+1},a_{\ell+2},\ldots,a_m}_\witn)^\top \in \F^{m+1},\ \text{s.t.}\ a_0 \bydef 1
\end{align}

Now, (you will have to take my word for it, but) the computation in any NP relation can be represented as three **R1CS matrices** that encode $n$ equations over $m+1$ variables:
\begin{align}
\label{eq:r1cs-mat}
\mat{U} &\bydef (u\_{i,j})\_{i\in[n],j\in[0,m]} \in \F^{n\times(m+1)} 
\\\\\
\mat{V} &\bydef (v\_{i,j})\_{i\in[n],j\in[0,m]} \in \F^{n\times(m+1)} 
\\\\\
\mat{W} &\bydef (w\_{i,j})\_{i\in[n],j\in[0,m]} \in \F^{n\times(m+1)} 
\end{align}
This way, the satisfiability of the relation $R$ can now be expressed as:
\begin{align}
\label{eq:r1cs-sum-eq}
\greendashedbox{
    R(\stmt; \witn)=1 \Leftrightarrow \forall i \in [n], \sum_{j=0}^m u_{i, j} a_j \cdot \sum_{j=0}^m v_{i, j} a_j = \sum_{j=0}^m w_{i,j} a_j
}
\end{align}

{: .todo}
The reason $a_0 = 1$ is fixed in $\vec{a}$ is to allow for ...

The relation above can be expressed a bit more clearly in terms of the rows of the matrices:
\begin{align}
\mat{U} &\bydef \begin{pmatrix}
 \text{ ---} & \vec{U}_1 & \text{--- }\\\\\
 \text{ ---} & \vec{U}_2 & \text{--- }\\\\\
    & \vdots & \\\\\
 \text{ ---} & \vec{U}_n & \text{--- }
\end{pmatrix}\\\\\
\mat{V} &\bydef \begin{pmatrix}
 \text{ ---} & \vec{V}_1 & \text{--- }\\\\\
    & \vdots & \\\\\
 \text{ ---} & \vec{V}_n & \text{--- }
\end{pmatrix}\\\\\
\mat{W} &\bydef \begin{pmatrix}
 \text{ ---} & \vec{W}_1 & \text{--- }\\\\\
    & \vdots & \\\\\
 \text{ ---} & \vec{W}_n & \text{--- }
\end{pmatrix}\\\\\
\end{align}
So, if $\vec{U}_i$ denotes the $i$th row in the matrix $\mat{U}$, we have:
\begin{align}
\label{eq:r1cs-vec-eq}
\greendashedbox{
    R(\stmt;\witn) = 1 \Leftrightarrow \forall i \in [n], (\vec{U}_i\cdot\vec{a})\cdot(\vec{V}_i\cdot\vec{a}) = \vec{W}_i\cdot\vec{a}
}
\end{align}
However, **the most common way** to look at R1CS you will find in the academic literature[^SBVplus12e] is:
\begin{align}
\label{eq:r1cs-mat-eq}
\greendashedbox{
    R(\stmt; \witn)=1 \Leftrightarrow \mat{U}\vec{a} \circ \mat{V}\vec{a} = \mat{W}\vec{a}
}
\end{align}

**Notes:**
 - Recall that $\circ$ denotes a [Hadamard product](/2025/01/20/Basics-of-linear-algebra.html#hadamard-products)!
 - $m$ is typically called the **number of (R1CS) variables**.
 - $n$ is typically called the **number of (R1CS) constraints** or equations (equal to the # of multiplications needed to compute $R$)

{: .note}
Yet another way to view R1CS is as $\vec{a}^\top U^\top \circ \vec{a}^\top V^\top = \vec{a}^\top W^\top$, where the matrices are transposed to be in $\F^{(m+1)\times n}$ and the vector $\vec{a}^\top \in \F^{1\times (m+1)}$ is now a row-vector. 

{: .info}
**tl;dr:** R1CS satisfiability (Eq. \ref{eq:r1cs-sum-eq}, \ref{eq:r1cs-vec-eq} or \ref{eq:r1cs-mat-eq}) $\Leftrightarrow$ $R(\stmt;\witn)$ satisfiability.

### Sparsity

When "compiling" an NP relation to an R1CS of $n$ equations and $m$ variables, if done right, the matrices are **sparse**: they only have $O(n)$ non-zero entries.

## Quadratic Arithmetic Programs (QAPs)

From our [R1CS discussion](#rank-1-constraint-systems-r1cs), we know that any [NP relation](/2025/01/21/NP-relations.html) $R$ can be turned into an R1CS constraint system defined by matrices $(\mat{U},\mat{V},\mat{W})$ from Eq. \ref{eq:r1cs-mat}.

In this section, we explain how an NP relation $R$ can be represented (or viewed) as a **QAP**[^GGPR13]\: a set of $m+1$ polynomials of degree $n-1$ each:

\begin{align}
\label{eq:qap-polys}
\gu\_j(X),\rv\_j(X),\bw\_j(X) \in \F[X]^{\le n-1},\forall j\in[0,m]
\end{align}

This way, the satisfiability of the relation $R$ can now be expressed as:
\begin{align}
\label{eq:qap-modulo}
\greendashedbox{
    R(\stmt;\witn) = 1 \Leftrightarrow \sum_{j=0}^m \gu_j(X) a_j \cdot \sum_{j=0}^m \rv_j(X) a_j \equiv \sum_{j=0}^m \bw_j(X) a_j \bmod X^n - 1
}
\end{align}

{: .note}
(1) We are assuming the same $\vec{a}=1\|\|\stmt\|\|\witn\in\F^m$ notation from Eq. \ref{eq:a}.\
(2) Let $(\omega,\omega^2,\ldots,\omega^n)$ denote the $n$th **roots of unity**[^rou] in the finite field $\F$ such that the $X^n - 1$ polynomial from Eq. \ref{eq:qap-modulo} above can be factored as $X^n - 1 = \prod_{i=0}^n (X-\omega^i)$.

The **key idea** is to <u>encode each column</u> $j\in[0,m]$ of the R1CS matrices $\mat{U},\mat{V},\mat{W}$ as polynomials $\gu_j(X),\rv_j(X),\bw_j(X)$, respectively, such that:
\begin{align}
\label{eq:qap-polys-def} % referenced externally
\gu_j(\omega^i) \bydef u_{i,j}\\\\\
\rv_j(\omega^i) \bydef v_{i,j}\\\\\
\bw_j(\omega^i) \bydef w_{i,j}
\end{align}

Put differently, the $j$th column of each R1CS matrix (e.g., $\mat{U}$) defines a **QAP polynomial** (e.g., $\gu_j(X)$):
\begin{align}
\begin{bmatrix}
\|       & \|    & \cdots & \|    \\\\\
\gu_0(X) & \gu_1(X) & \cdots & \gu_m(X) \\\\\
\|       & \|    & \cdots & \|    \\\\\
\end{bmatrix}
\bydef \mat{U}
\end{align}

{: .info}
Note that each polynomial $\gu_j,\rv_j,\bw_j$ is interpolated from $n$ points and thus has degree $\le n-1$.
\
Typically, roots-of-unity are used as the evaluation domain since they either (1) enable quickly-interpolating each polynomial using an $O(n\log{n})$ inverse FFT or (2) make polynomial operations, such as multiplication, faster.

Now, we can rewrite our $n$ R1CS constraint equations (from Eq. \ref{eq:r1cs-sum-eq}) as polynomial equations:
\begin{align}
\forall i \in [n], \sum_{j=0}^m u_{i, j} a_j \cdot \sum_{j=0}^m v_{i, j} a_j &= \sum_{j=0}^m w_{i,j} a_j\Leftrightarrow\\\\\
\forall i \in [n], \sum_{j=0}^m \gu_j(\omega^i) a_j \cdot \sum_{j=0}^m \rv_j(\omega^i) a_j &= \sum_{j=0}^m \bw_j(\omega^i) a_j\Leftrightarrow\\\\\
\label{eq:r1cs-to-qap}
\forall i \in [n], \sum_{j=0}^m \gu_j(\omega^i) a_j \cdot \sum_{j=0}^m \rv_j(\omega^i) a_j - \sum_{j=0}^m \bw_j(\omega^i) a_j &= 0
\end{align}
This last equation just says that the polynomial on the left-hand side has roots at all $\omega^i$'s.
This is equivalent to saying that it is divisible by $(X-\omega)(X-\omega^2)\cdots(X-\omega^n)=X^n - 1$[^xn1]:
\begin{align}
(X^n - 1) \mid \sum_{j=0}^m \gu_j(X) a_j \cdot \sum_{j=0}^m \rv_j(X) a_j - \sum_{j=0}^m \bw_j(X) a_j\Leftrightarrow\\\\\
\Leftrightarrow\sum_{j=0}^m \gu_j(X) a_j \cdot \sum_{j=0}^m \rv_j(X) a_j \equiv \sum_{j=0}^m \bw_j(X) a_j \bmod X^n - 1
\end{align}
This, in turn, is equivalent to saying that $\exists$ a degree $\le (n-2)$ **"quotient" polynomial** $\green{h(X)}$ such that:
\begin{align}
\sum_{j=0}^m \gu_j(X) a_j \cdot \sum_{j=0}^m \rv_j(X) a_j - \sum_{j=0}^m \bw_j(X) a_j &= \green{h(X)} (X^n - 1)\Leftrightarrow\\\\\ 
\label{eq:qap-quotient}
\sum_{j=0}^m \gu_j(X) a_j \cdot \sum_{j=0}^m \rv_j(X) a_j &= \sum_{j=0}^m \bw_j(X) a_j + \green{h(X)} (X^n - 1)
\end{align}
(Because $X^n-1$ has degree $n$ and the polynomial it divides has degree $\le (n-1)+(n-1) = 2n-2$.)

{: .note}
The main technique behind ZKP schemes such as [Groth16](/2025/01/25/Groth16.html) is (succintly) proving knowledge of such a quotient polynomial $\green{h(X)}$. 

{: .info}
**tl;dr:** QAP satisfiability (Eq. \ref{eq:qap-quotient}) $\Leftrightarrow$ R1CS satisfiability (Eq. \ref{eq:r1cs-sum-eq}) $\Leftrightarrow$ $R(\stmt;\witn)$ satisfiability. 

### QAPs are sparse too

Since a QAP is just a polynomial representation of an R1CS, a similar sparsity property holds: the number of non-zero entries interpolated by the $(\gu_j, \rv_j, \bw_j)_{j\in[0,m)}$ polynomials is $O(n)$.

As a result, computing for example, $\sum_{j=0}^m \gu_j(X) a_j$ (in FFT basis) can be done in $O(n)$ time.

---

[^technically]: I am glancing over the fact that NP relations are defined over arbitrarily-sized inputs $\stmt$ and $\witn$, whereas R1CS relations are defined for fixed-size $\stmt$ and $\witn$. Furthermore, there may be extra witness variables added in the transformation (i.e., $R(\stmt,\witn)=1$ iff. $\exists \mathsf{aux}$ such that $\vec{a}=\stmt\|\|\witn\|\|\mathsf{aux}$ satisfies the R1CS equations in Eq. \ref{eq:r1cs-mat-eq}). So, there's probably a more formal way of saying this that I do not want to get into for the sake of brevity.
[^rou]: Recall that, in order to have a primitive $n$th root of unity $\omega$, it must be that $n$ divides $p-1$, where $p$ is the order of $\F$ (and $p-1$ is the size of the multiplicative subgroup of $\F$).
[^xn1]: This follows from the fact that the $n$th roots of unity in $\F$ are precisely the solutions to the equation $X^n = 1$ over $\F$.

{% include refs.md %}
