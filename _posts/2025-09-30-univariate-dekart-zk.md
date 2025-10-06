---
tags:
title: "Draft: DeKART: ZK range proofs from univariate polynomials"
#date: 2020-11-05 20:45:59
permalink: dekart
published: false
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** We fix up our previous [non-ZK, univariate DeKART](/dekart-not-zk) scheme and also speed up its verifier by trading off prover time.

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
\def\vanishS{\frac{X^{n+1} - 1}{X - 1}}
%
\def\L{\mathbb{L}}
\def\lagrL{\mathcal{L}}
\def\lOne#1{\crs{\one{\lagrL_{#1}(\tau)}}}
\def\VL{V^*_\L}
\def\vanishL{\frac{X^L - 1}{X - 1}}
%
\def\bkzgSetup{\mathsf{BKZG.Setup}}
\def\bkzgCommit{\mathsf{BKZG.Commit}}
\def\bkzgOpen{\mathsf{BKZG.Open}}
\def\bkzgVerify{\mathsf{BKZG.Verify}}
%
\def\piPok{\pi_\mathsf{PoK}}
\def\zkpokProve{\Sigma_\mathsf{PoK}.\mathsf{Prove}}
\def\zkpokVerify{\Sigma_\mathsf{PoK}.\mathsf{Verify}}
\def\relPok{\mathcal{R}_\mathsf{pok}}
$</div> <!-- $ -->

## Preliminaries

The notation for this blog post is [the same as in the old post](/dekart-not-zk#preliminaries).

{% include pairings-prelims.md %}
{% include time-complexities-prelims-pairings.md %}

### ZKPoKs

We assume a ZK PoK for the following relation:
\begin{align}
\term{\relPok}(X, X_1, X_2; w_1, w_2) = 1 \Leftrightarrow X = w_1 \cdot X_1 + w_2 \cdot X_2 
\end{align}

{: .todo}
What kind of soundness assumption do we need?
Define $\zkpokProve$ and $\zkpokVerify$.

### Hiding KZG 

This **hiding** [KZG](/kzg) variant was (first?) introduced in the Zeromorph paper[^KT23e].

#### $\bkzgSetup(m; \mathcal{G}, \xi, \tau) \rightarrow (\vk,\ck)$

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

_Note:_ We assume the the bilinear group $\mathcal{G}$ is implicitly part of the VK and CK above.

#### $\bkzgCommit(\ck, f; \rho) \rightarrow C$

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

#### $\bkzgOpen(\ck, f, \rho, x; s) \rightarrow \pi$

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
    &\bydef \bkzgCommit\left(\ck, \frac{f(X) - f(x)}{(X - x)}; s\right)
\end{align}

{: .note}
When $x\notin \mathbb{H}$, we can evaluate $f(x)$ in $\Fmul{n}$ operations given the $f(\theta^i)$'s via [the Barycentric formula](/lagrange-interpolation#barycentric-formula) and create the proof via Eq. \ref{eq:kzg-pi-1}.
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

#### $\bkzgVerify(\vk, C, x, y; \pi) \rightarrow \\{0,1\\}$

Parse the verification key:
\begin{align}
    \left(\xiTwo, \tauTwo\right) \parse \vk
\end{align}

Parse the proof $(\pi_1,\pi_2)\parse\pi$ and assert that:
\begin{align}
    e(C - \one{y}, \two{1}) \equals e(\pi_1, \tauTwo - \two{x}) + e(\pi_2,\xiTwo)
\end{align}

#### Correctness of openings

Correctness holds since, assuming that $C \bydef \bkzgCommit(\ck, f; \rho)$ and $\pi \bydef \bkzgOpen(\ck, f, \rho, x; s)$, then the paring check in $\bkzgVerify(\ck, C, x, f(x); \pi)$ is equivalent to:
\begin{align}
    e(\bluebox{\rho\cdot\xiOne} + \one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \pair{s \cdot \xiOne + \one{\frac{f(\tau) - f(x)}{\tau - x}}}{ \tauTwo - \two{x}} + e(\bluebox{\one{\rho}}-s\cdot(\tauOne-\one{x}),\bluebox{\xiTwo})\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \pair{s \cdot \xiOne + \one{\frac{f(\tau) - f(x)}{\tau - x}}}{ \tauTwo - \two{x}} - e(s\cdot(\tauOne-\one{x}), \xiTwo)\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \pair{\one{\frac{f(\tau) - f(x)}{\tau - x}}}{ \tauTwo - \two{x}} + \bluedashedbox{\pair{s\cdot\xiOne}{\tauTwo - \two{x}}} - \bluedashedbox{e(s\cdot(\tauOne-\one{x}), \xiTwo)}\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\equals \pair{\one{\frac{f(\tau) - f(x)}{\tau - x}}}{ \tauTwo - \two{x}}\Leftrightarrow\\\\\
    e(\one{f(\tau)} - \one{f(x)}, \two{1}) &\stackrel{!}{=} \pair{\one{f(\tau) - f(x)}}{\two{1}}\\\\\
\end{align}

## The scheme

A few notes:
 - Values are represented in **radix $\term{b}$**
    - e.g., $\term{z_{i,j}}\in[b)$ denotes the $j$th **chunk** of $z_i \bydef \sum_{j\in[\ell)} \emph{z_{i,j}} \cdot b^{j}$ 
 - The goal is to prove that each value $z_i \in [b^\ell)$ by exhibiting a valid **radix-$b$ decomposition** as shown above
    + $\term{\ell}$ is the number of chunks ($z_{i,j}$'s) in this decomposition
 - We will have $\term{n}$ values we want to prove ($z_i$'s)
 - The degrees of committed polynomials will be either $n$ or $(b-1)n$

<!--  We will work with two kinds of vanishing polynomials:
     $\term{\VL(X)}\bydef \vanishL$ of degree $\term{L}-1 \bydef \emph{b(n+1)} - 1$ -->

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Setup}(b, n; \mathcal{G})\rightarrow \mathsf{prk},\mathsf{vk}$

{: .todo}
Should we use $b_\max$ and $n_\max$ here?
If we do, then this setup should output just powers-of-$\tau$ of max degree $L-1 = b(n+1) - 1$ instead of Lagrange commitments.
Then, a $\dekart.\mathsf{Specialize}$ algorithm can be used to get a CRS for a specific $n = 2^c$ or even non-power of two?
This would actually be informative and nice to deal with, notationally.

Assume $n=2^c$ for some $c\in\N$[^power-of-two-n] and let $\term{L} \bydef b(n+1) = 2^{d}$, for some $d\in\N$.

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
(\term{\vk}, \term{\ck_\S}) \gets \bkzgSetup(n+1; \mathcal{G}, \xi, \tau)
\end{align}
where:
 + $\term{\S}\bydef\\{\omega^0,\omega^1,\ldots,\omega^{\emph{n}}\\}$
 + $\term{\omega}$ is a primitive $(n+1)$th root of unity in $\F$
 - $\term{\lagrS_i(X)} \bydef \prod_{j\in\S, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}, \forall i\in[0,n]$
 + $\term{\VS(X)}\bydef \vanishS$ is a vanishing polynomial of degree $n$ whose $n$ roots are in $\S\setminus\\{\omega^0\\}$ 
 - $\vk \bydef \left(\xiTwo, \tauTwo\right)$, as per [$\bkzgSetup(\cdot)$](#bkzgsetupm-mathcalg-xi-tau-rightarrow-vkck)

Compute KZG public parameters, reusing the same $(\xi,\tau)$, for committing to polynomials interpolated from $L$ evaluations:
\begin{align}
(\cdot, \term{\ck_\L}) \gets \bkzgSetup(L; \mathcal{G}, \xi, \tau)
\end{align}
where:
 + $\term{\L}\bydef\\{\zeta^0,\zeta^1,\ldots,\zeta^{\emph{L-1}}\\}$
 + $\term{\zeta}$ is a primitive $L$th root of unity in $\F$
 - $\term{\lagrL_i(X)} \bydef \prod_{j\in\L, j\ne i} \frac{X - \zeta^j}{\zeta^i - \zeta^j}, \forall i\in[L)$

_Note:_ The [Lagrange polynomial](/lagrange-interpolation) $\lagrS_i(X)$ is of degree $n$, while $\lagrL_i(X)$ is of degree $L-1$.

Compute the range proof's proving key:
\begin{align}
\term{\prk}\gets \left(\vk, \ck_\S, \ck_\L\right)
\end{align}

{: .note}
When $b=2$, we will be able to simplify by letting $L = n+1$ and thus $\S = \L$ and $\ck_\L = \ck_\S$.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Commit}(\ck_\S,z_1,\ldots,z_{n}; \rho)\rightarrow C$

Parse the commitment key:
\begin{align}
    \left(\xiOne, \tauOne, \left(\sOne{i}\right)\_{i\in[0,n]}\right) \parse\ck_\S
\end{align}

Represent the $n$ values and a prepended $0$ value as a degree-$n$ polynomial:
\begin{align}
\term{f(X)} \bydef 0\cdot \lagrS_0(X) + \sum_{i\in[n]} z_i \cdot \lagrS_i(X)
\end{align}

Commit to the polynomial via [hiding KZG](#hiding-kzg):
\begin{align}
\term{\rho} &\randget \F\\\\\
C &\gets \bkzgCommit(\ck_\S, f; \rho) \bydef \rho \cdot \xiOne + \one{f(\tau)} = \rho\cdot \xiOne + \sum_{i\in[n]} z_i \cdot \sOne{i}
\end{align}

{: .note}
Note that $f(\omega^i) = z_i,\forall i\in[n]$ but the $f(\omega^0)$ evaluation is set to zero.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, C, \ell; z_1,\ldots,z_{n}, \rho)\rightarrow \pi$


**Step 1**a**:** Parse the public parameters:
\begin{align}
 \left(\vk, \ck_\S, \ck_\L\right)\parse \prk\\\\\
 \left(\xiOne, \tauOne, \left(\sOne{i}\right)\_{i\in[0,n]}\right) \parse \ck_\S\\\\\
 \left(\xiOne, \tauOne, \left(\lOne{i}\right)\_{i\in[L)}\right)\parse \ck_\L
\end{align}

**Step 1**b**:** Add $(\vk, C, \ell)$ to the $\FS$ transcript.

**Step 2**a**:** Re-randomize the commitment $C\bydef \rho\cdot \xiOne+\one{f(\tau)}$ **and** mask the degree-$n$ committed polynomial $f(X)$:
\begin{align}
\term{r}, \term{\Delta{\rho}} &\randget \F\\\\\
\term{\hat{f}(X)} &\bydef r \cdot \lagrS_0(X) + \emph{f(X)}\\\\\
\term{\hat{C}} &\gets \Delta{\rho} \cdot \xiOne + r\cdot \sOne{0} + \emph{C}\\\\\
               &\bydef \bkzgCommit(\ck_\S, \hat{f}; \rho + \Delta{\rho})
\end{align}

**Step 2**b**:** Add $\hat{C}$ to the $\FS$ transcript.

**Step 3:** Prove knowledge of $r$ and $\Delta{\rho}$ such that $\hat{C} - C = \Delta{\rho} \cdot \xiOne + r\cdot \sOne{0}$.
\begin{align}
    \term{\piPok} \gets \zkpokProve^\FSo\left(\underbrace{(\hat{C}-C, \xiOne, \sOne{0})}\_{\text{statement}}; \underbrace{(\Delta{\rho}, r)}\_{\text{witness}}\right)
\end{align}

{: .todo}
Say this was a $\Sigma$-protocol. Do we add the final proof to the transcript too?
It feels like we should add at least the final message from the prover to the transcript. 
So we could do that implicitly by (redundantly) adding the whole proof.

**Step 4**a**:** Represent all $j$th chunks $(z_{1,j},\ldots,z_{n,j})$ as a degree-$n$ polynomial and commit to it:
\begin{align}
\term{r\_j}, \term{\rho\_j} &\randget \F\\\\\
\term{f\_j(X)} &\bydef r\_j \cdot \lagrS_0(X) + \sum\_{i\in[n]} z\_{i,j}\cdot \lagrS_i(X)\\\\\
\term{C\_j} &\gets \rho_j \cdot \xiOne + r\_j\cdot \sOne{0} + \sum\_{i\in[n]} z\_{i,j}\cdot \sOne{i}\\\\\
            &\bydef \bkzgCommit(\ck\_\S, f\_j; \rho\_j)
\end{align}

**Step 4**b**:** Add $(C\_j)\_{j\in[\ell)}$ to the $\FS$ transcript.

**Step 5**a**:** For each $j\in[\ell)$, define a quotient polynomial, whose existence would show that, $\forall i\in[n]$, $f_j(\omega^i) \in [b)$:
\begin{align}
\forall j\in[\ell), \term{h_j(X)}
    &\bydef \frac{f_j(X)(f_j(X) - 1) \cdots \left(f_j(X) - (b-1)\right)}{\VS(X)}\\\\\
\end{align}

*Note:* Numerator is degree $bn$ and denominator is degree $n \Rightarrow h_j(X)$ is degree $(b-1)n$

**Step 5**b**:** Define a(nother) quotient polynomial, whose existence would show that, $\forall i\in[n]$, $\hat{f}(\omega^i) = \sum_{j\in[\ell)} 2^j \cdot f_j(\omega^i)$:
\begin{align}
\term{g(X)}
    &\bydef \frac{\hat{f}(X) - \sum_{j\in[\ell)} 2^j \cdot f_j(X)}{\VS(X)}\\\\\
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
h(X) \cdot \VS(X) \equals \beta \cdot \left(\hat{f}(X) - \sum_{j\in[\ell)} 2^j \cdot f_j(X)\right) + \sum_{j\in[\ell)} \beta_j\cdot f_j(X)(f_j(X) - 1) \cdots \left(f_j(X) - (b-1)\right)\\\\\
\end{align}


**Step 7**a**:** Commit to $h(X)$, of degree $(b-1)n$, by interpolating it over the larger $\L$ domain:
\begin{align}
\label{eq:D}
\term{\rho_h} &\randget \F\\\\\
\term{D} &\gets \rho_h\cdot \xiOne + \sum\_{i\in[L)} h(\zeta^i) \cdot \lOne{i}\\\\\
    &\bydef \bkzgCommit(\ck_\L, h; \rho_h)
\end{align}

_Note:_ We discuss [how to interpolate $h(\zeta^i)$'s efficiently](#appendix-computing-hx) in the appendix.

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
    \term{\gamma} &\fsget \F\\\\\
    \term{a} &\gets \hat{f}(\gamma)\\\\\
    \term{a\_h} &\gets h(\gamma)\\\\\
    \term{a\_j} &\gets f\_j(\gamma),\forall j\in[\ell)\\\\\
\end{align}

**Step 7:** We compute a hiding KZG opening proof for $u(\gamma)$:
\begin{align}
    \term{s} &\randget \F\\\\\
    \term{\pi_\gamma} &\gets \bkzgOpen(\ck_\L, u, \term{\rho_u}, \gamma; s)
\end{align}
where $\emph{\rho_u} \bydef \mu \cdot (\rho + \Delta{\rho}) + \mu_h \cdot \rho_h + \sum_{j\in[\ell)} \mu_j\cdot \rho_j$ is the blinding factor for the implicit commitment to $u(X)$, which the prover need not compute: 
\begin{align}
\term{U} 
    &\bydef \mu \cdot \hat{C} + \mu_h \cdot D + \sum_{j\in[\ell)} \mu_j\cdot C_j\\\\\
    &\bydef \bkzgCommit(\ck\_\L, u; \rho\_u)
\end{align}

{: .todo}
Evaluating $u(\zeta^i),i\in[L)$ requires evaluating all $f_j(\zeta^i)$'s, which we do not have; we only have $f_j(\omega^i)$'s.
So, for each $j\in[\ell)$, this would reuse the size-$(n+1)$ inverse FFT over $\S$ to get $f_j$'s coefficients from the [$h(X)$ computation](#appendix-computing-hx), but would add 1 size-$L$ FFT on $\sum_j \mu_j f_j(X)$ over $\L$ to get the extra evaluations at the $\zeta^i$'s.

Return the proof $\pi$:
\begin{align}
\term{\pi}\gets \left(\hat{C}, \piPok, (C\_j)\_{j\in[\ell)}, D, a, a_h, (a\_j)\_{j\in[\ell)}, \pi\_\gamma\right)
\end{align}

#### Proof size and prover time

**Proof size**:
 - $(\ell+2)\Gr_1$ for the $\hat{C}$, $C\_j$'s and $D$
 - $2$ $\Gr_1$ for $\pi\_\gamma$
 - **TODO:** $\|\piPok\|$
 - $(\ell+2)\F$ for $a, a_h$ and the $a_j$'s (i.e., for $\hat{f}(\gamma), h(\gamma)$, and the $f_j(\gamma)$'s)

**TODO:** **Prover time** is dominated by:

 - $\GaddOne{\ell n}$ for all $C_j$'s
    + Assuming precomputed $2\cdot \sOne{i}, \ldots, (b-1)\cdot \sOne{i},\forall i\in[n]$
    - i.e., one for each possible chunk value in $[b)$
 - $1$ $\fmsmOne{2}$ MSM to blind $\hat{C}$ with $\rho$ and $\Delta{r}$
 - $(\ell+1)$ $\fmsmOne{2}$ MSMs to blind all $C_j$'s with $r_j$ and $\rho_j$
 - **TODO:** time for $\zkpokProve$
 - $\Fmul{O(\ell L\log{L})}$ to interpolate $h(X)$, where $L\bydef bn$
    + See [more fine-grained break down here](#time-complexity).
    + **TODO: more precise?**
 - 1 $\fmsmOne{L+1}$ MSM for committing to $h(X)$
 - $\Fmul{O(n)}$ to interpolate $\hat{f}(\gamma)$ and $f_j(\gamma)$ evals via [the Barycentric formula](/lagrange-interpolation#barycentric-formula)
    + $h(\gamma)$ can be evaluated directly via Eq. \ref{eq:hx}
    + **TODO: more precise?**
 - 1 $\fmsmOne{L+1}$ MSM for computing $\pi_\gamma$ via [$\bkzgOpen(\cdot)$](#bkzgopenck-f-rho-x-s-rightarrow-pi)

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Verify}^{\mathcal{FS}(\cdot)}(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

{: .todo}
$b$ should be an input here
Checked for being smaller than in the setup.(Or just check that $b$ and $n$ "match" $L$? Could we allow for larger $b$ while shrinking $n$?)
Added to the FS transcript.

**Step 1:** Parse the $\vk$ and the proof $\pi$:
\begin{align}
\left(b, \xiTwo, \tauTwo,\right) &\parse \vk\\\\\
\left(\hat{C}, \piPok, (C_j)_{j\in[\ell)}, D, a, a_h, (a\_{j})\_{j\in[\ell)}, \pi\_\gamma\right) &\parse \pi
\end{align}
 
**Step 2**a**:** Add $(\vk, C, \ell)$ to the $\FS$ transcript.

**Step 2**b**:** Add $(\hat{C})$ to the $\FS$ transcript.

**Step 2**c**:** Add $((C_j)_{j\in[\ell})$ to the $\FS$ transcript.
 
**Step 3:** Generate (pseudo)random challenges for combing the quotient polynomials:
\begin{align}
\beta,\beta_0,\ldots,\beta_{\ell-1} &\fsget \\{0,1\\}^\lambda
\end{align}
 
**Step 4:** Add $D$ to the $\FS$ transcript.
 
**Step 5:** Generate (pseudo)random challenges for the batch KZG opening on $\hat{f}(X), h(X)$ and the $f_j(X)$'s:
\begin{align}
\mu,\mu_h,\mu_0,\ldots,\mu_{\ell-1}\fsget \\{0,1\\}^\lambda
\end{align}

**Step 6:** Reconstruct the commitment to $u(X)$ from Eq. \ref{eq:ux} 
\begin{align}
\term{U} \gets \mu\cdot \hat{C} + \mu_h\cdot D + \sum\_{j\in[\ell)} \mu_j \cdot C_j
\end{align}

**Step 7:** Generate a (pseudo)random evaluation point for the batch KZG opening:
\begin{align}
\gamma \fsget \F
\end{align}

**Step 8:** Verify that $a \equals \hat{f}(\gamma$), $a_h \equals h(\gamma)$ and $a_j \equals f_j(\gamma),\forall j\in[\ell)$:
\begin{align}
\label{eq:kzg-batch-verify}
\term{a_u} &\gets \mu \cdot a + \mu_h \cdot a_h + \sum_{j\in[\ell)} \mu_j\cdot a_j\\\\\
\textbf{assert}\ &\bkzgVerify(\vk, U, \gamma, a_u; \pi_\gamma) \equals 1 
\end{align}

**Step 9:** Make sure that the radix-$b$ representation holds and that chunks are $<b$ as per Eq. \ref{eq:hx-check}:
\begin{align}
\textbf{assert}\ h(\gamma) \cdot \VS(\gamma) &\equals \beta \cdot \left(\hat{f}(\gamma) - \sum\_{j\in[\ell)} 2^j \cdot f\_j(\gamma)\right) + \sum\_{j\in[\ell)} \beta\_j\cdot f\_j(\gamma)(f\_j(\gamma) - 1) \cdots (f\_j(\gamma)- (b-1))\Leftrightarrow\\\\\
\Leftrightarrow \textbf{assert}\ a\_h \cdot \VS(\gamma) &\equals \beta \cdot \left(a - \sum\_{j\in[\ell)} 2^j \cdot a\_j\right) + \sum\_{j\in[\ell)} \beta\_j\cdot a\_j(a\_j - 1) \cdots (a\_j - (b-1))
\end{align}

#### Verifier time

The verifier work is dominated by:

 - 1 $\vmsmOne{\ell+2}$ MSM for $U$
 - $\GmulOne{1} + \GaddOne{1}$ for computing $\one{\tau - a_u}$ inside [$\bkzgVerify(\cdot)$](#bkzgverifyvk-c-x-y-pi-rightarrow-01)
 - $\GmulTwo{1} + \GaddTwo{1}$ for computing $\two{\tau - \gamma}$ inside $\bkzgVerify(\cdot)$
 - size-$3$ multipairing for the rest of $\bkzgVerify(\cdot)$
 - $\Fmul{\ell+2}$ for computing $a_u$ 
 - $\Fmul{1 + (\ell+1) + \ell(b+1)}$ for the final check

## Conclusion

Your thoughts or comments are welcome on [this thread](https://x.com/alinush407/status/1950600327066980693).

## Appendix: Computing $h(X)$

{: .todo}
Uncomment and edit.

<!--
{: .note}
This assumes $b=2$ but we will generalize it to any $b$ later.

We borrow [differentiation tricks](/differentiation-tricks) from [Groth16](/groth16#computing-hx) to ensure we only do size-$L$ FFTs.
(Otherwise, we'd have to use size-$2N$ FFTs to compute the $\ell$ different $f_j(X)(f_j(X) - 1)\cdots(f_j(X) - (b-1))$ multiplications.)

Our goal will be to obtain all $(h(\zeta^i))_{i\in[L)}$ evaluations and then do a size-$L$ L-MSM to commit to it and obtain $\emph{D}$ from Eq: \ref{eq:D}.

Recall that:
\begin{align}
h(X)
    &= \frac{\sum_{j\in[\ell)}\beta_j \cdot \overbrace{(X-\omega^n)f_j(X)(f_j(X) - 1)\cdots(f_j(X)-(b-1))}^{\term{N_j(X)}}}{X^{n+1} - 1}
    \\\\\
    &\bydef \frac{\sum_{j\in[\ell)} \beta_j \cdot \emph{N_j(X)}}{X^{n+1} - 1}
\Leftrightarrow\\\\\
\Leftrightarrow
h(X) (X^{n+1} - 1)
    &=
\sum_{j\in[\ell)} \beta_j \cdot N_j(X)
\end{align}
Differentiating the above expression:
\begin{align}
h'(X)(X^{n+1} - 1) + h(X) (n+1)X^n &= \sum_{j\in[\ell)} \beta_j \cdot N_j'(X)\Leftrightarrow\\\\\
\Leftrightarrow
h(X) &= \frac{\sum_{j\in[\ell)} \beta_j \cdot N_j'(X) - h'(X)(X^{n+1} - 1)}{(n+1)X^n}
\end{align}
**Problem:** While this would reduce computing all $h(\omega^i)$'s, $i\in[n)$, to computing all $N_j'(\omega^i)$'s:
\begin{align}
\label{eq:h}
\emph{h(\omega^i)} &= \frac{\sum_{j\in[\ell)} \beta_j \cdot N_j'(\omega^i)}{(n+1)\omega^{in}}
\end{align}
...it does **not** necessarily help with computing all $h(\zeta^i)$'s for $i\in[L)$.

Depending on how $\zeta$ is related to $\omega$, not all hope may be lost.
Obviously, if $\zeta = \omega$ and $L = n$, we are in the previous case.
But $L = b(n+1)$ for $b \ge 2$.

### Time complexity

To compute all $f_j'(\omega^i)$'s for a single $j$:
 1. 1 size-$(n+1)$ inverse FFT, for $f_j$'s coefficients in monomial basis 
 2. $n$ $\F$ multiplications, for the coefficients of the derivative $f_j'$
 3. 1 size-$(n+1)$ FFT, for all $f_j'(\omega^i)$'s.

Then, to compute all $N_j'(\omega^i)$'s for a single $j$:
 4. $2n+1$ $\F$ multiplications, for all $N'_j(\omega^i)$'s as per Eq. \ref{eq:nj-prime}
    + (Assuming all $\pm (\omega^i - \omega^n)$ are precomputed.)

{: .note}
All the numbers above get multipled by $\ell$, since we are doing this for every $j\in[\ell)$.

Lastly, to compute all the $h(\omega^i)$'s, we do:
 5. $\ell n$ $\F$ multiplications to compute the $n$ different numerators from Eq. \ref{eq:h}, one for each evaluation $h(\omega^i)$
 6. $n$ $\F$ multiplications, to divide the $n$ numerators by (the precomputed) $(n+1)\omega^{-in}$'s

{: .note}
Doing this $h(X)$ interpolation faster is an open problem, which is why in the paper we explore a multinear variant of DeKART[^BDFplus25e].
-->

## References

[^power-of-two-n]: To use DeKART for non-powers of two $n$'s, just run the $\dekartSetup$ algorithm with the smallest $n' > n$ such that $n'$ is a power of two. Then, run the $\dekartProve$ algorithm with a vector of $n'$ values such that (1) the first $n$ values are the values you want to prove and (2) the last $n'-n$ values are set to zero.
[^pr1]: Pull request: [Add univariate DeKART range proof](https://github.com/aptos-labs/aptos-core/pull/17531/files)
[^Borg20]: [Membership proofs from polynomial commitments](https://solvable.group/posts/membership-proofs-from-polynomial-commitments/), William Borgeaud, 2020

For cited works, see below 👇👇

{% include refs.md %}
