---
tags:
 - polynomial commitment schemes
 - multilinear extensions (MLEs)
title: Multilinear polynomial commitment schemes (MLE PCS)
#date: 2020-11-05 20:45:59
#published: false
permalink: mle-pcs
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A catalog of polynomial commitment schemes for **multilinear** polynomials (i.e., multivariate polynomials where each variable has degree at most 1). These are the workhorse of modern SNARKs based on the sumcheck protocol.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\pcs{\mathsf{PCS}}
\def\kgen{\mathsf{Gen}}
\def\comm{\mathsf{Commit}}
\def\open{\mathsf{Open}}
\def\verify{\mathsf{Verify}}
\def\eval{\mathsf{Eval}}
$</div> <!-- $ -->

## Introduction

A **polynomial commitment scheme (PCS)** lets a prover commit to a polynomial $f$ and later prove that $f(\vec{r}) = v$ for a point $\vec{r}$ chosen by the verifier.

A [**multilinear** polynomial](/mle) in $\mu$ variables is a polynomial $f(x_1, \ldots, x_\mu) \in \F[x_1, \ldots, x_\mu]$ where each variable $x_i$ has individual degree at most 1.
Any function $g : \\{0,1\\}^\mu \rightarrow \F$ has a unique [**multilinear extension (MLE)**](/mle): the unique multilinear polynomial $\tilde{g}$ satisfying $\tilde{g}(\vec{b}) = g(\vec{b})$ for all $\vec{b} \in \\{0,1\\}^\mu$.

## Preliminaries

We use $\term{n} = 2^\term{\mu}$ to denote the number of evaluations of the multilinear polynomial (i.e., the number of coefficients) and $\term{\lambda}$ to denote the security parameter.

All complexities in the tables below are stated in big-$O$ notation (omitted for brevity).

### Error-correcting codes

The hash-based schemes rely on [error-correcting codes (ECCs)](/ecc) for messages of length $k$ and codewords of length $N$.

The two key parameters of a code are:
- **Relative rate** $\rho = k/N$
    + Higher rate means less redundancy.
- **Relative distance** $\delta = d/N$, where $d$ is the [minimum distance of the code](/ecc#distance) 
    + i.e., the minimum Hamming distance between any two distinct codewords
    + Higher distance means more errors can be detected.

The code families used in the table below are:
- **RS**: [Reed-Solomon](https://en.wikipedia.org/wiki/Reed%E2%80%93Solomon_error_correction) codes. Maximum distance separable (MDS) codes achieving $\delta = 1 - \rho$. Encoding requires $O(n \log n)$ via FFT.
- **Expander / Spielman**: Linear-time encodable codes based on expander graphs[^Spie96]. Achieve constant $\rho$ and $\delta$, but with small concrete distance.
- **Random foldable**: Codes with recursive folding structure (generalizing RS), supporting FRI-style protocols over arbitrary fields[^ZCF23e].
- **RAA**: Repeat-Accumulate-Accumulate codes. Linear-time encodable codes combining repetition, permutation, and two accumulation steps.
- **LDPC**: Low-density parity-check codes. Sparse linear codes with linear-time encoding.
- **LT codes**: Any linear-time encodable code (e.g., expander, RAA, LDPC).

## Known MLE PCS schemes

{: .todo}
Complexities **may be off** in many places.
(This is Claude reading the papers & filling in the tables, with me correcting only some of them.)
Assumptions **may be off** too.

### Hash-based / code-based (transparent, plausibly post-quantum)

| Scheme | Year | Code | $\rho$ | $\delta$ | CRS size | Prover | Verifier | Proof size | ZK |
|--------|------|------|--------|----------|-------|--------|----------|------------|:--:|
| [Ligero](/ligero)[^AHIV17] | 2017 | RS (interleaved) | $\rho$[^rs-param] | $1-\rho$ | $1$ | $n$ | $\lambda\sqrt{n}$ | $\lambda\sqrt{n}$ | |
| Ligero++[^BFHplus20] | 2020 | RS (interleaved) | $\rho$[^rs-param] | $1-\rho$ | $1$ | $n \log n$ | $\lambda\log^2 n$ | $\lambda\log^2 n$ | |
| Brakedown[^GLSplus21e] | 2021 | Expander (Spielman) | $\approx 0.65$ | $\approx 0.04$ | $1$ | $n$ | $\lambda\sqrt{n}$ | $\lambda\sqrt{n}$ | |
| Orion[^XZS22e]$^,$[^HS24e] | 2022 | Spielman (tensor) | $1/4$ | $\approx 0.055$ | $1$ | $n$ | $\lambda\log^2 n$ | $\lambda\log^2 n$ | |
| BaseFold[^ZCF23e] | 2023 | Random foldable | $1/c$[^basefold-c] | $\approx 1-1/c$ | $1$ | $n \log n$ | $\lambda\log^2 n$ | $\lambda\log^2 n$ | |
| DeepFold[^GLHplus24e] | 2024 | RS | $\rho$[^rs-param] | $1-\rho$ | $1$ | $n \log n$ | $\lambda\log^2 n$ | $\lambda\log^2 n$ | &#x2713; |
| [WHIR](/whir)[^ACFY24e] | 2024 | RS (constrained) | $\rho$[^rs-param] | $1-\rho$ | $1$ | $n \log n$ | $\lambda\log^2 n$ | $\lambda\log^2 n$ | |
| Blaze[^BCFplus24e] | 2024 | RAA | $1/r$[^blaze-r] | $\approx 0.19$ | $1$ | $n$ | $\lambda\log^2 n$ | $\lambda\log^2 n$ | |
| FICS[^BMMS25e] | 2025 | Any LT code | $\rho_0$[^lt-param] | $\delta_0$[^lt-param] | $1$ | $n$ | $\lambda\log n \log \log n$ | $\lambda\log n \log \log n$ | |
| Hobbit[^PP25e] | 2025 | Tensor (Spielman + RS) | $\rho$[^rs-param] | $1-\rho$ | $1$ | $n$ | $\lambda\log^2 n$ | $\lambda\log^2 n$ | |
| Ligerito[^NA25e] | 2025 | Any linear code | $\rho_0$[^lt-param] | $\delta_0$[^lt-param] | $1$ | $n \log n$ | $\frac{\lambda\log^2 n}{\log \log n}$ | $\frac{\lambda\log^2 n}{\log \log n}$ | |
| Bolt[^GNR26e] | 2026 | Sketched (LDPC) | $\rho$[^bolt-rate] | $\delta(\rho)$[^bolt-rate] | $1$ | $n$ | $\lambda\log n \log\log n$ | $\lambda\log n \log\log n$ | |

[^rs-param]: For RS-based schemes, the rate $\rho \in (0,1)$ is a tunable parameter (typically $\rho = 1/2$); distance is $\delta = 1-\rho$ (MDS).
[^basefold-c]: $c > 1$ is the code blow-up factor; e.g., $c = 2$ gives $\rho = 1/2$ and $\delta \approx 1/2$.
[^blaze-r]: $r \ge 1$ is the repetition factor; e.g., $r = 4$ gives $\rho = 1/4$ and $\delta \approx 0.19$ at that rate.
[^lt-param]: Depends on the chosen LT code; any code with constant rate $\rho_0$ and constant distance $\delta_0$ suffices.
[^bolt-rate]: Bolt supports any desired rate $\rho \in (0,1)$; the distance $\delta(\rho) > 0$ is a constant depending on $\rho$.

[Ligero](/ligero)[^AHIV17] encodes evaluations as a matrix and uses interleaved Reed-Solomon proximity tests.

Ligero++[^BFHplus20] composes Ligero's interleaved code testing with an inner product argument (from Aurora) to reduce proof size from $O(\sqrt{n})$ to polylogarithmic; combined with GKR for structured polynomial evaluation, it yields a PCS with $O(\log^2 n)$ verifier.

Brakedown[^GLSplus21e] achieves linear-time proving using expander-based codes and is the first built system with a linear-time prover; it is also field-agnostic.

Orion[^XZS22e] reduces proof size from $O(\sqrt{n})$ to $O(\log^2 n)$ via proof composition ("code switching").

BaseFold[^ZCF23e] generalizes FRI-style folding to arbitrary foldable codes, enabling field-agnostic MLE commitments.

DeepFold[^GLHplus24e] adapts FRI to the list decoding radius setting, achieving $\approx 3\times$ smaller proofs than unique-decoding-based schemes like BaseFold.

[WHIR](/whir)[^ACFY24e] is an IOPP for constrained Reed-Solomon codes with super-fast verification (hundreds of **micro**seconds); it directly supports multilinear polynomial queries and serves as a drop-in replacement for FRI/BaseFold.

Blaze[^BCFplus24e] achieves linear-time proving over binary extension fields using Repeat-Accumulate-Accumulate (RAA) codes; concretely faster than all prior schemes for large polynomials ($\ge 2^{25}$) with much smaller proofs than Brakedown.

FICS[^BMMS25e] is an IOPP for multilinear evaluation that achieves linear prover time with improved query complexity $O(\lambda \cdot \log\log n + \log n)$, compiled into a PCS via BCS.

Hobbit[^PP25e] uses a _tensor code_ (Spielman composed with RS) so that proof composition only requires encoding with the "SNARK-friendly" RS component, avoiding the expensive Spielman encoding. This yields a linear-time, transparent, plausibly post-quantum PCS with polylogarithmic proofs. The paper also presents a space-efficient variant with $O(B)$ working buffer space and $O(n/B + \log^2 B)$ proof size for tunable $B \in [\sqrt{n}, n]$. Concretely, Hobbit's PCS is $\approx 3\text{--}4.5\times$ faster than Brakedown and Orion.

Ligerito[^NA25e] uses Ligero's matrix-vector product protocol with a partial sumcheck, supporting any linear code with efficiently-evaluable generator matrix rows.

Bolt[^GNR26e] introduces _sketched codes_ (composing random LDPCs) with $(3+\varepsilon) \cdot n$ field additions plus $(1+\varepsilon) \cdot n$ Merkle hashing for commitment. The code supports any rate close to 1, is systematic, and has constant distance.
Bolt is $\approx 1.34\times$ faster than Brakedown and $\approx 1.41\times$ faster than Blaze for commitment, with $\approx 2\times$ smaller proofs than Brakedown.

### Lattice-based (transparent, post-quantum)

{: .todo}
Build a comparison table for lattice-based MLE PCS schemes. Known schemes include:
Wee-Wu[^WW22e] (2022; succinct vector, polynomial, and functional commitments from lattices),
Albrecht et al.[^ACLplus22e] (2022; lattice-based SNARKs with a PCS component),
Cini et al.[^CMNW24e] (2024; post-quantum PCS with fast verification and transparent setup),
Greyhound[^NS24e] (2024; fast polynomial commitments from lattices),
and Jindo[^HLSS26e] (2026; practical lattice-based PCS for ZK arguments).

### Discrete-log-based (transparent)

| Scheme | Year | Assumption | CRS size | Prover | Verifier | Proof size | ZK |
|--------|------|------------|-------|--------|----------|------------|:--:|
| [Hyrax](/hyrax)[^WTSplus18] | 2018 | DL | $\sqrt{n}$ | $n$ | $\sqrt{n}$ | $\sqrt{n}$ | |

{: .smallnote}
Hyrax[^WTSplus18] uses a "split-and-fold" approach over Pedersen commitments with $O(\sqrt{n})$ generators. No trusted setup is needed.

### Pairing-based (transparent)

| Scheme | Year | Assumption | CRS size | Prover | Verifier | Proof size | ZK |
|--------|------|------------|-------|--------|----------|------------|:--:|
| Kopis-PC[^SL20e] | 2020 | SXDH | $n$ | $n$ | $\sqrt{n}$ | $\log n$ | |
| Dory[^Lee20Dory] | 2020 | SXDH | $n$ | $n$ | $\log n$ | $\log n$ | |

These schemes use pairings but require no trusted setup -- the CRS consists of random group elements in $\mathbb{G}_1$ and $\mathbb{G}_2$.

Kopis-PC[^SL20e] extends Hyrax by using doubly-homomorphic commitments (via SXDH pairings) to compress the commitment to $O(1)$ size and the proof to $O(\log n)$; verification remains $O(\sqrt{n})$.

Dory[^Lee20Dory] achieves logarithmic verification using inner-pairing-product arguments.

### Pairing-based (trusted setup)

| Scheme | Year | Assumption | CRS size | Prover | Verifier | Proof size | ZK |
|--------|------|------------|-------|--------|----------|------------|:--:|
| [PST](/pst)[^PST13] | 2013 | $q$-SBDH + pairings | $n$ | $n$ | $\log{n}$ | $\log{n}$ | |
| Libra[^XZZplus19e] | 2019 | $q$-SBDH + ext. PKE | $n$ | $n$ | $\log n$ | $\log n$ | &#x2713; |
| Gemini[^BCHO22e] | 2022 | pairings | $n$ | $n$ | $\log n$ | $\log n$ | |
| Orion+[^CBBZ22e] | 2022 | CRHF + expander codes + KZG | $\sqrt{n}$ | $n$ | $\log n$ | $\log n$ | |
| Zeromorph[^KT23e] | 2023 | pairings | $n$ | $n$ | $\log n$ | $\log n$ | &#x2713; |
| Testudo[^CGGeplus23ee] | 2023 | pairings | $\sqrt{n}$ | $n$ | $\log n$ | $\log n$ | |
| [KZH-2](/kzh)[^KZHB25e] | 2025 | pairings | $n$ | $n$ | $\sqrt{n}$ | $\sqrt{n}$ | |
| [KZH-$\log n$](/kzh)[^KZHB25e] | 2025 | pairings | $n$ | $n$ | $\log n$ | $\log n$ | |
| Mercury[^EG25e] | 2025 | pairings | $n$ | $n$ (no FFTs) | $\log n$ | $1$ | |
| Samaritan[^GPS25e] | 2025 | pairings | $n$ | $n$ | $\log n$ | $1$ | |

PST[^PST13] is the first multilinear PCS, reducing multilinear evaluation proofs to pairing checks.

Libra[^XZZplus19e] defines a **zkVPD** (zero-knowledge verifiable polynomial delegation) scheme, which is an MLE PCS with zero-knowledge. The underlying PCS is PST-based (via Zhang et al.), but Libra shows that adding ZK requires only a small masking polynomial with $O(d\ell)$ random coefficients (instead of an exponential-sized one), yielding an efficient zkVPD. The one-time trusted setup depends only on the input size $n$, not the circuit.

Gemini[^BCHO22e] reduces multilinear evaluations to univariate KZG[^KZG10] claims via "split-and-fold," yielding elastic SNARKs where the prover can trade time for space.

Orion+[^CBBZ22e] (from the HyperPlonk paper) improves on Orion by replacing Merkle-tree batch openings with KZG-based multilinear PCS batch openings, shrinking proofs from $O(\log^2 n)$ to $O(\log n)$ while keeping the linear-time prover; the KZG SRS is only $O(\sqrt{n})$ since it operates on the column hashes.

Zeromorph[^KT23e] also reduces to univariate KZG commitments via a multilinear-to-univariate isomorphism.

Testudo[^CGGeplus23ee] combines PST with inner pairing product arguments (MIPP) to achieve $O(\log n)$ proof size and verification with only $O(\sqrt{n})$ SRS size.
The prover operates on $\sqrt{n}$-sized polynomials (vs. $n$-sized in PST).
Testudo proposes wrapping the PCS verification inside a Groth16 circuit, compressing the final proof to $O(1)$.

[^testudo-groth16]: In the full Testudo SNARK, the verifier only checks the outer Groth16 proof (3 pairings). The Groth16 circuit must verify: (1) the Fiat-Shamir hash chain for the Spartan sumcheck, (2) the generalized MIPP verification ($\approx \log(n)/2$ pairing checks encoded as R1CS constraints), and (3) two PST opening verifications on $\sqrt{n}$-sized polynomials. This R1CS circuit has $O(\log n)$ constraints.

KZH[^KZHB25e] combines ideas from Hyrax and KZG, representing polynomial evaluation as a matrix-vector multiplication; the commitment is a single $\mathbb{G}_1$ element. KZH-2 requires only $O(\sqrt{n})$ opening time and proof size. KZH-$\log n$ achieves $O(\log n)$ proof size and verifier time but with quasilinear commitment time; it avoids target group elements (unlike Dory).

Mercury[^EG25e] and Samaritan[^GPS25e] (concurrent work) achieve **constant proof size** with a linear-time prover and no prover FFTs; both provide generic frameworks for transforming univariate PCS into multilinear PCS.

### Groups-of-unknown-order-based (transparent)

| Scheme | Year | Assumption | CRS size | Prover | Verifier | Proof size | ZK |
|--------|------|------------|-------|--------|----------|------------|:--:|
| DARK[^BFS19e] | 2019 | strong RSA + adaptive root | $1$ | $n \log n$ | $\log n$ | $\log n$ | |
| Dew[^AGLplus22e] | 2022 | GGM (class groups) | $1$ | $n^3$ | $\log n$ | $1$ | &#x2713; |
| DewTwo[^BMSS25e] | 2025 | strong RSA + modular consistency | $1$ | $n \log n$ | $\log n$ | $\log \log n$ | &#x2713; |

DARK[^BFS19e] constructs a PCS for $\mu$-variate degree-$d$ polynomials from integer commitments in groups of unknown order; for multilinear polynomials ($d=1$), proofs have $O(\log n)$ size.

Dew[^AGLplus22e] achieves constant-size evaluation proofs from class groups but has cubic prover time.

DewTwo[^BMSS25e] significantly improves on Dew with quasi-linear prover time, $O(\log \log n)$ proof size, and security under falsifiable assumptions (not the GGM).
Concretely, DewTwo proofs are under 4.5KB for $n \le 2^{30}$.

## Known SNARK frameworks from MLE PCSs

Libra[^XZZplus19e] is also a SNARK framework that combines its zkVPD (listed above) with a linear-time GKR prover and the sumcheck protocol, yielding the first ZKP with optimal $O(C)$ prover time and succinct $O(d \log C)$ proof size and verification for depth-$d$ log-space uniform circuits of size $C$.

Spartan[^Sett19e] later showed how to build SNARKs from _any_ MLE PCS + sumcheck (without GKR), driving much of the demand for efficient MLE PCS constructions.

HyperPLONK[^CBBZ22e] adapts PLONK to the multilinear setting, replacing univariate polynomial IOPs with multilinear ones and using the sumcheck protocol for high-degree custom gates, achieving a linear-time prover.

## References

For cited works, see below

{% include refs.md %}
