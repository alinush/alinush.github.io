---
tags:
 - zero-knowledge proofs (ZKPs)
 - groth16
 - trusted setup
 - polynomials
 - interpolation
 - rank-1 constraint systems (R1CS)
title: How to verify a Groth16 VK was generated from some R1CS
#date: 2020-11-05 20:45:59
#published: false
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
permalink: groth16-vk-verify-from-r1cs
---

{: .info}
**tl;dr:**
Inspired by a tweet[^tweet], we explore whether, given (1) an R1CS and (2) some "powers-of-$\tau$", we could construct a cryptographic proof that a Groth16 VK was derived from them.
This should make it more efficient for folks to ensure that an on-chain VK corresponds to some published ZK circuit code (e.g., circom).
Nonetheless, this is **not sufficient**: one should also verify that the VK was generated from several independent contributions in an MPC ceremony and that there exists a corresponding proving key that is _consistent_ (e.g., has the same $\delta$ component, same QAP, etc.).

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
%
\def\one#1{\left[#1\right]_\textcolor{green}{1}} <!-- \_ -->
\def\two#1{\left[#1\right]_\textcolor{red}{2}}
\def\three#1{\left[#1\right]_\textcolor{blue}{\top}}
\def\pair#1#2{e\left(#1, #2\right)}
\def\bp{\mathcal{G}}
%
\def\gu{\textcolor{magenta}{u}}
\def\rv{\textcolor{red}{v}}
\def\bw{\textcolor{blue}{w}}
%
\def\relqap{\mathsf{QAP}\text{-}\mathsf{SAT}^{\gu_j,\rv_j,\bw_j}_{n,m}}
%
\def\crs#1{\textcolor{green}{#1}}
%
\def\bgmSetup{\mathsf{BGM17}.\mathsf{Setup}}
\def\grothSetup{\mathsf{Groth16}.\mathsf{Setup}}
\def\grothProve{\mathsf{Groth16}.\mathsf{Prove}}
\def\grothVerify{\mathsf{Groth16}.\mathsf{Verify}}
\def\grothBatchVerify{\mathsf{Groth16}.\mathsf{BatchVerify}}
\def\grothSim{\mathsf{Groth16}.\mathsf{Simulate}}
\def\grothRerand{\mathsf{Groth16}.\mathsf{Rerand}}
\def\grothBlind{\mathsf{Groth16}.\mathsf{Blind}}
\def\grothBlindVerify{\mathsf{Groth16}.\mathsf{BlindVerify}}
%
\def\alphabeta{\crs{\three{\alpha\beta}}}
%
\def\alphaOne{\crs{\one{\alpha}}}
\def\betaOne{\crs{\one{\beta}}}
\def\deltaOne{\crs{\one{\delta}}}
\def\betaTwo{\crs{\two{\beta}}}
\def\gammaTwo{\crs{\two{\gamma}}}
\def\deltaTwo{\crs{\two{\delta}}}
%
\def\ujc{\crs{\one{u_j(\tau)}}}
\def\vjc{\crs{\one{v_j(\tau)}}} 
%
\def\vvjc{\crs{\two{v_j(\tau)}}}
%
\def\uvw{\crs{\beta u_j(\tau) + \alpha v_j(\tau) + w_j(\tau)}}
\def\uvwOne{\one{\uvw}}
\def\uvwOneCol{\one{\beta\gu_j(\tau) + \alpha\rv_j(\tau) + \bw_j(\tau)}}
\def\uvwDeltaOne{\crs{\one{\frac{\uvw}{\delta}}}}
\def\uvwDeltaOneCol{\one{\frac{\beta\gu_j(\tau) + \alpha\rv_j(\tau) + \bw_j(\tau)}{\delta}}}
%
\def\tauN{\one{\tau^i(\tau^n - 1)}}
\def\tauNdelta{\one{\frac{\tau^i(\tau^n - 1)}{\delta}}}
\def\htaus{\crs{\one{\frac{\lagr_i(\tau) (\tau^n - 1)}{\delta}}}}
%
\def\uvwgamma{\crs{\frac{\beta u_j(\tau) + \alpha v_j(\tau) + w_j(\tau)}{\gamma}}}
\def\uvwGammaOne{\crs{\one{\uvwgamma}}}
%
\def\rk{\blue{r_k}}
\def\Uj{\crs{U_j}}
\def\Vj{\crs{V_j}}
\def\VjOne{\crs{\one{V_j}}}
%
\def\otau{\orange{\tilde{\tau}}}
\def\oalpha{\orange{\tilde{\alpha}}}
\def\obeta{\orange{\tilde{\beta}}}
%
\def\btau{\blue{\bar{\tau}}}
\def\balpha{\blue{\bar{\alpha}}}
\def\bbeta{\blue{\bar{\beta}}}
%
\def\odelta{\orange{\tilde{\delta}}}
\def\bdelta{\blue{\bar{\delta}}}
%
\def\ptau{\mathsf{ptau}}
\def\outTwo{\mathsf{qp}}
%
\def\trx{\mathsf{trx}}
%
\def\phaseOneInit{\mathsf{Phase}_1.\mathsf{Init}}
\def\phaseOneContribute{\mathsf{Phase}_1.\mathsf{Contribute}}
\def\phaseOneVerify{\mathsf{Phase}_1.\mathsf{Verify}}
%
\def\phaseTwoInit{\mathsf{Phase}_2.\mathsf{Init}}
\def\phaseTwoContribute{\mathsf{Phase}_2.\mathsf{Contribute}}
\def\phaseTwoVerify{\mathsf{Phase}_2.\mathsf{Verify}}
%
\def\pok{\mathsf{pok}}
\def\hashPokNoArg{\mathcal{H}} % conditionals on # of args don't really work
\def\hashPok#1{\hashPokNoArg\left(#1\right)}
$</div> <!-- $ -->

{% include zkp.md %}

## Background and notation

Mostly, assuming familiarity with [Groth16](/groth16) and its [QAP/R1CS](/r1cs)-based computational model.

{: .note}
We'll be using [additive group notation](/groth16#pairing-friendly-groups).

### Powers-of-$\tau$

We use **powers-of-$\tau$** to denote a bunch of group elements structured as follows:
\begin{align}
\label{eq:ptau}
\ptau(\tau,\alpha,\beta)
&\bydef 
\left(
    \two{\beta},
    \left(\two{\tau^i},\one{\alpha\tau^i},\one{\beta\tau^i}\right)\_{i\in[0, n-1]},
    \left(\one{\tau^i}\right)\_{i\in[0, 2n-2]}
\right)
\\\\\
&\bydef
\left\[\begin{array}%
    \two{\beta}\\\\\
    \left(\two{\tau^0}, \two{\tau^1}, \two{\tau^2}, \ldots, \two{\tau^{n-1}}\right)\\\\\
    \left(\one{\alpha\tau^0}, \one{\alpha\tau^1}, \one{\alpha\tau^2},\ldots,\one{\alpha\tau^{n-1}}\right)\\\\\
    \left(\one{\beta\tau^0}, \one{\beta\tau^1}, \one{\beta\tau^2},\ldots,\one{\beta\tau^{n-1}}\right)\\\\\
    \left(\one{\tau^0}, \one{\tau^1}, \one{\tau^2},\ldots,\one{\tau^{2n-2}}\right)\\\\\
\end{array}\right\]
\end{align}
...where $(\tau,\alpha,\beta)\in \F^3$.

### QAPs

Mostly recall that ZK relation can be compiled into a [quadratic arithmetic program (QAP)](/groth16#qaps); a set of $m+1$ polynomials of degree $\le n-1$ each.
\begin{align}
\label{eq:qap}
\left(\gu_j(X),\rv_j(X),\bw_j(X)\right)_{j\in[0,m]}
\end{align}

Recall that:
 - $n$ is called either (1) the degree of the QAP or (2) the number of R1CS constraints.
 - $m$ is called either (1) the size of the QAP or (2) the number of R1CS variables

### [BGM17]

In practice, most folks use the [BGM17][^BGM17] formulation of Groth16, which has a slightly different verification key (VK).

#### $\mathsf{BGM17.Setup}_\mathcal{G}(1^\lambda, R)\rightarrow (\mathsf{prk},\mathsf{vk},\mathsf{td})$

The trapdoor is _almost the same_ as in Groth16's except there is no more $\gamma$:
\begin{align}
\label{eq:bgm17-trapdoor}
\td\gets \left(\begin{array} %
\tau,
\alpha,\beta,
\delta
\end{array}\right)\randget\F^4
\end{align}

The proving key remains **the same** as in Groth16:
\begin{align}
\label{eq:bgm17-prk}
\prk \gets \left(
\begin{array} %
%
\alphaOne,\betaOne,\betaTwo,\deltaOne,\deltaTwo
\\\\\
%
\left(
    \ujc, \vjc
\right)\_{j\in[0,m]},
%
\left(
    \vvjc
\right)\_{j\in[0,m]}\\\\\
%
\left(
    \uvwDeltaOne
\right)\_{j\in[\ell+1,m]}\\\\\
%
\left(
    \htaus
\right)\_{i\in[0,n-2]}
\end{array}\right)
\end{align}

The verification key is also _almost the same_ as in Groth16's, except it lacks a $\gamma$ component and thus no longer divides by $\gamma$:
\begin{align}
\label{eq:bgm17-vk}
\vk \gets \left(
\begin{array} %
\alphaOne,\betaTwo,\deltaTwo\\\\\
%
\left(
    \uvwOne
\right)\_{j\in[0,\ell]}
\end{array}\right)
\end{align}

## Protocol sketch

Let's start by observing that given some ZK circuit code written in some zkDSL (e.g., `circom` or [NoirLang](https://x.com/NoirLang), it is easy to compile it and obtain the QAP polynomials from Eq. $\ref{eq:qap}$.

 > A cry is heard: _"But you said R1CS, not QAP!"_.
 > Yes, I did. But recall that [they are one and the same](/r1cs).

Also, let's for now assume that the $\ptau(\tau,\alpha,\beta)$ powers-of-$\tau$ from Eq. $\ref{eq:ptau}$ are available to the verifier. (We can think of compressing them later.) 

Next, looking at the VK in Eq. $\ref{eq:bgm17-vk}$ observe that the $(\alphaOne,\betaTwo)$ components are trivial to prove correctness of, since they are part of $\ptau(\tau,\alpha,\beta)$. 

For the $\deltaTwo$ component, for now, there is nothing we want to prove.

{: .error}
Again, not saying this protocol is sufficient to ensure security of a deployed VK.
For example, as pointed out by [levochka.eth](https://x.com/levs57/status/1899511053383254019), a trapdoored $\delta$ in the VK would allow an attacker to forge proofs.

Thus, the difficult component we must prove correctness of is the last one:
\begin{align}
\left(
    \uvwOne
\right)\_{j\in[0,\ell]}
\end{align}

First, observe that the verifier, who has the QAP polynomials and the powers-of-$\tau$ can simply reconstruct this component[^pp-phase-2]:
\begin{align}
\uvwOne &\equals 
  \sum\_{i=0}^{n-1} \left( \gu\_{j,i}\cdot \one{\beta\tau^i} + \rv\_{j,i}\cdot \one{\alpha\tau^i} + \bw\_{j,i}\cdot \one{\tau^i} \right)
\end{align}
Here, $\gu_{j,i}$ denotes the $i$th coefficient of the $\gu_j(X)$ polynomial (same for $\rv_j(X)$ and $\bw_j(X)$).

{: .note}
In practice, the QAP polynomials are interpolated in Lagrange basis, so the equation above will look slightly different. But, for now, glancing over that.

**Problem:** The verification work above involves a size-$3n$ (or so) multi-scalar multiplication (MSM).
Although it should work quite fast in practice, can we help the verifier do it asymptotically faster?

**Idea** (to be explored): If we can assume[^can-we] we have succinct, structured commitments to the vectors of $\one{\beta\tau^i}$'s, $\one{\alpha\tau^i}$'s, and $\one{\tau^i}$'s (e.g., AFGHO-style commitments[^AFGplus10]), then it may be possible to convince the verifier asymptotically faster (in terms of scalar multiplications in the group $\Gr_1$, rather than scalar operations in $\mathbb{F}$) by using an IPA-based MSM argument similar to $\mathsf{MIPP}_k$ in [BMM+19][^BMMplus19].

The difficulty will be that $\mathsf{MIPP}\_k$ assumes that the scalars are structured as $(b^0, b^1, \ldots, b^{n-1})$, which is not the case here for our scalars (e.g., the $\gu_{j,i}$'s). 
This may be fixable though.

# References

[^can-we]: Unclear why this would be reasonable, since powers-of-$\tau$ ceremonies do not output such commitments. And if the verifier has to compute an AFGHO-style commitment to the $\ptau$ it is game-over in terms of verifier-efficiency.
[^pp-phase-2]: I made this observation in the [Groth16 blogpost too](/groth16#post-processing-phase-1-and-phase-2-into-a-bgm17-prk-and-vk).
[^tweet]: Twitte replies [here](https://x.com/alinush/status/1899310471930576978) and [here](https://x.com/alinush/status/1899314608688832928).

{% include refs.md %}
