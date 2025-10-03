---
tags:
title: "DeKART: ZK range proofs from univariate polynomials"
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

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\crs#1{\textcolor{green}{#1}}
\def\tauOne{\crs{\one{\tau}}}
\def\tauTwo{\crs{\two{\tau}}}
%
\def\dekart{\mathsf{DeKART}}
\def\dekartUni{\dekart^\mathsf{FFT}}
\def\dekartSetup{\dekart.\mathsf{Setup}}
\def\dekartProve{\dekart.\mathsf{Prove}}
%
\def\bad#1{\textcolor{red}{\text{#1}}}
\def\good#1{\textcolor{green}{\text{#1}}}
%
\def\crsH{\crs{H}}
%
\def\S{\mathbb{S}}
\def\lagrS{\mathcal{S}}
\def\sOne#1{\crs{\one{\lagrS_{#1}(\tau)}}}
\def\VS{V^*_\S}
\def\vanishS{\frac{X^{n+1} - 1}{X - 1}}
\def\vanishSTwo{\crs{\two{\frac{\tau^{n+1} - 1}{\tau-1}}}}
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

### ZKPoKs

We assume a ZK PoK for the following relation:
\begin{align}
\term{\relPok}(X, X_1, X_2; w_1, w_2) = 1 \Leftrightarrow X = w_1 \cdot X_1 + w_2 \cdot X_2 
\end{align}

{: .todo}
What kind of soundness assumption do we need?
Define $\zkpokProve$ and $\zkpokVerify$.

### Blinded KZG 

#### $\bkzgSetup(1^\lambda, d) \rightarrow (\vk,\ck)$

{: .todo}
Pick root of unity.
Define Lagrange polys here instead of the DeKART setup.

#### $\bkzgCommit(\ck, f; \rho) \rightarrow C$

Parse the commitment key:
\begin{align}
    \left(\crsH, \left(\crs{\one{\lagr_i(\tau)}}\right)\_{i\in[m)}\right) \parse\ck
\end{align}

Commit to $f$, but additively blind by $\rho\cdot \crsH$:
\begin{align}
C &\gets   \rho \cdot \crsH + \sum_{i\in[m)} z_i \cdot \crs{\one{\lagr_i(\tau)}}
    \bydef \rho \cdot \crsH + \one{f(\tau)} 
\end{align}

{: .todo}
Explain that it commits as $\one{f(\tau)} + \rho\cdot \crsH$, for $\rho\randget\F$. 
Explain how it opens since it's a bit different.

## The scheme

A few notes:
 - Values are represented in **radix $\term{b}$**
    - e.g., $\term{z_{i,j}}\in[b)$ denotes the $j$th **chunk** of $z_i \bydef \sum_{j\in[\ell)} \emph{z_{i,j}} \cdot b^{j}$ 
 - The goal is to prove that each value $z_i \in [b^\ell)$ by exhibiting a valid **radix-$b$ decomposition** as shown above
    + $\term{\ell}$ is the number of chunks ($z_{i,j}$'s) in this decomposition
 - We will have $\term{n}$ values we want to prove ($z_i$'s)
 - The degrees of committed polynomials will be either $n$ or $(b-1)n$
 - We will work with two kinds of vanishing polynomials:
    + $\term{\VS(X)}\bydef \vanishS$ of degree $n$
    + $\term{\VL(X)}\bydef \vanishL$ of degree $\term{L}-1 \bydef \emph{b(n+1)} - 1$

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Setup}(1^\lambda, b, n)\rightarrow \mathsf{prk},\mathsf{vk}$

{: .todo}
Should we use $b_\max$ and $n_\max$ here?
If we do, then this setup should output just powers-of-$\tau$ of max degree $L-1 = b(n+1) - 1$ instead of Lagrange commitments.
Then, a $\dekart.\mathsf{Specialize}$ algorithm can be used to get a CRS for a specific $n = 2^c$ or even non-power of two?
This would actually be informative and nice to deal with, notationally.

Assume $n=2^c$ for some $c\in\N$[^power-of-two-n] and let:

 - $\term{\S}\bydef\\{\omega^0,\omega^1,\ldots,\omega^{\emph{n}}\\}$, where $\term{\omega}$ is a primitive $(n+1)$th root of unity in $\F$
 - $\term{L} \bydef b(n+1) = 2^{d}$, for some $d\in\N$
 - $\term{\L}\bydef\\{\zeta^0,\zeta^1,\ldots,\zeta^{\emph{L-1}}\\}$, where $\term{\zeta}$ is a primitive $L$th root of unity in $\F$

{: .note}
For efficiency, we restrict ourselves to $(n+1)$ and $b$ that are powers of two, so that $L \bydef b(n+1)$ is a power of two as well.
Ideally though, since the highest-degree polynomial involved in our scheme is $(b-1)n$, we could have used a smaller $L = (b-1)n + 1$ $= bn - (n - 1)$.
But this $L$ may not be a power of two, which means FFTs would be trickier.

Define the $i$th [Lagrange polynomials](/lagrange-interpolation) w.r.t. the $\S$ and $\L$ domains:
 - $\forall i\in[0,n], \term{\lagrS_i(X)} \bydef \prod_{j\in\S, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}$ of degree $n$ 
 - $\forall i\in[L), \term{\lagrL_i(X)} \bydef \prod_{j\in\L, j\ne i} \frac{X - \zeta^j}{\zeta^i - \zeta^j}$ of degree $L-1$

Return the public parameters:
 - $\term{\tau}\randget\F$
 - $\term{\crsH}\randget \Gr_1$
 - $\vk\gets \left(b, \crsH, \tauTwo,\vanishSTwo\right)$
 - $\ck_\S \gets \left(\crsH, \left(\sOne{i}\right)\_{i\in[0,n]}\right)$
 - $\ck_\L \gets \left(\crsH, \left(\lOne{i}\right)\_{i\in[L)}\right)$
 - $\prk\gets \left(\vk, \ck_\S, \ck_\L\right)$

{: .note}
When $b=2$, we will be able to simplify by letting $L = n+1$ and $\S = \L$.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Commit}(\ck_\S,z_1,\ldots,z_{n}; \rho)\rightarrow C$

Parse the commitment key:
\begin{align}
    \left(\crsH, \left(\sOne{i}\right)\_{i\in[0,n]}\right) \parse\ck_\S
\end{align}

<!-- $\term{\vec{z}}\bydef[0, z_1,\ldots,z_{n}]$: -->
Represent the $n$ values and a prepended $0$ value as a degree-$n$ polynomial:
\begin{align}
\term{f(X)} \bydef 0\cdot \lagrS_0(X) + \sum_{i\in[n]} z_i \cdot \lagrS_i(X)
\end{align}

Commit to the polynomial via [blinded KZG](#blinded-kzg):
\begin{align}
\term{\rho} &\randget \F\\\\\
C &\gets \bkzgCommit(\ck_\S, f; \rho) \bydef \rho \cdot \crsH + \one{f(\tau)} = \rho\cdot \crsH + \sum_{i\in[n]} z_i \cdot \sOne{i}
\end{align}

{: .note}
Note that $f(\omega^i) = z_i,\forall i\in[n]$ but the $f(\omega^0)$ evaluation is set to zero.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, C, \ell; z_1,\ldots,z_{n}, \rho)\rightarrow \pi$


**Step 1**a**:** Parse the public parameters:
\begin{align}
 \left(\vk, \ck_\S, \ck_\L\right)\parse \prk\\\\\
 \left(\crsH, \left(\sOne{i}\right)\_{i\in[0,n]}\right) \parse \ck_\S\\\\\
 \left(\crsH, \left(\lOne{i}\right)\_{i\in[L)}\right)\parse \ck_\L
\end{align}

**Step 1**b**:** Add $(\vk, C, \ell)$ to the $\FS$ transcript.

**Step 2**a**:** Re-randomize the commitment $C\bydef \rho\cdot \crsH+\one{f(\tau)}$ **and** mask the degree-$n$ committed polynomial $f(X)$:
\begin{align}
\term{r}, \term{\Delta{\rho}} &\randget \F\\\\\
\term{\hat{f}(X)} &\bydef r \cdot \lagrS_0(X) + \emph{f(X)}\\\\\
\term{\hat{C}} &\gets \Delta{\rho} \cdot \crsH + r\cdot \sOne{0} + \emph{C}\\\\\
               &\bydef \bkzgCommit(\ck_\S, \hat{f}; \rho + \Delta{\rho})
\end{align}

**Step 2**b**:** Add $\hat{C}$ to the $\FS$ transcript.

**Step 3:** Prove knowledge of $r$ and $\Delta{\rho}$ such that $\hat{C} - C = \Delta{\rho} \cdot \crsH + r\cdot \sOne{0}$.
\begin{align}
    \term{\piPok} \gets \zkpokProve^\FSo\left(\underbrace{(\hat{C}-C, \crsH, \sOne{0})}\_{\text{statement}}; \underbrace{(\Delta{\rho}, r)}\_{\text{witness}}\right)
\end{align}

{: .todo}
Say this was a $\Sigma$-protocol. Do we add the final proof to the transcript too?
It feels like we should add at least the final message from the prover to the transcript. 
So we could do that implicitly by (redundantly) adding the whole proof.

**Step 4**a**:** Represent all $j$th chunks $(z_{1,j},\ldots,z_{n,j})$ as a degree-$n$ polynomial and commit to it:
\begin{align}
\term{r\_j}, \term{\rho\_j} &\randget \F\\\\\
\term{\hat{f}\_j(X)} &\bydef r\_j \cdot \lagrS_0(X) + \sum\_{i\in[n]} z\_{i,j}\cdot \lagrS_i(X)\\\\\
\term{\hat{C}\_j} &\gets \rho_j \cdot \crsH + r\_j\cdot \sOne{0} + \sum\_{i\in[n]} z\_{i,j}\cdot \sOne{i}\\\\\
            &\bydef \bkzgCommit(\ck\_\S, \hat{f}\_j; \rho\_j)
\end{align}

*Note:* The $\ell$ size-$(n+2)$ MSMs here can be carefully-optimized: $n$ of the scalars are in $[b)$.

**Step 4**b**:** Add $(\hat{C}\_j)\_{j\in[\ell)}$ to the $\FS$ transcript.

**Step 5**a**:** For each $j\in[\ell)$, define a quotient polynomial, whose existence would show that, $\forall i\in[n]$, $f_j(\omega^i) \in [b)$:
\begin{align}
\forall j\in[\ell), \term{h_j(X)}
    &\bydef \frac{f_j(X)(f_j(X) - 1) \cdots \left(f_j(X) - (b-1)\right)}{\VS(X)}\\\\\
\end{align}

*Note:* Numerator is degree $bn$ and denominator is degree $n \Rightarrow h_j(X)$ is degree $(b-1)n$

**Step 5**b**:** Define a(nother) quotient polynomial, whose existence would show that, $\forall i\in[n]$, $f(\omega^i) = \sum_{j\in[\ell)} 2^j \cdot f_j(\omega^i)$:
\begin{align}
\term{g(X)}
    &\bydef \frac{f(X) - \sum_{j\in[\ell)} 2^j \cdot f_j(X)}{\VS(X)}\\\\\
\end{align}

*Note:* Numerator is degree $n$ and denominator is degree $n \Rightarrow g(X)$ is degree 0! (A constant!)

**Step 6:** Combine all the quotients into a single one, using random challenges from the verifier:
\begin{align}
\term{\beta,\beta\_0, \ldots,\beta_{\ell-1}}
    &\fsget \\{0,1\\}^\lambda\\\\\
\term{h(X)} 
    &\gets \beta \cdot g(X) + \sum\_{j\in[\ell)} \beta\_j \cdot h\_j(X)
    %= \frac{\sum\_{j\in[\ell)}\beta\_j (X-\omega^n)f\_j(X)(f\_j(X) - 1)\ldots(f_j(X)-(b-1))}{X^{n+1} - 1}
\end{align}

**Step 7**a**:** Commit to $h(X)$, of degree $(b-1)n$, by interpolating it over the larger $\L$ domain:
\begin{align}
\label{eq:D}
\term{\rho_h} &\randget \F\\\\\
\term{D} &\gets \rho_h\cdot \crsH + \sum\_{i\in[L)} h(\zeta^i) \cdot \lOne{i}\\\\\
    &\bydef \bkzgCommit(\ck_\L, h; \rho_h)
\end{align}

_Note:_ We discuss [how to interpolate $h(\zeta^i)$'s efficiently](#appendix-computing-hx) in the appendix.

**Step 7**b**:** Add $D$ to the $\FS$ transcript.

**Step 8:** The verifier asks us to take a random linear combination of $h(X)$, $f(X)$ and the $f_j(X)$'s:
\begin{align}
\term{\xi, \xi_h, \xi\_0,\ldots,\xi\_{\ell-1}} &\fsget \\{0,1\\}^\lambda\\\\\
\term{u(X)} &\bydef
  \xi \cdot f(X) +
  \xi\_h\cdot h(X) +
  \sum\_{j\in[\ell)} \xi\_j\cdot f\_j(X) 
\end{align}

**Step 9:** We get a random challenge from the verifier and open $u(X)$ at it (fast via [the Barycentric formula](/lagrange-interpolation#barycentric-formula)):
\begin{align}
    \term{\gamma} &\fsget \F\\\\\
    \term{a} &\gets f(\gamma)\\\\\
    \term{a\_h} &\gets h(\gamma)\\\\\
    \term{a\_j} &\gets f\_j(\gamma),\forall j\in[\ell)\\\\\
\end{align}

**Step 7:** We compute a KZG proof for $u(\gamma)$:
\begin{align}
    \term{\pi_\gamma} \gets \one{\frac{u(\tau) - u(\gamma)}{\tau-\gamma}}
\end{align}

_Note:_ By definition of the quotient polynomial above, $\emph{\pi_\gamma}$ can be computed in a size-$((b-1)n+1$ MSM as $\sum_{i\in[L)} \frac{u(\zeta^i) - u(\gamma)}{\zeta^i - \gamma} \cdot \lOne{i}$[^kzg-lagrange-no-ffts].

{: .todo}
Evaluating $u(\zeta^i),i\in[L)$ requires evaluating all $f_j(\zeta^i)$'s, which we do not have; we only have $f_j(\omega^i)$'s.
So, for each $j\in[\ell)$, this would reuse the size-$(n+1)$ inverse FFT over $\S$ to get $f_j$'s coefficients from the [$h(X)$ computation](#appendix-computing-hx), but would add 1 size-$L$ FFT on $\sum_j \xi_j f_j(X)$ over $\L$ to get the extra evaluations at the $\zeta^i$'s.

Return the proof $\pi$:
\begin{align}
\term{\pi}\gets \left(\hat{C}, \piPok, (\hat{C}\_j)\_{j\in[\ell)}, D, a, a_h, (a\_j)\_{j\in[\ell)}, \pi\_\gamma\right)
\end{align}

#### Proof size and prover time

**Proof size**:
 - $(\ell+3)\Gr_1$ for the $\hat{C}$, $\hat{C}\_j$'s, $D$ and $\pi\_\gamma$
 - $(\ell+2)\F$ for $a, a_h$ and the $a_j$'s (i.e., for $f(\gamma), h(\gamma)$, and the $f_j(\gamma)$'s)
 - **TODO:** ? for $\piPok$

**TODO:** **Prover time** is dominated by:

 - $\ell n$ $\Gr_1$ $\textcolor{green}{\text{additions}}$ for each $c_j, j\in[\ell)$
    + Assuming precomputed $[2\cdot \lagrS_i(\tau), \ldots, (b-1)\cdot \lagrS_i(\tau)]$
 - $\ell$ $\Gr_1$ scalar multiplications to blind each $c_j$ with $r_j$
 - $O(\ell L\log{L})$ $\F$ multiplications to interpolate $h(X)$, where $L\bydef bn$
    + See [break down here](#time-complexity).
 - 1 size-$((b-1)n+1)$ L-MSM for committing to $h(X)$
 - 1 size-$((b-1)n+1)$ L-MSM for committing to the KZG proof in $\pi_\gamma$

{: .todo}
Include Barycentric interpolation work too.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Verify}^{\mathcal{FS}(\cdot)}(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

**Step 1:** Parse the $\vk$ and the proof $\pi$:
 - $\left(b, \tauTwo,\vanishSTwo\right) \parse \vk$
 - $\left((C_j)_{j\in[\ell)}, D, (e\_{j,\gamma})\_{j\in[\ell)}, e\_\gamma, \pi\_\gamma\right) \parse \pi$

**Step 2:** Make sure the radix-$b$ decomposition is correct:
\begin{align}
\label{eq:c_j-decomposition}
\textbf{assert}\ C \equals \sum\_{j\in[\ell)} \bluedashedbox{b^j} \cdot C\_j
\end{align}

**Step 3:** Reconstruct a commitment $\term{U}$ to $\sum_{j\in[\ell)} \xi_j\cdot f_j(X) + \xi_\ell h(X)$:
 - add $(\vk, C, \ell, (C_j)_{j\in[\ell})$ to the $\FS$ transcript
 - $(\beta_j)_{j\in[\ell)} \fsget \\{0,1\\}^\lambda$
 - add $D$ to the $\FS$ transcript.
 - $\left(\left(\xi\_j\right)\_{j\in[0,\ell]}\right) \fsget \left(\\{0,1\\}^\lambda\right)^{\ell+1}$
 - $\emph{U} \gets \sum\_{j\in[\ell)} \xi_j \cdot C_j + \xi_\ell\cdot D$
 - $\gamma \fsget \F$

**Step 4:** Verify that $e_{j,\gamma} \equals f_j(\gamma)$ and $e_\gamma \equals h(\gamma)$:
\begin{align}
\label{eq:kzg-batch-verify}
\textbf{assert}\ \pair{U - \one{\sum\_{j\in[\ell)} \xi\_j \cdot e\_{j,\gamma} + \xi\_\ell \cdot e\_\gamma}}{\two{1}} \equals \pair{\pi\_\gamma}{\tauTwo - \two{\gamma}}
\end{align}

**Step 5:** Make sure that the $f_j(\omega^i)$'s are in $[b)$:
\begin{align}
\label{eq:zero-check-test}
\textbf{assert}\ e\_\gamma \cdot \frac{\gamma^{n+1} - 1}{\gamma - \omega^n} \equals \sum\_{j\in[\ell)} \beta\_j\cdot e\_{j,\gamma}(e\_{j,\gamma} - 1)\bluedashedbox{\ldots(e\_{j,\gamma} - (b-1))}
\end{align}

#### Verifier time

The verifier work is dominated by:

 - size-$\ell$ $\mathbb{G}_1$ small-MSM (i.e., small $b^0, b^1, b^2, \ldots, b^{\ell-1}$ scalars)
 - size-$(\ell+2)$ $\mathbb{G}_1$ L-MSM for the left input the LHS pairing
 - 1 $\Gr_2$ scalar multiplication for the right input the RHS pairing
 - size-$2$ multipairing for the KZG proof verification

## Conclusion

Your thoughts or comments are welcome on [this thread](https://x.com/alinush407/status/1950600327066980693).

## Appendix: Computing $h(X)$

{: .note}
This assumes $b=2$ but we will generalize it to any $b$ later.

We borrow [differentiation tricks](/2025/01/24/Polynomial-differentiation-tricks.html) from [Groth16](/groth16#computing-hx) to ensure we only do size-$L$ FFTs.
(Otherwise, we'd have to use size-$2N$ FFTs to compute the $\ell$ different $f_j(X)(f_j(X) - 1)\ldots(f_j(X) - (b-1))$ multiplications.)

Our goal will be to obtain all $(h(\zeta^i))_{i\in[L)}$ evaluations and then do a size-$L$ L-MSM to commit to it and obtain $\emph{D}$ from Eq: \ref{eq:D}.

Recall that:
\begin{align}
h(X)
    &= \frac{\sum_{j\in[\ell)}\beta_j \cdot \overbrace{(X-\omega^n)f_j(X)(f_j(X) - 1)\ldots(f_j(X)-(b-1))}^{\term{N_j(X)}}}{X^{n+1} - 1}
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

## References

[^kzg-lagrange-no-ffts]: When $\gamma\notin\S$, we can use [a simple trick](https://ethresear.ch/t/kate-commitments-from-the-lagrange-basis-without-ffts/6950). However, when $\gamma = \omega^i \in \S$, we can use [differentiation tricks](/2025/01/24/Polynomial-differentiation-tricks.html) to compute the otherwise-uncomputable $\frac{u(\omega^i) - u(\omega^i)}{\omega^i - \omega^i}$ scalar by evaluating the derivative of $\frac{u(X) - u(\omega^i)}{X - \omega^i}$ at $X = \omega^i$. So, by evaluating $u'(X)$ at $X = \omega^i$, which should give $\sum_{j\ne i, j\in[0,n]} \frac{\omega^{j - i} (u(\omega^i) - u(\omega^j))}{\omega^j - \omega^i}$.
[^power-of-two-n]: To use DeKART for non-powers of two $n$'s, just run the $\dekartSetup$ algorithm with the smallest $n' > n$ such that $n'$ is a power of two. Then, run the $\dekartProve$ algorithm with a vector of $n'$ values such that (1) the first $n$ values are the values you want to prove and (2) the last $n'-n$ values are set to zero.
[^pr1]: Pull request: [Add univariate DeKART range proof](https://github.com/aptos-labs/aptos-core/pull/17531/files)
[^Borg20]: [Membership proofs from polynomial commitments](https://solvable.group/posts/membership-proofs-from-polynomial-commitments/), William Borgeaud, 2020

For cited works, see below 👇👇

{% include refs.md %}
