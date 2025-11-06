---
tags:
 - papers
 - range proofs
 - zero-knowledge proofs (ZKPs)
 - KZG
title: "Draft: DeKART: ZK range proofs from univariate polynomials"
#date: 2020-11-05 20:45:59
permalink: dekart
#published: false
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** We fix up our previous [non-ZK, univariate DeKART](/dekart-not-zk) scheme and also speed up its verifier by trading off prover time.
This is joint work with Dan Boneh, Trisha Datta, Kamilla Nazirkhanova and Rex Fernando.

<!--more-->

{% include pairings.md %}
{% include fiat-shamir.md %}
{% include time-complexities.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\crs#1{\textcolor{green}{#1}}
\def\tauOne{\crs{\one{\tau}}}
\def\tauTwo{\crs{\two{\tau}}}
\def\xiOne{\crs{\one{\xi}}}
\def\xiTwo{\crs{\two{\xi}}}
%
\def\dekart{\mathsf{DeKART}}
\def\dekartUni{\dekart^\mathsf{FFT}}
\def\dekartSetup{\dekart.\mathsf{Setup}}
\def\dekartProve{\dekart.\mathsf{Prove}}
%
\def\bad#1{\textcolor{red}{\text{#1}}}
\def\good#1{\textcolor{green}{\text{#1}}}
%
\def\S{\mathbb{S}}
\def\lagrS{\mathcal{S}}
\def\sOne#1{\crs{\one{\lagrS_{#1}(\tau)}}}
\def\VS{V^*_\S}
\def\vanishSfrac{\frac{X^{n+1} - 1}{X - 1}}
\def\vanishS{(X^{n+1} - 1)/(X - 1)}
%
\def\L{\mathbb{L}}
\def\lagrL{\mathcal{L}}
\def\lOne#1{\crs{\one{\lagrL_{#1}(\tau)}}}
\def\VL{V^*_\L}
\def\vanishL{\frac{X^L - 1}{X - 1}}
%
\def\vkHkzg{\vk_\mathsf{HKZG}}
\def\hkzgSetup{\mathsf{HKZG.Setup}}
\def\hkzgCommit{\mathsf{HKZG.Commit}}
\def\hkzgOpen{\mathsf{HKZG.Open}}
\def\hkzgVerify{\mathsf{HKZG.Verify}}
%
\def\piPok{\pi_\mathsf{PoK}}
\def\zkpokProve{\Sigma_\mathsf{PoK}.\mathsf{Prove}}
\def\zkpokVerify{\Sigma_\mathsf{PoK}.\mathsf{Verify}}
\def\relPok{\mathcal{R}_\mathsf{pok}}
$</div> <!-- $ -->

## Notation

The notation for this blog post is [the same as in the old post](/dekart-not-zk#preliminaries).

{% include pairings-prelims.md %}
{% include time-complexities-prelims-pairings.md %}
- We use $a\fsget S$ to denote sampling from a set $S$ in a deterministic manner using the Fiat-Shamir transcript $\FS$ derived so far

## Preliminary: ZKPoKs

We assume a ZK PoK for the following relation:
\begin{align}
\term{\relPok}(X, X_1, X_2; w_1, w_2) = 1 \Leftrightarrow X = w_1 \cdot X_1 + w_2 \cdot X_2 
\end{align}

{: .todo}
What kind of soundness assumption do we need? Is the 2-special soundness of $\Sigma_\mathsf{PoK}$ enough?

### $\Sigma_\mathsf{PoK}.\mathsf{Prove}(X, X_1, X_2; w_1, w_2)\rightarrow \pi$

**Step 1:** Add $(X, X_1, X_2)$ to the $\FS$ transcript.

**Step 2:** Compute the commitment:
\begin{align}
x_1, x_2 &\randget \F\\\\\
\term{A} &\gets x_1 \cdot X_1 + x_2 \cdot X_2
\end{align}

**Step 3**: Add $A$ to the $\FS$ transcript.

**Step 4:** Derive the challenge pseudo-randomly via Fiat-Shamir:
\begin{align}
\term{e} &\fsget \F
\end{align}

**Step 5:** Compute the response
\begin{align}
\term{\sigma_1} &\gets x_1 - e \cdot w_1\\\\\
\term{\sigma_2} &\gets x_2 - e \cdot w_2
\end{align}

The final proof is:
\begin{align}
    \pi \gets (A, \sigma_1, \sigma_2) \in \Gr\times \F^2
\end{align}

### $\Sigma_\mathsf{PoK}.\mathsf{Verify}(X, X_1, X_2; \pi)$

**Step 0:** Parse the proof as:
\begin{align}
    (A, \sigma_1, \sigma_2) \parse \pi
\end{align}

**Step 1:** Add $(X, X_1, X_2)$ to the $\FS$ transcript.

**Step 2**: Add $A$ to the $\FS$ transcript.

**Step 3:** Derive the challenge pseudo-randomly via Fiat-Shamir:
\begin{align}
\term{e} &\fsget \F
\end{align}

**Step 4**: Add $(\sigma_1,\sigma_2)$ to the $\FS$ transcript.

**Step 5:** Check the proof:
\begin{align}
    \textbf{assert}\ A \equals e\cdot X + \sigma_1 \cdot X_1 + \sigma_2 \cdot X_2
\end{align}

Correctness holds because:
\begin{align}
A &\equals e\cdot X + \sigma_1 \cdot X_1 + \sigma_2 \cdot X_2\Leftrightarrow\\\\\
x_1 X_1 + x_2 X_2 &\equals e\cdot (w_1 X_1 + w_2 X_2) + (x_1 - e w_1) \cdot X_1 + (x_2 - e w_2) \cdot X_2\Leftrightarrow\\\\\
x_1 X_1 + x_2 X_2 &\equals e w_1 X_1 + e w_2 X_2 + x_1 X_1 - e w_1 X_1 + x_2 X_2 - e w_2 X_2\Leftrightarrow\\\\\
x_1 X_1 + x_2 X_2 &\equals x_1 X_1 + x_2 X_2\Leftrightarrow 1 \stackrel{!}{=} 1
\end{align}
{: .note}

## Preliminary: Hiding KZG 

This **hiding** [KZG](/kzg) variant was (first?) introduced in the Zeromorph paper[^KT23e].

### $\mathsf{HKZG.Setup}(m; \mathcal{G}, \xi, \tau) \rightarrow (\mathsf{vk},\mathsf{ck})$

The algorithm is given:
1. a bilinear group $\term{\mathcal{G}}$ with generators $\one{1},\two{1},\three{1}$ and associated field $\F$, as explained in the [preliminaries](#preliminaries) 
2. random trapdoors $\term{\xi,\tau}\in \F$

Pick an $m$th root of unity $\term{\theta}$ and let:
\begin{align}
    \term{\mathbb{H}} &\bydef \\{\theta^0, \theta^1, \ldots, \theta^{m-1}\\}\\\\\
    \term{\ell_i(X)} &\bydef \prod_{j\in\mathbb{H}, j\ne i} \frac{X - \theta^j}{\theta^i - \theta^j}
\end{align}

Return the public parameters:
\begin{align}
    \vk &\gets (\xiTwo, \tauTwo)\\\\\
    \ck &\gets (\xiOne, \tauOne, (\crs{\one{\ell_i(\tau)}})_{i\in[m)})
\end{align}

_Note:_ We assume that the bilinear group $\mathcal{G}$ is implicitly part of the VK and CK above.

### $\mathsf{HKZG.Commit}(\mathsf{ck}, f; \rho) \rightarrow C$

Parse the commitment key:
\begin{align}
    \left(\xiOne, \cdot, \left(\crs{\one{\ell_i(\tau)}}\right)\_{i\in[m)}\right) \parse\ck
\end{align}

Commit to $f$, but additively blind by $\rho\cdot \xiOne$:
\begin{align}
C 
    &\gets  \rho \cdot \xiOne + \sum_{i\in[m)} f(\theta^i) \cdot \crs{\one{\ell_i(\tau)}}\\\\\
    &\bydef \rho \cdot \xiOne + \one{f(\tau)} 
\end{align}

### $\mathsf{HKZG.Open}(\mathsf{ck}, f, \rho, x; s) \rightarrow \pi$

Parse the commitment key:
\begin{align}
    \left(\xiOne, \tauOne, \left(\crs{\one{\ell_i(\tau)}}\right)\_{i\in[m)}\right) \parse\ck
\end{align}

Assuming $x\notin\mathbb{H}$, commit to a blinded quotient polynomial:
\begin{align}
\label{eq:kzg-pi-1}
\pi_1 &\leftarrow s \cdot \xiOne + \sum_{i \in [m)} \frac{f(\theta^i) - f(x)}{\theta^i - x} \cdot \crs{\one{\ell_i(\tau)}}\\\\\
    &\bydef s \cdot \xiOne + \one{\frac{f(\tau) - f(x)}{\tau - x}}\\\\\
\label{eq:kzg-pi-2}
    &\bydef \hkzgCommit\left(\ck, \frac{f(X) - f(x)}{(X - x)}; s\right)
\end{align}

{: .note}
When $x\notin \mathbb{H}$, we can evaluate $f(x)$ in $\Fmul{O(n)}$ operations given the $f(\theta^i)$'s via [the Barycentric formula](/lagrange-interpolation#barycentric-formula) and create the proof via Eq. \ref{eq:kzg-pi-1}.
([Batch inversion](/batch-inversion) should be used to compute all the $(\theta^i - x)^{-1}$'s fast.)
When $x\in \mathbb{H}$, we could use [differentiation tricks](/differentiation-tricks#opening-a-lagrange-basis-kzg-commitment-at-a-root-of-unity) to interpolate the quotient $\frac{f(X) - f(x)}{X - x}$ in Lagrange basis and create the proof via Eq. \ref{eq:kzg-pi-2}.

Compute an additional blinded component:
\begin{align}
\pi_2 \leftarrow \one{\rho} - s \cdot (\tauOne - \one{x})
\end{align}

Return the proof:
\begin{align}
\pi\gets (\pi_1,\pi_2)
\end{align}

### $\mathsf{HKZG.Verify}(\mathsf{vk}, C, x, y; \pi) \rightarrow \\{0,1\\}$

Parse the verification key:
\begin{align}
    \left(\xiTwo, \tauTwo\right) \parse \vk
\end{align}

Parse the proof $(\pi_1,\pi_2)\parse\pi$ and assert that:
\begin{align}
    e(C - \one{y}, \two{1}) \equals e(\pi_1, \tauTwo - \two{x}) + e(\pi_2,\xiTwo)
\end{align}

#### Correctness of openings

Correctness holds since, assuming that $C \bydef \hkzgCommit(\ck, f; \rho)$ and $\pi \bydef \hkzgOpen(\ck, f, \rho, x; s)$, then the paring check in $\hkzgVerify(\ck, C, x, f(x); \pi)$ is equivalent to:
\begin{align}
    e(\cancel{\rho\cdot\xiOne} + \one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \pair{s \cdot \xiOne + \one{\frac{f(\tau) - f(x)}{\tau - x}}}{ \tauTwo - \two{x}} + e(\cancel{\one{\rho}}-s\cdot(\tauOne-\one{x}),\cancel{\xiTwo})\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \bluedashedbox{\pair{s \cdot \xiOne + \one{\frac{f(\tau) - f(x)}{\tau - x}}}{ \tauTwo - \two{x}}} - e(s\cdot(\tauOne-\one{x}), \xiTwo)\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \bluedashedbox{\pair{\one{\frac{f(\tau) - f(x)}{\tau - x}}}{ \tauTwo - \two{x}} + \cancel{\pair{s\cdot\xiOne}{\tauTwo - \two{x}}}} - \cancel{e(s\cdot(\tauOne-\one{x}), \xiTwo)}\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \pair{\one{\frac{f(\tau) - f(x)}{\cancel{\tau - x}}}}{\cancel{\tauTwo - \two{x}}}\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\stackrel{!}{=} \pair{\one{f(\tau) - f(x)}}{\two{1}}\\\\\
\end{align}

## The scheme

A few notes:
 - Values are represented in **radix $\term{b}$**
    - e.g., $\term{z_{i,j}}\in[b)$ denotes the $j$th **chunk** of $z_i \bydef \sum_{j\in[\ell)} b^j \cdot \emph{z_{i,j}}$
 - The goal is to prove that each value $z_i \in [b^\ell)$ by exhibiting a valid **radix-$b$ decomposition** as shown above
    + $\term{\ell}$ is the number of chunks ($z_{i,j}$'s) in this decomposition
 - We will have $\term{n}$ values we want to prove ($z_i$'s)
 - The degrees of committed polynomials will be either $n$ or $(b-1)n$

<!--  We will work with two kinds of vanishing polynomials:
     $\term{\VL(X)}\bydef \vanishL$ of degree $\term{L}-1 \bydef \emph{b(n+1)} - 1$ -->

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Setup}(n; \mathcal{G})\rightarrow (\mathsf{prk},\mathsf{ck},\mathsf{vk})$

Assume $n=2^c$ for some $c\in\N$[^power-of-two-n] s.t. $n \mid p-1$ (where $p$ is the order of the bilinear group $\mathcal{G}$) and let $\term{L} \bydef b(n+1) = 2^{d}$, for some $d\in\N$ s.t. $L \mid p-1$ as well.

{: .note}
For efficiency, we restrict ourselves to $(n+1)$ and $b$ that are powers of two, so that $L \bydef b(n+1)$ is a power of two as well.
Ideally though, since the highest-degree polynomial involved in our scheme is $(b-1)n$, we could have used a smaller $L = (b-1)n + 1$ $= bn - (n - 1)$.
But this $L$ may not be a power of two, which means FFTs would be trickier.

Pick random trapdoors for the [hiding KZG](#hiding-kzg) scheme:
\begin{align}
    \term{\xi,\tau}\randget\F
\end{align}

Compute KZG public parameters for committing to polynomials interpolated from $n+1$ evaluations:
\begin{align}
((\xiTwo,\tauTwo), \term{\ck_\S}) \gets \hkzgSetup(n+1; \mathcal{G}, \xi, \tau)
\end{align}
where:
 + $\term{\S}\bydef\\{\omega^0,\omega^1,\ldots,\omega^{\emph{n}}\\}$
 + $\term{\omega}$ is a primitive $(n+1)$th root of unity in $\F$
 - $\term{\lagrS_i(X)} \bydef \prod_{j\in\S, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}, \forall i\in[n+1)$
 + $\term{\VS(X)}\bydef \vanishSfrac$ is a vanishing polynomial of degree $n$ whose $n$ roots are in $\S\setminus\\{\omega^0\\}$ 
 - $\emph{\ck_\S} \bydef \left(\xiOne,\tauOne, (\sOne{i})_{i\in[n+1)}\right)$

Compute KZG public parameters, reusing the same $(\xi,\tau)$, for committing to polynomials interpolated from $L$ evaluations:
\begin{align}
(\cdot, \term{\ck_\L}) \gets \hkzgSetup(L; \mathcal{G}, \xi, \tau)
\end{align}
where:
 + $\term{\L}\bydef\\{\zeta^0,\zeta^1,\ldots,\zeta^{\emph{L-1}}\\}$
 + $\term{\zeta}$ is a primitive $L$th root of unity in $\F$
 - $\term{\lagrL_i(X)} \bydef \prod_{j\in\L, j\ne i} \frac{X - \zeta^j}{\zeta^i - \zeta^j}, \forall i\in[L)$

_Note:_ The [Lagrange polynomial](/lagrange-interpolation) $\lagrS_i(X)$ is of degree $n$, while $\lagrL_i(X)$ is of degree $L-1$.

Compute the range proof's proving key:
\begin{align}
\term{\vk}  &\gets \left(\overbrace{\xiTwo, \tauTwo}^{\term{\vkHkzg}}, \xiOne, \sOne{0}\right)\\\\\
\term{\ck} &\gets \ck_\S\\\\\
\term{\prk} &\gets \left(\vk, \ck_\S, \ck_\L\right)
\end{align}

{: .note}
When $b=2$, we will be able to simplify by letting $L = n+1$ and thus $\S = \L$ and $\ck_\L = \ck_\S$.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Commit}(\ck,z_1,\ldots,z_{n}; \rho)\rightarrow C$

Parse the commitment key:
\begin{align}
    \left(\xiOne, \tauOne, \left(\sOne{i}\right)\_{i\in[n+1)}\right) \parse\ck
\end{align}

Represent the $n$ values and a prepended $0$ value as a degree-$n$ polynomial:
\begin{align}
\term{f(X)} \bydef 0\cdot \lagrS_0(X) + \sum_{i\in[n]} z_i \cdot \lagrS_i(X)
\end{align}

Commit to the polynomial via [hiding KZG](#hiding-kzg):
\begin{align}
\term{\rho} &\randget \F\\\\\
C &\gets \hkzgCommit(\ck_\S, f; \rho) \bydef \rho \cdot \xiOne + \one{f(\tau)} = \rho\cdot \xiOne + \sum_{i\in[n]} z_i \cdot \sOne{i}
\end{align}

{: .note}
Note that $f(\omega^i) = z_i,\forall i\in[n]$ but the $f(\omega^0)$ evaluation is set to zero.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Prove}(\mathsf{prk}, C, \ell; z_1,\ldots,z_{n}, \rho)\rightarrow \pi$


**Step 1**a**:** Parse the public parameters:
\begin{align}
 \left(\vk, \ck_\S, \ck_\L\right)\parse \prk\\\\\
 \left(\xiOne, \tauOne, \left(\sOne{i}\right)\_{i\in[n+1)}\right) \parse \ck_\S\\\\\
 \left(\xiOne, \tauOne, \left(\lOne{i}\right)\_{i\in[L)}\right)\parse \ck_\L
\end{align}

**Step 1**b**:** Add $(\vk, C, b, \ell)$ to the $\FS$ transcript.

**Step 2**a**:** Re-randomize the commitment $C\bydef \rho\cdot \xiOne+\one{f(\tau)}$ **and** mask the degree-$n$ committed polynomial $f(X)$:
\begin{align}
\term{r}, \term{\Delta{\rho}} &\randget \F\\\\\
\term{\hat{f}(X)} &\bydef r \cdot \lagrS_0(X) + \emph{f(X)}\\\\\
\term{\hat{C}} &\gets \Delta{\rho} \cdot \xiOne + r\cdot \sOne{0} + \emph{C}\\\\\
               &\bydef \hkzgCommit(\ck_\S, \hat{f}; \rho + \Delta{\rho})
\end{align}

**Step 2**b**:** Add $\hat{C}$ to the $\FS$ transcript.

**Step 3a:** Prove knowledge of $r$ and $\Delta{\rho}$ such that $\hat{C} - C = \Delta{\rho} \cdot \xiOne + r\cdot \sOne{0}$.
\begin{align}
    \term{\piPok} \gets \zkpokProve\left(\underbrace{(\hat{C}-C, \xiOne, \sOne{0})}\_{\text{statement}}; \underbrace{(\Delta{\rho}, r)}\_{\text{witness}}\right)
\end{align}

**Step 3**b**:** Add $\piPok$ to the $\FS$ transcript.

**Step 4**a**:** Represent all $j$th chunks $(z_{1,j},\ldots,z_{n,j})$ as a degree-$n$ polynomial and commit to it:
\begin{align}
\term{r\_j}, \term{\rho\_j} &\randget \F\\\\\
\term{f\_j(X)} &\bydef r\_j \cdot \lagrS_0(X) + \sum\_{i\in[n]} z\_{i,j}\cdot \lagrS_i(X)\\\\\
\term{C\_j} &\gets \rho_j \cdot \xiOne + r\_j\cdot \sOne{0} + \sum\_{i\in[n]} z\_{i,j}\cdot \sOne{i}\\\\\
            &\bydef \hkzgCommit(\ck\_\S, f\_j; \rho\_j)
\end{align}

**Step 4**b**:** Add $(C\_j)\_{j\in[\ell)}$ to the $\FS$ transcript.

**Step 5**a**:** For each $j\in[\ell)$, define a quotient polynomial, whose existence would show that, $\forall i\in[n]$, $f_j(\omega^i) \in [b)$:
\begin{align}
\forall j\in[\ell), \term{h_j(X)}
    &\bydef \frac{f_j(X)(f_j(X) - 1) \cdots \left(f_j(X) - (b-1)\right)}{\VS(X)}\\\\\
\end{align}

*Note:* Numerator is degree $bn$ and denominator is degree $n \Rightarrow h_j(X)$ is degree $(b-1)n$

**Step 5**b**:** Define a(nother) quotient polynomial, whose existence would show that, $\forall i\in[n]$, $\hat{f}(\omega^i) = \sum_{j\in[\ell)} b^j \cdot f_j(\omega^i)$:
\begin{align}
\term{g(X)}
    &\bydef \frac{\hat{f}(X) - \sum_{j\in[\ell)} b^j \cdot f_j(X)}{\VS(X)}\\\\\
\end{align}

*Note:* Numerator is degree $n$ and denominator is degree $n \Rightarrow g(X)$ is degree 0! (A constant!)

**Step 6:** Combine all the quotients into a single one, using (pseudo)random challenges from the verifier:
\begin{align}
\term{\beta,\beta\_0, \ldots,\beta_{\ell-1}}
    &\fsget \\{0,1\\}^\lambda\\\\\
\label{eq:hx}
\term{h(X)} 
    &\gets \beta \cdot g(X) + \sum\_{j\in[\ell)} \beta\_j \cdot h\_j(X)
\end{align}

*Note:* The goal of the prover is to convince the verifier that:
\begin{align}
\label{eq:hx-check}
h(X) \cdot \VS(X) \equals \beta \cdot \left(\hat{f}(X) - \sum_{j\in[\ell)} b^j \cdot f_j(X)\right) + \sum_{j\in[\ell)} \beta_j\cdot f_j(X)(f_j(X) - 1) \cdots \left(f_j(X) - (b-1)\right)\\\\\
\end{align}


**Step 7**a**:** Commit to $h(X)$, of degree $(b-1)n$, by interpolating it over the larger $\L$ domain:
\begin{align}
\term{\rho_h} &\randget \F\\\\\
\label{eq:D}
\term{D} &\gets \rho_h\cdot \xiOne + \sum\_{i\in[L)} h(\zeta^i) \cdot \lOne{i}\\\\\
    &\bydef \hkzgCommit(\ck_\L, h; \rho_h)
\end{align}

_Note:_ We discuss how to interpolate $h(X)$ efficiently by either evaluating it [at all $\omega^i$'s (when $b=2$)](#appendix-computing-hx-for-b2) or [at all $\zeta^i$'s (when $b>2$)](#appendix-computing-hx-for-bne-2) in the appendix.

**Step 7**b**:** Add $D$ to the $\FS$ transcript.

**Step 8:** The verifier asks us to take a (pseudo)random linear combination of $h(X)$, $\hat{f}(X)$ and the $f_j(X)$'s:
\begin{align}
\term{\mu, \mu_h, \mu\_0,\ldots,\mu\_{\ell-1}} &\fsget \\{0,1\\}^\lambda\\\\\
\label{eq:ux}
\term{u(X)} &\bydef
  \mu \cdot \hat{f}(X) +
  \mu\_h\cdot h(X) +
  \sum\_{j\in[\ell)} \mu\_j\cdot f\_j(X) 
\end{align}

**Step 9:** We get a (pseudo)random challenge from the verifier and open $u(X)$ at it: 
\begin{align}
    \term{\gamma} &\fsget \F\setminus\S\\\\\
    \term{a} &\gets \hat{f}(\gamma)\\\\\
    \term{a\_h} &\gets h(\gamma)\\\\\
    \term{a\_j} &\gets f\_j(\gamma),\forall j\in[\ell)\\\\\
\end{align}

**Step 10:** We compute a hiding KZG opening proof for $u(\gamma)$:
\begin{align}
    \term{s} &\randget \F\\\\\
    \term{\pi_\gamma} &\gets \hkzgOpen(\ck_\L, u, \term{\rho_u}, \gamma; s)
\end{align}
where $\emph{\rho_u} \bydef \mu \cdot (\rho + \Delta{\rho}) + \mu_h \cdot \rho_h + \sum_{j\in[\ell)} \mu_j\cdot \rho_j$ is the blinding factor for the implicit commitment to $u(X)$, which the prover need not compute: 
\begin{align}
\term{U} 
    &\bydef \mu \cdot \hat{C} + \mu_h \cdot D + \sum_{j\in[\ell)} \mu_j\cdot C_j\\\\\
    &\bydef \hkzgCommit(\ck\_\L, u; \rho\_u)
\end{align}

{: .note}
When $b > 2$, committing to $u(X)$ requires evaluating $u(\zeta^i)$ for all $i\in[L)$, which in turn requires having all $\hat{f}(\zeta^i)$'s and $f_j(\zeta^i)$'s.
**Fortunately**, we already have them from the differentiation-based [$h(X)$ interpolation for $b > 2$](#appendix-computing-hx-for-bne-2).

Return the proof $\pi$:
\begin{align}
\term{\pi}\gets \left(\hat{C}, \piPok, (C\_j)\_{j\in[\ell)}, D, a, a_h, (a\_j)\_{j\in[\ell)}, \pi\_\gamma\right)
\end{align}

#### Proof size and prover time

**Proof size**:
 - $(\ell+2)\Gr_1$ for the $\hat{C}$, $C\_j$'s and $D$
 - $2$ $\Gr_1$ for $\pi\_\gamma$
 - $1 \Gr_1 + 2\F$ for $\|\piPok\|$
 - $(\ell+2)\F$ for $a, a_h$ and the $a_j$'s (i.e., for $\hat{f}(\gamma), h(\gamma)$, and the $f_j(\gamma)$'s)

$\Rightarrow$ in **total**, $\emph{\|\pi\|=(\ell+5)\Gr_1 + (\ell+4)\F}$,

**Prover time** is dominated by:

 - $\GaddOne{\ell n}$ for all $C_j$'s
    + Assuming precomputed $2\cdot \sOne{i}, \ldots, (b-1)\cdot \sOne{i},\forall i\in[n]$
    - i.e., one for each possible chunk value in $[b)$
 - $1$ $\fmsmOne{2}$ MSM to blind $\hat{C}$ with $\rho$ and $\Delta{r}$
 - $(\ell+1)$ $\fmsmOne{2}$ MSMs to blind all $C_j$'s with $r_j$ and $\rho_j$
 - $1 \fmsmOne{2}$ for $\zkpokProve$
 - $\Fmul{O(\ell L\log{L})}$ to interpolate $h(X)$, where $L\bydef bn$
    + See [more fine-grained break down here](#time-complexity).
 - 1 $\fmsmOne{L+1}$ MSM for committing to $h(X)$
 - $\Fmul{O(\ell n)}$ to interpolate $\hat{f}(\gamma)$ and $f_j(\gamma)$ evals via [the Barycentric formula](/lagrange-interpolation#barycentric-formula)
    + (_Note:_ $h(\gamma)$ can be evaluated directly via Eq. \ref{eq:hx}.)
    + there will be $(\ell+1)$ size-$n$ Barycentric interpolations
    - the following need only be done once: 
        + batch invert all $\frac{1}{\gamma -\omega^i}$'s $\Rightarrow \Fmul{O(n)}$
        - compute $\frac{\gamma^n - 1}{n}$ in $\Fmul{\log_2{n}} + 1$
    - each interpolation will then involve:
        - do $\Fmul{2n}$ and $\Fadd{n}$ (i.e., two $\F$ multiplication for each $y_i \cdot \omega^i \cdot \frac{1}{\gamma-\omega^i}$)
        - do $\Fmul{1}$ to accumulate $\frac{\gamma^n - 1}{n}$
 - 1 $\fmsmOne{L+1}$ MSM for computing $\pi_\gamma$ via [$\hkzgOpen(\cdot)$](#hkzgopenck-f-rho-x-s-rightarrow-pi)

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Verify}(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

**Step 1:** Parse the $\vk$ and the proof $\pi$:
\begin{align}
\left(\vkHkzg, \xiOne, \sOne{0}\right) &\parse \vk\\\\\
\left(\hat{C}, \piPok, (C_j)_{j\in[\ell)}, D, a, a_h, (a\_{j})\_{j\in[\ell)}, \pi\_\gamma\right) &\parse \pi
\end{align}
 
**Step 2**a**:** Add $(\vk, C, b, \ell)$ to the $\FS$ transcript.

**Step 2**b**:** Add $(\hat{C})$ to the $\FS$ transcript.

**Step 3:** Verify ZKPoK:
\begin{align}
\textbf{assert}\
    \zkpokVerify\left(\hat{C}-C, \xiOne, \sOne{0}; \piPok\right) \equals 1
\end{align}

**Step 4**a**:** Add $\piPok$ to the $\FS$ transcript.

**Step 4**b**:** Add $((C_j)_{j\in[\ell})$ to the $\FS$ transcript.
 
**Step 5:** Generate (pseudo)random challenges for combing the quotient polynomials:
\begin{align}
\beta,\beta_0,\ldots,\beta_{\ell-1} &\fsget \\{0,1\\}^\lambda
\end{align}
 
**Step 6:** Add $D$ to the $\FS$ transcript.
 
**Step 7:** Generate (pseudo)random challenges for the batch KZG opening on $\hat{f}(X), h(X)$ and the $f_j(X)$'s:
\begin{align}
\mu,\mu_h,\mu_0,\ldots,\mu_{\ell-1}\fsget \\{0,1\\}^\lambda
\end{align}

**Step 8:** Reconstruct the commitment to $u(X)$ from Eq. \ref{eq:ux} 
\begin{align}
\term{U} \gets \mu\cdot \hat{C} + \mu_h\cdot D + \sum\_{j\in[\ell)} \mu_j \cdot C_j
\end{align}

**Step 9:** Generate a (pseudo)random evaluation point for the batch KZG opening:
\begin{align}
\gamma \fsget \F
\end{align}

**Step 10:** Verify that $a \equals \hat{f}(\gamma$), $a_h \equals h(\gamma)$ and $a_j \equals f_j(\gamma),\forall j\in[\ell)$:
\begin{align}
\label{eq:kzg-batch-verify}
\term{a_u} &\gets \mu \cdot a + \mu_h \cdot a_h + \sum_{j\in[\ell)} \mu_j\cdot a_j\\\\\
\textbf{assert}\ &\hkzgVerify(\vkHkzg, U, \gamma, a_u; \pi_\gamma) \equals 1 
\end{align}

**Step 11:** Make sure that the radix-$b$ representation holds and that chunks are $<b$ as per Eq. \ref{eq:hx-check}:
\begin{align}
\textbf{assert}\ h(\gamma) \cdot \VS(\gamma) &\equals \beta \cdot \left(\hat{f}(\gamma) - \sum\_{j\in[\ell)} b^j \cdot f\_j(\gamma)\right) + \sum\_{j\in[\ell)} \beta\_j\cdot f\_j(\gamma)(f\_j(\gamma) - 1) \cdots (f\_j(\gamma)- (b-1))\Leftrightarrow\\\\\
\Leftrightarrow \textbf{assert}\ a\_h \cdot \VS(\gamma) &\equals \beta \cdot \left(a - \sum\_{j\in[\ell)} b^j \cdot a\_j\right) + \sum\_{j\in[\ell)} \beta\_j\cdot a\_j(a\_j - 1) \cdots (a\_j - (b-1))
\end{align}

#### Verifier time

The verifier work is dominated by:

 - 1 $\vmsmOne{3}$ MSM for verifying $\piPok$
 - 1 $\vmsmOne{\ell+2}$ MSM for deriving the KZG commitment $U$
 - $\GmulOne{1} + \GaddOne{1}$ for computing $\one{\tau - a_u}$ inside [$\hkzgVerify(\cdot)$](#hkzgverifyvk-c-x-y-pi-rightarrow-01)
 - $\GmulTwo{1} + \GaddTwo{1}$ for computing $\two{\tau - \gamma}$ inside $\hkzgVerify(\cdot)$
 - size-$3$ multipairing for the rest of $\hkzgVerify(\cdot)$
 - $\Fmul{(\ell+2)} + \Fadd{(\ell+2)}$ for computing $a_u$ 
 - $\Fmul{(1 + (\ell+1) + \ell b)} + \Fadd{(1 + \ell + 1 + \ell)}$ for the final zerocheck

## Implementation

### Benchmarks for $b=2$ over BLS12-381

{: .note}
These benchmarks are from our (in-progress) DeKART implementation in `arkworks v0.5.0` [here](https://github.com/aptos-labs/aptos-core/blob/main/crates/aptos-dkg/src/range_proofs/dekart_univariate_v2.rs).
To reproduce, see this [README](https://github.com/aptos-labs/aptos-core/tree/main/crates/aptos-crypto/benches/README.md).\
\
The Bulletproof proof size is $32\times \left(9 + 2\cdot \log_2{(n\cdot \ell)}\right)$ bytes.\
\
The DeKART verifier time only varies with $\ell$; not with $n$.
This means that by using higher $b$, we can decrease $\ell$ (e.g., from $\log_2{\texttt{MAX\_VALUE}}$ to $\log_b{\texttt{MAX\_VALUE}}$).
This will reduce proof size **and** speed up our verifier by a factor of $\log_2{b}$.
However, it will make proving slower by a factor of $b$
(e.g., 16x slower proving by for a 4x faster-to-verify and smaller proof 👌).
Nonetheless, it will be great for applications like [confidential assets](/confidential-assets).

#### $\ell = 8$ numbers

| Scheme             | n    | Proving time (ms) | Verify time (ms) | Total time (ms) | Proof size (bytes) |
|--------------------|------|-------------------|------------------|-----------------|--------------------|
| Bulletproofs       | 2    |              3.24 |             0.52 |            3.76 | 544                |
| DeKART (BLS12-381) | 1    | <span style="color:#dc2626">4.28</span> (0.76x) | <span style="color:#dc2626">3.04</span> (0.17x) | <span style="color:#dc2626">7.32</span> (0.51x) | <span style="color:#dc2626">1,008</span> (1.85x) |
| Bulletproofs       | 4    |              6.25 |             0.89 |            7.14 | 608                |
| DeKART (BLS12-381) | 3    | <span style="color:#15803d; font-weight:700">4.34</span> (1.44x) | <span style="color:#dc2626">2.96</span> (0.30x) | <span style="color:#dc2626">7.30</span> (0.98x) | <span style="color:#dc2626">1,008</span> (1.66x) |
| Bulletproofs       | 8    |             11.66 |             1.40 |           13.06 | 672                |
| DeKART (BLS12-381) | 7    | <span style="color:#15803d; font-weight:700">4.66</span> (2.50x) | <span style="color:#dc2626">2.92</span> (0.48x) | <span style="color:#15803d; font-weight:700">7.58</span> (1.72x) | <span style="color:#dc2626">1,008</span> (1.50x) |
| Bulletproofs       | 16   |             22.32 |             2.48 |           24.80 | 736                |
| DeKART (BLS12-381) | 15   | <span style="color:#15803d; font-weight:700">5.34</span> (4.18x) | <span style="color:#dc2626">2.98</span> (0.83x) | <span style="color:#15803d; font-weight:700">8.32</span> (2.98x) | <span style="color:#dc2626">1,008</span> (1.37x) |
| Bulletproofs       | 32   |             45.50 |             4.44 |           49.94 | 800                |
| DeKART (BLS12-381) | 31   | <span style="color:#15803d; font-weight:700">10.34</span> (4.40x) | <span style="color:#15803d; font-weight:700">2.95</span> (1.51x) | <span style="color:#15803d; font-weight:700">13.29</span> (3.76x) | <span style="color:#dc2626">1,008</span> (1.26x) |
| Bulletproofs       | 64   |             91.64 |             7.17 |           98.81 | 864                |
| DeKART (BLS12-381) | 63   | <span style="color:#15803d; font-weight:700">11.76</span> (7.79x) | <span style="color:#15803d; font-weight:700">2.89</span> (2.48x) | <span style="color:#15803d; font-weight:700">14.65</span> (6.74x) | <span style="color:#dc2626">1,008</span> (1.17x) |
| Bulletproofs       | 128  |            171.31 |            12.73 |          184.04 | 928                |
| DeKART (BLS12-381) | 127  | <span style="color:#15803d; font-weight:700">18.71</span> (9.16x) | <span style="color:#15803d; font-weight:700">2.93</span> (4.34x) | <span style="color:#15803d; font-weight:700">21.64</span> (8.50x) | <span style="color:#dc2626">1,008</span> (1.09x) |
| Bulletproofs       | 256  |            339.23 |            23.93 |          363.16 | 992                |
| DeKART (BLS12-381) | 255  | <span style="color:#15803d; font-weight:700">31.73</span> (10.69x) | <span style="color:#15803d; font-weight:700">2.89</span> (8.28x) | <span style="color:#15803d; font-weight:700">34.62</span> (10.49x) | <span style="color:#dc2626">1,008</span> (1.02x) |
| Bulletproofs       | 512  |            664.35 |            46.06 |          710.41 | 1,056              |
| DeKART (BLS12-381) | 511  | <span style="color:#15803d; font-weight:700">42.50</span> (15.63x) | <span style="color:#15803d; font-weight:700">2.90</span> (15.88x) | <span style="color:#15803d; font-weight:700">45.40</span> (15.65x) | <span style="color:#15803d; font-weight:700">1,008</span> (0.95x) |
| Bulletproofs       | 1024 |          1,346.50 |            90.55 |        1,437.05 | 1,120              |
| DeKART (BLS12-381) | 1023 | <span style="color:#15803d; font-weight:700">75.59</span> (17.81x) | <span style="color:#15803d; font-weight:700">2.91</span> (31.12x) | <span style="color:#15803d; font-weight:700">78.50</span> (18.31x) | <span style="color:#15803d; font-weight:700">1,008</span> (0.90x) |
| Bulletproofs       | 2048 |          2,653.50 |           180.76 |        2,834.26 | 1,184              |
| DeKART (BLS12-381) | 2047 | <span style="color:#15803d; font-weight:700">141.58</span> (18.74x) | <span style="color:#15803d; font-weight:700">2.94</span> (61.48x) | <span style="color:#15803d; font-weight:700">144.52</span> (19.61x) | <span style="color:#15803d; font-weight:700">1,008</span> (0.85x) |

#### $\ell = 16$ numbers

| Scheme             | n    | Proving time (ms) | Verify time (ms) | Total time (ms) | Proof size (bytes) |
|--------------------|------|-------------------|------------------|-----------------|--------------------|
| Bulletproofs       | 2    |              5.46 |             0.82 |            6.28 | 608                |
| DeKART (BLS12-381) | 1    | <span style="color:#dc2626">6.45</span> (0.85x) | <span style="color:#dc2626">3.21</span> (0.26x) | <span style="color:#dc2626">9.66</span> (0.65x) | <span style="color:#dc2626">1,648</span> (2.71x) |
| Bulletproofs       | 4    |             11.04 |             1.37 |           12.41 | 672                |
| DeKART (BLS12-381) | 3    | <span style="color:#15803d; font-weight:700">6.71</span> (1.65x) | <span style="color:#dc2626">3.36</span> (0.41x) | <span style="color:#15803d; font-weight:700">10.07</span> (1.23x) | <span style="color:#dc2626">1,648</span> (2.45x) |
| Bulletproofs       | 8    |             21.23 |             2.42 |           23.65 | 736                |
| DeKART (BLS12-381) | 7    | <span style="color:#15803d; font-weight:700">7.05</span> (3.01x) | <span style="color:#dc2626">3.20</span> (0.76x) | <span style="color:#15803d; font-weight:700">10.25</span> (2.31x) | <span style="color:#dc2626">1,648</span> (2.24x) |
| Bulletproofs       | 16   |             40.63 |             4.03 |           44.66 | 800                |
| DeKART (BLS12-381) | 15   | <span style="color:#15803d; font-weight:700">8.58</span> (4.74x) | <span style="color:#15803d; font-weight:700">3.18</span> (1.27x) | <span style="color:#15803d; font-weight:700">11.76</span> (3.80x) | <span style="color:#dc2626">1,648</span> (2.06x) |
| Bulletproofs       | 32   |             83.00 |             6.98 |           89.98 | 864                |
| DeKART (BLS12-381) | 31   | <span style="color:#15803d; font-weight:700">16.09</span> (5.16x) | <span style="color:#15803d; font-weight:700">3.22</span> (2.17x) | <span style="color:#15803d; font-weight:700">19.31</span> (4.66x) | <span style="color:#dc2626">1,648</span> (1.91x) |
| Bulletproofs       | 64   |            159.72 |            12.12 |          171.84 | 928                |
| DeKART (BLS12-381) | 63   | <span style="color:#15803d; font-weight:700">17.97</span> (8.89x) | <span style="color:#15803d; font-weight:700">3.20</span> (3.79x) | <span style="color:#15803d; font-weight:700">21.17</span> (8.12x) | <span style="color:#dc2626">1,648</span> (1.78x) |
| Bulletproofs       | 128  |            306.54 |            22.53 |          329.07 | 992                |
| DeKART (BLS12-381) | 127  | <span style="color:#15803d; font-weight:700">28.48</span> (10.76x) | <span style="color:#15803d; font-weight:700">3.15</span> (7.15x) | <span style="color:#15803d; font-weight:700">31.63</span> (10.40x) | <span style="color:#dc2626">1,648</span> (1.66x) |
| Bulletproofs       | 256  |            600.51 |            43.83 |          644.34 | 1,056              |
| DeKART (BLS12-381) | 255  | <span style="color:#15803d; font-weight:700">48.73</span> (12.32x) | <span style="color:#15803d; font-weight:700">3.18</span> (13.78x) | <span style="color:#15803d; font-weight:700">51.91</span> (12.41x) | <span style="color:#dc2626">1,648</span> (1.56x) |
| Bulletproofs       | 512  |          1,197.00 |            88.54 |        1,285.54 | 1,120              |
| DeKART (BLS12-381) | 511  | <span style="color:#15803d; font-weight:700">61.91</span> (19.33x) | <span style="color:#15803d; font-weight:700">3.16</span> (28.02x) | <span style="color:#15803d; font-weight:700">65.07</span> (19.76x) | <span style="color:#dc2626">1,648</span> (1.47x) |
| Bulletproofs       | 1024 |          2,369.10 |           171.48 |        2,540.58 | 1,184              |
| DeKART (BLS12-381) | 1023 | <span style="color:#15803d; font-weight:700">111.55</span> (21.24x) | <span style="color:#15803d; font-weight:700">3.12</span> (54.96x) | <span style="color:#15803d; font-weight:700">114.67</span> (22.16x) | <span style="color:#dc2626">1,648</span> (1.39x) |
| Bulletproofs       | 2048 |          4,763.80 |           349.29 |        5,113.09 | 1,248              |
| DeKART (BLS12-381) | 2047 | <span style="color:#15803d; font-weight:700">205.36</span> (23.20x) | <span style="color:#15803d; font-weight:700">3.15</span> (110.89x) | <span style="color:#15803d; font-weight:700">208.51</span> (24.52x) | <span style="color:#dc2626">1,648</span> (1.32x) |

#### $\ell = 32$ numbers

| Scheme             | n    | Proving time (ms) | Verify time (ms) | Total time (ms) | Proof size (bytes) |
|--------------------|------|-------------------|------------------|-----------------|--------------------|
| Bulletproofs       | 2    |              9.95 |             1.42 |           11.37 | 672                |
| DeKART (BLS12-381) | 1    | <span style="color:#dc2626">11.32</span> (0.88x) | <span style="color:#dc2626">3.77</span> (0.38x) | <span style="color:#dc2626">15.09</span> (0.75x) | <span style="color:#dc2626">2,928</span> (4.36x) |
| Bulletproofs       | 4    |             19.91 |             2.30 |           22.21 | 736                |
| DeKART (BLS12-381) | 3    | <span style="color:#15803d; font-weight:700">11.61</span> (1.71x) | <span style="color:#dc2626">3.68</span> (0.62x) | <span style="color:#15803d; font-weight:700">15.29</span> (1.45x) | <span style="color:#dc2626">2,928</span> (3.98x) |
| Bulletproofs       | 8    |             40.13 |             3.96 |           44.09 | 800                |
| DeKART (BLS12-381) | 7    | <span style="color:#15803d; font-weight:700">12.11</span> (3.31x) | <span style="color:#15803d; font-weight:700">3.69</span> (1.07x) | <span style="color:#15803d; font-weight:700">15.80</span> (2.79x) | <span style="color:#dc2626">2,928</span> (3.66x) |
| Bulletproofs       | 16   |             76.14 |             6.69 |           82.83 | 864                |
| DeKART (BLS12-381) | 15   | <span style="color:#15803d; font-weight:700">12.74</span> (5.98x) | <span style="color:#15803d; font-weight:700">3.67</span> (1.82x) | <span style="color:#15803d; font-weight:700">16.41</span> (5.05x) | <span style="color:#dc2626">2,928</span> (3.39x) |
| Bulletproofs       | 32   |            149.45 |            11.95 |          161.40 | 928                |
| DeKART (BLS12-381) | 31   | <span style="color:#15803d; font-weight:700">27.80</span> (5.38x) | <span style="color:#15803d; font-weight:700">3.72</span> (3.21x) | <span style="color:#15803d; font-weight:700">31.52</span> (5.12x) | <span style="color:#dc2626">2,928</span> (3.16x) |
| Bulletproofs       | 64   |            288.81 |            22.40 |          311.21 | 992                |
| DeKART (BLS12-381) | 63   | <span style="color:#15803d; font-weight:700">29.82</span> (9.69x) | <span style="color:#15803d; font-weight:700">3.68</span> (6.09x) | <span style="color:#15803d; font-weight:700">33.50</span> (9.29x) | <span style="color:#dc2626">2,928</span> (2.95x) |
| Bulletproofs       | 128  |            572.05 |            42.26 |          614.31 | 1,056              |
| DeKART (BLS12-381) | 127  | <span style="color:#15803d; font-weight:700">47.78</span> (11.97x) | <span style="color:#15803d; font-weight:700">3.70</span> (11.42x) | <span style="color:#15803d; font-weight:700">51.48</span> (11.93x) | <span style="color:#dc2626">2,928</span> (2.77x) |
| Bulletproofs       | 256  |          1,135.90 |            83.23 |        1,219.13 | 1,120              |
| DeKART (BLS12-381) | 255  | <span style="color:#15803d; font-weight:700">81.28</span> (13.98x) | <span style="color:#15803d; font-weight:700">3.86</span> (21.56x) | <span style="color:#15803d; font-weight:700">85.14</span> (14.32x) | <span style="color:#dc2626">2,928</span> (2.61x) |
| Bulletproofs       | 512  |          2,240.80 |           167.07 |        2,407.87 | 1,184              |
| DeKART (BLS12-381) | 511  | <span style="color:#15803d; font-weight:700">102.28</span> (21.91x) | <span style="color:#15803d; font-weight:700">3.86</span> (43.28x) | <span style="color:#15803d; font-weight:700">106.14</span> (22.69x) | <span style="color:#dc2626">2,928</span> (2.47x) |
| Bulletproofs       | 1024 |          4,527.10 |           328.03 |        4,855.13 | 1,248              |
| DeKART (BLS12-381) | 1023 | <span style="color:#15803d; font-weight:700">180.72</span> (25.05x) | <span style="color:#15803d; font-weight:700">3.66</span> (89.63x) | <span style="color:#15803d; font-weight:700">184.38</span> (26.33x) | <span style="color:#dc2626">2,928</span> (2.35x) |
| Bulletproofs       | 2048 |          8,911.40 |           663.67 |        9,575.07 | 1,312              |
| DeKART (BLS12-381) | 2047 | <span style="color:#15803d; font-weight:700">343.12</span> (25.97x) | <span style="color:#15803d; font-weight:700">3.75</span> (176.98x) | <span style="color:#15803d; font-weight:700">346.87</span> (27.60x) | <span style="color:#dc2626">2,928</span> (2.23x) |

#### $\ell = 64$ numbers

| Scheme             | n    | Proving time (ms) | Verify time (ms) | Total time (ms) | Proof size (bytes) |
|--------------------|------|-------------------|------------------|-----------------|--------------------|
| Bulletproofs       | 2    |             19.59 |             2.42 |           22.01 | 736                |
| DeKART (BLS12-381) | 1    | <span style="color:#dc2626">21.03</span> (0.93x) | <span style="color:#dc2626">4.34</span> (0.56x) | <span style="color:#dc2626">25.37</span> (0.87x) | <span style="color:#dc2626">5,488</span> (7.46x) |
| Bulletproofs       | 4    |             37.80 |             3.89 |           41.69 | 800                |
| DeKART (BLS12-381) | 3    | <span style="color:#15803d; font-weight:700">20.99</span> (1.80x) | <span style="color:#dc2626">4.39</span> (0.89x) | <span style="color:#15803d; font-weight:700">25.38</span> (1.64x) | <span style="color:#dc2626">5,488</span> (6.86x) |
| Bulletproofs       | 8    |             74.05 |             6.67 |           80.72 | 864                |
| DeKART (BLS12-381) | 7    | <span style="color:#15803d; font-weight:700">21.42</span> (3.46x) | <span style="color:#15803d; font-weight:700">4.32</span> (1.54x) | <span style="color:#15803d; font-weight:700">25.74</span> (3.14x) | <span style="color:#dc2626">5,488</span> (6.35x) |
| Bulletproofs       | 16   |            143.14 |            11.62 |          154.76 | 928                |
| DeKART (BLS12-381) | 15   | <span style="color:#15803d; font-weight:700">23.03</span> (6.22x) | <span style="color:#15803d; font-weight:700">4.37</span> (2.66x) | <span style="color:#15803d; font-weight:700">27.40</span> (5.65x) | <span style="color:#dc2626">5,488</span> (5.91x) |
| Bulletproofs       | 32   |            288.07 |            21.73 |          309.80 | 992                |
| DeKART (BLS12-381) | 31   | <span style="color:#15803d; font-weight:700">51.75</span> (5.57x) | <span style="color:#15803d; font-weight:700">4.39</span> (4.95x) | <span style="color:#15803d; font-weight:700">56.14</span> (5.52x) | <span style="color:#dc2626">5,488</span> (5.53x) |
| Bulletproofs       | 64   |            549.63 |            42.65 |          592.28 | 1,056              |
| DeKART (BLS12-381) | 63   | <span style="color:#15803d; font-weight:700">53.66</span> (10.24x) | <span style="color:#15803d; font-weight:700">4.35</span> (9.80x) | <span style="color:#15803d; font-weight:700">58.01</span> (10.21x) | <span style="color:#dc2626">5,488</span> (5.20x) |
| Bulletproofs       | 128  |          1,100.30 |            84.91 |        1,185.21 | 1,120              |
| DeKART (BLS12-381) | 127  | <span style="color:#15803d; font-weight:700">88.91</span> (12.38x) | <span style="color:#15803d; font-weight:700">4.36</span> (19.47x) | <span style="color:#15803d; font-weight:700">93.27</span> (12.71x) | <span style="color:#dc2626">5,488</span> (4.90x) |
| Bulletproofs       | 256  |          2,208.40 |           163.01 |        2,371.41 | 1,184              |
| DeKART (BLS12-381) | 255  | <span style="color:#15803d; font-weight:700">149.66</span> (14.76x) | <span style="color:#15803d; font-weight:700">4.33</span> (37.65x) | <span style="color:#15803d; font-weight:700">153.99</span> (15.40x) | <span style="color:#dc2626">5,488</span> (4.64x) |
| Bulletproofs       | 512  |          4,351.90 |           329.06 |        4,680.96 | 1,248              |
| DeKART (BLS12-381) | 511  | <span style="color:#15803d; font-weight:700">182.69</span> (23.82x) | <span style="color:#15803d; font-weight:700">4.28</span> (76.88x) | <span style="color:#15803d; font-weight:700">186.97</span> (25.04x) | <span style="color:#dc2626">5,488</span> (4.40x) |
| Bulletproofs       | 1024 |          8,576.10 |           650.01 |        9,226.11 | 1,312              |
| DeKART (BLS12-381) | 1023 | <span style="color:#15803d; font-weight:700">320.90</span> (26.73x) | <span style="color:#15803d; font-weight:700">4.29</span> (151.52x) | <span style="color:#15803d; font-weight:700">325.19</span> (28.37x) | <span style="color:#dc2626">5,488</span> (4.18x) |
| Bulletproofs       | 2048 |         17,469.00 |         1,307.60 |       18,776.60 | 1,376              |
| DeKART (BLS12-381) | 2047 | <span style="color:#15803d; font-weight:700">619.91</span> (28.18x) | <span style="color:#15803d; font-weight:700">4.49</span> (291.22x) | <span style="color:#15803d; font-weight:700">624.40</span> (30.07x) | <span style="color:#dc2626">5,488</span> (3.99x) |


## Conclusion

Your thoughts or comments are welcome on [this thread](https://x.com/alinush/status/1950600327066980693).

### Acknowledgements

This is joint work with Dan Boneh, Trisha Datta, Kamilla Nazirkhanova and Rex Fernando.

### Future work

{: .todo}
We could accept a $b_\max$ and $n_\max$ as arguments to $\dekartSetup$ and change the $b$ subscript from $\mathsf{Dekart}_b$ to be an actual argument.
If we do, then this setup should only output powers-of-$\tau$ of max degree $L-1 = b(n+1) - 1$ instead of Lagrange commitments.
Then, a $\dekart.\mathsf{Specialize}$ algorithm can be introduce to obtain a CRS for a specific $n$, including dealing with non-powers of two.

{: .todo}
Once $b$ is an input to the setup, prove and verification algorithm, it should be checked for being smaller than in the setup.
(Or just check that $b$ and $n$ "match" $L$? Could we allow for larger $b$ while shrinking $n$?)


## Appendix: Computing $h(X)$ for $b=2$

{: .warning}
Recall that, when $b=2$, the degree of $h(X)$ is $n \Rightarrow$ we no longer need two different FFT domains: i.e., $\S = \L$ and $L = n + 1$.
This is why the algorithm below can stay rather simple.

We borrow [differentiation tricks](/differentiation-tricks) from [Groth16](/groth16#computing-hx-for-b2) to avoid doing FFT-based polynomial multiplication.
This keeps our FFTs of size $(n+1)$, as opposed to size $2(n+1)$.

Our goal will be to obtain all $(h(\omega^i))_{i\in[n+1)}$ evaluations and then do a $\fmsmOne{n+2}$ MSM to commit to it and obtain $\emph{D}$ from Eq. \ref{eq:D}.

Recall that:
\begin{align}
\label{eq:hx-njx}
h(X)
    &= \frac{\beta \cdot \left(\hat{f}(X) - \sum_{j\in[\ell)} 2^j \cdot f_j(X)\right) + \sum_{j\in[\ell)} \beta_j\cdot f_j(X)(f_j(X) - 1)}{\VS(X)}\\\\\
\label{eq:njx}
    &= \frac{\beta \cdot \hat{f}(X) - \beta\cdot\sum_{j\in[\ell)} 2^j \cdot f_j(X) + \sum_{j\in[\ell)} \beta_j\cdot \overbrace{f_j(X)(f_j(X) - 1)}^{\bydef \term{N_j(X)}}}{\vanishS}\\\\\
    &= \frac{\beta \cdot \hat{f}(X) - \beta\cdot \sum_{j\in[\ell)} 2^j \cdot f_j(X) + \sum_{j\in[\ell)} \beta_j\cdot \term{N_j(X)}}{\vanishS}
\end{align}
If we try and compute $h(\omega^i)$ using the formula above, we will only succed for $i = 0$:
\begin{align}
\label{eq:h_omega_0}
h(\omega^0) &= \frac{\beta \cdot \left(r - \sum_{j\in[\ell)} 2^j \cdot r_j\right) + \sum_{j\in[\ell)} \beta_j\cdot r_j(r_j - 1)}{n+1}\\\\\
\end{align}

_Note:_ $\VS(X) \bydef 1 + X + X^2 + \ldots + X^n \Rightarrow \VS(\omega^0) = \VS(1) = n+1$.

Unfortunately, for $i\in[n]$, the formula yields 0/0.
But we can apply [differentiation tricks](/differentiation-tricks#interpolating-fxgx-in-lagrange-basis), which tell us that, $\forall i\in[n]$:
\begin{align}
\label{eq:h_omega_i}
h(\omega^i)
    &= \left.\frac{\beta \cdot \emph{\hat{f}'(X)} - \beta\cdot\sum_{j\in[\ell)} 2^j \cdot \emph{f_j'(X)} + \sum_{j\in[\ell)}\beta_j\cdot \emph{N_j'(X)}}{\emph{\left(\vanishS\right)'}}\right|_{X=\omega^i}
\end{align}

So, as long as we can evaluate the derivatives highlighted above efficiently, we can interpolate $h(X)$!

**Step 1:** The derivative of the denominator $\VS(X)$ can be evaluated as follows:
\begin{align}
(\VS(X))' = \left(\vanishS\right)'
    &= \frac{(X^{n+1} - 1)'(X-1) - (X-1)'(X^{n+1} - 1)}{(X-1)^2}\\\\\
    &= \frac{(n+1)X^n(X-1) - (X^{n+1} - 1)}{(X-1)^2}\\\\\
    %&= \frac{(n+\cancel{1})X^{n+1} - (n+1)X^n - (\cancel{X^{n+1}} - 1)}{(X-1)^2}\\\\\
    %&= \frac{nX^{n+1} - (n+1)X^n + 1}{(X-1)^2}\\\\\
\end{align}
Plugging in any root of unity $\omega^i\ne \omega^0$, we get:
\begin{align}
\emph{\left.\left(\vanishS\right)'\right|_{X=\omega^i}}
    &= \frac{(n+1)(\omega^i)^n(\omega^i-1) - (\overbrace{(\omega^i)^{n+1}}^{1} - 1)}{(\omega^i-1)^2}\\\\\
    &= \frac{(n+1)(\omega^i)^n(\omega^i-1)}{(\omega^i-1)^2}\\\\\
    &= \frac{(n+1)(\omega^i)^n}{\omega^i-1}\\\\\
    \label{eq:vanishSprime_0}
    &= \frac{(n+1)\omega^{-i}}{\omega^i-1} = \emph{\frac{n+1}{\omega^i(\omega^i - 1)}}\\\\\
    %&= \frac{-(n+1)(\omega^i)^n + 1}{(\omega^i-1)^2}\\\\\
    %&= \frac{-(n+1)\omega^{-i} + 1}{(\omega^i-1)^2}\\\\\
\end{align}

The expression above can only be used, and **need** only be used, to evaluate the derivative at $\omega^i$ when $i\ne0$.
In fact, the **inverses** of these evaluations should be **precomputed** during the setup!
(It is wiser to precompute the inverses so that we can evaluate Eq. \ref{eq:h_omega_i} without the need for a batch inversion.)

<!--Unfortunately, at $i=0$, we'd get a division by zero in Eq. \ref{eq:vanishSprime_0}.
Fortunately, we can use a different expression to deal with $i=0$.
\begin{align}
\label{eq:vs-of-one}
\vanishSfrac &= 1 + X + X^2 + \ldots + X^n\Rightarrow\\\\\
\left(\vanishSfrac\right)' &= 1 + 2X + 3X^2 + \ldots + nX^{n-1}\Rightarrow\\\\\
%=\sum_{k\in[1, n-1]} k X^{k-1}\Rightarrow\\\\\
\emph{\left.\left(\vanishS\right)'\right|_{X=\omega^0}} &= 1 + 2 + 3 + \ldots + n = \emph{\frac{n(n+1)}{2}}
\end{align}
This **inverted** evaluation should also be **precomputed!**-->

**Step 2:** The derivative of $\hat{f}(X)$ must be evaluated at all the roots of unity:
First, a size-$(n+1)$ inverse FFT can be used to get the coefficients $\term{\hat{f}\_i}$ of $\hat{f}(X)$ s.t.:
\begin{align}
\hat{f}(X) = \sum\_{i\in [n+1)} \hat{f}\_i \cdot X^i
\end{align}

Second, the derivative's coefficients can be computed in time $\Fmul{n}$ as:
\begin{align}
\hat{f}'(X) = \sum_{i\in [1, n+1)} i \cdot \hat{f}_i \cdot X^{i-1}
\end{align}

Third, a size-$(n+1)$ FFT can be used to compute all evaluations of $\hat{f}'(X)$ at the roots of unity:
\begin{align}
\hat{f}'(\omega^0), 
\hat{f}'(\omega^1), 
\ldots
\hat{f}'(\omega^n)
\end{align}

**Step 3:** The derivatives of $f_j(X)$ must be evaluated at all the roots of unity:

This can be done just like for $\hat{f}(X)$ in _Step 3_ above: an inverse FFT, a differentiation, followed by an FFT.

{: .warning}
We will compute each $f_j'(X)$ derivative _individually_, rather than compute one derivative for the $\sum_j 2^j\cdot f_j(X)$ polynomial.
This is because we will need the individual $f_j'(X)$ derivatives anyway in _Step 4_ below.

**Step 4:** The derivative of $N_j(X)$ must be evaluated at all the roots of unity:
Recall that:
\begin{align}
\emph{N_j(X)} 
    &\bydef f_j(X)(f_j(X) - 1)\Rightarrow\\\\\
\term{N_j'(X)}
    &= \left(f_j(X)(f_j(X) - 1)\right)'\Rightarrow\\\\\
    &= f_j(X)(f_j(X) - 1)' + f_j'(X)(f_j(X) - 1)\Rightarrow\\\\\
    &= f_j(X)f_j'(X) + f_j'(X)f_j(X) - f_j'(X)\Rightarrow\\\\\
    &= 2f_j(X)f_j'(X) - f_j'(X)\\\\\
    &= f_j'(X) \left[ 2f_j(X) - 1 \right]
\end{align}
Note that:
\begin{align}
\forall i \in [n],\ &f_j(\omega^i)\in\\{0,1\\}\Rightarrow\\\\\
\forall i \in [n],\ &2f_j(\omega^i) - 1\in \\{-1,1\\}\Rightarrow\\\\\
\forall i \in [n],\ &N_j'(\omega^i) = \pm f_j'(\omega^i)
\end{align}
As a result, computing  $N_j'(\omega^i)$ will cost **at most** $\Fadd{1}$.

### Time complexity

**tl;dr:** Time complexity is dominated by: $2(\ell+1)$ size-$(n+1)$ FFTs, $\Fmul{3\ell n}$ and $\Fadd{3\ell n}$.

To compute **all** $\hat{f}'(\omega^i)$'s and $f_j'(\omega^i)$'s:
 1. $\ell+1$ size-$(n+1)$ inverse FFT for the coefficients in monomial basis 
 2. $\Fmul{(\ell+1)n}$ for doing the differentiation on the coefficients
 3. $\ell+1$ size-$(n+1)$ FFT for the evaluations

Then, to compute **all** $N_j'(\omega^i)$'s, given the above:
 1. $\Fadd{\ell n}$

Then, to evaluate **all** $h(\omega^i)$'s, for $i\in[n]$, given the above:
 1. $\Fmul{(2\ell+2)n}$ as per Eq. \ref{eq:h_omega_i_expanded}
    + $\ell$ multiplications come from the first sum over $2^j\cdot f_j'$
    - 1 multiplication comes from multiplying by $\beta$
    + $\ell$ come from the second sum over $\beta_j\cdot (\pm f_j')$
    - 1 last multiplication from dividing by the precomputed inverted denominator
 1. $\Fadd{(2\ell+2)n}$
    + $\ell$ additions come from the first sum
    + $\ell$ additions come from the second sum
    - 2 additions come from adding everything in the numerator
 
Lastly, to evaluate $h(\omega^0)$, as per Eq. \ref{eq:h_omega_0}
 1. $\Fmul{3\ell+2}$
    + $\ell$ multiplications come from the first sum over $2^j\cdot r_j$
    - 1 multiplication comes from multiplying by $\beta$
    + $2\ell$ come from the second sum over $\beta_j\cdot r_j(r_j-1)$
    - 1 last multiplication from dividing by the precomputed inverted denominator
 1. $\Fadd{2\ell+2}$, just like with the $h(\omega^i)$'s

Note that, $\forall i\in[n]$ we can rewrite Eq. \ref{eq:h_omega_i} with the insights from above as:
\begin{align}
\label{eq:h_omega_i_expanded}
h(\omega^i) 
    &= \frac{\beta \cdot \emph{\hat{f}'(\omega^i)} - \beta\cdot\sum_{j\in[\ell)} 2^j \cdot \emph{f_j'(\omega^i)} + \sum_{j\in[\ell)}\beta_j\cdot \emph{N_j'(\omega^i)}}{\emph{(n+1)/(\omega^i(\omega^i-1))}}\\\\\
    &= \frac{\beta \left(\hat{f}'(\omega^i) - \sum_{j\in[\ell)} 2^j \cdot f_j'(\omega^i)\right) + \sum_{j\in[\ell)}\beta_j\cdot \emph{\left(\pm f_j'(\omega^i)\right)}}{(n+1)/(\omega^i(\omega^i-1))}\\\\\
\end{align}

{: .note}
Doing this $h(X)$ interpolation faster is an open problem, which is why in the paper we explore a multinear variant of DeKART[^BDFplus25e].

## Appendix: Computing $h(X)$ for $b\ne 2$

Recall that, when $b > 2$, the formula for $h(X)$ in Eq. \ref{eq:hx-njx} changes to:
\begin{align}
h(X)
    &= \frac{\beta \cdot \left(\hat{f}(X) - \sum_{j\in[\ell)} \emph{b}^j \cdot f_j(X)\right) + \sum_{j\in[\ell)} \beta_j\cdot f_j(X)(f_j(X) - 1)\emph{\ldots(f_j(X) - (b-1))}}{\VS(X)}\\\\\
    &= \frac{\beta \cdot \left(\hat{f}(X) - \sum_{j\in[\ell)} b^j \cdot f_j(X)\right) + \sum_{j\in[\ell)} \beta_j\cdot \overbrace{f_j(X)(f_j(X) - 1)\ldots(f_j(X) - (b-1))}^{\bydef \term{N_j(X)}}}{\vanishS}\\\\\
    &= \frac{\beta \cdot \left(\hat{f}(X) - \sum_{j\in[\ell)} b^j \cdot f_j(X)\right) + \sum_{j\in[\ell)} \beta_j\cdot \term{N_j(X)}}{\vanishS}
\end{align}

As a result, the degree of $N_j(X)$ is $bn$.
Thus, the degree of $h(X)$ becomes $(b-1)n$ 

So, to interpolate $h(X)$, we would have to evaluate it over the larger size-$L$ domain $\L$ (instead of the size-$(n+1)$ domain $\S$ used in Eq. \ref{eq:h_omega_i}).

Our **new challenge** is that the 0/0 trick used before, when $b=2$, will no longer apply here: some of the $\zeta^i\in\L$ will not necessarily fall in the $h(\zeta^i) = 0/0$ case, while others will.

{: .todo}
Our approach will have two parts.
First, we'll use similar differentiation tricks as in the $b=2$ case to compute $h(\zeta^i)$ for $i$'s that give us 0/0.
Then, we'll re-use the coefficient form of the $\hat{f}$ and $f_j$ polynomials from the first part and do size-$L$ FFTs to get the $\hat{f}(\zeta^i)$ and $f_j(\zeta^i)$ evaluations that do not give us division by 0 errors.

## References

[^power-of-two-n]: To use DeKART for non-powers of two $n$'s, just run the $\dekartSetup$ algorithm with the smallest $n' > n$ such that $n'$ is a power of two. Then, run the $\dekartProve$ algorithm with a vector of $n'$ values such that (1) the first $n$ values are the values you want to prove and (2) the last $n'-n$ values are set to zero.
[^pr1]: Pull request: [Add univariate DeKART range proof](https://github.com/aptos-labs/aptos-core/pull/17531/files)
[^Borg20]: [Membership proofs from polynomial commitments](https://solvable.group/posts/membership-proofs-from-polynomial-commitments/), William Borgeaud, 2020

For cited works, see below 👇👇

{% include refs.md %}
