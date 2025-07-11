---
tags:
 - kzg
 - hyrax
 - kzh
 - polynomial commitments
 - tensors
title: KZH polynomial commitments
#date: 2020-11-05 20:45:59
#published: false
permalink: kzh
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** KZG + Hyrax[^WTSplus18] = KZH[^KZHB25e]. This name makes me happy: not only it stands on its own but it also coincides with the first three authors' initials!

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\ipa{\mathsf{IPA}}
\def\hyrax{\mathsf{Hyrax}}
\def\kzh#1{\mathsf{KZH}_{#1}}
\def\kzhTwo{\kzh{2}}
\def\kzhK{\kzh{k}}
\def\kzhTwoGen{\kzhTwo^{n, m}}
\def\kzhTwoSqr{\kzhTwo^{\sqrt{N},\sqrt{N}}}
\def\kzhSetup#1{\kzh{#1}.\mathsf{Setup}}
\def\kzhOpen#1{\kzh{#1}.\mathsf{Open}}
\def\tobin#1{\langle #1 \rangle}
\def\vect#1{\boldsymbol{#1}}
\def\btau{\vect{\tau}}
\def\prk{\mathsf{prk}}
\def\ck{\mathsf{ck}}
\def\G{\vect{G}}
\def\A{\vect{A}}
\def\V{\widetilde{V}}
\def\Vp{\V'}
\def\VV{\widetilde{\vect{V}}}
\def\H{\mat{H}}
%\def\msm#1#2{#1\text{-}\vec{\gr}_{#2}^\times}
\def\msm#1#2{\mathsf{msm}_{#2}^{#1}}
\def\Fmul#1{#1\ \F^\times}
\def\Gadd#1#2{#1\ \Gr_{#2}^+}
\def\Gmul#1#2{#1\ \Gr_{#2}^\times}
\def\Fadd#1{#1\ \F^+}
\def\pair{\mathbb{P}}
\def\multipair#1{\mathbb{P}^{#1}}
%\def\?{\vect{?}}
% - Let $\tobin{i}_s$ denote the $s$-bit binary representation of $i$
$</div> <!-- $ -->

{% include mle.md %}

## Preliminaries

 - $[m]=\\{1,2,3,\ldots,m\\}$
 - $[m)=\\{0,1,2,\ldots,m-1\\}$
 - $\bin^s$ denotes the boolean hypercube of size $2^s$.
 - Let $\F$ denote a finite field of prime order $p$
 - Let $\Gr_1,\Gr_2,\Gr_T$ denote cyclic groups of prime order $p$ with a bilinear map $e : \Gr_1\times\Gr_2\rightarrow\Gr_T$ where computing discrete logs is hard
    + We use additive group notation
 - Denote $\MLE{s}$ as the space of all multilinear extensions (MLEs) $f(X_1,\ldots,X_s)$ of size $2^s$ with entries in $\F$
    - We also use $\MLE{s_1,s_2,\ldots,s_\ell} \bydef \MLE{\sum_{i\in[\ell]} s_i}$ 
 - Denote $i$'s binary representation as $\vect{i} = (i_0, i_1, \ldots, i_{s-1})\in \bin^s$, s.t. $i=\sum_{k=0}^{s-1} 2^k \cdot i_k$
    - We often naturally interchange between these two, when it is clear from context
 - $(v_0, v_2, \ldots, v_{n-1})^\top$ denotes the transpose of a row vector
 - We typically use bolded variables to indicate vectors and matrices
    - e.g., a matrix $\mat{A}$ consists of rows $\mat{A}\_i,\forall i\in[n)$, where each row $\mat{A}\_i$ consists of entries $A_{i,j},\forall j\in[m)$
    - e.g., vectors $\A$ are typically italicized while matrices $\mat{M}$ are not
 - We use $\vect{a}\cdot G\bydef (a_0\cdot G,a_1\cdot G,\ldots, a_{n-1}\cdot G)$
 - We use $a\cdot \G\bydef (a\cdot G_0,a\cdot G_1,\ldots, a\cdot G_{n-1})$
 - We use $\vect{a}\cdot \G \bydef \sum_{i\in[n)} a_i\cdot G_i$
 - Recall the definition of $\eq(\x,\boldsymbol{b})$ Lagrange polynomials from [here](/spartan#mathsfeqmathbfxmathbfb-lagrange-polynomials)
 - For time complexities, we use:
    + $\Fadd{n}$ for $n$ field additions.
    + $\Fmul{n}$ for $n$ field multiplications in $\F$
    + $\msm{n}{b}$ for a single multi-scalar multiplication (MSM) in $\Gr_b$ of size $n$
    - $\Gadd{n}{b}$ for $n$ additions in $\Gr_b$
    - $\Gmul{n}{b}$ for $n$ individual scalar multiplications in $\Gr_b$
    + $\multipair{n}$ for a multipairing of size $n$ and $\pair$ for one pairing

## Hyrax overview

The main idea in Hyrax is that, for a **row** vector $\term{a}\in\F^{1\times n}$, a **column** vector $\term{b}^\top \in \F^m$ and a matrix $\term{\mat{A}}\in \F^{n\times m}$, you can express a dot product as:
\begin{align}
    \label{eq:hyrax}
    \sum_{i\in[n)} \sum_{j\in[m)} a_i \cdot M_{i,j} \cdot b_j
    = 
    \vec{a}\cdot \mat{M}\cdot \vec{b}^\top
    &\bydef
    \underbrace{\vec{a}}\_{\in\F^{1\times n}}
    \cdot \underbrace{\begin{bmatrix}
        \mat{M}\_0 \cdot \vec{b}^\top\\\\\
        \mat{M}\_1 \cdot \vec{b}^\top\\\\\
        \vdots &\\\\\
        \mat{M}\_{n-1} \cdot \vec{b}^\top\\\\\
    \end{bmatrix}}\_{\in \F^n}\\\\\
    %\label{eq:hyrax-rows}
    &\bydef
    \underbrace{\begin{bmatrix}
        %\| & \| & & \|\\\\\
        \vec{a} \cdot \mat{M}\_0^\top &
        \vec{a} \cdot \mat{M}\_1^\top &
        \cdots &
        \vec{a} \cdot \mat{M}\_{m-1}^\top\\\\\
        %\| & \| & & \|\\\\\
    \label{eq:hyrax-cols}
    \end{bmatrix}}\_{\in\F^{1\times m}}\cdot\underbrace{\vec{b}^\top}\_{\in\F^m}
\end{align}
where $\term{\mat{M}_i}\in\F^{1\times m}$ is the $i$th row in $\mat{M}$ and $\term{\mat{M}^\top_j}\in\F^n$ is the $j$th column.

<details><summary>Why❓ (Click to expand 👇)</summary>
\begin{align}
\vec{a}\cdot \mat{M}\cdot \vec{b}^\top  
    &= \vec{a}\cdot \left( \begin{bmatrix}
           M_{0,0} & M_{0,1} & \ldots & M_{0,m-1}\\\
           M_{1,0} & M_{1,1} & \ldots & M_{1,m-1}\\\
           \vdots & \vdots & \ddots & \vdots \\\
           M_{n-1,0} & M_{n-1,1} & \ldots & M_{n-1,m-1}
       \end{bmatrix}
       \cdot
       \begin{bmatrix} b_0\\\ b_1\\\ \vdots\\\ b_{m-1}\end{bmatrix} \right)\\\
    &= \vec{a}\cdot \begin{bmatrix}
           M_{0,0}\cdot b_0 + M_{0,1}\cdot b_1 + \cdots + M_{0,m-1}\cdot b_{m-1}
           \\\
           M_{1,0}\cdot b_0 + M_{1,1}\cdot b_1 + \cdots + M_{1,m-1}\cdot b_{m-1}
           \\\
           \vdots
           \\\
           M_{n-1,0}\cdot b_0 + M_{n-1,1}\cdot b_1 + \cdots + M_{n-1,m-1}\cdot b_{m-1}
       \end{bmatrix}
       \\\
    &= \begin{bmatrix}a_0 & a_1 & \cdots & a_{n-1}\end{bmatrix} \cdot \begin{bmatrix}
           \sum_{j\in[m)} M_{0,j} \cdot b_j
           \\\
           \sum_{j\in[m)} M_{1,j} \cdot b_j
           \\\
           \vdots
           \\\
           \sum_{j\in[m)} M_{n-1,j} \cdot b_j
       \end{bmatrix}
       \\\
    &=
        \left(a_0 \sum_{j\in[m)} M_{0,j} \cdot b_j\right) +
        \left(a_1 \sum_{j\in[m)} M_{1,j} \cdot b_j\right) +
        \cdots +
        \left(a_{n-1} \sum_{j\in[m)} M_{n-1,j} \cdot b_j\right)\\\
    &\goddamnequals
        \sum_{i\in[n)} \sum_{j\in[m)} a_i \cdot M_{i,j} \cdot b_j
\end{align}
</details>

Hyrax represents an MLE $\term{f(\X,\Y)}\in \MLE{n,m}$ as a matrix $\mat{M}$, where each row $\emph{\mat{M}\_i} \bydef (f(\i,\j))\_{j\in[m)}$.
Put differently, $\term{M_{i,j}}\bydef f(\i,\j)$.

Hyrax commits to $f$ by **individually** committing to the rows $\mat{M}_i$ using a Pedersen vector commitment as:
\begin{align}
    \term{D_i} \gets \mat{M}_i \cdot \term{\G} = \sum\_{j\in[m)} f(\i, \j) \cdot G_j\in \Gr
\end{align}
where $\emph{\G}\in\Gr^m$ is the commitment key.
This yields an $n$-sized commitment.

An opening proof for $z\equals f(\x,\y)$, can be framed through the lens of Eq. \ref{eq:hyrax}:
\begin{align}
z 
    &=\sum_{i\in[n)}\sum_{j\in[m)} \eq(\x, \i) \cdot \eq(\y,\j) \cdot f(\i,\j)\\\\\
    &=\sum_{i\in[n)}\sum_{j\in[m)} \eq(\x, \i) \cdot M_{i,j} \cdot \eq(\y,\j)\\\\\
    &\bydef 
    \sum_{i\in[n)}\sum_{j\in[m)} a_i \cdot M_{i,j} \cdot b_j 
    =\vec{a}\cdot\mat{M}\cdot\vec{b}^\top
\end{align}
where $\vec{a} \bydef (\eq(\x,\i))\_{i\in[n)}$ and $\vec{b} \bydef (\eq(\y, \j))_{j\in[m)}$.

What does an opening proof look like exactly?

First, both the prover and the verifier compute the $\vec{a},\vec{b}$ vectors from $\x$ and $\y$
(in $\Fmul{2n}$ and $\Fmul{2m}$ time, respectively; see [appendix](#computing-all-mathsfeqboldsymbolxboldsymbolis)).

Second, the verifier uses $\vec{a}$ and the $D_i$'s to derive a commitment $\term{C}$ to the vector $\vec{a} \cdot \mat{M} \in \F^{1\times m}$ from Eq. \ref{eq:hyrax-cols}:
\begin{align}
\term{C} \gets \sum_{i\in[n)} a\_i\cdot D\_i 
    &= \sum\_{i\in[n)} a\_i\cdot(\mat{M}\_i\cdot \G)\\\\\
    &= \sum\_{i\in[n)} a\_i\cdot\left(\sum\_{j\in[m)} M\_{i,j} \cdot G\_j\right)\\\\\
    &= \sum\_{i\in[n)}\sum\_{j\in[m)} (a\_i\cdot M\_{i,j}) \cdot G\_j\\\\\
    &= \sum\_{j\in[m)}\left(\sum\_{i\in[n)} (a\_i\cdot M\_{i,j})\right) \cdot G\_j\\\\\
    &= \sum\_{j\in[m)}(\vec{a}\cdot \mat{M}^\top\_j) \cdot G\_j\\\\\
\end{align}
(This can be generalized into a nicer homorphic property of such Pedersen matrix commitments.)

Note that this step costs the verifier an $\msm{\Gr}{n}$.

Third, the prover computes $\vec{a}\cdot \mat{M}$ via $m$ inner-products in $\F$ of size $n$ each (as per Eq. \ref{eq:hyrax-cols}) and gives the verifier an **inner-product argument (IPA)** proof[^BBBplus18] that $z = (\vec{a} \cdot \mat{M})\cdot\vec{b}^\top$.
The verifier checks the IPA proof against (1) the commitment $C$ to $\vec{a}\cdot{\mat{M}}$ and (2) $\vec{b}$.

{: .note}
The prover proves an inner-product of size only $m$!

{: .note}
To commit to MLEs $f\in\MLE{N}$, Hyrax is typically used with $n=m=\sqrt{N}$, yielding sublinear-sized commitments & proofs and sublinear-time verifier.
The prover time will be dominated by the $\sqrt{N}$-sized IPA proof

## $\mathsf{KZH}_2$ construction

This construction can be parameterized to commit to any MLE 
$f(\X,\Y)\in \MLE{\term{\nu},\term{\mu}}$
representing a matrix of $\term{n} = 2^\nu$ rows and $\term{m}=2^\mu$ columns, where
$\X\in \bin^\nu$ indicates the row and $\Y\in\bin^\mu$ indicates the column.

### $\mathsf{KZH}_2.\mathsf{Setup}(1^\lambda, \nu,\mu) \rightarrow (\mathsf{vk},\mathsf{ck})$[^N]

Notation:
 - $n \gets 2^\nu$ denotes the # of matrix rows
 - $m \gets 2^\mu$ denotes the # of matrix columns
 - $N = n\cdot m\bydef 2^{\nu + \mu}$ denotes the total # of entries in the matrix

Pick trapdoors and generators:
 - $\term{\alpha}\randget\F$
 - $\term{\btau} \bydef (\tau_0, \tau_1,\ldots,\tau_{n-1})\randget \F^n$
 - $\term{\G}\bydef(G_0,\ldots, G_{m-1})\randget \Gr_1^m$
 - $\term{\V}\randget \Gr_2$

Compute $\H\in\Gr_1^{n \times m}$:
\begin{align}
H\_{i,j} 
    &\gets \tau\_i \cdot G_j\in \Gr_1
,
\forall i\in[n),j\in[m)
\\\\\
\H\_i
    &\gets \tau_i\cdot \G
    %\\\\\
    \bydef (\tau_i \cdot G_0,\tau_i\cdot G_1,\dots,\tau_i\cdot G_{m-1})\in\Gr_1^m
,
\forall i\in[n)
\\\\\
    %&\bydef (H\_{i,0},\ldots,H_{i,m-1})\\\\\
\term{\H}
    &\bydef \begin{pmatrix}
        \text{ ---} & \H\_0 & \text{--- }\\\\\ 
        \text{ ---} & \H\_1 & \text{--- }\\\\\ 
         & \vdots & \\\\\
        \text{ ---} & \H\_{n-1} & \text{--- }\\\\\
    \end{pmatrix}
    %\\\\\
    \bydef \begin{pmatrix}
        \text{ ---} & \tau_0 \cdot \G & \text{--- }\\\\\
        \text{ ---} & \tau_1\cdot\G & \text{--- }\\\\\
        &\vdots &\\\\\
        \text{ ---} &\tau_{n-1}\cdot\G & \text{--- }\\\\\
    \end{pmatrix}
    %\bydef\begin{pmatrix}
    %    \tau_0 \cdot G_0 &\tau_0 \cdot G_1 &  \dots & \tau_0\cdot G_{m-1}\\\\\
    %    \tau_1 \cdot G_0 &\tau_1 \cdot G_1 & \dots & \tau_1\cdot G_{m-1}\\\\\
    %    \vdots  &   & & \vdots\\\\\
    %    \tau_{n-1} \cdot G_0 & \tau_{n-1}\cdot G_1 & \dots & \tau_{n-1}\cdot G_{m-1}\\\\\
    %\end{pmatrix}
    %\\\\\
    %\bydef \begin{pmatrix}
    %    \| & \| & & \| \\\\\
    %    \btau\cdot G_0 &
    %    \btau\cdot G_1 &
    %    \cdots &
    %    \btau\cdot G_{m-1}\\\\\
    %    \| & \| & & \| \\\\\
    %\end{pmatrix}
\end{align}

Compute $\A\in\Gr_1^m$, $\VV\in\Gr_2^n$ and $\Vp\in\Gr_2$:
\begin{align}
\term{\A}
    &\gets (\alpha\cdot\G)
    %\\\\\
    \bydef (\alpha\cdot G_0, \alpha\cdot G_1,\ldots,\alpha\cdot G_{m-1})\in\Gr_1^m\\\\\
    %&\bydef (A_0,\ldots,A_{m-1})\\\\\
\term{\VV}
    &\gets (\btau\cdot \V)
    %\\\\\
    \bydef (\tau_0\cdot \V, \tau_1\cdot \V,\ldots,\tau_{n-1}\cdot \V)\in\Gr_2^n\\\\\
    %&\bydef (V_0,\ldots,V_{n-1})\\\\\
\term{\Vp}
    &\gets \alpha\cdot \V\in\Gr_2\\\\\
\end{align}

Return the VK and proving key:

 - $\vk\gets (\Vp,\VV,\A)$
 - $\ck\gets (\A, \H)$[^ck]

{: .warning}
Interestingly, the $G_i$'s and $\V$ generators are not needed in the $\ck$ (when proving) nor in the $\vk$ (when verifying), although the KZH paper does include them.
They would indeed be useful when trying to verify correctness of the $\ck$ and $\vk$.

### $\mathsf{KZH}_2.\mathsf{Commit}(\mathsf{ck}, f(\boldsymbol{X},\boldsymbol{Y})) \rightarrow (C, \mathsf{aux})$

Parse the $\ck$ as:
\begin{align}
((\cdot,\cdot, \A), \H) 
    &\parse \ck,\ \text{where:}\\\\\
\A
    &= 
    %(A\_j)\_{j\in[m)} = 
    \alpha\cdot \G
    %=(\alpha\cdot G_j)\_{j\in[m)}
    \\\\\
\H 
    &=
    %(H\_{i,j})\_{i\in[n),j\in[m)} = 
    (\tau\_i \cdot \G)\_{i\in[n)}
\end{align}

Let $\term{\vec{f_i}\bydef(f(\i,\j))\_{\j \in\bin^\mu}}$ denote the $i$th row of the matrix encoded by $f$.
Compute the **full commitment** to $f$ (via a single $\msm{N}{1}$):
\begin{align}
\term{C} 
    \gets \sum_{i \in [n)} \sum_{j\in [m)} f(\i, \j)\cdot H_{i,j}
    \bydef \emph{\sum_{i\in [n)} \vec{f_i} \cdot \mat{H}_i} \in \Gr_1
\end{align}

Compute the $n$ **row commitments** of $f$ (via $n$ $\msm{m}{1}$):
\begin{align}
\term{D_i} 
    \gets \sum_{j\in[m)} f(\i, \j) \cdot A_j
    \bydef \emph{\vec{f_i} \cdot \A}\in\Gr_1
,
\forall i\in[n)
\end{align}

Set the auxiliary info to be these $n$ row commitments:
 - $\term{\aux}\gets (D_i)_{i\in[n)}\in\Gr_1^n$

### $\mathsf{KZH}_2.\mathsf{Open}(f(\boldsymbol{X},\boldsymbol{Y}), (\boldsymbol{x}, \boldsymbol{y}), z; \mathsf{aux})\rightarrow \pi$

Partially-evaluate $f\in \MLE{\nu,\mu}$:
\begin{align}
\term{f_\x(\Y)} &\gets f(\x, \Y) \in \MLE{\mu}
\\\\\
\label{eq:fxY}
&\bydef \sum_{i\in[n)} \eq(\x, \i) f(\i,\Y)
\end{align}
<!--Evaluate $f(\x,\y)$:
\begin{align}
\term{z}\gets f_\x(\y) \bydef f(\x,\y)
\end{align}-->

Return the proof[^open]:
 - $\pi \gets (f_\x, \aux) \in \F^m \times \Gr_1^n$

{: .note}
When $\x\in\bin^\nu$ and $\y\in{\bin^\mu}$, the step above involves **zero work**:  $f_\x(\Y)$ is just the $x$th column in the matrix encoded by $f$.
Furthermore, $z=f(\x,\y)$ is simply the entry at location $(x,y)$ in the matrix.
When $\x$ is an arbitrary, point, computing all the $\eq(\x, \i)$'s requires $\Fmul{2n}$ (see [appendix](#computing-all-mathsfeqboldsymbolxboldsymbolis)).
Then, assuming a Lagrange-basis representation for all $f(\i,\Y)$ rows, combining them together as per Eq. \ref{eq:fxY} will require (1) $\Fmul{m}$ for each row $i$ to multiply $\eq(\x, \i)$ by $f(\i,\Y)$ and (2) $\Fadd{(n-1)m}$ to add all multiplied rows together.
So, $\Fmul{n(m + 2)} + \Fadd{(n-1)m}$ in total.

### $\mathsf{KZH}_2.\mathsf{Verify}(\mathsf{vk}, C, (\boldsymbol{x}, \boldsymbol{y}), z; \pi)\rightarrow (z, \pi)$

Parse the VK and the proof:
\begin{align}
(\Vp,\VV,\A)
    &\parse \vk\\\\\
(f_\x,\aux)
    &\parse\pi\\\\\
(D_i)_{i\in[n)}
    &\parse \aux\\\\\
\end{align}

Check the row commitments are consistent with the full commitment (via a multipairing $\multipair{n+1}$):
\begin{align}
e(C, \Vp) \equals \sum_{i\in[n)} e(D_i, V_i)\Leftrightarrow\\\\\
\end{align}

Check the auxiliary data:
\begin{align}
\label{eq:kzh2-verify-aux}
\sum_{j\in[m)} f_\x(\j) \cdot A_j \equals \sum_{i\in[n)}\eq(\x, \i) \cdot D_i\Leftrightarrow
\end{align}

Check $z$ against the partially-evaluated $f_\x$:
\begin{align}
z\equals f_\x(\y) 
\end{align}

{: .note}
Assuming $f_\x$ is received in Lagrange basis, computing all $f_\x(\j)$ is just fetching entries.
Therefore, the LHS of the auxiliary check from Eq. \ref{eq:kzh2-verify-aux} **always** involves an $\msm{m}{1}$.
When $(\x,\y)$ are on the hypercube (1) the RHS is a single $\Gr_1$ scalar multiplication which can be absorbed into the MSM on the LHS and (2) the last check on $z$ involves simply fetching the $y$th entry in $f_\x$.
When $(\x,\y)$ are arbitrary, the RHS involves $\Fmul{2n}$ to evaluate all $\eq(\x,\i)$ Lagrange polynomials (see [appendix](#computing-all-mathsfeqboldsymbolxboldsymbolis)) and then an $\msm{n}{1}$ which can be absorbed into the LHS.
The final check involves evaluating the $f_\x$ MLE at an arbitrary $\y$.
This involves evaluating all $\eq(\y,\j)$ Lagrange polynomials in $\Fmul{2m}$ time and then taking a dot product in $\Fmul{m} + \Fadd{m}$ time.

#### Correctness

The first check is correct because:
\begin{align}
e(C, \Vp) &\equals \sum_{i\in[n)} e(D_i, V_i)\Leftrightarrow\\\\\
e\left(\sum_{i\in[n)} \vec{f_i} \cdot \mat{H}\_i, \alpha\cdot \V\right) 
    &\equals
\sum_{i\in[n)} e\left(\vec{f_i} \cdot \A, \tau_i \cdot \V\right)
\Leftrightarrow
\\\\\\
\sum_{i\in[n)} e\left(\vec{f_i} \cdot \mat{H}\_i, \alpha\cdot \V\right) 
    &\equals
\sum_{i\in[n)} e\left(\vec{f_i} \cdot \A, \tau_i \cdot \V\right)
\Leftrightarrow
\\\\\\
\sum_{i\in[n)} e\left((\vec{f_i} \cdot \tau_i) \cdot \G, \alpha\cdot \V\right) 
    &\equals
\sum_{i\in[n)} e\left((\vec{f_i} \cdot \alpha)\cdot \G, \tau_i \cdot \V\right)
\Leftrightarrow
\\\\\\
\sum_{i\in[n)} e\left(\vec{f_i} \cdot \G, (\alpha\cdot \tau_i)\cdot \V\right) 
    &\goddamnequals
\sum_{i\in[n)} e\left(\vec{f_i} \cdot \G, (\alpha\cdot \tau_i)\cdot \V\right)
\end{align}

The second check is correct because:
\begin{align}
\sum_{j\in[m)} f_\x(\j) \cdot A_j &\equals \sum_{i\in[n)}\eq(\x, \i) \cdot D_i\Leftrightarrow\\\\\
\alpha \sum_{j\in[m)} f(\x, \j) \cdot G_j &\equals \sum_{i\in[n)}\eq(\x, \i) \cdot \left( \sum_{j\in [m)} f(\i,\j) \cdot A_j \right)\Leftrightarrow\\\\\
\alpha \sum_{j\in[m)} \sum_{i\in[n)} \eq(\x,\i) f(\i, \j) \cdot G_j &\equals \sum_{i\in[n)}\eq(\x, \i) \cdot \alpha \left( \sum_{j\in [m)} f(\i,\j) \cdot G_j \right)\Leftrightarrow\\\\\
\alpha \sum_{i\in[n)} \sum_{i\in[m)} \eq(\x,\i) f(\i, \j) \cdot G_j &\equals \alpha \sum_{i\in[n)}\eq(\x, \i) \cdot \left( \sum_{j\in [m)} f(\i,\j) \cdot G_j \right)\Leftrightarrow\\\\\
\alpha \sum_{i\in[n)} \sum_{i\in[m)} \eq(\x,\i) f(\i, \j) \cdot G_j &\goddamnequals \alpha \sum_{i\in[n)} \sum_{j\in [m)} \eq(\x, \i) f(\i,\j) \cdot G_j
\end{align}

### Efficient instantiation

Typically, when commiting to a size-$N$ MLE, the scheme is most-efficiently set up with $n = m = \sqrt{N} = 2^s$ via $\kzhSetup{2}(1^\lambda, s, s)$.
(Assuming $\sqrt{N}$ is a power of two, for simplicity here; otherwise, must pad.)

## Performance

{: .todo}
Include vanilla $\kzhK(d)$, explaining eval proofs for hypercube and for non-hypercube points and how $\kzh{\log_2{N}}$ yields $2\log_2{N}$-sized proofs.
Include the optimized variant of $\kzhK(d)$.

{: .info}
We use $\kzhTwo(n,m)$ to refer to the $\kzhTwo$ scheme set up with [$\kzhSetup{2}(1^\lambda, \log_2{n},\log_2{m})$](#mathsfkzh_2mathsfsetup1lambda-numu-rightarrow-mathsfvkmathsfck)

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\read#1{\mathsf{read}\left(#1\right)}
\def\sqN{\sqrt{N}}
$</div> <!-- $ -->

Setup, commitments and proof sizes:

|--------------+-------+-------+-------------+-----+--------+-------|
| Scheme       | $\ck$ | $\vk$ | Commit time | $C$ | $\aux$ | $\pi$ |
|--------------|-------|-------|-------------|-----+--------|-------|
| $\hyrax^{n,m}$ | $\Gr^n,\ck_\ipa$               | $\Gr^n,\vk_\ipa$                 | $n\cdot\msm{m}{\Gr}$                  | $\Gr^n$ | $\bot$       | $\pi_\ipa$ |
|--------------+-------+-------+-------------|-----|--------|-------|
| $\kzhTwoGen$ | $\Gr_2^{n+1}, \Gr_1^{m+nm}     $ | $\Gr_2^{n+1}, \Gr_1^m$           | $\msm{nm}{1} + n\cdot\msm{m}{1}$      | $\Gr_1$ | $\Gr_1^n$    | $\F^m, \Gr_1^n$ |
|--------------+-------+-------+-------------|-----|--------|-------|
| $\kzhTwoSqr$ | $\Gr_2^{\sqN+1}, \Gr_1^{N+\sqN}$ | $\Gr_2^{\sqN+1}\times\Gr_1^\sqN$ | $\msm{N}{1} + \sqN\cdot\msm{\sqN}{1}$ | $\Gr_1$ | $\Gr_1^\sqN$ | $\F^\sqN, \Gr_1^\sqN$ |
|--------------+-------+-------+-------------|-----|--------|-------|

Openings at arbitry points:

|----------------+--------------------+---------------|
| Scheme         | Open time (random) | Verifier time |
|----------------|--------------------|---------------|
| $\hyrax^{n,m}$ | $\Fmul{2(n+m)} + \Fmul{nm} + \ipa.\mathcal{P}(m)$ | $\Fmul{2(n+m)} + \msm{n}{\Gr} + \ipa.\mathcal{V}(m)$ |
|----------------|--------------------|---------------|
| $\kzhTwoGen$   | $\Fmul{nm} + \Fadd{nm} + \read{\aux}$             | $\multipair{n+1} + \msm{m+n}{1} + \Fmul{(2n+3m)} + \Fadd{m}$ |
|----------------|--------------------|---------------|
| $\kzhTwoSqr$   | $\Fmul{N} + \Fadd{N} + \read{\aux}$               | $\multipair{\sqN+1} + \msm{2\sqN}{1} + \Fmul{5\sqN} + \Fadd{\sqN}$ |
|----------------+--------------------+---------------|

Openings at points on the hypercube:

|----------------+-----------------------+---------------|
| Scheme         | Open time (hypercube) | Verifier time |
|----------------|-----------------------|---------------|
| $\hyrax^{n,m}$ | $\ipa.\mathcal{P}(m)$ | $\ipa.\mathcal{V}(m)$ |
|----------------|-----------------------|---------------|
| $\kzhTwoGen$   | $\read{\aux}$         | $\multipair{n+1} + \msm{m+1}{1}$       | 
|----------------|-----------------------|---------------|
| $\kzhTwoSqr$   | $\read{\aux}$         | $\multipair{\sqN+1} + \msm{\sqN+1}{1}$ | 
|----------------+-----------------------+---------------|


{: .warning}
For "Open time (random)" the time should technically have $\Fmul{n(m+2)} + \Fadd{(n-1)m}$ instead, but it's peanuts, so ignoring.

## Appendix

### Computing all $\mathsf{eq}(\boldsymbol{x},\boldsymbol{i})$'s

This can be done using a tree-based algorithm.
Here is an example when $\i\in\\{0,1\\}^\ell$ with $\ell = 3$ and $n=2^\ell$:
```
                               1                                 <-- level 0
                         /           \
                      /                 \    
                   /                       \  
                /                             \
           (1 - x_0)                          x_0                <-- level 1
        /             \                 /             \
   (1 - x_1)          x_1          (1 - x_1)          x_1        <-- level 2
    /     \         /     \         /     \         /     \          (4 muls)
(1-x_2)   x_2   (1-x_2)   x_2   (1-x_2)   x_2   (1-x_2)   x_2    <-- level 3
   |       |       |       |       |       |       |       |         (8 muls)
   |       |       |       |       |       |       |       |
eq_0(x) eq_1(x) eq_2(x) eq_3(x) eq_4(x) eq_5(x) eq_6(x) eq_7(x)  <-- results
```

One can see that, given $\x\in\F^\ell$, one needs to:
 - compute all negations $(1-x_k),\forall k\in[\ell)$ in $\ell$ field additions
    + **TODO:** Is the negation here problematic, performance-wise? Can a more efficient basis be used?
 - At every level $k\in[2,\ell]$ in the tree, compute $2^k$ field multiplications

In general, for $n=2^\ell$, the number of field multiplications can be upper bounded by $T(n) = T(n/2) + n = 2n-1$.
But since we are skipping the $2$ multiplications at level 1 and the $1$ multiplication at level 0, it is really:

$$\Fmul{2n-4}$$

e.g., for $n=8$, it is $2 \cdot 8 - 4 = 16 - 4 = 12$

For all intents and purposes, we're gonna use $\Fmul{2n}$.

## References

For cited works, see below 👇👇

{% include refs.md %}

[^ck]: We are excluding the $\Vp$ and $\VV$ components from $\kzhTwo$'s $\ck$ because are not actually needed to create a commitment.
[^N]: In the KZH paper[^KZHB25e], the setup algorithm only takes $N$ as input (but they confusingly denote it by $k$?)
[^open]: In the KZH paper[^KZHB25e], the evaluation $z$ is also included in the proof, but this is unnecessary. Furthermore, the paper's opening algorithm unnecessarily includes the proving key $\ck$ as a a parameter, even thought it does **not** use it at all.
