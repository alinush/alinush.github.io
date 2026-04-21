---
type: note
tags:
 - witness encryption (WE)
 - encryption
title: Witness encryption (WE)
#date: 2020-11-05 20:45:59
#published: false
permalink: we 
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---


{: .info}
**tl;dr:** Some notes to self on state-of-the-art witness encryption (WE) schemes.

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\adp{\mathsf{ADP}}
\def\aadp{\mathsf{AADP}}
\def\eval{\mathsf{eval}}
\def\x{\mathbf{x}}
\def\M{\mathsf{M}}
\def\A{\mathbf{A}}
\def\B{\mathbf{B}}
\def\R{\mathbf{R}}
\def\Rvss{\mathcal{R}_\mathsf{vss}}
\def\Radp#1{\mathcal{R}_\mathsf{adp}^{#1}}
\def\span{\mathsf{span}}
\def\Fbar{\bar{\F}}
$</div> <!-- $ -->

{% include defs-zkp.md %}

<!--more-->

## Related work

WE is implied by **indistinguishability-obfuscation (iO)** but it is weaker than iO[^GMM17e].

### Affine determinant programs (ADPs)

Bartusek et al.[^BIJplus20e] introduced **affine determinant programs (ADPs)** as key building block for WE and for iO.

An ADP is a function:

$$\term{\adp} : \{0,1\}^{\term{n}} \to \{0,1\}$$

specified by a tuple $(\term{\A}, \term{\B\_1, \ldots, \B\_n})$ of $\term{k}\times k$ matrices over $\term{\Fq}$ and a function $\term{\eval}: \Fq \to \\{0,1\\}$. Specifically:
\begin{align}
\adp(\x) = \eval\left(\det{\left(\A + \sum_{i\in[n]} x\_i \B\_i\right)}\right)
\end{align}
where $\term{\x} \bydef (\term{x_1},\ldots,\term{x_n})$
An affine function $\M$ can be defined as:
\begin{align}
\M(\x) \bydef \A + \sum_{i\in[n]} x\_i \B\_i
\end{align}
so that the ADP can be more simply viewed as:
\begin{align}
\adp(\x) = \eval\left(\det{\M(\x)}\right)
\end{align}

{: .note}
$x_i\B\_i$ is defined as the all zeros matrix when $x_i = 0$ and as $\B_i$ when $x_i = 1$.

Viewed as an NP relation, ADP satisfiability becomes:
\begin{align}
\term{\Radp{\eval}}\begin{pmatrix}{}
	\A, \B_1,\ldots,\B_n \in \Fq^{k\times k} \textbf{;}\\\\\
	\x
\end{pmatrix} = 1\Leftrightarrow 
	{ \x \in \\{0,1\\}^n }
    \wedge
    { 1 = \eval\left(\det{\left(\A + \sum_{i\in[n]} x\_i \B\_i\right)}\right) }
\end{align}

{: .warning}
The $x\in\\{0,1\\}^n$ check is actually also implemented as an ADP, but I am not showing it there for simplicity. 

{: .note}
The ADP relation is **parameterized** by an $\eval$ function! Typically, the $\eval$ function may test whether its input is zero, or whether it has the right parity.
e.g.:
\begin{align}
\term{\eval_0(y)} = \begin{cases}
    1,& y \equals 0\\\\\
    0,& \text{otherwise}
\end{cases}
\end{align}

### Encoding a dimension $d=1$ VSS as an ADP 

The (dimension-1) vector subset-sum (VSS) problem can be defined as an NP relation:

\begin{align}
\term{\Rvss}\begin{pmatrix}{}
	\mathbf{h} \in \Z^n, \ell \in \Z \textbf{;}\\\\\
	\witn
\end{pmatrix} = 1\Leftrightarrow { \witn \in \\{0,1\\}^n } \wedge { \mathbf{h}\cdot \witn = \ell }
\end{align}

They show how there exists a **randomized** ADP over $\Fp$ such that if satisfied it implies VSS satisfiability.
Specifically, to encode a VSS instance $(\mathbf{h},\ell)$ as an ADP, pick a prime $q > \max_{\witn \in \\{0,1\\}^n} |\mathbf{h}\cdot \witn|$, interpret $\mathbf{h}$ and $\ell$ as elements of $\Fq$, sample $\R \xleftarrow{\$} \Fq^{k \times k}$, and set $\A = -\ell \R$ and $\B_i = h_i \R$ for $i \in [n]$.

{: .warning}
The requirement on $q$ ensures that the integer inner product $\mathbf{h}\cdot\witn$ does not wrap around modulo $q$, so that $\mathbf{h}\cdot\witn = \ell$ over $\Z$ iff $\mathbf{h}\cdot\witn = \ell$ over $\Fq$.

**Correctness:** $\forall \mathbf{h}\in\Fq^n,\ell \in \Fq,\witn\in\\{0,1\\}^n$ such that $\mathbf{h}\cdot \witn = \ell$, we have: 
\begin{align}
\Pr_{\R \randget \Fq^{k\times k}}\begin{bmatrix}
    \emph{\Radp{\eval_0}}\begin{pmatrix}
        \underbrace{-\ell \R}\_{\A}, \underbrace{h\_1 \R}\_{\B\_1},\ldots,\underbrace{h\_n \R}\_{\B\_n}\textbf{;}\\\\\
        \witn
    \end{pmatrix} = 1 
\end{bmatrix} = 1
\end{align}

**Soundness:** $\forall \mathbf{h}\in\Fq^n,\ell \in \Fq,\witn\in\\{0,1\\}^n$ such that $\mathbf{h}\cdot \witn \ne \ell$, we have: 
\begin{align}
\Pr_{\R \randget \Fq^{k\times k}}\begin{bmatrix}
    \Radp{\eval_0}\begin{pmatrix}
        -\ell \R, h\_1 \R,\ldots, h\_n \R\textbf{;}\\\\\
        \witn
    \end{pmatrix} = 1
\end{bmatrix} \leq k / q
\end{align}

**Proof (Soundness):**
We will prove the contrapositive "ADP for $(\mathbf{h},\ell)$ accepts $\witn$ $\Rightarrow \mathbf{h}\cdot\witn = \ell$."
Let:
\begin{align}
\aadp_\mathsf{vss}(\witn) = \eval\_0\left(\det\left(-\ell \R + \sum_{i\in[n]} w_i h_i \R\right)\right)
\end{align}
denote the AADP for the VSS instance $(\mathbf{h},\ell)$.
Suppose, this ADP accepts $\witn$; i.e.:
$$\begin{align}
1 &= \aadp_\mathsf{vss}(\witn) \Leftrightarrow \\
0 &= \det\left(-\ell \R + \sum_{i\in[n]} w_i h_i \R\right) \\
             &= \det\left(\left(\sum_{i=1}^n w_i h_i - \ell\right) \R\right)\\
             &= \det\left(\left(\mathbf{h} \cdot w - \ell\right) \R\right)\\
             &= \left(\mathbf{h} \cdot w - \ell\right)^k \cdot \det\left(\R\right)
\end{align}$$

<!-- because $\det(c \cdot A) = c^k \det(A)$ -->

This is a product of two terms. It equals zero iff at least one factor is zero:

1. $\det(\R) = 0$ 
2. $s^k = 0 \iff s = 0 \iff \mathbf{h} \cdot \witn = \ell$ over $\Fq$ $\iff \mathbf{h} \cdot \witn = \ell$ over $\Z$ (by our choice of $q$).

Since the soundness assumption is $\mathbf{h} \cdot \witn \neq \ell$, case 2 is ruled out. So the ADP can only accept if $\det(\R) = 0$, which happens with probability [at most $k/q$](#sampling-singular-matrix). $\blacksquare$

### Arithmetic ADPs (AADPs)

Soukhanov et al.[^SRGK26e] generalize ADPs to **arithmetic ADPs (AADPs)**:

$$\term{\aadp} : \Fbar^{\term{n}} \to \{0,1\}$$

defined from the same $k\times k$ matrices as before, except:
 - restricted to using $\eval_0$ as its evaluation function, slightly redefined to now take an $\Fbar$, rather than an $\F$, input
 - it now takes **non-zero** inputs $\x\in\Fbar$
i.e.,:
\begin{align}
\aadp(\x) = \eval_0\left(\det{\left(\A + \sum_{i\in[n]} x\_i \B\_i\right)}\right),\forall \x \ne \vec{0}
\end{align}
where $\term{\Fbar}$ denotes the **algebraic closure** of $\F$ (i.e., all field extensions $\F_{q^k}$ for all $k$).

**Observations:**
1. The restriction to $\eval_0$ is artificial: AFAICT, it's just because it suffices for the WE use-case
2. $\F$ is cryptographically large (e.g., 256-bits)
3. The determinant defines a polynomial over $\F$, that can be evaluated by the adversary maliciously with inputs from $\Fbar$ in order to break the encryption. This is why the definition requires the input to be from an algebraic closure.


## Appendix: Probability of sampling a singular matrix over $\Fq$
{: #sampling-singular-matrix}

The proof above relies on the fact that a uniformly-random $k\times k$ matrix $\R$ over $\Fq$ is singular (i.e., square and non-invertible) with negligible probability.
This follows from a classical result on the **general linear group** $\text{GL}(k, \Fq)$, i.e., the group of all invertible $k\times k$ matrices over $\Fq$.

**Counting invertible matrices.**
To build an invertible $k\times k$ matrix over $\Fq$, we choose its rows one at a time, each of which must be linearly independent of the previous ones, leading to full-rank invertible matrix:

 - Row 1 can be any nonzero vector
    + There are $q^k$ possible size-$k$ vectors
    + Only one of them is the zero vector, which we want to avoid since it would trivially be in the span of any other row $\Rightarrow$ would not be full rank
    + $\Rightarrow q^k - 1$ possible vectors for row 1
 - Row 2 can be any vector outside the span of row 1:
    + So we must exclude the span of row 1, denoted by $\mathbf{r}_1$: i.e., exclude $\span(\mathbf{r}_1) = \\{ c \cdot \mathbf{r}_1, \forall c \in \Fq\\}$
        * This excludes the zero-vector, since $c$ can be zero.
    + The size of $\span(\mathbf{r}_1)$ is $q$, since $c \in \Fq$ and $\mathbf{r}_1$ is fixed.
    + $\Rightarrow q^k - q$ possible vectors for row 2
 - Row 3 can be any vector outside the span of rows 1–2:
    + So we must exclude $\span(\mathbf{r}_1, \mathbf{r}_2) = \\{ c_1 \cdot \mathbf{r}_1 + c_2 \cdot \mathbf{r}_2, \forall c_1, c_2 \in \Fq\\}$
    + $\mathbf{r}_1$ and $\mathbf{r}_2$ are linearly independent $\Rightarrow$ every pair $(c_1, c_2)$ gives a distinct vector $\Rightarrow \sizeof{\span(\mathbf{r}_1, \mathbf{r}_2)} = q^2$.
    + $\Rightarrow q^k - q^2$ possible vectors for row 3  
  $\vdots\hspace{5em}\vdots\hspace{5em}\vdots\hspace{5em}\vdots\hspace{5em}\vdots\hspace{5em}\vdots$
 - Row $k$ can be any vector outside the span of the first $k-1$ rows: $q^k - q^{k-1}$ choices.

So the number of invertible matrices is:

$$|\text{GL}(k, \Fq)| = \prod_{i=0}^{k-1}(q^k - q^i)$$

**Probability of non-singularity.**
Since the total number of $k\times k$ matrices over $\Fq$ is $q^{k^2}$, the probability that a uniformly-random matrix is invertible is:

\begin{align}
\Pr[\det(\R) \neq 0] &= \frac{|\text{GL}(k, \Fq)|}{q^{k^2}}\\\\\
  &= \frac{\prod_{i=0}^{k-1}(q^k - q^i)}{q^{k^2}}\\\\\
  &= \frac{\prod_{i=0}^{k-1}(q^k - q^i)}{(q^k)^k}
   = \frac{\prod_{i=0}^{k-1}(q^k - q^i)}{\prod_{i=0}^{k-1} q^k}\\\\\
  &= \prod_{i=0}^{k-1} \frac{q^k - q^i}{q^k}\\\\\
  &= \prod_{i=0}^{k-1} \left(1 - \frac{q^i}{q^k}\right)\\\\\
  &= \prod_{i=0}^{k-1} \left(1 - q^{i-k}\right)
\end{align}

**Lower bound.**
For all $i\in[0,k)$, we have $1 - q^{i-k} \geq 1 - q^{-1} = 1 - 1/q$.
(This is equivalent to $-q^{i-k} \geq - q^{-1} \Leftrightarrow q^{i-k} \leq q^{-1} \Leftrightarrow i - k \leq -1 \Leftrightarrow i \leq k - 1$, which is true from the premise that $i\in[0,k)$.)

Thus:

$$\Pr[\det(\R) \neq 0] \geq \left(1 - \frac{1}{q}\right)^k$$

Equivalently, the probability of singularity is:

\begin{align}
\Pr[\det(\R) = 0] &= 1 - \Pr[\det(\R) \neq 0]\\\\\
  &\leq 1 - \left(1 - \frac{1}{q}\right)^k\\\\\
  &\leq 1 - \left(1 - \frac{k}{q}\right)\\\\\
  &= \frac{k}{q}
\end{align}
where the last inequality applies Bernoulli's inequality $(1-x)^k \geq 1 - kx$ for $x \in [0, 1]$ and $k \geq 1$.

{: .smallnote}
$x$ here is $1/q$.
Put differently, we're applying this to $\left(1-\frac{1}{q}\right)^k \ge 1 - \frac{k}{q}\Leftrightarrow - \left(1-\frac{1}{q}\right)^k \le -\left(1-\frac{k}{q}\right)$.

For cryptographic $q$ (e.g., $q \approx 2^{256}$) and any reasonable $k$, this is negligibly small.

## References

For cited works, see below 👇👇

{% include refs.md %}
