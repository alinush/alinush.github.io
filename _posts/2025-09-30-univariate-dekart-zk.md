---
tags:
title: "Smaller and faster-to-verify DeKART ZK range proofs"
#date: 2020-11-05 20:45:59
published: false
permalink: dekart-v2
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Trading off prover time for smaller and faster verification in our previous [DeKART](/dekart) scheme.

<!--more-->

{% include pairings.md %}
{% include fiat-shamir.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\correlate#1{\mathsf{CorrelatedRandomness}(#1)}
\def\dekart{\mathsf{DeKART}}
\def\dekartUni{\dekart^\mathsf{FFT}}
\def\tildeDekartUni{\widetilde{\dekart}^\mathsf{FFT}}
\def\dekartMulti{\dekart^{\vec{X}}}
\def\H{\mathbb{H}}
\def\L{\mathbb{L}}
\def\bad#1{\textcolor{red}{\text{#1}}}
\def\good#1{\textcolor{green}{\text{#1}}}
\def\vanish{\frac{X^{n+1} - 1}{X - \omega^n}}
$</div> <!-- $ -->

## Preliminaries

You can read the original [blog post on DeKART](/dekart) for proving that a vector of values all lie in $[0,2^\ell)$.

The notation for this blog post is [the same as there](/dekart#preliminaries), except we rely on **polynomial interactive oracle proofs (PIOP)** notation to describe our range proof protocol more abstractly, independent of the choice of **polynomial commitment scheme (PCS)**.
Later on, [our concrete construction](#mathsfdekart_bmathsffftmathsfsetup1lambda-b-nrightarrow-mathsfprkmathsfvk) will use the [KZG PCS](/kzg).

## Univariate batched ZK range proof

{: .note}
We're going to describe the range proof protocol as a PIOP below.

Let:
 - $\term{b}$ denote the **chunk size** or **radix**.
 - $\term{\ell}$ denote the **number of chunks** in each value.
 - $\term{z_0}, \ldots, \term{z_{n-1}}\in\emph{[b^\ell)}$ denote $\term{n}$ **different values**.
 - $\term{z_{i,j}}\in\emph{[b)}$ denote the $j$th chunk of $z_i$, for all $j\in[\ell)$.

The values are represented as a blinded, degree-$n$ polynomial $\term{f(X)}\in\F[X]$:
\begin{align}
\label{eq:f-batched}
f(\omega^i) &= z_i,\forall i\in[n)\\\\\
f(\omega^n) &= \term{r}
\end{align}
where $\emph{r}\randget \F$ is a blinding factor and $\term{\omega}$ is a $(n+1)$th primitive root of unity in $\F$.

In other words, the **prover** starts with $f(X)$ and the **verifier** has an **oracle** $[[f(X)]]$.
The prover aims to convince the verifier that the committed $z_i$'s are in $[b^\ell)$.

Let $\H\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$ denote the set of all $(n+1)$th roots of unity.

{: .note}
We will (a bit awkwardly) require that exists $k\in\N$ s.t. $n + 1= 2^k$, since many fields $\F$ of interest have prime order $p$ where $p-1$ is divisible by $2^k$ and thus will admit an $(n+1)$th primitive root of unity. e.g., [BLS12-381](/pairings#bls12-381-performance) admits a root of unity for $k=32$.
As we shall see later, our construction will also need a $(bn)$th primitive roots of unity.

First, the prover represents the $j$th chunk of all $n$ values as a blinded, degree-$n$ polynomial $\term{f_j(X)}$:
\begin{align}
f_j(\omega^i) &= z_{i,j},\forall i\in[n)\\\\\
f_j(\omega^n) &= \term{r_j}
\end{align}
where the prover picks the $\emph{r_j}$’s randomly, but correlates them such that:
\begin{align}
\label{eq:correlate}
r = \sum_{j\in[\ell)} b^j\cdot r_j
\end{align}
We denote this by $(r_j)_{j\in[\ell)}\randget \term{\correlate{r, b, \ell}}$.

As a result, the following **radix-$b$ representation** relation will hold for these $f$ and $f_j$ polynomials:
\begin{align}
\label{eq:radix-b}
f(X) = \sum_{j\in[\ell)} b^j \cdot f_j(X)
\end{align}

The prover sends $[[f_j]]$ oracles to the verifier, who can easily check Eq. \ref{eq:radix-b} holds against them.

The remaining task is to prove that $f_j$ stores $b$-sized chunks; i.e.:
\begin{align}
f_j(X) \in \\{0,1,\ldots,b-1\\}, \forall X\in \H\setminus\\{\omega^n\\}\Leftrightarrow
\end{align}
The **key observation** is that this is equivalent to:
\begin{align}
\left. \vanish\ \middle|\ f_j(X)\left(f_j(X) - 1\right)\ldots\left(f_j(X) - (b-1)\right) \right.
\end{align}
This, in turn, is equivalent to proving there exists a quotient polynomial $\term{h_j(X)}$ of degree $bn - n = \emph{(b-1)n}$ such that:
\begin{align}
\label{eq:unbatched-zero-check}
\vanish\cdot \emph{h_j(X)} = f_j(X)\left(f_j(X) - 1\right)\ldots\left(f_j(X) - (b-1)\right) 
\end{align}

The verifier picks random $\emph{\beta_j}$'s and sends them to the prover.

The prover computes $\term{h(X)}\bydef \sum_{j\in[\ell)} \beta_j \cdot h_j(X)$ and sends back an $\[[h(X)]]$ oracle.

The verifier picks a random $\term{\gamma}$ and queries the oracles for $h(\gamma)$ and $(f_j(\gamma))_{j\in[\ell]}$.

Lastly, the verifier checks, for each $j\in[\ell)$, that Eq. \ref{eq:unbatched-zero-check} holds at a random $X=\gamma$ point:
\begin{align}
\frac{\gamma^{n+1} - 1}{\gamma - \omega^n} \cdot \sum_{j\in[\ell)} {\beta_j} \cdot h_j(\gamma) &= \sum_{j\in[\ell)} {\beta_j} \cdot f_j(\gamma)\left(f_j(\gamma) - 1\right)\ldots\left(f_j(\gamma) - (b-1)\right)\Leftrightarrow\\\\\
\frac{\gamma^{n+1} - 1}{\gamma - \omega^n} \cdot h(\gamma) &= \sum_{j\in[\ell)} {\beta_j} \cdot f_j(\gamma)\left(f_j(\gamma) - 1\right)\ldots\left(f_j(\gamma) - (b-1)\right)
\end{align}

We call this scheme $\term{\dekartUni_b}$ and describe its [prover](#mathsfdekart_bmathsffftmathsfprovemathcalfscdotmathsfprk-c-ell-z_0ldotsz_n-1-rrightarrow-pi) and [verifier](#mathsfdekart_bmathsffftmathsfverifymathcalfscdotmathsfvk-c-ell-pirightarrow-01) algorithms below, which instantiate the PIOP above with the [KZG PCS](/kzg).

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Setup}(1^\lambda, b, n)\rightarrow \mathsf{prk},\mathsf{vk}$

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\crs#1{\textcolor{green}{#1}}
\def\tauOne{\crs{\one{\tau}}}
\def\tauTwo{\crs{\two{\tau}}}
\def\vanishTwo{\crs{\two{\frac{\tau^{n+1} - 1}{\tau-\omega^n}}}}
\def\ellOne#1{\crs{\one{\ell_{#1}(\tau)}}}
\def\sOne#1{\crs{\one{s_{#1}(\tau)}}}
$</div> <!-- $ -->

Let:

 - $\term{N} \bydef b(n+1) = 2^c$
    - (i.e., if $(n+1)$ and $b$ are powers of two $\Rightarrow N$ is a power of two too)
    + Ideally, we would have preferred to use a slightly-smaller $N$ value.
        + i.e., the highest-degree polynomial is $(b-1)n$ so $N' = (b-1)n + 1 = bn - (n - 1)$ would suffice
        + Ours is bigger: $N - N' = b(n+1) - (bn - (n-1)) = b + n - 1$
    - However, the field may not admit such an $N$th primitive root of unity when $N\ne 2^c$
    - Plus, FFTs for $N\ne 2^c$ would be trickier too.
 - $\term{\omega} \gets$ a primitive $(n+1)$th root of unity in $\F$
 - $\term{\H}\bydef\\{\omega^0,\omega^1,\ldots,\omega^n\\}$
 - $\term{\zeta} \gets$ a primitive $N$th root of unity in $\F$
 - $\term{\L}\bydef\\{\zeta^0,\zeta^1,\ldots,\zeta^{N-1}\\}$

Generate powers of $\tau$ up to and including $\tau^{(b-1)n}$:

 - $\term{\tau}\randget\F$

_Note:_ This scheme is for proving values are in $[b^\ell)$.
The highest degree of any committed polynomial in this scheme is $(b-1)n$.
The vanishing polynomial $\vanish$ will have degree $n$.

Let $\term{\ell_i(X)} \bydef \prod_{j\in\H, j\ne i} \frac{X - \omega^j}{\omega^i - \omega^j}$ denote the $i$th degre-$n$ [Lagrange polynomial](/lagrange-interpolation), for $i\in[0, n]$, w.r.t. the $\H$ domain.

Let $\term{s_i(X)} \bydef \prod_{j\in\L, j\ne i} \frac{X - \zeta^j}{\zeta^i - \zeta^j}$ denote the $i$th degre-$(N-1)$ [Lagrange polynomial](/lagrange-interpolation), for $i\in[N)$, w.r.t. the $\L$ domain.

Return the public parameters:
 - $\vk\gets \left(b, \tauTwo,\vanishTwo\right)$
 - $\prk\gets \left(\vk, \left(\ellOne{i})\right)_{i\in[0,n]}, \left(\sOne{i}\right)\_{i\in[N)}\right)$

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Commit}(\mathsf{prk},z_0,\ldots,z_{n-1}; r)\rightarrow C$

This is just a [KZG commitment](/kzg) to the vector $\vec{z}\bydef [z_0,\ldots,z_{n-1}]$:

 - $\left(\cdot, (\ellOne{i},\cdot)\_{i\in[0,n]}\right)\parse\prk$
 - $C \gets r\cdot \ellOne{n} + \sum_{i\in[n)} z_i \cdot \ellOne{i} \bydef \one{\emph{f(\tau)}}$ (as per Eq. \ref{eq:f-batched})

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Prove}^{\mathcal{FS}(\cdot)}(\mathsf{prk}, C, \ell; z_0,\ldots,z_{n-1}, r)\rightarrow \pi$

Recall $\emph{z_{i,j}}\in[b)$ denotes the $j$th chunk of $z_i\in[0,b^\ell)$.

**Step 1:** Parse the proving key:
\begin{align}
\left((b,\cdot,\cdot), \left(\ellOne{i}\right)_{i\in[0,n]}, \bluedashedbox{\left(\sOne{i}\right)\_{i\in[N)}}\right) &\parse\prk\\\\\
\end{align}

**Step 2:** Commit to $f_j(X)$, which stores the $j$th bits of each value:
\begin{align}
(\emph{r\_j})\_{j\in[n)} &\randget \correlate{r, \ell}\\\\\
\term{C\_j} &\gets r\_j\cdot \ellOne{n} + \sum\_{i\in[n)} z\_{i,j}\cdot \ellOne{i} \bydef \one{\emph{f\_j(\tau)}},\forall j\in[\ell)
\end{align}

*Note:* The $\ell$ size-$(n+1)$ MSMs here can be carefully-optimized: the scalars are in $[b)$.

**Step 3a:** Interpolate a quotient polynomial arguing that $f_j(\omega^i) \in \bluedashedbox{[b)}$, except at $\omega^n$: 
\begin{align}
\emph{h_j(X)}
    &\gets \frac{f_j(X)(f_j(X) - 1)\bluedashedbox{\ldots(f_j(X) - (b-1))}}{(X^{n+1} - 1) / (X-\omega^n)}\\\\\
    &= \frac{(X-\omega^n)f_j(X)(f_j(X) - 1)\bluedashedbox{\ldots(f_j(X)-(b-1))}}{X^{n+1} - 1},\forall j \in[\ell)
\end{align}

*Note:* Numerator is degree $\bluedashedbox{bn}$ and denominator is degree $n \Rightarrow h_j(X)$ is degree $\bluedashedbox{(b-1)n}$

**Step 3b:** Add $(\vk, C, \ell, (C\_j)\_{j\in[\ell})$ to the $\FS$ transcript.

**Step 4a:** Combine all $h_j$'s into a single polynomial using random challenges from the verifier:
\begin{align}
(\term{\beta\_j})\_{j\in[\ell)}
    &\fsget \\{0,1\\}^\lambda\\\\\
\term{h(X)} 
    &\gets \sum\_{j\in[\ell)} \emph{\beta\_j} \cdot h\_j(X)
    %= \frac{\sum\_{j\in[\ell)}\beta\_j (X-\omega^n)f\_j(X)(f\_j(X) - 1)\ldots(f_j(X)-(b-1))}{X^{n+1} - 1}
\end{align}

*Note:* $h(X)$ is of degree $\bluedashedbox{(b-1)n}$ too, just like the $h_j(X)$'s.

**Step 4b:** Commit to $h(X)$:
\begin{align}
\label{eq:D}
\term{D} \gets \bluedashedbox{\sum\_{i\in[N)} h(\zeta^i) \cdot \sOne{i}} \bydef \one{\emph{h(\tau)}}
\end{align}

_Note:_ We discuss [how to interpolate $h(\zeta^i)$'s efficiently](#appendix-computing-hx) in the appendix.

**Step 4c:** Add $D$ to the $\FS$ transcript.

**Step 5a:** The verifier asks us to take a random linear combination of $h(X)$ and the $f_j(X)$'s:
\begin{align}
\left(\left(\term{\xi\_j}\right)\_{j\in[0,\ell]}\right) &\fsget \left(\\{0,1\\}^\lambda\right)^{\ell+1}\\\\\
\term{u(X)} &\bydef \sum\_{j\in[\ell)} \emph{\xi\_j} f\_j(X) + \emph{\xi\_\ell} h(X)
\end{align}

**Step 6:** We get a random $\term{\gamma}\in\F$ from the verifier and evaluate (fast via [the Barycentric formula](/dekart#lagrange-polynomials)):
\begin{align}
    \emph{\gamma} &\fsget \F\\\\\
    \term{e\_{j,\gamma}} &\gets f\_j(\gamma),\forall j\in[\ell)\\\\\
    \term{e_\gamma} &\gets h(\gamma)
\end{align}

**Step 7:** We compute a KZG proof for $u(\gamma)$:
\begin{align}
    \term{\pi_\gamma} \gets \one{\frac{u(\tau) - u(\gamma)}{\tau-\gamma}}
\end{align}

_Note:_ By definition of the quotient polynomial above, $\emph{\pi_\gamma}$ can be computed in a size-$\bluedashedbox{((b-1)n+1)}$ MSM as $\bluedashedbox{\sum_{i\in[N)} \frac{u(\zeta^i) - u(\zeta)}{\zeta^i - \gamma} \cdot \sOne{i}}$[^kzg-lagrange-no-ffts].

{: .todo}
Evaluating $u(\zeta^i),i\in[N)$ requires evaluating all $f_j(\zeta^i)$'s, which we do not have; we only have $f_j(\omega^i)$'s.
So, for each $j\in[\ell)$, this would reuse the size-$(n+1)$ inverse FFT over $\H$ to get $f_j$'s coefficients from the [$h(X)$ computation](#appendix-computing-hx), but would add 1 size-$N$ FFT on $\sum_j \xi_j f_j(X)$ over $\L$ to get the extra evaluations at the $\zeta^i$'s.

Return the proof $\pi\in\Gr_1^{\ell+2} \times \F^{\ell+1}$:
\begin{align}
\term{\pi}\gets \left((C\_j)\_{j\in[\ell)}, D, (e\_{j,\gamma})\_{j\in[\ell)}, e\_\gamma, \pi\_\gamma\right)
\end{align}

#### Proof size and prover time

**Proof size** is _trivial_: $(\ell+2)\Gr_1 + (\ell+1)\F$ $\Rightarrow$ independent of the batch size $n$, but linear in the number of chunks $\ell$ of the values.

**Prover time** is dominated by:

 - $\ell n$ $\Gr_1$ $\textcolor{green}{\text{additions}}$ for each $c_j, j\in[\ell)$
    + Assuming precomputed $[2\cdot \ell_i(\tau), \ldots, (b-1)\cdot \ell_i(\tau)]$
 - $\ell$ $\Gr_1$ scalar multiplications to blind each $c_j$ with $r_j$
 - $O(\ell N\log{N})$ $\F$ multiplications to interpolate $h(X)$, where $N\bydef bn$
    + See [break down here](#time-complexity).
 - 1 size-$((b-1)n+1)$ L-MSM for committing to $h(X)$
 - 1 size-$((b-1)n+1)$ L-MSM for committing to the KZG proof in $\pi_\gamma$

{: .todo}
Include Barycentric interpolation work too.

### $\mathsf{Dekart}\_b^\mathsf{FFT}.\mathsf{Verify}^{\mathcal{FS}(\cdot)}(\mathsf{vk}, C, \ell; \pi)\rightarrow \\{0,1\\}$

**Step 1:** Parse the $\vk$ and the proof $\pi$:
 - $\left(b, \tauTwo,\vanishTwo\right) \parse \vk$
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

We borrow [differentiation tricks](/2025/01/24/Polynomial-differentiation-tricks.html) from [Groth16](/groth16#computing-hx) to ensure we only do size-$N$ FFTs.
(Otherwise, we'd have to use size-$2N$ FFTs to compute the $\ell$ different $f_j(X)(f_j(X) - 1)\ldots(f_j(X) - (b-1))$ multiplications.)

Our goal will be to obtain all $(h(\zeta^i))_{i\in[N)}$ evaluations and then do a size-$N$ L-MSM to commit to it and obtain $\emph{D}$ from Eq: \ref{eq:D}.

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
...it does **not** necessarily help with computing all $h(\zeta^i)$'s for $i\in[N)$.

Depending on how $\zeta$ is related to $\omega$, not all hope may be lost.
Obviously, if $\zeta = \omega$ and $N = n$, we are in the previous case.
But $N = b(n+1)$ for $b \ge 2$.

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

[^kzg-lagrange-no-ffts]: When $\gamma\notin\H$, we can use [a simple trick](https://ethresear.ch/t/kate-commitments-from-the-lagrange-basis-without-ffts/6950). However, when $\gamma = \omega^i \in \H$, we can use [differentiation tricks](/2025/01/24/Polynomial-differentiation-tricks.html) to compute the otherwise-uncomputable $\frac{u(\omega^i) - u(\omega^i)}{\omega^i - \omega^i}$ scalar by evaluating the derivative of $\frac{u(X) - u(\omega^i)}{X - \omega^i}$ at $X = \omega^i$. So, by evaluating $u'(X)$ at $X = \omega^i$, which should give $\sum_{j\ne i, j\in[0,n]} \frac{\omega^{j - i} (u(\omega^i) - u(\omega^j))}{\omega^j - \omega^i}$.
[^pr1]: Pull request: [Add univariate DeKART range proof](https://github.com/aptos-labs/aptos-core/pull/17531/files)
[^Borg20]: [Membership proofs from polynomial commitments](https://solvable.group/posts/membership-proofs-from-polynomial-commitments/), William Borgeaud, 2020

For cited works, see below 👇👇

{% include refs.md %}
