---
tags:
 - zero-knowledge proofs (ZKPs)
 - polynomials
 - interpolation
 - rank-1 constraint systems (R1CS)
title: The Spartan zkSNARK framework
#date: 2020-11-05 20:45:59
#published: false 
permalink: spartan
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** What a beautiful construction!

<!--more-->

{% include zkp.md %}
{% include mle.md %}
{% include fiat-shamir.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
%
\def\oracle#1{\langle #1 \rangle}
\def\prove{\mathsf{Prove}}
%
\def\b{\boldsymbol{b}}
\def\btau{\boldsymbol{\tau}}
\def\binS{\bin^s}
\def\binN{\bin^{\log{n}}}
\def\C{\mathcal{C}}
\def\inst{\mathbf{i}}
\def\k{\boldsymbol{k}}
\def\r{\boldsymbol{r}}
\def\z{\mathbf{z}}
\def\Z{\boldsymbol{Z}}
%
\def\bit{\mathsf{bit}}
\def\bits{\mathsf{bits}}
%
\def\row{\mathsf{row}}
\def\col{\mathsf{col}}
\def\val{\mathsf{val}}
\def\rowbits#1{\overrightarrow{\mathsf{row}_{#1}}}
\def\colbits#1{\overrightarrow{\mathsf{col}_{#1}}}
%
\def\ok{\mathsf{ok}}
\def\dense{\mathcal{\green{D}}}
\def\sparse{\mathcal{\red{S}}}
\def\setup{\mathsf{Setup}}
\def\commit{\mathsf{Commit}}
\def\open{\mathsf{Open}}
\def\verify{\mathsf{Verify}}
$</div> <!-- $ -->

## Introduction

Spartan[^Sett19e]$^,$[^Sett20] is a framework for building zkSNARK schemes using the well-known [sumcheck protocol](#multivariate-sumcheck)[^LFKN92]$^,$[^Thal20] and a **sparse multilinear (MLE) polynomial commitment scheme (PCS)**.

Spartan is a SNARK for [R1CS](/r1cs) satisfiability.
Usually, such R1CS SNARKs are built by viewing the R1CS as a [QAP](/r1cs/#quadratic-arithmetic-programs-qaps).
Spartan doesn't really do that: it works directly with the R1CS matrices.

A consequence of this seems to be that its proving time is, at best, $\Omega(n)$ where $n$ is the maximum number of non-zero entries in one of the three R1CS matrices.
In contrast, SNARKs for QAP like [Groth16](/groth16) tend to have proving times of $\omega(\max{(N,m)})$ where $N$ is the number of R1CS constraints (i.e., number of rows in the matrix) and $m$ is the number of R1CS variables (i.e., number of columns).
For example, [Groth16](/groth16/#prover-time)) does:
 - 6 size-$N$ FFTs, so $O(N\log{N}) \F$ multiplications
 - 1 size-$(N-1) \Gr_1$ **multi-(large-)scalar multiplication (MLSM)**
 - 1 size $\approx m \Gr_2$ **multi-(small-)scalar multiplication (MsSM)**
 - 3 size $\approx m$  $\Gr_1$ MsSM 

### Why I really like Spartan

1. Most of the prover work is delegatable, **publicly!**
1. Sumcheck-based, either [multivariate](/sumcheck) or [univariate](/univariate-sumcheck)
    - $\Rightarrow$ linear-time (concretely-efficient) prover!
1. PCS-based, multilinear or univariate, depending on choice of sumcheck ☝️
1. It poses a very nice research question: _What is the most efficient PCS for sparse MLEs?_
1. For structured / repetitive / uniform circuits, Spartan's [most expensive step](#6-sparse-mle-pcs-leftarrow-sumcheck--dense-mle-pcs-aka-spark) can be done by the verifier!

### Technical overview

(Universal) setup:
1. R1CS matrices as MLEs $\tilde{A},\tilde{B},\tilde{C}$
1. Commit to them via a sparse MLE PCS $\Rightarrow$ get a universal setup!

Proving:
1. Commit to the MLE extension $\tilde{Z}(\Y)$ of the **statement-witness vector** $\z = (\stmt, 1, \witn)$ containing the statement and witness 
1. Reduce R1CS satisfiability to zerocheck on $F(\X) = \sum_\j \tilde{A}(\X,\j)\tilde{Z}(\j) \sum_\j\tilde{B}(\X,\j)\tilde{Z}(\j) - \sum_\j \tilde{C}(\X,\j)\tilde{Z}(\j)$ over boolean hypercube
1. Reduce zerocheck to 0-sumcheck on $F(\X)\eq_\btau(\X)$ where $\tau$ is a random point
1. Reduce 0-sumcheck to opening $F(\X)$ at $\X=\r_x$ for a random point $\r_x$
1. Reduce $F(\r_x)$ opening to three (batched) sumchecks on $\tilde{V}(\r_x, \Y)\tilde{Z}(\Y)$, for all R1CS matrices $V \in \\{A,B,C\\}$
    + Just swap in $\X=\r_x$ into the $F(\X)$ expression above and note that all you need are these three sums!
1. Reduce the batched sumchecks to openings under a random point $\r_y$
    - of $\tilde{Z}(\r_y)$
    - of $\tilde{V}(\r_x,\r_y)$ for all R1CS matrices $V\in\\{A,B,C\\}$ 
        - This last part is really key, because the proving cost is mostly affected by the sparse MLE PCS we use for $\tilde{V}$

## Preliminaries
 
We assume familiarity with:
 - [Multilinear extensions (MLEs)](#multilinear-extensions-mles)
 - [$\mathsf{eq}(\mathbf{X};\mathbf{b})$ Lagrange polynomials](/mle#lagrange-polynomials)
 - multilinear extension (MLE) polynomial commitment schemes (PCS) such as PST[^PST13e].
 - the [multivariate sumcheck](#multivariate-sumcheck) protocol[^Thal20]

### Notation

 - We use $[s) \bydef \\{0,1,\ldots,s-1\\}$
 <!-- $\mathbf{a} \concat \mathbf{b}$ denotes the concatenation of two vectors into one -->
 - We refer to a sumcheck that verifies a polynomial sums to 0 over the hypercube as a **0-sumcheck**
 - We typically denote the **boolean hypercube** of size $2^s$ as $\binS$
 - We often use $\tilde{V}$ to refer the MLE of a vector or matrix $V$.
 - When, clear from context, we switch between the number $b$ and its binary vector representation $\b \bydef [b_0,\ldots,b_{s-1}]\in\binS$, such that $b = \sum_{i\in[s)} b_i 2^i$.
{% include prelims-fiat-shamir.md %}

### Multilinear extensions (MLEs)

Recall that a **vector** $V = [V_0, \ldots V_{n-1}]$, where $n = 2^\ell$, can be represented as a degree-1 multivariate polynomial with $\ell$ variables, a.k.a. a [multilinear extension (MLE)](/mle) by interpolation using [$\eq_i(\cdot)$ Lagrange polynomials](/mle#lagrange-polynomials):
\begin{align}
\label{eq:mle}
\tilde{V}(\X) \bydef \sum_{i\in [n)} V_i \cdot \eq_i(\X)
\end{align}
This way, if $\i=[i_0,\ldots,i_{s-1}]$ is the binary representation of $i$, we have:
\begin{align}
\tilde{V}(\i) = V_i,\forall i \in [n)
\end{align}

Similarly, we can represent a **matrix** $(A_{i,j})_{i,j\in[m)}$ as an MLE:
\begin{align}
\label{eq:mle-matrix}
\tilde{A}(\X,\Y) \bydef \sum\_{i\in [m),j\in[m)} A\_{i,j} \cdot \eq\_i(\X)\eq\_j(\Y)
\end{align}
This way, we similarly have:
\begin{align}
\tilde{A}(\i,\j) = A\_{i,j},\forall i,j \in [n)
\end{align}

### Dense MLE PCS

Spartan uses a **"dense" multilinear polynomial commitment scheme** to commit to size-$2^s$ MLEs where most of the $2^s$ terms are non-zero.

#### $\dense.\setup(s)\rightarrow (\ck,\ok)$

Returns a **commitment key** $\ck$ used to commit to multilinear polynomials over $s$ variables and to create **opening proofs** and an **opening key** $\ok$ used to verify openings.

#### $\dense.\commit(\ck, \tilde{F})\rightarrow c$

Computes the commitment $c$ to the multilinear polynomial $\tilde{F}(X_0,\ldots,X_{s-1})$.

#### $\dense.\open^\FSo(\ck, c, \tilde{F}, \boldsymbol{a}) \rightarrow (e, \pi)$

Creates an opening proof $\pi$ arguing that $\tilde{F}(\boldsymbol{a}) = e$, where
$\tilde{F}$ is committed in $c$, $\boldsymbol{a}\in \F^s$ and $e \in \F$.

#### $\dense.\verify^\FSo(\ok, c, \boldsymbol{a}, b; \pi) \rightarrow \\{0,1\\}$

Verifies that the opening proof $\pi$ correctly argues that $\tilde{F}(\boldsymbol{a}) = b$ where $\tilde{F}$ is the polynomial committed in $c$.

### Sparse MLE PCS

Let $m\bydef 2^s$.
Spartan additionally needs a **"sparse" multilinear polynomial commitment scheme** used to commit to size-$m^2$ MLEs where most of the terms in the MLE are zero.
For example, perhaps only $n = o(2^{2s})$ or $n = O(m)$ terms are non-zero.

{: .note}
Our sparse MLE PCS definition below is **specialized** for Spartan's use case of committing to three MLEs for the [sparse R1CS matrices](/r1cs#sparsity)!
So, our algorithms always operate over these three (commitments to) matrices!

#### $\sparse.\setup(s, n)\rightarrow (\ck,\ok)$

Sets up a scheme for committing to three multilinear polynomials over $2s$ variables, such that each polynomial interpolates an $m\times m$ (R1CS) matrix with at most $n$ non-zero entries and $m\bydef 2^s$.
Returns the **commitment key** $\ck$ and the **opening key** $\ok$.
(Recall matrix interpolation from [here](#multilinear-extensions-mles).)

#### $\sparse.\commit(\ck, \tilde{A}, \tilde{B}, \tilde{C})\rightarrow (c_A, c_B, c_C)$

Returns commitments $(c_A, c_B, c_C)$ to the three MLEs of the $A,B$ and $C$ matrices.

#### $\sparse.\open^\FSo(\ck, (\tilde{A},\tilde{B},\tilde{C}), (\r_x,\r_y)) \rightarrow (e_a, e_b, e_c; \pi)$

Creates an opening proof $\pi$ arguing all the following evaluations hold:
\begin{align}
\label{eq:sparse-mle-evals}
\tilde{A}(\r_x,\r_y) &= e_a\\\\\
\tilde{B}(\r_x,\r_y) &= e_b\\\\\
\tilde{C}(\r_x,\r_y) &= e_c\\\\\
\end{align}

#### $\sparse.\verify^\FSo(\ok, (c_A,c_B,c_C), (\r_x,\r_y); \pi) \rightarrow \\{0,1\\}$

Verifies that the opening proof $\pi$ correctly argues that the evaluations in Eq. \ref{eq:sparse-mle-evals} hold for the MLEs committed in $c_A, c_B$ and $c_C$.

### Multivariate sumcheck

The [multivariate sumcheck](/sumcheck) protocol consists of a prover algorithm and a verifier one.

#### $\SC.\prove^{\FSo}(F, T, s, d)\rightarrow (e,\pi;\r)$ 

Returns a **sumcheck proof** $\pi$ that the claimed sum $T=\sum_{\b \in \binS} F(\b)$ is valid iff. $F(\r) = e$, for some random $\r\fsget \F^s$, picked via Fiat-Shamir on the transcript so far (maintained via the $\FSo$ oracle).
Here, $s$ denotes the number of variables in $F$ and $d$ denotes the maximum degree of a variable in $F$.
Additionally, returns the evaluation claim $e$ and the randomness $\r$, so it can be verified separately **outside** this algorithm.

{: .note}
Note that the sumcheck proof merely **reduces** verifying the sum $T$ to verifying the evaluation claim $e\equals F(\r)$.
Why do we formalize it in this way?
Because it is very useful in higher-level protocols that use sumcheck!
Such protocols tend to further reduce verifying the evaluation claim $e$ to yet another sumcheck, so returning an opening proof for $e$ here would not be useful for them (e.g., this happens in [Step 4](#4-opening-fboldsymbolr_x-leftarrow-degree-2-sumchecks) of Spartan).

#### $\SC.\verify^\FSo(T, e, d; \pi)\rightarrow (b\in\\{0,1\\}; \r)$

Verifies the sumcheck proof $\pi$ that the claimed sum $T=\sum_{\b\in\binS} F(\b)$ is correct iff., for a **previously-fixed** polynomial $F$[^fixed-polynomial] whose variables have max-degree $d$, we have $F(\r) = e$.
As a result, the verifier must check **outside this algorithm** that $F(\r) = e$ against some oracle to $F$ (e.g., a polynomial commitment).
Here, $\r\fsget\F^s$ is a random point derived via Fiat-Shamir.
Returns a success bit $b\in\\{0,1\\}$ and the randomness $\r$ used.

{: .note}
Note that our sumcheck algorithms are non-interactive and assume a Fiat-Shamir[^FS87] oracle that maintains the transcript of messages sent by the prover to the verifier.
This transcript is used to derive public randomness in the non-interactive setting (which, in the interactive setting, the verifier would just pick).
This formalization, although a bit awkward, makes it easier to reason about securely-using sumcheck in a black-box fashion in [our later description of Spartan](#spartan-piop-framework-for-non-zk-snarks).)

### Multivariate zerocheck

We want to 
One of the tasks in Spartan is to prove a **zerocheck** on a polynomial $F$ (see [Step 3](#3-zerocheck-on-fboldsymbolx-leftarrow-degree-3-0-sumcheck-on-fboldsymbolxeq_btauboldsymbolx)), i.e.:
\begin{align}
F(\X) = 0, \forall \X\in \binS
\end{align}
There is a nice **zerocheck-to-sumcheck reduction** for this!
Let:
\begin{align}
\label{eq:zerocheck}
Q(\Y)\bydef \sum_{\b\in\binS} F(\b)\cdot\eq_\b(\Y)
\end{align}
<!-- (Note that $Q(\b) = F(\b),\forall \b\in\binS$.) -->

It can be shown that the zerocheck is equivalent to picking a random $\btau\in\F^s$ and checking:
\begin{align}
\label{eq:q-tau}
Q(\btau)
  = \sum_{\b\in\binS} F(\b)\cdot \eq_\b(\btau) &= 0\Leftrightarrow\\\\\
    \label{eq:0-sumcheck}
    \sum_{\b\in\binS} F(\b)\cdot \eq_\btau(\b) &= 0
\end{align}
In other words, it's equivalent to doing a **0-sumcheck** on $F(\X)\cdot\eq_\tau(\X)$ as per Eq. \ref{eq:0-sumcheck}!

{: .note}
What's the intuition?
It is simply checking that a random linear combination between the $F(\b)$'s and the random $\eq_\b(\tau)$ coefficients is zero!
In fact, other polynomials could be used to represent the random coefficients.
e.g., instead of $\eq_\b(\X)$ one could use $r_\b(\X) \bydef \prod_{\i\in \binS} X_i^{b_i}$.

<details>
<summary>
👇 Why? Stating this as an informal theorem and proving it below... 👇
</summary>
<b>Theorem</b> (informal):
Pick $\btau$ randomly. Then, $Q(\btau) = 0 \Leftrightarrow F(\X) = 0, \forall \X \in \binS$.
(Roughly, b.c. there is a probability with which this does <b>not</b> hold. See lemma 4.3 in <a href="#fn:Sett19e">Spartan eprint</a> for a formal claim.)
<br/><br/>

<b>Proof</b> ("$\Leftarrow$"):
This follows from the definition of $Q(\cdot)$ from Eq. \ref{eq:zerocheck}, by just swapping $F(\X)$ with 0 and observing $Q$ is zero everywhere, including at $\btau$.
<br/><br/>

<b>Proof</b> [by contradiction] ("$\Rightarrow$"):
Suppose that $Q(\btau) = 0$ at a random $\tau$ yet $\exists \b\in\binS$ such that $F(\b) \ne 0$.
Then, again, from the definition of $Q(\cdot)$ from Eq. \ref{eq:zerocheck}, this implies that $Q(\Y)$ is a non-zero polynomial.
(Because one of the terms of the sum from Eq. \ref{eq:zerocheck} will have a non-zero $F(\b)$ value.)
Roughly, this contradicts the Schwartz-Zippel lemma.
</details>

### R1CS

Spartan is a SNARK for [R1CS](/r1cs) satisfiability.

The R1CS matrices $\term{A}, \term{B}, \term{C}$ are assumed to be **square** (of $\term{m}$ rows and $m$ columns) and **sparse**, with $\term{n}$ non-zero entries.

The R1CS is said to be **satisfiable** if exists a **statement-witness vector** $\z\in \F^m$ such that:
\begin{align}
\label{eq:r1cs-sat}
A \z \circ B \z = C \z
\end{align}
where:
\begin{align}
\label{eq:z}
\term{\z} = (\term{\stmt}, 1, \term{\witn}) \in \mathbb{F}^{|\stmt|} \times \mathbb{F} \times \mathbb{F}^{m-|\stmt|-1}
\end{align}
with $\term{\stmt}$ being the **public statement** and $\term{\witn}$ being the **private witness**.

For convenience, an **R1CS instance** is defined as:
\begin{align}
\label{eq:r1cs-instance}
\term{\inst} = (\mathbb{F},A,B,C,\stmt,m,n)
\end{align}

{: .note}
Note that an R1CS instance $\inst$ includes the public statement $\stmt$, but not the private witness $\witn$.
It also includes the R1CS (square) matrix size $m$ and the # of non-zero entries $n$.

{: .definition}
An R1CS instance is said to be **satisfiable** iff. exists a private witness $\witn$ s.t. Eq. $\ref{eq:r1cs-sat}$ holds.
We also say the instance is **satisfied by** $\witn$.

## Spartan PIOP explanation

We focus this blog post on explaining how Spartan obtains a SNARK (no ZK) by reducing R1CS satisfiability (from Eq. \ref{eq:r1cs-sat}) to two sumchecks, a dense MLE PCS opening and a sparse MLE PCS opening.

This section describes things from the **lens of polynomial interactive oracle proofs (PIOPs)**, so it assumes interaction between the SNARK **prover** and the **verifier**.

[Later on](#spartan-piop-framework-for-non-zk-snarks), we more formally describe the Spartan framework to construct a SNARK from:
1. the [sumcheck protocol](#multivariate-sumcheck)
2. a [dense MLE PCS](#dense-mle-pcs)
3. a [sparse MLE PCS](#sparse-mle-pcs) (typically, obtained via Spartan's dense-to-sparse MLE compiler called _Spark_)

**Notation:** Let $\term{s}=\lceil \log{m} \rceil$, where $\log$'s base is always 2.

### (1) MLEs of R1CS matrices, public statement and private witness

We represent the R1CS matrices $A$, $B$ and $C$ as [multilinear extensions (MLE)](#multilinear-extensions-mles) $\term{\tilde{A}}, \term{\tilde{B}},\term{\tilde{C}}$ (see Eq. \ref{eq:mle-matrix}).
<!--For example, for $A \bydef (A_{i,j})\_{i,j\in[m)}$, we define:
\begin{align}
%\term{\tilde{A}(X_1, \ldots, X_s, Y_1,\ldots,Y_s)} \bydef
\term{\tilde{A}(\X,\Y)} = \sum_{\i,\j \in \binS} A_{i,j} \cdot \eq(\X, \i)\eq(\Y,\j)
\end{align}
such that:
\begin{align}
\tilde{A}(\i,\j)=A_{i,j},\forall i,j\in[m)
\end{align}
where $i\in[m)$ is a row index, $j\in[m)$ is a column index and $\i,\j\in \binS$ are their $s$-bit binary representations, 
-->

Let:
 1. $\term{\tilde{P}}$ denote the size $2^{s-1}$ MLE of **only** the public statement $(\stmt, 1)\in \F^{m/2}$
 2. $\term{\tilde{W}}$ denote the size $2^{s-1}$ MLE of **only**  the private witness $\witn\in \F^{m/2}$
    + _Note:_ We assume, without loss of generality, that $\|\witn\| = \|\stmt\|+1$
 3. $\z \bydef (\stmt, 1, \witn) \in \mathbb{F}^m$ denote the **statement-witness vector**, as per Eq. \ref{eq:z}
 4. $\term{\tilde{Z}}$ denote the size-$2^s$ MLE of $\z$

As an MLE, $\tilde{Z}$ can be _decomposed_[^SCPplus22] into its left half $\tilde{P}$ and right half $\tilde{W}$:
\begin{align}
\label{eq:Z}
\term{\tilde{Z}}(\Y) &= Y\_0 \cdot \underbrace{\term{\tilde{P}}(Y_1, \ldots, Y_{s-1})}\_{\text{MLE for}\ (\stmt,1)} + (1-Y_0)\cdot \underbrace{\term{\tilde{W}}(Y_1,\ldots,Y_{s-1})}_{\text{MLE for}\ \witn}
\end{align}

The prover begins by sending the verifier an _oracle_ $\oracle{\tilde{W}}$ to $\tilde{W}$.
This means the verifier will also have an $\oracle{\Z}$ to $\Z$, which is important later on.
(Recall we are describing Spartan from the lens of PIOPs.)

### (2) R1CS satisfiability $\Leftarrow$ degree-2 zerocheck on $F(\X)$

Then, satisfiability of an R1CS instance $A,B,C$ with public input $\stmt$ by witness $\witn$ can be expressed as:

\begin{align}
\forall\ \text{rows}\ i\in[m), \sum_{j\in[m)} A_{i,j} z_j \cdot \sum_{j\in[m)} B_{i,j} z_j - \sum_{j\in[m)} C_{i,j} z_j = 0\Leftrightarrow\\\\\
\forall\ \i\in\binS, \sum_{\j\in\binS} \tilde{A}(\i,\j) \tilde{Z}(\j) \cdot \sum_{\j\in\binS} \tilde{B}(\i,\j) \tilde{Z}(\j) - \sum_{\j\in\binS} \tilde{C}(\i,\j) \tilde{Z}(\j) = 0
%\Leftrightarrow\\\\\
%\forall \x\in \binS, \sum_{\j\in\binS} \tilde{A}(\x,\j) \tilde{Z}(\j) \cdot \sum_{\j\in\binS} \tilde{B}(\x,\j) \tilde{Z}(\j) - \sum_{\j\in\binS} \tilde{C}(\x,\j) \tilde{Z}(\j) = 0\Leftrightarrow\\\\\
\end{align}
To prove the above equation holds, define a multivariate polynomial $\term{F}$ associated with the R1CS instance $\inst$:
\begin{align}
\label{eq:F}
\term{F(\X)}
&\bydef \sum_{\j\in\binS} \tilde{A}(\X,\j) \tilde{Z}(\j) \cdot \sum_{\j\in\binS} \tilde{B}(\X,\j) \tilde{Z}(\j) - \sum_{\j\in\binS} \tilde{C}(\X,\j) \tilde{Z}(\j)
\end{align}

Note that $F(\X)$ contains a product of two MLEs, so it is a **degree-2** multivariate polynomial.

Then, the main result of Spartan can be stated as a theorem:

{: .theorem}
An R1CS instance $\inst$ (see Eq. \ref{eq:r1cs-instance}) is satisfied by a witness $\witn \Leftrightarrow F(\X) = 0$ for all $\X \in \binS$ (i.e., $F$ is zero on the hypercube).

### (3) Zerocheck on $F(\boldsymbol{X})$ $\Leftarrow$ degree-3 0-sumcheck on $F(\boldsymbol{X})\eq_\btau(\boldsymbol{X})$

[We know from above](#zero-check) that a zerocheck on $F$ can be reduced to a 0-sumcheck on another related polynomial: <!-- $\term{G}$: -->
\begin{align}
\label{eq:G}
F(\X)\cdot \eq_\term{\btau}(\X)
\end{align}
where $\term{\btau}\randget\F^s$ is randomly picked by the verifier.
Specifically, the sumcheck will be:
\begin{align}
\label{eq:first-sumcheck}
\sum_{\b\in\binS} F(\b)\cdot \eq_\btau(\b) \equals 0
\end{align}

To convince the verifier, the prover will send two things.

First, an evaluation at a random point $\term{\r_x}\in \F^s$ picked by the verifier:
\begin{align}
\label{eq:ex}
\term{e_x} 
\bydef F(\term{\r_x})\cdot \eq_\btau(\term{\r_x})
\end{align}

Second, a sumcheck proof $\term{\pi_x}$, which the verifier will check against the claimed sum (i.e., 0) and the evaluation $e_x$ (as per the sumcheck protocol[^Thal20]).

{: .definition}
We refer to the sumcheck from Eq. \ref{eq:first-sumcheck} as Spartan's **first sumcheck**!

Once the sumcheck proof is verified, the remaining verifier work is checking that the $e_x$ evaluation from Eq. \ref{eq:ex} is correct!

Fortunately, verifying the $\eq_\btau(\r_x)$ part of $e_x$ is easy.
Unfortunately, the $F(\r_x)$ part is trickier: $F$'s formula from Eq. \ref{eq:F} includes three other sums!
Fortunately, Spartan observes that these sums can also be proved using sumcheck!

### (4) Opening $F(\boldsymbol{r}_x)$ $\Leftarrow$ degree-2 sumchecks 

<!--i.e., to $\sum_\j \tilde{V}(\r_x, \j)$ (for each R1CS matrix $V$) sumchecks plus a $\sum_\j \tilde{Z}(\j)$ sumcheck will be needed to evaluate $F$ as per Eq. \ref{eq:F}.-->


How can the prover prove the $F(\r_x)$ evaluation?

First, expand it as per Eq. \ref{eq:F} to:
\begin{align}
\label{eq:Frx}
F(\r_x)
&= \sum_{\j\in\binS} \tilde{A}(\r_x,\j) \tilde{Z}(\j) \cdot \sum_{\j\in\binS} \tilde{B}(\r_x,\j) \tilde{Z}(\j) - \sum_{\j\in\binS} \tilde{C}(\r_x,\j) \tilde{Z}(\j)\\\\\
\end{align}
Denote the three sums above by:
\begin{align}
\label{eq:three-sumchecks}
\term{v_A} &\bydef \sum_{\j\in\binS} \tilde{A}(\r_x,\j) \tilde{Z}(\j)\\\\\
\term{v_B} &\bydef \sum_{\j\in\binS} \tilde{B}(\r_x,\j) \tilde{Z}(\j)\\\\\
\term{v_C} &\bydef \sum_{\j\in\binS} \tilde{C}(\r_x,\j) \tilde{Z}(\j)\\\\\
\end{align}
such that:
\begin{align}
F(\r_x) &= v_A \cdot v_B - v_C
\end{align}

Now, we have reduced verifying $F(\r_x)$ to verifying the three sumchecks from Eq. \ref{eq:three-sumchecks}!

### (5) Degree-2 sumchecks $\Leftarrow$ Opening $Z(\r_y), A(\r_x,\r_y),\ldots, C(\r_x,\r_y)$

Luckily, the sumchecks from Eq. \ref{eq:three-sumchecks} can be batched into a single one (while remaining degree-2). 

First, the verifier picks random scalars:
\begin{align}
\term{(r_A, r_B, r_C)}\randget\F^3\\\\\
\end{align}
Second, randomly combine the $v_A, v_B, v_C$ sumchecks via these scalars:
\begin{align}
\label{eq:batched-sumcheck}
\term{T} 
&\bydef r\_A v\_A + r\_B v\_B + r\_C v\_C \\\\\
&= r\_A\left(\sum\_{\j\in\binS} \tilde{A}(\r\_x,\j) \tilde{Z}(\j)\right) +
r\_B\left(\sum\_{\j\in\binS} \tilde{B}(\r\_x,\j) \tilde{Z}(\j)\right) + 
r\_C\left(\sum\_{\j\in\binS} \tilde{C}(\r\_x,\j) \tilde{Z}(\j)\right)\\\\\
\label{eq:second-sumcheck}
&= \sum\_{\j\in\binS} \left(\underbrace{r_A \tilde{A}(\r\_x,\j) \tilde{Z}(\j) +
 r_B \tilde{B}(\r\_x,\j) \tilde{Z}(\j) + 
 r_C \tilde{C}(\r\_x,\j) \tilde{Z}(\j)}\_{\term{M\_{\r_x}(\j)}}\right)\\\\\
\end{align}
Now, the prover proves _one_ sumcheck on the $\term{M_{\r_x}(\Y)}$ polynomial from above (instead of three as per Eq. \ref{eq:three-sumchecks}). 

_Small note:_
In practice, this single $M_{\r_x}$ sumcheck can be **batched, carefully,** so as to not blow up the size of the involved field elements from the $(r_A,r_B,r_C)$ random linear combination.

{: .definition}
We refer to this Eq. \ref{eq:second-sumcheck} sumcheck as Spartan's **second sumcheck**!
(Recall the first one was in Eq. \ref{eq:first-sumcheck}).

As before, the prover sends a sumcheck proof $\term{\pi_y}$ that reduces verifying the claimed sum $T$ to verifying an evaluation $\term{e_y}\bydef M_{\r_x}(\term{\r_y})$ at a random $\term{\r_y}\in\F^s$ picked by the verifer.

To verify the $e_y$ evaluation, the verifier needs to check:
\begin{align}
e_y &\equals M\_{\r_x}(\r_y) \Leftrightarrow\\\\\
    \label{eq:mrx-opening}
    &\equals \left(
        r_A \cdot \underbrace{\tilde{A}(\r\_x,\r_y)}\_{\term{a_{x,y}}} +
        r_B \cdot \underbrace{\tilde{B}(\r\_x,\r_y)}\_{\term{b_{x,y}}} + 
        r_C \cdot \underbrace{\tilde{C}(\r\_x,\r_y)}\_{\term{c_{x,y}}}
    \right)
        \cdot \underbrace{\tilde{Z}(\r_y)}\_{\term{e_z}}\\\\\
    &\equals
        (r_A \cdot \term{a_{x,y}} + r_B \cdot \term{b_{x,y}} + r_C \cdot \term{c_{x,y}}) \cdot \term{e_z}
\end{align}

_In theory_ (i.e., in the PIOP model), this is easy to do:
 1. The verifier has oracles $\oracle{\tilde{A}},\oracle{\tilde{B}},\oracle{\tilde{C}} \Rightarrow$ it can query for the $(a_{x,y},b_{x,y},c_{x,y})$ evaluations
 2. The verifier has a $\oracle{\tilde{Z}}$ oracle (recall from Eq. \ref{eq:Z}) $\Rightarrow$ it can also query for the $e_z$ evaluation

_In practice_, **this is the most difficult task in Spartan**: instantiating the PIOP model with the right **sparse** R1CS MLEs, so as to enable efficient opening proofs for the $(a_{x,y},b_{x,y},c_{x,y})$ evaluations.

#### Naive sparse MLE PCS

It's useful to clarify why a naive sparse MLE PCS would be **extremely-inefficient**.

First, recall that:
 - Every R1CS matrix is of size $m\times m\Rightarrow$ can be naively represented as a size-$m^2$ vector $V\Leftrightarrow$ a size-$m^2$ MLE. 
 - Every R1CS matrix is sparse $\Leftrightarrow$ around $n \approx m$ entries in $V$ are non-zero.

Even though committing to the sparse MLE $\tilde{V}$ could be done in $O(n)$, not $O(m^2)$ via a **dense MLE PCS** scheme (e.g., PST[^PST13e]), two problems remain:
 1. The size of the structured reference string (SRS) could be $\Theta(m^2)$, which is too large
 2. The opening time for $\tilde{V}(\r_x,\r_y)$ in all previously-known dense MLE PCS schemes is $\Theta(m^2)$! (Would love to hear if this is wrong.)

### (6) Sparse MLE PCS $\Leftarrow$ sumcheck & dense MLE PCS (a.k.a., Spark)

To efficiently address the challenges above, Spartan proposes a compiler, called **Spark**.

**Spark** can take any [dense MLE PCS](#dense-mle-pcs) for size-$n$ MLEs and turn it into a [**sparse** one](#sparse-mle-pcs) for size $m^2$ MLEs with only $n \approx m$ non-zero entries.

Recall that $m=2^s$ and that we have a size-$m^2$ MLE $\tilde{V}$ of a sparse R1CS matrix, say, $V=(V\_{i,j})\_{i,j\in[m)}$ with $n\approx m$ non-zero entries:
\begin{align}
\tilde{V}(\X,\Y) = \sum\_{\i\in\binS,\j\in\binS} V\_{i,j}\cdot\eq\_i(\X)\eq\_j(\Y)
\end{align}

Spark's goal is to come up with a sparse MLE PCS that can efficiently open $\tilde{V}(\r_x,\r_y)$ as per Eq. \ref{eq:mrx-opening}:
\begin{align}
\label{eq:r1cs-matrix-sumcheck}
\tilde{V}(\r_x,\r_y) = \sum_{\i\in\binS,\j\in\binS} A_{i,j}\cdot\eq_i(\r_x)\eq_j(\r_y)
\end{align}

How?

First, for each R1CS matrix $V$, the universal setup will commit to three **dense** MLEs representing the non-zero entries $V_{i,j}$ in the matrix and their locations $i,j$.

Denote the set of non-zero entries in a matrix $V$ by:
\begin{align}
%N\_V \bydef 
\left(i_k,j_k,V_{i_k,j_k}\right)\_{k\in[n)}
\end{align}

Then, we can define three MLEs $\row,\col,\val : \F^{\log{n}} \rightarrow \F$ that represent this set as:
\begin{align}
\label{eq:rows-cols-vals}
\forall k\in[n),
\begin{cases}
    \term{\row(\k)} &= i_k \wedge {}\\\\\
    \term{\col(\k)} &= j_k \wedge {}\\\\\
    \term{\val(\k)} &= A_{i_k,j_k}
\end{cases}
%\row(\X) \bydef \sum_{\b\in\binS} 
\end{align}
(These can be interpolated [as usual](#multilinear-extensions-mles).)

Now assume a function that converts a row or column index $i\in[m)$ (or $j\in[m)$) to its $s$-bit binary representation:

$$\term{\bits} : [m) \rightarrow \binS$$

As a result, we can rewrite the R1CS matrix sumcheck from Eq. \ref{eq:r1cs-matrix-sumcheck} as:
\begin{align}
\label{eq:r1cs-sparse-sumcheck}
\tilde{V}(\r_x,\r_y) 
&= \sum_{\i\in\binS,\j\in\binS} V_{i,j}\cdot\eq_i(\r_x)\cdot\eq_j(\r_y)\\\\\
&= \sum_{\i\in\binS,\j\in\binS} V_{i,j}\cdot\eq_{\r_x}(\i)\cdot\eq_{\r_y}(\j)\\\\\
&= \sum_{V_{i,j}\ne 0} V_{i,j}\cdot\eq_{\r_x}(\i)\cdot\eq_{\r_y}(\j)\\\\\
\label{eq:r1cs-dense-sumcheck}
&= \sum_{k\in[n)} \val(\k)\cdot\eq_{\r_x}(\bits(\row(\k)))\cdot\eq_{\r_y}(\bits(\col(\k)))\\\\\
%&\bydef \sum_{k\in[n)} \val(\k)\cdot\eqr{V}(\k,\r_x)\eqc{V}(\k,\r_y)\\\\\
\end{align}

{: .error}
Unfortunately, the expression being summed over above in Eq. \ref{eq:r1cs-dense-sumcheck} is **not** a polynomial.
This is because $\bits$'s domain is $[m)$ and we cannot evaluate it on arbitrary field elements in $\F$.

My understanding so far is that Spark is an efficient protocol for "linearizing" the $\eq_{\r_x}(\bits(\row(\r_k)))$ expression into an MLE that agrees with it over hypercube (and its $\col$ counterpart).

{: .todo}
Describe the Spark approach, later refined by Lasso[^STW23e] and Shout[^ST25e].

## Spartan PIOP framework for (non-ZK) SNARKs

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
%\def\derive{\mathsf{Derive}}
\def\spartanProof{\begin{pmatrix}
    c_\witn, \pi_w, e_w,\\
    \pi_x, e_x, \pi_y, e_y,\\
    v_A, v_B, v_C,\\
    a_{x,y}, b_{x,y}, c_{x,y},\pi_{x,y}\\ \end{pmatrix}}
$</div>

We describe Spartan as a **framework** for obtaining (non-ZK) SNARKs given a [dense MLE PCS](#dense-mle-pcs) $\dense$ and a [sparse MLE PCS](#sparse-mle-pcs) $\sparse$ (from a compiler like Spark[^Sett19e]).


### $\mathsf{Spartan}_{\mathcal{D},\mathcal{S}}.\mathsf{Setup}(A, B, C) \Rightarrow (\prk,\vk)$

Notation:

 - $m\bydef 2^s$ denote the number of rows and columns in the square [R1CS matrices](#r1cs) $A,B,C$
 - $n_A,n_B,n_C$ denote the max number of non-zero entries in $A,B$ and $C$, respectively
 - $n\gets \max{(n_A,n_B,n_C)}$

Set up the dense and sparse PCSs:
 - $(\ck_\dense,\ok_\dense)\gets \dense.\setup(s-1)$
 - $(\ck_\sparse,\ok_\sparse)\gets \sparse.\setup(s, n)$

Commit to the R1CS matrices:
 - $(c_A,c_B,c_C) \gets \sparse.\commit(\ck_\sparse, \tilde{A}, \tilde{B}, \tilde{C})$

Bureaucratically-track the commitments and the PCS's opening keys and commitments keys: 
 - $\vk\gets (c_A,c_B,c_C,\ok_\dense,\ok_\sparse)$
 - $\prk\gets (A,B,C,\vk, \ck_\dense,\ck_\sparse)$

### $\mathsf{Spartan}_{\mathcal{D},\mathcal{S}}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, \mathbf{x}; \mathbf{w}) \Rightarrow \pi$ 

Recall $m\bydef 2^s$ is the # of rows and columns in the R1CS matrices.

Commit to the witness and set up the Fiat-Shamir transcript:
 - $(\cdot,\cdot,\cdot,\vk,\ck_\dense,\cdot)\parse \prk$
 - Let $W \bydef \witn\in \F^{m/2}$
 - $c_\witn\gets\dense.\commit(\ck_\dense,\tilde{W})$
    + _ZK:_ Would need changes
 - add $(\vk,c_\witn)$ to $\FS$ transcript

Prove the first [sumcheck](#scprovefsof-t-s-drightarrow-epir):
 - $\btau \fsget \F^s$
 - Let $Z \bydef (\stmt, 1, \witn)\in \F^m$
 - Let $F(\X) \bydef \sum_{\j\in\binS} \tilde{A}(\X,\j) \tilde{Z}(\j) \cdot \sum_{\j\in\binS} \tilde{B}(\X,\j) \tilde{Z}(\j) - \sum_{\j\in\binS} \tilde{C}(\X,\j) \tilde{Z}(\j)$
 - $(e_x, \pi_x; \r_x\in\F^s) \gets \SC.\prove^\FSo(F\cdot \eq_\btau, 0, s, 3)$ (see Eq. \ref{eq:F})
    + _ZK:_ Would need changes

Prove the second [sumcheck](#scprovefsof-t-s-drightarrow-epir):
 - $(r_A, r_B, r_C) \fsget \F^3$
 - Let $M_{\r_x}(\Y) \bydef r_A \tilde{A}(\r\_x,\Y) \tilde{Z}(\Y) + r_B \tilde{B}(\r\_x,\Y) \tilde{Z}(\Y) + r_C \tilde{C}(\r\_x,\Y) \tilde{Z}(\Y)$
 - $v_A \gets \sum_{\j\in\binS} \tilde{A}(\r_x,\j) \tilde{Z}(\j)$
 - $v_B \gets \sum_{\j\in\binS} \tilde{B}(\r_x,\j) \tilde{Z}(\j)$
 - $v_C \gets \sum_{\j\in\binS} \tilde{C}(\r_x,\j) \tilde{Z}(\j)$
 - $T\gets r_A v_A + r_B v_B + r_C v_C$ 
 - $(e_y, \pi_y; \r_y) \gets \SC.\prove^\FSo(M_{\r_x}, T, s, 2)$ (see Eq. \ref{eq:second-sumcheck})
    + _ZK:_ Would need changes
    + _Performance:_ This can be carefully implemented so as to only apply the random linear combination on the univariate polynomial sumcheck messages and work mostly over small field elements.

<!-- The Spartan proof, defined as a macro, to avoid mistakes -->
<div style="display: none;">$
\def\spartanProof{\begin{pmatrix}
    c_\witn, \pi_w, e_w,\\
    \pi_x, e_x, \pi_y, e_y,\\
    v_A, v_B, v_C,\\
    a_{x,y}, b_{x,y}, c_{x,y},\pi_{x,y}\\ \end{pmatrix}}
$</div>

Compute one dense and one sparse MLE opening:
 - $(e_w, \pi_w) \gets\dense.\open^\FSo(\ck_\dense, c_\witn, \tilde{W},(r_{y,t})_{t\in[1,s)})$
    + _ZK:_ Would need changes
 - $(a_{x,y},b_{x,y},c_{x,y};\pi_{x,y})\gets \sparse.\open^\FSo\begin{pmatrix}
    \ck_\sparse,
    (\tilde{A}, \tilde{B}, \tilde{C}),%\\\\\
    (\r_x,\r_y)
    \end{pmatrix}$

We are done:
 - $\pi\gets\spartanProof$

#### Prover time

 - Witness-dependent:
    - dense MLE commitment to size-$m/2$ witness vector $W$ (would need ZK)
    + degree-3 sumcheck over $F(\X)\cdot \eq_\btau(\X)$ (would need ZK)
        - Recall $\tilde{Z}(\j) = z_j$, where $\z$ is the statement-witness vector from Eq. \ref{eq:z}
        - Recall $\eq_\btau(\X)$ is a size-1 MLE
<!-- Let $\tilde{V}_j(\X) \bydef \tilde{V}(\X,\j)$ for every R1CS matrix $V\in\\{A,B,C\\}$ be an MLE of size-$m$ -->
        - Let $\tilde{V}'(\X) \bydef \sum_{\j \in \binS} \tilde{V}(\X,\j) z_j$ for every R1CS matrix $V\in\\{A,B,C\\}$
            + Note that $V(\X,\j)$ is a size-$m$ _precomputable_ MLE for the $j$th column of matrix $V$
        - Sumcheck is over $\left(\tilde{A}'(\X)\cdot\tilde{B}'(\X) + \tilde{C}'(\X)\right)\cdot\eq_\btau(\X)$
    + degree-2 sumcheck over $M_{\r_x}(\Y)$ (would need ZK)
    - dense MLE opening for $\tilde{W}$ (would need ZK)
 - Witness-independent:
    - sparse MLE openings for the R1CS matrices

{: .todo}
Two $f_1(\r_1) = v_1,f_2(\r_2) = v_2$ MLE openings can be batched via a sumcheck:
pick a random $\alpha\in\F$ and check that $v_1 + \alpha v_2 \equals \sum_\b \left(f_1(\b) \eq_{\r_1}(\b) + \alpha f_2(\b)\eq_{\r_2}(\b)\right)$
(This will further drive up the proof size though.)

#### Ideal proof size we can hope for

**tl;dr:** Not even accounting for the MLE openings, looks like it will be $> 80+2592+1952+192=4816$ bytes.

 - $1 \times \Gr_1 + 1 \times \F$, for the dense MLE commitment $c_\witn$ to $W$ and the $e_w$ evaluation
    - i.e., $48+32 = 80$ bytes
 - **TODO:** ideal dense MLE ZK PCS opening size, for $\pi_w$ 
    + e.g., PST[^PST13] (not ZK) would be $(\log{m}-1)\times \Gr_1\Rightarrow$ for $m=20$ we have $19 \times 48 = 912$ bytes
 - $((3+1)\log{m} + 1)\times \F$, for $(\pi_x, e_x)$
    + e.g., for $m=2^{20}\Rightarrow (4 \cdot 20 + 1)\cdot 32 = 81\cdot32 = 2592$ bytes
    - or, via HyperPLONK[^CBBZ22e] tricks that avoid extra evaluations, ignoring batched opening proof size: $\log{m}\times \Gr_1 + (\log{m} + 1)\times \F = 20 \times 48 + 21 \times 32 = 960 + 672 = 1632$ bytes
 - $((2+1)\log{m} + 1)\times \F$, for $(\pi_y, e_y)$
    + e.g., for $m=2^{20}\Rightarrow (3 \cdot 20 + 1)\cdot 32 = 61\cdot32 = 1952$ bytes
    - or, as before via HyperPLONK tricks $\Rightarrow 1632$ bytes
 - $6 \times \F$, for $v_A,v_B,v_C,a_{x,y},b_{x,y},c_{x,y}$
    - i.e., $6 \cdot 32 = 192$ bytes
 - **TODO:** ideal sparse MLE opening size, for $\pi_{x,y}$

{: .note}
Unclear whether committing to the sumcheck univariate polynomials would help for small degrees like 2 and 3, since we'd need to also reveal evaluations and their (batched) proofs.

### $\mathsf{Spartan}_{\mathcal{D},\mathcal{S}}.\mathsf{Verify}^{\mathcal{FS}(\cdot)}(\mathbb{x}; \mathbf{\pi}) \Rightarrow \\{0,1\\}$

Parse the proof and set up the Fiat-Shamir transcript:
 - $\spartanProof\parse\pi$
 - add $(\vk,c_\witn)$ to $\FS$ transcript

Verify the first [sumcheck](#scverifyfsot-e-d-pirightarrow-bin01-r):
 - $\btau \fsget \F^s$
 - $(s_x; \r_x) \gets \SC.\verify^\FSo(0, e_x, 3; \pi_x)$
    + _ZK:_ Would need changes
 - **assert** $s_x \equals 1$
 - **assert** $e_x \equals (v_A \cdot v_B - v_C)\cdot \eq_\btau(\r_x)$

Verify the second [sumcheck](#scverifyfsot-e-d-pirightarrow-bin01-r):
 - Let $P \bydef (\stmt, 1) \in \F^{m/2}$
 - $(r_A, r_B, r_C) \fsget \F^3$
 - $T\gets r_A v_A + r_B v_B + r_C v_C$
 - $(s_y; \r_y) \gets \SC.\verify^\FSo(T, e_y, 2; \pi_y)$
    + _ZK:_ Would need changes
 - **assert** $s_y \equals 1$
 - $z_y \gets \left(r_{y,0} \tilde{P}(r_{y,1},\ldots,r_{y,s-1}) + (1-r_{y,0})e_w\right)$ 
 - **assert** $e_y \equals (r_A \cdot a_{x,y} + r_B \cdot b_{x,y} + r_C \cdot c_{x,y}) \cdot z_y$
 
Verify the $e_w \equals \tilde{W}(\r_y)$ opening:
 - $(\cdot,\cdot,\cdot,\ok_\dense,\cdot) \gets \vk$
 - **assert** $\dense.\verify^\FSo(\ok_\dense, c_\witn, (r_{y,t})_{t\in[1,s)}, e_w; \pi_w)$
    + _ZK:_ Would need changes

Verify the R1CS MLE evaluations:
 - $(c_A, c_B, c_C,\cdot,\ok_\sparse) \gets \vk$
 - **assert** $\sparse.\verify^\FSo\begin{pmatrix}
    \ok_\sparse,
    (c_A, c_B, c_C),
    (\r_x, \r_y),
    (a_{x,y}, b_{x,y}, c_{x,y});
    \pi_{x,y}
\end{pmatrix}$

Succeed:
 - **return 1**

#### Verifier time

 - verify degree-3 sumcheck
 - verify degree-2 sumcheck
 - verify dense PCS opening
 - verify sparse PCS opening; will involve at least:
    + one degree-2 sumcheck (if not worse)
    + verifying some dense MLE PCS openings, hopefully batched

## Conclusion

I like Spartan a lot!
It is very interesting to think of how to instantiate it efficiently so as to strike the desired proof size and verifier time without sacrificing prover time too much.

{: .todo}
Cost of making it ZK?
First, the dense MLE PCS for $\witn$ must have hiding commitments and ZK opening proofs.
Second, the univariate polynomials in Spartan's first and second sumchecks have to be blinded.
And that's it: the third sumcheck inside the sparse MLE PCS is on a public polynomial!

{: .todo}
Generalize to $\|\stmt\| + 1 \ne \|\witn\|$ and also being non-powers of two.

{: .todo}
Generalize to non-square R1CS matrices with $N$ non-zero entries and $n$ rows / R1CS constraints, s.t. $n$ is not necessarily equal to $m$.

### Acknowledgements

Thanks to Weijie Wang for explaining Spark[^Sett19e].
Thanks to Albert Garreta for explaining through Spartan, Spark and other multivariate protocols.
Thanks to Justin Thaler, Kabir Peshawaria and Guru Vamsi Policharla for explaining many things about sumchecks, Spartan, and MLE PCSs.

## Appendix

### Spartan protocol from the original paper

<div align="center"><img style="width:75%" src="/pictures/spartan.png" /></div>

### Extra resources

 - Srinath Setty's [HackMD on Spartan and Spark](https://hackmd.io/@srinathsetty/spartan)
 - encrypt.a41.io's [Spartan writeup](https://encrypt.a41.io/zk/snark/spartan)
 - [Sumcheck implementations, Kabir Peshawaria](https://gitlab.com/IrreducibleOSS/binius/-/tree/ad2d620e56dff3b18d502c6dafa557d6988ad920/crates/core/src/protocols)
    + [Simpler Python code here](https://github.com/IrreducibleOSS/binius-models/blob/main/binius_models/ips/sumcheck.py)
 - Sub-logarithmic sumcheck[^SP25e]
 - [Sumchecks from Ingonyama](https://github.com/ingonyama-zk/papers/blob/main/sumcheck_201_book.pdf)
 - [Hyrax PCS](https://xn--2-umb.com/24/hyrax-pcs/)
 - [Brakedown PCS](https://xn--2-umb.com/24/brakedown/)
 - [WHIR PCS](https://xn--2-umb.com/24/whir/)

## References

For cited works, see below 👇👇

[^fixed-polynomial]: Viewed from the PIOP lens, "fixed" here means that the sumcheck prover first sent a polynomial oracle $\oracle{F}$ to the verifier **and** only after that it invoked $\SC.\prove$ on $F$. (In practice, this means the prover first sent a commitment to the polynomial $F$ to the verifier.)

{% include refs.md %}
