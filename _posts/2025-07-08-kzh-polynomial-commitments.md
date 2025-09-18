---
tags:
 - KZG
 - Hyrax
 - KZH
 - polynomial commitments
 - tensors
title: KZH polynomial commitments
#date: 2020-11-05 20:45:59
#published: false
permalink: kzh
# TODO: uncomment
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** KZG + [Hyrax](/hyrax) = KZH[^KZHB25e]. This name makes me happy: not only it stands on its own but it also coincides with the first three authors' initials!

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\ipa{\mathsf{IPA}}
\def\kzh#1{\mathsf{KZH}_{#1}}   <!-- _ _ $____ -->
\def\kzhTwo{\kzh{2}}
\def\kzhK{\kzh{k}}
\def\kzhLogN{\kzh{\log{n}}}
\def\kzhTwoGen{\kzhTwo^{n, m}}
\def\kzhTwoSqr{\kzhTwo^{\sqrt{N}}}
\def\kzhSetup#1{\kzh{#1}.\mathsf{Setup}}
\def\kzhOpen#1{\kzh{#1}.\mathsf{Open}}
\def\tobin#1{\langle #1 \rangle}
\def\vect#1{\boldsymbol{#1}}
\def\b{\vect{b}}
\def\btau{\vect{\tau}}
\def\G{\vect{G}}
\def\A{\vect{A}}
\def\V{\widetilde{V}}
\def\Vp{\V'}
\def\VV{\widetilde{\vect{V}}}
\def\H{\mat{H}}
\def\ok{\mathsf{ok}}
\def\crs#1{\textcolor{green}{#1}}
%\def\?{\vect{?}}
% - Let $\tobin{i}_s$ denote the $s$-bit binary representation of $i$
$</div> <!-- $_ -->

{% include pairings.md %}
{% include mle.md %}
{% include time-complexities.md %}

## Preliminaries

### Notation

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
 - For any size-$\ell$ vector $\b$, and $k\in[\ell)$, we let $\b_{[k:]}\bydef (b_k, b_{k+1},\ldots,b_{\ell-1})$ denote the size $\ell-k$ suffix of $\b$.
    + Similary, we let $\b_{[:k]}\bydef (b_0, \ldots, b_k)$ denote the size $k$ prefix of $\b$.
 - $(v_0, v_2, \ldots, v_{n-1})^\top$ denotes the transpose of a row vector
 - We typically use bolded variables to indicate vectors and matrices
    - e.g., a matrix $\mat{A}$ consists of rows $\mat{A}\_i,\forall i\in[n)$, where each row $\mat{A}\_i$ consists of entries $A_{i,j},\forall j\in[m)$
    - e.g., vectors $\A$ are typically italicized while matrices $\mat{M}$ are not
 - We use $\vect{a}\cdot G\bydef (a_0\cdot G,a_1\cdot G,\ldots, a_{n-1}\cdot G)$
 - We use $a\cdot \G\bydef (a\cdot G_0,a\cdot G_1,\ldots, a\cdot G_{n-1})$
 - We use $\vect{a}\cdot \G \bydef \sum_{i\in[n)} a_i\cdot G_i$
 - Recall the definition of $\eq(\boldsymbol{b};\x)$ Lagrange polynomials from [here](/spartan#mathsfeqmathbfxmathbfb-lagrange-polynomials)
{% include time-complexities-prelims-pairings.md %}
 - It is useful to understand [Hyrax](/hyrax), which KZH is highly-related to.

<!-- ## Overview

TODO: add; will be very similar to hyrax
TODO: explain that the \sqrt{N} comitments can be "pre-verified" ahead of time (may be useful for Spartan?)
TODO: rewrite eq() polys as \vec{a} and \vec{b}

-->

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
Compute the **full commitment** to $f$ (via a single $\msm{N}\_1$):
\begin{align}
\term{C} 
    \gets \sum_{i \in [n)} \sum_{j\in [m)} f(\i, \j)\cdot H_{i,j}
    \bydef \emph{\sum_{i\in [n)} \vec{f_i} \cdot \mat{H}_i} \in \Gr_1
\end{align}

Compute the $n$ **row commitments** of $f$ (via $n$ $\msm{m}\_1$):
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
&\bydef \sum_{i\in[n)} \eq(\i; \x) f(\i,\Y)
\end{align}
<!--Evaluate $f(\x,\y)$:
\begin{align}
\term{z}\gets f_\x(\y) \bydef f(\x,\y)
\end{align}-->

Return the proof[^open]:
 - $\pi \gets (f_\x, \aux) \in \F^m \times \Gr_1^n$

### Opening time

When $\x\in\bin^\nu$ and $\y\in{\bin^\mu}$, the step above involves **zero work**:  $f_\x(\Y)$ is just the $x$th column in the matrix encoded by $f$.
Furthermore, $z=f(\x,\y)$ is simply the entry at location $(x,y)$ in the matrix.

When $\x$ is an arbitrary, point, computing all the $\eq(\i;\x)$'s requires $\Fmul{2n}$ (see [here](/mle#computing-all-lagrange-evaluations-fast)).
Then, assuming a Lagrange-basis representation for all $f(\i,\Y)$ rows, combining them together as per Eq. \ref{eq:fxY} will require (1) $\Fmul{m}$ for each row $i$ to multiply $\eq(\i;\x)$ by $f(\i,\Y)$ and (2) $\Fadd{(n-1)m}$ to add all multiplied rows together.
So, $\Fmul{n(m + 2)} + \Fadd{(n-1)m}$ in total.

### $\mathsf{KZH}_2.\mathsf{Verify}(\mathsf{vk}, C, (\boldsymbol{x}, \boldsymbol{y}), z; \pi)\rightarrow \\{0,1\\}$

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
e(C, \Vp) \equals \sum_{i\in[n)} e(D_i, \V_i)\Leftrightarrow\\\\\
\end{align}

{: .note}
This step is agnostic of the evaluation claim $f(\x,\y)\equals z$ and, in some settings, could be memoized (e.g., when verifying multiple proofs for the same commitment $C$).

Check the proof:
\begin{align}
\label{eq:kzh2-verify-aux}
\sum_{j\in[m)} f_\x(\j) \cdot A_j \equals \sum_{i\in[n)}\eq(\i;\x) \cdot D_i\Leftrightarrow
\end{align}

Check $z$ against the partially-evaluated $f_\x$:
\begin{align}
z\equals f_\x(\y) 
\end{align}

### Verification time

Assuming $f_\x$ is received in Lagrange basis, computing all $f_\x(\j)$ is just fetching entries.
Therefore, the LHS of the auxiliary check from Eq. \ref{eq:kzh2-verify-aux} **always** involves an $\msm{m}\_1$.

When $(\x,\y)$ are on the hypercube (1) the RHS is a single $\Gr_1$ scalar multiplication which can be absorbed into the MSM on the LHS and (2) the last check on $z$ involves simply fetching the $y$th entry in $f_\x$.

When $(\x,\y)$ are arbitrary, the RHS involves $\Fmul{2n}$ to evaluate all $\eq(\i;\x)$ Lagrange polynomials (see [here](/mle#computing-all-lagrange-evaluations-fast)) and then an $\msm{n}\_1$ which can be absorbed into the LHS.

The final check involves evaluating the $f_\x$ MLE at an arbitrary $\y$.
This involves evaluating all $\eq(\j;\y)$ Lagrange polynomials in $\Fmul{2m}$ time and then taking a dot product in $\Fmul{m} + \Fadd{m}$ time.

### Correctness

The first check is correct because:
\begin{align}
e(C, \Vp) &\equals \sum_{i\in[n)} e(D_i, \V_i)\Leftrightarrow\\\\\
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
\sum_{j\in[m)} f_\x(\j) \cdot A_j &\equals \sum_{i\in[n)}\eq(\i;\x) \cdot D_i\Leftrightarrow\\\\\
\alpha \sum_{j\in[m)} f(\x, \j) \cdot G_j &\equals \sum_{i\in[n)}\eq(\i;\x) \cdot \left( \sum_{j\in [m)} f(\i,\j) \cdot A_j \right)\Leftrightarrow\\\\\
\alpha \sum_{j\in[m)} \sum_{i\in[n)} \eq(\i;\x) f(\i, \j) \cdot G_j &\equals \sum_{i\in[n)}\eq(\i;\x) \cdot \alpha \left( \sum_{j\in [m)} f(\i,\j) \cdot G_j \right)\Leftrightarrow\\\\\
\alpha \sum_{i\in[n)} \sum_{j\in[m)} \eq(\i;\x) f(\i, \j) \cdot G_j &\equals \alpha \sum_{i\in[n)}\eq(\i;\x) \cdot \left( \sum_{j\in [m)} f(\i,\j) \cdot G_j \right)\Leftrightarrow\\\\\
\alpha \sum_{i\in[n)} \sum_{j\in[m)} \eq(\i;\x) f(\i, \j) \cdot G_j &\goddamnequals \alpha \sum_{i\in[n)} \sum_{j\in [m)} \eq(\i;\x) f(\i,\j) \cdot G_j
\end{align}

### Efficient instantiation

Typically, when commiting to a size-$N$ MLE, the scheme is most-efficiently set up with $n = m = \sqrt{N} = 2^s$ via $\kzhSetup{2}(1^\lambda, s, s)$.
(Assuming $\sqrt{N}$ is a power of two, for simplicity here; otherwise, must pad.)

### Performance

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\read#1{\mathsf{read}\left(#1\right)}
\def\sqN{\sqrt{N}}
$</div> <!-- $ -->

{: .todo}
Include vanilla $\kzhK(d)$, explaining eval proofs for hypercube and for non-hypercube points and how $\kzh{\log_2{N}}$ yields $2\log_2{N}$-sized proofs.
Include the optimized variant of $\kzhK(d)$.

We use $\kzhTwo^{n,m}$ to refer to the $\kzhTwo$ scheme set up with [$\kzhSetup{2}(1^\lambda, \log_2{n},\log_2{m})$](#mathsfkzh_2mathsfsetup1lambda-numu-rightarrow-mathsfvkmathsfck)
We use $\kzhTwoSqr$ to refer to $\kzhTwo^{\sqN,\sqN}$.

Setup, commitments and proof sizes:

|--------------+-------+-------+-------------+-----+--------+-------|
| Scheme       | $\ck$ | $\vk$ | Commit time | $C$ | $\aux$ | $\pi$ |
|--------------|-------|-------|-------------|-----+--------|-------|
| $\kzhTwoGen$ | $\Gr_2^{n+1}, \Gr_1^{m+nm}     $ | $\Gr_2^{n+1}, \Gr_1^m$           | $\msm{nm}_1 + n\cdot\msm{m}_1$      | $\Gr_1$ | $\Gr_1^n$    | $\F^m, \Gr_1^n$ |
|--------------+-------+-------+-------------|-----|--------|-------|
| $\kzhTwoSqr$ | $\Gr_2^{\sqN+1}, \Gr_1^{N+\sqN}$ | $\Gr_2^{\sqN+1}\times\Gr_1^\sqN$ | $\msm{N}_1 + \sqN\cdot\msm{\sqN}_1$ | $\Gr_1$ | $\Gr_1^\sqN$ | $\F^\sqN, \Gr_1^\sqN$ |
|--------------+-------+-------+-------------|-----|--------|-------|

Openings at arbitry points:

|----------------+--------------------+---------------|
| Scheme         | Open time (random) | Verifier time |
|----------------|--------------------|---------------|
| $\kzhTwoGen$   | $\Fmul{nm} + \Fadd{nm} + \read{\aux}$             | $\multipair{n+1} + \msm{m+n}_1 + \Fmul{(2n+3m)} + \Fadd{m}$ |
|----------------|--------------------|---------------|
| $\kzhTwoSqr$   | $\Fmul{N} + \Fadd{N} + \read{\aux}$               | $\multipair{\sqN+1} + \msm{2\sqN}_1 + \Fmul{5\sqN} + \Fadd{\sqN}$ |
|----------------+--------------------+---------------|

Openings at points on the hypercube:

|----------------+-----------------------+---------------|
| Scheme         | Open time (hypercube) | Verifier time |
|----------------|-----------------------|---------------|
| $\kzhTwoGen$   | $\read{\aux}$         | $\multipair{n+1} + \msm{m+1}_1$       | 
|----------------|-----------------------|---------------|
| $\kzhTwoSqr$   | $\read{\aux}$         | $\multipair{\sqN+1} + \msm{\sqN+1}_1$ | 
|----------------+-----------------------+---------------|


{: .warning}
For "Open time (random)" the time should technically have $\Fmul{n(m+2)} + \Fadd{(n-1)m}$ instead, but it's peanuts, so ignoring.

## $\mathsf{KZH}_{\log{n}}$ construction

The KZH paper[^KZHB25e] describes a family $\kzhK$ of commitment schemes for $k$-dimensional tensors and thus for multilinear extension (MLE) polynomials.
In this section, we (more clearly?) re-describe the $k = \log{n}$ instantiation of this family, which can be used to commit to any MLE $f(\X)\in \MLE{\ell}$ representing a vector of $\term{n} \bydef 2^\ell$ entries.

{: .todo}
Check this against notes from Arantxa!

### $\mathsf{KZH}_{\log{n}}.\mathsf{Setup}(1^\lambda, n) \rightarrow (\mathsf{vk},\mathsf{ck},\mathsf{ok})$

Notation:
 - $\ell \bydef \log{n}$, where $n$ denotes the total # of entries in the MLE
 - We assume $\one{1}$ and $\two{1}$ have been randomly picked and fixed globally.

{: .warning}
Currently, we assume $\ell \ge 2$ and $\ell$ is even.

Pick trapdoor:
\begin{align}
\term{\btau}\randget\F^\ell
\end{align}

Compute the public parameters.
\begin{align}
\ck 
    &\gets 
    \begin{pmatrix}
        \eq(i\_0, \ldots, i\_{\ell-1}; \tau\_0,\ldots,\tau\_{\ell-1})\_{i_0,\ldots,i\_{\ell-1}\in\\{0,1\\}}\\\\\
        \eq(i\_1, \ldots, i\_{\ell-1}; \tau\_1,\ldots,\tau\_{\ell-1})\_{i\_1,\ldots,i\_{\ell-1}\in\\{0,1\\}}\\\\\
        \vdots\\\\\
        \eq(i\_{\ell-2}, i\_{\ell-1}; \tau\_{\ell-2},\tau\_{\ell-1})\_{i\_{\ell-2},i\_{\ell-1}\in\\{0,1\\}}\\\\\
        \eq(i\_{\ell-1};\tau\_{\ell-1})\_{i\_{\ell-1}\in\\{0,1\\}}\\\\\
    \end{pmatrix}
    \bydef\left(\crs{\one{\eq(\i\_{[k:]};\btau\_{[k:]})}}\right)\_{k\in[\ell), \i_{[k:]}\in\bin^{\ell-k}}
    \\\\\
\vk &\gets \left(\crs{\two{\tau\_0}},\crs{\two{\tau\_1}},\ldots,\crs{\two{\tau\_{\ell-1}}}\right)\bydef \crs{\two{\btau}}\\\\\
\ok &\gets \textbf{TODO}\\\\\
\end{align}

{: .note}
Recall our [$\b_{[k:]}$ notation](#notation) for the size-$(\ell-k)$ suffix of $\b$ starting at $b_k$ and inclusively-ending at $b_{\ell-1}$.
We distinguish public parameters from other group elements by highlighting them in $\crs{\text{green}}$

### Public parameter sizes

For the commitment key $\ck$:
 - There are $2^\ell + 2^{\ell-1} + \ldots + 2^1 = 2^{\ell+1} - 2 = \emph{2n - 2}$ possible $\crs{\one{\eq(\i\_{[k:]};\btau\_{[k:]})}}$ commitments $\Rightarrow \|\ck\| = 2n-2$ $\Gr_1$.
 - $\|\vk\| = \log{n}$ $\Gr_2$
 - **TODO:** $\|\ok\| = ?$

### $\mathsf{KZH}_{\log{n}}.\mathsf{Commit}(\mathsf{ck}, f(\boldsymbol{X})) \rightarrow (C, \mathsf{aux})$

Parse the commitment key:
\begin{align}
\left(\crs{\one{\eq(\i; \btau)}}\right)_{i\in[n)},\ldots \parse \ck
\end{align}

Commit to the polynomial:
\begin{align}
C\gets \sum_{i\in[n)} f(\i)\cdot \crs{\one{\eq(\i;\tau)}}
\end{align}

Compute the auxiliary data:
\begin{align}
\aux
    \label{eq:kzh-logn-aux}
    \gets\begin{pmatrix}
        f(i_0, \tau\_1,\tau\_2,\ldots,\tau\_{\ell-1})\_{i_0\in\\{0,1\\}}\\\\\
        f(i_0, i_1, \tau\_1,\ldots,\tau\_{\ell-1})\_{i_0,i_1\in\\{0,1\\}}\\\\\
        \vdots\\\\\
        f(i\_0,\ldots, i\_{\ell/2-1}, \tau\_{\ell/2},\ldots,\tau\_{\ell-1})\_{i\_0,\ldots,i\_{\ell/2-1}\in\\{0,1\\}}\\\\\
    \end{pmatrix}
    \bydef \left(\one{f(\i_{[:k]},\btau_{[k+1:]})}\right)\_{k\in[\ell/2), \i\_{[:k]}\in\bin^k}
\end{align}

{: .note}
Recall our [$\b_{[:k]}$ notation](#notation) for the size-$(k+1)$ prefix of $\b$ starting at $b_0$ and inclusively-ending at $b_k$.

{: .todo}
Since we are going up to $i_{\ell / 2 - 1}$, we are implicitly assuming $\ell$ is even and $\ge 2$. I guess we could either floor or ceil?

{: .todo}
The auxiliary data contains commitments to the left half, right half, left-left half, and so on, sub-MLEs / sub-vectors of size up to $\ell/2$.
Can depict it more intuitively via a tree.

### Auxiliary data size

For each $k\in[\ell/2)$, there are $2^{k+1}$ choices for $\i_{[:k]}$. Thus, $\|\aux\| =$ $2^1 + 2^2 + \ldots + 2^{(\ell/2 - 1) + 1} =$ $2^1 + \ldots + 2^{\ell/2} = 2^{\ell/2 + 1} - 2 = \emph{2\sqrt{n} - 2}$.

### Commit time

1. A size-$n$ fixed-base MSM in $\Gr_1$ to compute $C$
2. Several MSMs for computing the sub-MLE commitments:
    - 2 size-$n/2$ MSMs for the 1st row in Eq. \ref{eq:kzh-logn-aux}
    - 4 size-$n/4$ MSMs for the 2nd row
    - $\ldots$
    - $2^{\ell/2}$ size-$n/2^{\ell/2}$ MSMs for the last row = $\sqrt{n}$ size-$\sqrt{n}$ MSMs 
<!-- Note: Doing MSMs for the smallest sub-MLE commitments + combine these into larger ones does not work: e.g., good luck combining a size-2 MLE commitment like 4\tau_1 + 5(1-\tau_1) with another one into a size-4 MLE commitment. It would require multiplyin by \tau in the exponent -->

{: .todo}
Use notation for MSM sizes in different groups.

### $\mathsf{KZH}_{\log{n}}.\mathsf{Open}(\mathsf{ok}, f(\boldsymbol{X}), \boldsymbol{x}, y; \mathsf{aux})\rightarrow \pi$

First, compute the initial commitments:
\begin{align}
\term{C_{0, b}} &= \one{f(b, \tau_1, \ldots, \tau_{\ell-1})} \bydef \one{f(0, \btau_{[1:]})}, b\in\bin\\\\\
\end{align}

For $k\in[1, \ell-1)$, compute commitments:
<!--for all $i_k\in\bin$, compute:-->
\begin{align}
\term{C_{k, b}} &= \one{f(x_0,\ldots,x_{k-1}, b, \tau_{k+1}, \ldots, \tau_{\ell-1})} \bydef \one{f(\x_{[:k-1]}, 0, \btau_{[k+1:]})},b\in\bin\\\\\
\end{align}

{: .note}
The extreme cases are $\emph{C_{1, b}} = \one{f(x_0, b, \tau_2, \ldots, \tau_{\ell-1})}$ and $\emph{C_{\ell-2,b}} = \one{f(x_0, \ldots x_{\ell-3}, b, \tau_{\ell-1})}$. 

Lastly, partially-evaluate:
\begin{align}
f(x_0, x_1,\ldots,x_{\ell-2}, X_{\ell-1}) \bydef \term{t_1} \cdot X_{\ell-1} + \term{t_0} 
\end{align}
Return the proof:
\begin{align}
\pi\gets \left(\left(C_{k, b}\right)_{k\in[\ell-1),b\in\bin}, t_0, t_1\right)
\end{align}

### Opening time

{: .todo}
Describe algorithm to compute commitments and to partially-evaluate! Then, figure out what $\ok$ needs to be.

### Proof size

 - $2(\ell-1)$ $\Gr_1$ elements
 - $2$ $\F$ elements

### $\mathsf{KZH}_{\log{n}}.\mathsf{Verify}(\mathsf{vk}, C, \boldsymbol{x}, y; \pi)\rightarrow \\{0,1\\}$

Parse the proof:
\begin{align}
\left(\left(C_{k, b}\right)_{k\in[\ell-1),b\in\bin}, t_0, t_1\right)\parse \pi
\end{align}

First, verify the initial commitments:
\begin{align}
\term{C_0}\gets C
\end{align}

For $k\in[\ell-1)$, verify the commitments:
\begin{align}
\pair{\emph{C_k}}{\two{1}} &\equals \pair{C_{k, 0}}{\two{1 - \tau_k}} + \pair{C_{k,1}}{\two{\tau_k}}\\\\\
\term{C_{k+1}} &\gets (1-x_k)\cdot C_{k,0} + x_k \cdot C_{k,1}
\end{align}

Can be rewritten as:
\begin{align}
\pair{\emph{C_k}}{\two{1}} &\equals \pair{C_{k, 0}}{\two{1}} + \pair{-C_{k,0}}{\two{\tau_k}} + \pair{C_{k,1}}{\two{\tau_k}}\\\\\
\pair{C_k - C_{k,0}}{\two{1}} &\equals \pair{C_{k,1}-C_{k,0}}{\two{\tau_k}}\\\\\
\end{align}
This means that, with a random linear combination, we can turn the bulk of the verification work into a $(\log{n}+1)$-sized multipairing.
{: .note}

Lastly, verify the partial evaluation:
\begin{align}
C_{\ell-1} &\equals t_1 \cdot \one{\tau_k} + t_0\cdot\one{1} = \one{t_1\cdot \tau_k + t_0}
\end{align}

### Verification time

_Naively_:

 - $\ell-1$ size-3 multipairing (to verify the $C_{k,b}$'s)
 - $\ell-1$ size-2 $\Gr_1$ MSMs (to compute the $C_k$'s)
 - a size-2 $\Gr_1$ MSM (to verify the $(t_1,t_0)$ polynomial)

**Faster** (pick random $\term{\alpha_k}$'s and combine the pairing checks):
\begin{align}
\pair{\sum_{k\in[\ell-1)} \emph{\alpha_k} \cdot C_k}{\two{1}} &\equals \sum_{k\in[\ell-1)} \left(\pair{\emph{\alpha_k} \cdot C_{k, 0}}{\two{1 - \tau_k}} + \pair{\emph{\alpha_k} \cdot C_{k,1}}{\two{\tau_k}}\right)\Leftrightarrow\\\\\
\end{align}
\begin{align\*}
\Leftrightarrow\pair{\sum_{k\in[\ell-1)} \left(\alpha_k (1-x_{k-1}) \cdot C_{k-1,0} + \alpha_k x_{k-1} \cdot C_{k-1,1}\right)}{\two{1}} &\equals \sum_{k\in[\ell-1)} \left(\pair{\alpha_k \cdot C_{k, 0}}{\two{1 - \tau_k}} + \pair{\alpha_k \cdot C_{k,1}}{\two{\tau_k}}\right)
\end{align\*}

This takes:
 - $2\ell-2$ $\Gr_1$ scalar multiplications (for $\alpha_k \cdot C_{k,0}$ and $\alpha_k\cdot C_{k,1}$)
 - a size-$(2\ell-1)$ multipairing
 - a size-$(2\ell-2)$ $\Gr_1$ MSM (for the $\Gr_1$ input of the pairing on the left-hand side)
 - a size-2 $\Gr_1$ MSM (as before: to verify the $(t_1,t_0)$ polynomial)

## References

For cited works, see below 👇👇

{% include refs.md %}

[^ck]: We are excluding the $\Vp$ and $\VV$ components from $\kzhTwo$'s $\ck$ because are not actually needed to create a commitment.
[^N]: In the KZH paper[^KZHB25e], the setup algorithm only takes $N$ as input (but they confusingly denote it by $k$?)
[^open]: In the KZH paper[^KZHB25e], the evaluation $z$ is also included in the proof, but this is unnecessary. Furthermore, the paper's opening algorithm unnecessarily includes the proving key $\ck$ as a a parameter, even thought it does **not** use it at all.
