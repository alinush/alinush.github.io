---
tags:
title: Examples of zero-knowledge-proof systems
#date: 2020-11-05 20:45:59
published: false
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A table comparing zero-knowledge proof (ZKP) proof systems on a bunch of dimensions.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\fft{\mathsf{FFT}}
\def\smallMexpGr#1#2{\Gr_{#1}^{\green{#2}}}
\def\bigMexpGr#1#2{\Gr_{#1}^{\red{#2}}}
$</div> <!-- $ -->

{% include zkp.md %}

<!-- Example of a Markdown table

    |-----------------+------------+-----------------+----------------|
    | Default aligned |Left aligned| Center aligned  | Right aligned  |
    |-----------------|:-----------|:---------------:|---------------:|
    | First body part |Second cell | Third cell      | fourth cell    |
    | Second line     |foo         | **strong**      | baz            |
    | Third line      |quux        | baz             | bar            |
    |-----------------+------------+-----------------+----------------|
    | Second body     |            |                 |                |
    | 2 line          |            |                 |                |
    |=================+============+=================+================|
    | Footer row      |            |                 |                |
    |-----------------+------------+-----------------+----------------|

-->


## State-of-the-art ZKPs

<!-- Longer numbers are defined here -->
<div style="display: none;">$
%
\def\grothP{\begin{array}%
    6\times\fft_n + 
    \bigMexpGr{1}{n-1} +
    2\times \smallMexpGr{1}{m+1} +
    \smallMexpGr{2}{m+1} +
    \smallMexpGr{1}{m-\ell}
\end{array}}
$</div> <!-- $ -->

### Notation

We use the following notation to indicate time or space complexities:

 - $\fft_n$ denotes a size-$n$ FFT
 - $\ell$ denotes the size of the public statement $\stmt$ (e.g., $\stmt\in\F^\ell$)
 - $n$ denotes the # of R1CS constraints ($\approx$ the # of multiplication gates in the circuit)
 - $m$ denotes the # of R1CS variables ($\approx$ the size of the NP statement $\stmt$, witness $\witn$, and auxiliary witness generation data)
 - $\smallMexpGr{i}{n}$ denotes a multi-exponentiation of size-$n$ in $\Gr_i$ with "$\green{\text{small}}$" exponents (e.g., as big as the R1CS vector of statement and witness data)
 - $\bigMexpGr{i}{n}$ denotes a multi-exponentiation of size-$n$ in $\Gr_i$ with "$\red{\text{large}}$" exponents (e.g., uniform in $\Zp$ where $\|\Gr\| = p$)

### Preliminaries

{: .todo}
R1CS, PLONK(ish) constraint systems, AIR, CCS.

### Prover time

|--------------------------+------------|
| Proof system             | Prover time|
|--------------------------|------------|
| Bulletproofs[^BBBplus18] | $O(n)$     |
| Groth16[^groth16]        | $\grothP$  |
| PLONK                    |            |
|--------------------------+------------|

<!-- TODO: add more subsections

-----------------+----------------+-------------+-------------+---------------+---------------|
 Verifier time   | Proof size     | CRS size    | CRS type    | Assumptions   | Constraints   |
-----------------|----------------|-------------|-------------|---------------|---------------|
 $O(n)$          | $O(n\log{n})$  | $O(1)$      | Transparent | DL, FS[^FS87] | R1CS          |
                 |                |             |             |               |               |
-----------------+----------------+-------------+-------------+---------------+---------------|
-->

## References

For cited works, see below 👇👇

[^groth16]: [Groth16](/2025/01/25/Groth16.html#prover-time), Alin Tomescu, 2024

{% include refs.md %}
