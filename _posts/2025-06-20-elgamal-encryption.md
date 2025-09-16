---
tags:
 - ElGamal
 - encryption
title: ElGamal encryption
#date: 2020-11-05 20:45:59
#published: false
permalink: elgamal
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** ElGamal public key encrypting $\approx$ Using an ephemeral Diffie-Hellman exchanged key as a one-time pad.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\ek{\mathsf{ek}}
\def\dk{\mathsf{dk}}
$</div> <!-- $ -->

## Preliminaries

 - We assume a group $\Gr$ where Decisional Diffie-Hellman (DDH) is hard
 - We use additive group notation for $\Gr$

## Exponentiated ElGamal

This variant of ElGamal (first proposed by Cramer, Gennaro and Schoenmakers[^CGS97]?) encrypts a field element $m\in\F$ by "exponentiating" it into $m\cdot G$.
The encryption pubkey is $\ek \bydef \dk \cdot H$, where $H$ is another generator such that $\log_G{H}$ is unknown and hard to compute.

Note that the [original ElGamal paper](#original-elgamal) is described as only encrypting group element messages $m\in \Gr$.
As a result, it only needs one generator $H$.

### $\mathsf{E}.\mathsf{KGen}(1^\lambda) \rightarrow (\mathsf{dk}, \mathsf{ek})$

 - $\dk \randget \F$
 - $\ek \gets \dk \cdot H$

### $\mathsf{E}.\mathsf{Enc}(\mathsf{ek}, m; r) \rightarrow (C, D)$


 - $C \gets m \cdot G + r\cdot \ek$
 - $D \gets r \cdot H$

### $\mathsf{E}.\mathsf{Dec}(\mathsf{dk}, (C,D)) \rightarrow m\cdot G$

 - **return** $C - \dk \cdot D$

#### Correctness

Correctness holds because:
\begin{align}
C - \dk \cdot D 
 &= (m \cdot G + r\cdot \ek) - \dk\cdot(r\cdot H)\\\\\
 &= (m \cdot G + (r\cdot \dk) \cdot H) - (\dk\cdot r)\cdot H\\\\\
 &= m\cdot G
\end{align}

## Twisted ElGamal

{: .todo}
I believe this was first proposed by Chen et al.[^CMTA20]?

This variant of ElGamal adds a small _twist_: the $r \cdot G $ and  $r\cdot \ek$ components from [exponentiated ElGamal](#exponentiated-elgamal) are switched out.

The **advantage** is that the first component of the ciphertext (i.e. , $C$ from above) can now be treated as a Pedersen commitment to the encrypted message $m$.

This has efficiency advantages when composing Twisted ElGamal with $\Sigma$-protocols and other ZK proof systems like Bulletproofs[^BBBplus18].

### $\mathsf{E}.\mathsf{KGen}(1^\lambda) \rightarrow (\mathsf{dk}, \mathsf{ek})$
 
 - $\dk \randget \F$
 - $\ek \gets \dk^{-1} \cdot H$

### $\mathsf{E}.\mathsf{Enc}(\mathsf{ek}, m; r) \rightarrow (C, D)$
 - $C \gets m \cdot G + r\cdot H$
 - $D \gets r \cdot \ek$

### $\mathsf{E}.\mathsf{Dec}(\mathsf{dk}, (C,D)) \rightarrow m\cdot G$

 - **return** $C - \dk \cdot D$

#### Correctness

Correctness holds because:
\begin{align}
C - \dk \cdot D 
 &= (m \cdot G + r\cdot H) - \dk\cdot(r\cdot \ek)\\\\\
 &= (m \cdot G + r \cdot H) - (\dk\cdot r\cdot\dk^{-1}) H\\\\\
 &= (m \cdot G + r \cdot H) - r\cdot H\\\\\
 &= m\cdot G
\end{align}

## Conclusion

{: .todo}
Threshold variant.
Weighted variant.
DLog algorithms.

## Appendix

### Original ElGamal

The original ElGamal encryption paper[^Elga85] talks about encrypting a group element $m \in \Gr$, where $\Gr =\Zp$ and $p=kq+1$ for some other large prime $q$. (These days, $q \approx 2^{3072}$.)

First, the paper recalls the Diffie-Hellman[^DH76] key exchange:
<div align="center"><img style="width:50%" src="/pictures/elgamal/elga1.png" /></div>

Then, it emphasizes that the prime $p$ should have a large prime factor (i.e., our $q$ above):
<div align="center"><img style="width:50%" src="/pictures/elgamal/elga2.png" /></div>

Lastly, it introduces the scheme by describing how to encrypt and decrypt a **group element** in $m\in\Gr$:
<div align="center"><img style="width:50%" src="/pictures/elgamal/elga3.png" /></div>

Great were the days when the main result of a cryptography paper could be stated in three paragraphs like this! 🥲

## References

For cited works, see below 👇👇

{% include refs.md %}
