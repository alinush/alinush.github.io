---
tags:
 - vector commitments (VCs)
 - polynomials 
 - fast fourier transform (FFT)
 - Lagrange 
 - aggregation 
 - KZG
 - polynomial commitments
 - stateless validation
 - papers
title: Aggregatable Subvector Commitments for Stateless Cryptocurrencies from Lagrange Polynomials
permalink: asvc
date: 2020-05-06 14:00:00
---
{: .info}
**tl;dr:** We build a vector commitment (VC) scheme from KZG commitments to Lagrange polynomials that has (1) constant-sized, aggregatable proofs, which can all be precomputed in $O(n\log{n})$ time, and (2) linear public parameters, which can be derived from any "powers-of-tau" CRS in $O(n\log{n})$ time.
Importantly, the auxiliary information needed to update proofs (a.k.a. the "update key") is $O(1)$-sized.
Our scheme is compatible with recent techniques to aggregate subvector proofs across _different_ commitments[^GRWZ20].

<!--more-->

This is joint work with [Ittai Abraham](https://twitter.com/ittaia), [Vitalik Buterin](https://twitter.com/VitalikButerin), [Justin Drake](https://twitter.com/drakefjustin), [Dankrad Feist](https://twitter.com/dankrad) and [Dmitry Khovratovich](https://twitter.com/khovr).
Our **full paper** is available online [here](https://eprint.iacr.org/2020/527), has been recently accepted to [SCN'20](https://scn.unisa.it/), and has been presented [here](https://www.youtube.com/watch?v=Yzs6DEVFTLM) (25 minutes) and [here](https://www.youtube.com/watch?v=KGRnpjPjduI&list=PLj80z0cJm8QHm_9BdZ1BqcGbgE-BEn-3Y&index=22&t=0s) (1 hour).
You can find the slides in [this GitHub repo](https://github.com/alinush/asvc-talk).

**A little backstory:**
I've been interested in vector commitments (VCs) ever since [Madars Virza](https://madars.org/) first showed me how KZG and roots of unity gives rise to a simple VC scheme.
In 2018, I was trying to figure out if VC proofs can be updated fast in such a construction.
I came up with a KZG-based scheme that could update a proof for $v_i$ given a change to any $v_j $.
Unfortunately, it required an $O(n)$-sized, _static_, _update key_ to do the update.
Since each player $i$ in a stateless cryptocurrency has to update their proof for $v_i$, this $O(n)$-sized update key is an annoying storage burden for that user.

Then, I saw [Vitalik Buterin's post](https://ethresear.ch/t/using-polynomial-commitments-to-replace-state-roots/7095) on using _partial fraction decomposition_ to aggregate KZG proofs.
This was great, since it immediately implied VC proofs can be aggregated.
However, after conversations with [Ittai Abraham](https://twitter.com/ittaia) and the Ethereum Research team, it became clear this can also be used to reduce the update key size.
The key ingredient was turning two commitments to $A(X)/(X-i)$ and $A(X)/(X-j)$ into a commitment to $A(X)/\left((X-i)(X-j)\right)$ (see [here](#updating-proofs)).
This post explains this technique and how to make it work by taking care of all details (e.g., making update keys verifiable, computing them from the KZG public params efficiently, etc.).

<p hidden>$$
\newcommand{\vect}[1]{\boldsymbol{\mathrm{#1}}}
\newcommand{\prk}{\mathsf{prk}}
\newcommand{\vrk}{\mathsf{vrk}}
\newcommand{\upk}{\mathsf{upk}}
$$</p>
<!--  \overset{\mathrm{def}}{=} -->

# Preliminaries

Let $[i,j]=\\{i,i+1,i+2,\dots,j-1,j\\}$ and $[0, n) = [0,n-1]$.
Let $p$ be a sufficiently large prime that denotes the order of our groups.

In this post, beyond basic group theory for cryptographers[^KL15] and basic polynomial arithmetic, I will assume you are familiar with a few concepts:

 - **Bilinear maps**[^GPS08]. Specifically, $\exists$ a bilinear map $e : \Gr_1 \times \Gr_2 \rightarrow \Gr_T$ such that:
    - $\forall u\in \Gr_1,v\in \Gr_2, a\in \Zp, b\in \Zp, e(u^a, v^b) = e(u,v)^{ab}$
    - $e(g_1,g_2)\ne 1_T$ where $g_1,g_2$ are the generators of $\Gr_1$ and $\Gr_2$ respectively and $1_T$ is the identity of $\Gr_T$
 - **KZG**[^KZG10] **polynomial commitments** (see [here](/kzg)),
 - The **Fast Fourier Transform (FFT)**[^CLRS09] applied to polynomials. Specifically,
    - Suppose $\Zp$ admits a primitive _root of unity_ $\omega$ of order $n$ (i.e., $n \mid p-1$)
    - Let $$H=\{1, \omega, \omega^2, \omega^3, \dots, \omega^{n-1}\}$$ denote the set of all $n$ $n$th roots of unity
    - Then, FFT can be used to efficiently evaluate any polynomial $\phi(X)$ at all $X\in H$ in $\Theta(n\log{n})$ time
        - i.e., compute all $$\{\phi(\omega^{i-1})\}_{i\in[n]}$$

# VCs from Lagrange polynomials

We build upon a previous line of work on VCs from Lagrange polynomials[^CDHK15]<sup>,</sup>[^KZG10]<sup>,</sup>[^Tome20].

Recall that given a vector $\vect{v} = [v_0, v_1, \dots, v_{n-1}]$, we can interpolate a polynomial $\phi(X)$ such that $\phi(i)=v_i$ as follows:
\begin{align}
    \phi(X)=\sum_{i=0}^{n-1} v_i \cdot \lagr_i(X),\ \text{where}\ \lagr_i(X) = \prod_{\substack{j\in [0,n)\\\\j\ne i}}\frac{X-j}{i-j} 
\end{align}

<!-- TODO: add this to polynomial basics -->

It is well-known that this Lagrange representation of $\vect{v}$ naturally gives rise to a **vector commitment (VC)** scheme[^CF13].
The key idea is to commit to $\vect{v}$ by committing to $\phi(X)$ using KZG polynomial commitments (see [here](/kzg)).
Then, proving $\phi(i) = v_i$ proves that $v_i$ is the $i$th element in the vector.
Next, we describe how this scheme works in more detail and what features it has.

## Trusted setup

To set up the VC scheme for committing to any vector of size $n$, use an MPC protocol[^BGM17] to generate public parameters $\left(g^{\tau^i}\right)_{i\in [0,n]}$. 
<!-- Note: need to commit to A(X) which has roots at all n i's, so need g^{\tau^n} -->
Then, either:

 1. Spend $O(n^2)$ time to compute commitments $\ell_i = g^{\lagr_i(\tau)}$ to all $n$ Lagrange polynomials $\lagr_i(X)$.
 2. Or, "shift" the computation of these commitments into the MPC protocol, losing some efficiency.

{: .warning}
We will fix this later by storing $v_i$ at $\phi(\omega_n^i)$, which will allow us to compute all $\ell_i$'s in $O(n\log{n})$ time.

Either way, the **proving key** is $\prk=\left(g^{\tau^i},\ell_i\right)_{i\in[0,n)}$ and will be used to commit to a vector and create proofs.
The **verification key** is $\vrk=(g,g^{\tau})$ and will be used to verify proofs.

## Committing to a vector

The **commitment** to a vector $\vect{v}$ is just a KZG commitment $c=g^{\phi(\tau)}$ to its polynomial $\phi(X)$.
This can be computed very fast, in $O(n)$ time, given the proving key $\prk$:

\begin{align}
c &= \sum_{i=0}^{n-1} \ell_i^{v_i}\\\\\
  &= \sum_{i=0}^{n-1} g^{v_i \cdot \lagr_i(\tau)}\\\\\
  &= g^{\prod_{i=0}^{n-1} v_i \cdot \lagr_i(\tau)}\\\\\
  &= g^{\phi(\tau)}
\end{align}

### Updating the commitment
 
KZG commitments and thus vector commitments are _homomorphic_: given commitments $c$ and $c'$ to $\vect{v}$ and $\vect{v'}$, we can get a commitment $C=c \cdot c'$ to $\vect{v} + \vect{v'}$.

A consequence of this is that we can easily update a commitment $c$ to $c'$, given a change $\delta$ to $v_i$ as:
\begin{align}
c' = c \cdot \ell_i^{\delta}
\end{align}

## Constant-sized proofs

To prove that $v_i$ is the $i$th element in $\vect{v}$, we have to prove that $\phi(i)=v_i$.
For this, we need to:

 1. Interpolate $\phi(X)$ in $O(n\log^2{n})$ field operations and get its coefficients.
 2. Divide $\phi(X)$ by $X-i$ in $O(n)$ field operations and get a quotient $q_i(X)$ such that $\phi(X)=q_i(X)(X-i) + v_i$ (see the [polynomial remainder theorem](2020/03/16/polynomials-for-crypto.html#the-polynomial-remainder-theorem)).
 3. Compute a KZG commitment $\pi_i=g^{q_i(\tau)}$ to $q_i(X)$ using an $O(n)$ time multi-exponentiation

The proof will be: 
\begin{align}
\pi_i=g^{q_i(\tau)}=g^\frac{\phi(\tau)-v_i}{\tau-i}
\end{align}

{: .warning}
In _Appendix D.7_ in [our paper](https://eprint.iacr.org/2020/527), we show how to compute $\pi_i$ in $O(n)$ time, _without interpolating_ $\phi(X)$ by carefully crafting our public parameters.

To verify the proof, we can check with a pairing that:
\begin{align}
e(c/g^{v_i}, g)=e(\pi_i, g^{\tau}/g^i)
\end{align}

This is equivalent to checking that the [polynomial remainder theorem](polynomials#the-polynomial-remainder-theorem) holds for $\phi(i)$ at $X=\tau$. 

## Constant-sized $I$-subvector proofs

To prove multiple positions $(v_i)_{i\in I}$, an **$I$-subvector proof** $\pi_I$ can be computed using a [KZG batch proof](kzg#batch-proofs) as:

\begin{align}
\pi_I &= g^{q_I(\tau)}=g^\frac{\phi(\tau)-R_I(\tau)}{A_I(\tau)}
\end{align}

For this, the prover has to interpolate the following polynomials in $O(\vert I\vert \log^2{\vert I\vert})$ time:

\begin{align}
A_I(X) &=\prod_{i\in I} (X - i)\\\\\
R_I(X) &=\sum_{i\in I} v_i \prod_{j\in I,j\ne i}\frac{X - j}{i - j}\ \text{s.t.}\ R_I(i) = v_i,\forall i\in I
\end{align}

Verifying the proof can also be done with two pairings:
\begin{align}
e(c/g^{R_I(\tau)}, g)=e(\pi_I, g^{A_I(\tau)})
\end{align}

Note that the verifier has to spend $O(\vert I\vert \log^2{\vert I\vert})$ time to interpolate and commit to $A_I(X)$ and $R_I(X)$.

{: .warning}
Later on, we show how to aggregate an $I$-subvector proof $\pi_I$ from all individual proofs $\pi_i, i\in I$ in $O(\vert I\vert \log^2{\vert I\vert})$ time.

# Enhancing Lagrange-based VCs 

The VC scheme presented so far has several nice features:

 - $O(1)$-sized commitments
 - $O(n)$-sized proving key and $O(1)$-sized verification key
 - $O(1)$-sized proofs and $O(1)$-sized $I$-subvector proofs

It also has additional features, which we didn't explain:

 - _Homomorphic proofs:_ Suppose we are given (1) a proof $\pi_i$ for $v_i$ w.r.t. a commitment $c$ for $\vect{v}$ and (2) a proof $\pi_i'$ for $v_i'$ w.r.t. to $c'$ for vector $\vect{v'}$. Then, can obtain a proof $\Lambda_i=\pi_i \cdot \pi_i'$ for $v_i + v_i'$ w.r.t. $C=c\cdot c'$, which is a commitment to $\vect{v}+\vect{v'}$.
 - _Hiding:_ can commit to a vector as $g^{\phi(\tau)} h^{r(\tau)}$ to get a commitment that hides all information about $\vect{v}$.
    - Here, will need extra $h^{\tau^i}$'s.
    - Also, $r(X)$ is a random, degree $n-1$ polynomial.
<!-- 
    Note: degree higher than $n-1$ doesn't do anything extra, AFAICT: if you give $n$ evaluations of $\phi$, you reveal $\phi(X)$ anyway, so no sense in "protecting" r(X).
    \
    In other applications, it might make sense for r(X) to have degree higher than \phi(X), if you want to hide \phi's degree (I think).
-->

Nonetheless, applications such as _stateless cryptocurrencies_[^CPZ18], require extra features:

 1. **Aggregatable proofs:** Blocks can be made smaller by aggregating all users' proofs in a block into a single subvector proof.
 2. **Updatable proofs:** In a stateless cryptocurrency, each user $i$ has a proof of her balance stored at position $i$ in the vector. However, since the vector changes after each transaction in the currency, the user must be able to update her proof so it verifies w.r.t. the updated vector commitment.
 3. **Precompute _all_ proofs fast:** Proof serving nodes in stateless cryptocurrencies can operate faster if they periodically precompute all proofs rather than updating all $O(n)$ proof after each new block.
 4. **Updatable public parameters:** Since many $g^{\tau^i}$'s are already publicly available from previous trusted setup ceremonies implemented via MPC, it would be nice to use them safely by "refreshing" them with additional trusted randomness.

[Our paper](https://eprint.iacr.org/2020/527) adds all these features by carefully making use of roots of unity[^vG13ModernCh8], Fast Fourier Transforms (FFTs)[^CLRS09] and partial fraction decomposition[^Buterin20UsingPoly].

## Aggregating proofs into subvector profs

Drake and Buterin[^Buterin20UsingPoly] observe that partial fraction decomposition can be used to aggregate KZG proofs.

Let's first take a quick look at how partial fraction decomposition works.

### Partial fraction decomposition

Any _accumulator polynomial fraction_ can be decomposed as:
\begin{align}
\frac{1}{\prod_{i\in I} (X-i)} = \sum_{i\in I} c_i \cdot \frac{1}{X-i}
\end{align}

The key question is "What are the $c_i$'s?"
Surprisingly, the answer is given by a slightly tweaked Lagrange interpolation formula on a set of points $I$ [^BT04]:

\begin{align}
\lagr_i(X)=\prod_{j\in I, j\ne i} \frac{X-j}{i - j}=\frac{A_I(X)}{A_I'(i) (X-i)},\ \text{where}\ A_I(X)=\prod_{i\in I} (X-i)
\end{align}

Here, $A_I'(X)$ is the derivative of $A_I(X)$ and has the (non-obvious) property that $A_I'(i)=\prod_{j\in I,j\ne i} (i-j)$.
(Check out [this post](/threshold-bls#our-quasilinear-time-bls-threshold-signature-aggregation) for some intuition on why this tweaked Lagrange formula works.)

Now, let us interpolate the polynomial $\phi(X)=1$ using this new Lagrange formula from a set of $|I|$ points $(v_i, \phi(v_i)=1)\_{i\in I}$.
\begin{align}
         \phi(X) &= \sum_{i\in I} v_i \lagr_i(X)\Leftrightarrow\\\\\ 
               1 &= A_I(X)\sum_{i\in[0,n)} \frac{v_i}{A_I'(i)(X-i)}\Leftrightarrow\\\\\
\frac{1}{A_I(X)} &= \sum_{i\in I} \frac{1}{A_I'(i)(X-i)}\Leftrightarrow\\\\\
\frac{1}{A_I(X)} &= \sum_{i\in I} \frac{1}{A_I'(i)}\cdot\frac{1}{(X-i)}\Rightarrow\\\\\
             c_i &= \frac{1}{A_I'(i)}
\end{align}

Thus, to compute all $c_i$'s needed to decompose, we need to evaluate $A'(X)$ at all $i\in I$.
Fortunately, this can be done in $O(\vert I\vert \log^2{\vert I\vert})$ field operations using a polynomial multipoint evaluation[^vG13ModernCh10].

### Applying partial fraction decomposition to VC proofs

Recall that an $I$-subvector proof is just a commitment to the following quotient polynomial:

\begin{align}
q_I(X)
   &= \phi(X)\frac{1}{A_I(X)}- R_I(X)\frac{1}{A_I(X)}\\\\\
\end{align}

Next, we replace $\frac{1}{A_I(X)}$ with its partial fraction decomposition $\sum_{i\in I} \frac{1}{A_I'(i)(X-i)}$.

\begin{align}
q_I(X)
   &= \phi(X)\sum_{i\in I} \frac{1}{A_I'(i)(X-i)} - \left(A_I(X)\sum_{i\in I} \frac{v_i}{A_I'(i)(X-i)}\right)\cdot \frac{1}{A_I(X)} \\\\\
   &= \sum_{i\in I} \frac{\phi(X)}{A_I'(i)(X-i)} - \sum_{i\in I} \frac{v_i}{A_I'(i)(X-i)}\\\\\
   &= \sum_{i\in I} \frac{1}{A_I'(i)}\cdot \frac{\phi(X) - v_i}{X-i}\\\\\
   &= \sum_{i\in I} \frac{1}{A_I'(i)}\cdot q_i(X)
\end{align}

So in the end, we were able to express $q_I(X)$ as a linear combination of $q_i(X)$'s, which are exactly the quotients committed to in the proofs of the $v_i$'s (see [here](#constant-sized-proofs)).

Thus, given a set of proofs $(\pi_i)\_{i\in I}$ for a bunch of $v_i$'s, we can aggregate them into an $I$-subvector proof $\pi_I$ as:
\begin{align}
   \pi_I &= \prod_{i\in I} \pi_i^{\frac{1}{A_I'(i)}}
\end{align}

This takes $O(\vert I\vert \log^2{\vert I\vert})$ field operations to compute all the $c_i$'s, as explained in the previous subsection.

## Updating proofs

First, recall that a proof $\pi_i$ for $v_i$ is a KZG commitment to:
\begin{align}
q_i(X)=\frac{\phi(X)-v_i}{X-i}
\end{align}

Suppose that $v_j$ changes to $v_j+\delta$, thus changing the vector commitment and invalidating any proof $\pi_i$.
Thus, we want to be able to update any proof $\pi_i$ to a new proof $\pi_i'$ that verifies w.r.t. the updated commitment.
Note that we must consider two cases:
 
 1. $i=j$ 
 2. $i\ne j$.

We refer to the party updating their proof $\pi_i$ as the **proof updater**.

### The $i=j$ case

Let's see how the quotient polynomial $q_i'(X)$ in the updated proof $\pi_i'$ relates to the original quotient $q_i(X)$:
\begin{align}
q_i'(X)
    &=\frac{\phi'(X)-(v_i+\delta)}{X-i}\\\\\
    & =\frac{\left(\phi(X) + \delta\lagr_i(X)\right) - v_i -\delta}{X-i}\\\\\
    &=\frac{\phi(X) - v_i}{X-i}-\frac{\delta(\lagr_i(X)-1)}{X-i}\\\\\
    &= q_i(X) + \delta\left(\frac{\lagr_i(X)-1}{X-i}\right)
\end{align}

Observe that if we include KZG commitments $u_i$ to $\frac{\lagr_i(X)-1}{X-i}$ in our public parameters, then we can update $\pi_i$ to $\pi_i'$ as:
\begin{align}
\pi_i' = \pi_i \cdot \left(u_i\right)^{\delta}
\end{align}

We include a commitment $u_i$ as part of each user $i$'s update key $\upk_i = u_i = g^\frac{\lagr_i(\tau)-1}{\tau-i}$.
This way, each user $i$ can update her proof after a change to their own $v_i$.
This leaves us with handling updates to $v_j$ for $j\ne i$.
We handle this next by including additional information in $\upk_i$.

### The $i\ne j$ case

Again, let's see how $q_i'(X)$ relates to the original $q_i(X)$, but after a change $\delta$ at position $j\ne i$:
\begin{align}
q_i'(X)
    &=\frac{\phi'(X)-v_i}{X-i}\\\\\
    &=\frac{\left(\phi(X) + \delta\lagr_j(X)\right) - v_i}{X-i}\\\\\
    &=\frac{\phi(X) - v_i}{X-i}-\frac{\delta\lagr_j(X)}{X-i}\\\\\
    &= q_i(X) + \delta\left(\frac{\lagr_j(X)}{X-i}\right)
\end{align}

This time we are in a bit of pickle because there are $O(n^2)$ possible polynomials $U_{i,j}(X) = \frac{\lagr_j(X)}{X-i}$
Let, $u_{i,j}=g^{U_{i,j}(\tau)}$ denote their commitments.
This would mean we'd need each user $i$ to have $n-1$ $u_{i,j}$'s: one for each $j\in[0,n),j\ne i$.
Then, for any change $\delta$ to $v_j$, user $i$ could update its $\pi_i$ to $\pi_i'$ as:
\begin{align}
\pi_i' = \pi_i \cdot \left(u_{i,j}\right)^{\delta}
\end{align}

However, this would mean each user $i$'s update key is $\upk_i = (u_i, (u_{i,j})_{j\in [0,n),j\ne i})$ and is $O(n)$-sized.
This makes it impractical for use in applications such as stateless cryptocurrencies, where each user $i$ has to include their $\upk_i$ in every transaction they issue.

#### Re-constructing $u_{i,j}$ fast

Fortunately, by putting additional information in $\upk_i$ and $\upk_j$, we can help user $i$ reconstruct $u_{i,j}$ in $O(1)$ time.
Let $A(X)=\prod_{i\in [0,n)} (X-i)$ be the accumulator polynomial over all $i$'s.
Let $A'(X)$ be its derivative and store the evaluation $A'(i)$ in each user's $\upk_i$.
Additionally, store $a_i = g^\frac{A(\tau)}{\tau-i}$ in each user's $\upk_i$.
(Note that $a_i$ is just a KZG proof for $A(i) = 0$.)

{: .error}
Computing all $a_i$'s takes $O(n^2)$ time, but we improve this to $O(n\log{n})$ time later using roots of unity.

Next, using the tweaked Lagrange formula from before, rewrite $U_{i,j}(X)$ as:
\begin{align}
U_{i,j}(X)
    &=\frac{\lagr_j(X)}{X-i}\\\\\
    &= \frac{A(X)}{A'(j)(X-j)(X-i)}\\\\\
    &= \frac{1}{A'(j)}\cdot A(X) \cdot \frac{1}{(X-j)(X-i)}
\end{align}

Next, notice that we can decompose $\frac{1}{(X-j)(X-i)}$:
\begin{align}
U_{i,j}(X)
    &= \frac{1}{A'(j)}\cdot A(X) \cdot \frac{1}{(X-j)(X-i)}\\\\\
    &= \frac{1}{A'(j)}\cdot A(X) \cdot \left(c_j \frac{1}{X-j}+ c_i\frac{1}{X-i}\right)
    &= \frac{1}{A'(j)}\cdot \left(c_j \frac{A(X)}{X-j}+ c_i\frac{A(X)}{X-i}\right)
\end{align}

Now, notice that this implies the commitment $u_{i,j}$ can be computed in $O(1)$ time as:
\begin{align}
u_{i,j}
    &= \left(a_j^{c_j} \cdot a_i^{c_i}\right)^\frac{1}{A'(j)}
\end{align}

What are $c_i$ and $c_j$? Just define $A_{i,j}(X) = (X-i)(X-j)$, take its derivative $A_{i,j}'(X)=(X-i)+(X-j)$ and, [as mentioned before](#partial-fraction-decomposition), you have $c_i=1/A_{i,j}'(i)=1/(i-j)$ and $c_j=1/A_{i,j}'(j)=1/(j-i)$

Thus, it is sufficient to set each user's $\upk_i=(u_i, a_i, A'(i))$.

{: .info}
Note that for user $i$ to update their proof, they need not just their own $\upk_i$ but also the $\upk_j$ corresponding to the changed position $j$.
This is fine in settings such as stateless cryptocurrencies, where $\upk_j$ is part of the transaction that sends money from user $i$ to user $j$.

## Verifiable update keys

In the stateless cryptocurrency setting, it is very important that user $i$ be able verify $\upk_j$ before using it to update her proof.
Similarly, miners should verify the update keys they use for updating the commitment $c$.
(We did not discuss it, but $\upk_i$ can also be used to derive a commitment to $\lagr_i(X)$ needed to update $c$ after a change to $v_i$.)

To verify $\upk_i$, we need to include a commitment $a=g^{A(\tau)}$ to $A(X)$ in the $\vrk$.
This way, each $a_i$ in $\upk_i$ can be verified as a normal KZG proof w.r.t. $a$.
Then, each $u_i$ can also be verified by noticing two things:

 1. $u_i$ is just a KZG proof that $\lagr_i(i) = 1$
 2. $a_i$ can be transformed into $\ell_i=g^{\lagr_i(\tau)}$ in $O(1)$ time by exponentiating it with $1/A'(i)$, which is part of $\upk_i$

As a result, $u_i$ can now be verified as a KZG proof that $\lagr_i(i) = 1$ against $\ell_i$.

## Precomputing all proofs fast

Computing all $n$ constant-sized proofs for $v_i=\phi(i)$ in less than quadratic time seems very difficult.
Fortunately, Feist and Khovratovich[^FK20] give a beautiful technique that can do this, subject to the restriction that the evaluation points are roots of unity, rather than $[0,1,\dots, n-1]$.
Thus, if we change our scheme to store $v_i$ at $\phi(\omega^i)$ where $\omega$ is an $n$th primitive root of unity, we can use this technique to compute all VC proofs $(\pi_i)_{i\in [0,n)}$ in $O(n\log{n})$ time.

Furthermore, we can use this same technique to compute all the $a_i$'s from each $\upk_i$ in $O(n\log{n})$ time.

## Efficiently-computable and updatable public parameters

Our scheme's public parameters, consisting of the proving key, verification key and update keys, need to be generated via an MPC protocol[^BGM17], to guarantee nobody learns the trapdoor $\tau$.
Unfortunately, the most efficient MPC protocols only output $g^{\tau^i}$'s.
This means we should (ideally) find a way to derive the remaining public parameters from these $g^{\tau^i}$'s.

First, when using roots of unity, we have $A(X)=\prod_{i\in [0,n)} (X-\omega^i) = X^n - 1$.
Thus, the commitment $a=g^{A(\tau)}$ to $A(X)=X^{n} - 1$ can be computed in $O(1)$ time via an exponentiation.

Second, the commitments $\ell_i=g^{\lagr_i(\tau)}$ to Lagrange polynomials can be computed via a single DFT on the $(g^{\tau^i})$'s.
(See _Sec 3.12.3, pg. 97_ in [Madars Virza's](https://madars.org/) PhD thesis[^Virza17]).
<!-- Also briefly mentioned in BCG+15: Oakland paper I-C-2, page 5 -->

Third, each $a_i = g^{A(\tau)/(\tau -\omega^i)}$ is just a bilinear accumulator membership proof for $\omega^i$ w.r.t. $A(X)$.
Thus, all $a_i$'s can be computed in $O(n\log{n})$ time via the Feist-Khovratovich technique[^FK20].

Lastly, we need a way to compute all $u_i =  g^{\frac{\lagr_i(\tau)-1}{X-\omega^i}}$.
It turns out this is also doable in $O(n\log{n})$ time using an FFT on a carefully-crafted input (see _Sec 3.4.5_ in [our paper](https://eprint.iacr.org/2020/527)).

As a last benefit, since our parameters can be derived from $g^{\tau^i}$'s which are _updatable_, our parameters are updatable.
This is very useful as it allows safe reuse of existing parameters generated for other schemes.

# Parting thoughts

Please see [our paper](https://eprint.iacr.org/2020/527) for more goodies, including:

 - A formalization of our primitive (in Sec 3.1)
 - The full algorithms of our VC (in Sec 3.4.4)
 - A new security definition for KZG batch proofs with a reduction to $n$-SBDH (in Appendix C)
 - The efficient algorithm for computing the $u_i$'s (in Sec 3.4.5)
 - A comparison to other VCs (in Table 2)
 - An survey of existing VC schemes over prime-order groups, with a time complexity analysis (in Appendix D) 
 - A smaller, incomplete survey of existing VC schemes over hidden-order groups (in Appendix D) 

## Are roots of unity necessary?

[Babis Papamanthou](https://twitter.com/chbpap) asked me a very good question: _"What functionality requires the use of roots of unity?"_
I hope the last two sections answered that clearly:

 - Can precompute all $n$ VC proofs in quasilinear time
 - Can derive our public parameters efficiently from the $g^{\tau^i}$'s 
    - This includes all $u_i$'s and $a_i$'s needed to update proofs efficiently
 - Can have (efficiently) updatable public parameters
 - Can remove $A'(i)$ from $\upk_i$, since $A'(i)=n\omega^{-i}$ (see _Appendix A_ in [our paper](https://eprint.iacr.org/2020/527))

## Future work

It would be very exciting to see by how much this new VC scheme improves the performance of stateless cryptocurrencies such as Edrax[^CPZ18].

# Acknowledgements

Special thanks goes to [Madars Virza](https://madars.org/) who first introduced me to Lagrange-based VCs in 2017 and helped me with some of the related work.

### References

[^Bold03]: **Threshold Signatures, Multisignatures and Blind Signatures Based on the Gap-Diffie-Hellman-Group Signature Scheme**, by Boldyreva, Alexandra, *in PKC 2003*, 2002
[^Buterin20UsingPoly]: **Using polynomial commitments to replace state roots**, by Vitalik Buterin, *in \url{https://ethresear.ch/t/using-polynomial-commitments-to-replace-state-roots/7095}*, 2020, [[URL]](https://ethresear.ch/t/using-polynomial-commitments-to-replace-state-roots/7095)
[^BGM17]: **Scalable Multi-party Computation for zk-SNARK Parameters in the Random Beacon Model**, by Sean Bowe and Ariel Gabizon and Ian Miers, *in Cryptology ePrint Archive, Report 2017/1050*, 2017, [[URL]](https://eprint.iacr.org/2017/1050)
[^BLS04]: **Short Signatures from the Weil Pairing**, by Boneh, Dan and Lynn, Ben and Shacham, Hovav, *in Journal of Cryptology*, 2004
[^BT04]: **Barycentric Lagrange Interpolation**, by Berrut, J. and Trefethen, L., *in SIAM Review*, 2004
[^CF13]: **Vector Commitments and Their Applications**, by Catalano, Dario and Fiore, Dario, *in Public-Key Cryptography -- PKC 2013*, 2013
[^CLRS09]: **Introduction to Algorithms, Third Edition**, by Cormen, Thomas H. and Leiserson, Charles E. and Rivest, Ronald L. and Stein, Clifford, 2009
[^CDHK15]: **Composable and Modular Anonymous Credentials: Definitions and Practical Constructions**, by Camenisch, Jan and Dubovitskaya, Maria and Haralambiev, Kristiyan and Kohlweiss, Markulf, *in Advances in Cryptology -- ASIACRYPT 2015*, 2015
[^CPZ18]: **Edrax: A Cryptocurrency with Stateless Transaction Validation**, by Alexander Chepurnoy and Charalampos Papamanthou and Yupeng Zhang, *in Cryptology ePrint Archive, Report 2018/968*, 2018
[^FK20]: **Fast amortized Kate proofs**, by Dankrad Feist and Dmitry Khovratovich, 2020, [[pdf]](https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf)
[^GAGplus19]: **SBFT: A Scalable and Decentralized Trust Infrastructure**, by G. Golan Gueta and I. Abraham and S. Grossman and D. Malkhi and B. Pinkas and M. Reiter and D. Seredinschi and O. Tamir and A. Tomescu, *in 2019 49th Annual IEEE/IFIP International Conference on Dependable Systems and Networks (DSN)*, 2019, [[PDF]](https://arxiv.org/pdf/1804.01626.pdf).
[^GJKR07]: **Secure Distributed Key Generation for Discrete-Log Based Cryptosystems**, by Gennaro, Rosario and Jarecki, Stanislaw and Krawczyk, Hugo and Rabin, Tal, *in Journal of Cryptology*, 2007
[^GPS08]: **Pairings for cryptographers**, by Steven D. Galbraith and Kenneth G. Paterson and Nigel P. Smart, *in Discrete Applied Mathematics*, 2008
[^GRWZ20]: **Pointproofs: Aggregating Proofs for Multiple Vector Commitments**, by Sergey Gorbunov and Leonid Reyzin and Hoeteck Wee and Zhenfei Zhang, *in Cryptology ePrint Archive, Report 2020/419*, 2020, [[URL]](https://eprint.iacr.org/2020/419)
[^KL15]: **Introduction to Modern Cryptography**, by Jonathan Katz and Yehuda Lindell, 2007
[^KZG10]: **Constant-Size Commitments to Polynomials and Their Applications**, by Kate, Aniket and Zaverucha, Gregory M. and Goldberg, Ian, *in ASIACRYPT '10*, 2010
[^Shamir79]: **How to Share a Secret**, by Shamir, Adi, *in Commun. ACM*, 1979
[^TCZplus20]: **Towards Scalable Threshold Cryptosystems**, by Alin Tomescu and Robert Chen and Yiming Zheng and Ittai Abraham and Benny Pinkas and Guy Golan Gueta and Srinivas Devadas, *in 2020 IEEE Symposium on Security and Privacy (SP)*, 2020, [[PDF]](/papers/dkg-sp2020.pdf).
[^Tome20]: **How to Keep a Secret and Share a Public Key (Using Polynomial Commitments)**, by Tomescu, Alin, 2020
[^vG13ModernCh8]: **Fast Multiplication**, by von zur Gathen, Joachim and Gerhard, Jurgen, *in Modern Computer Algebra*, 2013
[^vG13ModernCh10]: **Fast polynomial evaluation and interpolation**, by von zur Gathen, Joachim and Gerhard, Jurgen, *in Modern Computer Algebra*, 2013
[^Virza17]: **On Deploying Succinct Zero-Knowledge Proofs**, by Virza, Madars, 2017

[prevpost]: /amt
