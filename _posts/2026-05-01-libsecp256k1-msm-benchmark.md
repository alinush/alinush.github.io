---
type: note
tags:
 - ecdsa
 - elliptic curves
title: "Benchmarking MSMs over secp256k1"
#date: 2020-11-05 20:45:59
#published: false
permalink: secp256k1-msm
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Running some secp256k1 MSM benchmarks.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Background

For ECDSA verification and pubkey recovery, the relevant MSM size is $n=2$.
For **(modified) ECDSA batch verification**, we will be interested in $n \ge 4$.

### GLV

secp256k1 has a GLV endomorphism $\phi(x,y)=(\beta x, y)$, where $\beta$ is a primitive cube root of 1 over the base field $\F_p$.
This lets you split a 256-bit scalar into two ~128-bit halves, speeding up scalar multiplication arithmetic.

The four libraries benchmarked below differ in where they apply GLV:

| Library                    | Single-mul GLV | MSM GLV |
|----------------------------|:--------------:|:-------:|
| `p256k1` (FFI to libsecp256k1) | ✅              | ✅       |
| `gnark-crypto`             | ✅              | ❌       |
| `ark-secp256k1`            | ❌              | ❌       |
| `halo2curves`              | ❌              | ❌       |

For `p256k1`, both [Strauss-WNAF and Pippenger-WNAF in `libsecp256k1`](https://github.com/bitcoin-core/secp256k1/blob/master/src/ecmult_impl.h) call `secp256k1_scalar_split_lambda` (resp. `secp256k1_ecmult_endo_split`) to feed Pippenger $2n$ pairs of half-length scalars instead of $n$ pairs of full-length scalars.

For `gnark-crypto`, only the per-point [`mulGLV`](https://github.com/Consensys/gnark-crypto/blob/master/ecc/secp256k1/g1.go) path uses the endomorphism; `MultiExp` runs Pippenger over the full 256-bit scalars (no `glv`/`phi`/`endomorph` references in `multiexp*.go`).

For `ark-secp256k1`, the [`GLVConfig`](https://docs.rs/ark-ec/latest/ark_ec/scalar_mul/glv/trait.GLVConfig.html) trait exists in `ark-ec`, but no curve in [`arkworks-rs/algebra`](https://github.com/arkworks-rs/algebra) implements it (`grep -rln "impl GLVConfig\|GLVConfig for"` is empty). secp256k1 only implements `SWCurveConfig`, so both `mul` and `VariableBaseMSM::msm` use the generic double-and-add over 256-bit scalars.

For `halo2curves`, the [`CurveEndo`](https://github.com/privacy-ethereum/halo2curves/blob/main/src/arithmetic.rs) trait exists and the [`endo!`](https://github.com/privacy-ethereum/halo2curves/blob/main/src/derive/curve.rs) macro provides a `decompose_scalar` impl for curves like `bn256` (`endo!(G1, Fr, ENDO_PARAMS_BN);`). But [`secp256k1/curve.rs`](https://github.com/privacy-ethereum/halo2curves/blob/main/src/secp256k1/curve.rs) never invokes the macro, so `Secp256k1` doesn't implement `CurveEndo`. Independently, [`msm.rs`](https://github.com/privacy-ethereum/halo2curves/blob/main/src/msm.rs) doesn't reference `CurveEndo::decompose_scalar` at all — `msm_serial`/`msm_parallel`/`msm_best` run Pippenger (with Booth encoding) over full 256-bit scalars regardless of whether the curve has GLV.

## p256k1

Bitcoin Core's [`libsecp256k1`](https://github.com/bitcoin-core/secp256k1) C library ships a Pippenger-WNAF [multi-scalar multiplication (MSM)](https://en.wikipedia.org/wiki/Exponentiation_by_squaring#Multi-scalar) routine, but neither the Rust [`secp256k1`](https://crates.io/crates/secp256k1) crate nor the pure-Rust [`libsecp256k1`](https://crates.io/crates/libsecp256k1) port expose it. i
The [`p256k1`](https://github.com/Trust-Machines/p256k1) crate does.

Below I benchmark its MSM.

`libsecp256k1` exposes `secp256k1_ecmult` for individual signature verication (and for pubkey recovery) and exposes `secp256k1_ecmult_multi_var` for $n$-element MSM, dispatched to either Strauss-WNAF (small $n$) or Pippenger-WNAF (larger $n$). The cutoff is `ECMULT_PIPPENGER_THRESHOLD = 88` ([line 55 of `ecmult_impl.h`](https://github.com/bitcoin-core/secp256k1/blob/master/src/ecmult_impl.h#L55)): for $n < 88$ the library calls `secp256k1_ecmult_strauss_wnaf`, and for $n \ge 88$ it calls `secp256k1_ecmult_pippenger_wnaf`. So in the table below, the rows for $n \in \\{2, 4, 8, 16, 32, 64\\}$ measure Strauss-WNAF + GLV, and the rows for $n \in \\{128, 256, 512, 1024\\}$ measure Pippenger-WNAF + GLV.

### Run the benchmark

I [forked](https://github.com/alinush/p256k1/tree/msm-benchmark) the `p256k1` crate and added
1. a [Criterion](https://github.com/bheisler/criterion.rs) benchmark that times `Point::multimult` 
2. a naive `for i in 0..n { p += scalars[i] * points[i] }` loop for $n \in \\{2, 4, \ldots, 1024\\}$, 
3. a `run-benches.sh` script that runs these, parses Criterion's `estimates.json` files and outputs a Markdown table.

```bash
git clone --branch msm-benchmark https://github.com/alinush/p256k1.git
cd p256k1
# The script needs `cargo`, `jq`, `awk`, and `bc`.
./run-benches.sh
```

Benchmarks shoud take ~1-2 minutes to run.

### Results

Run on an Apple M4 Max, release build:

| $n$  | MSM (µs)   | Naive (µs) | Speedup | µs per scalar mul (MSM) | µs per scalar mul (Naive) |
|-----:|-----------:|-----------:|--------:|------------------------:|--------------------------:|
|    2 |     13.130 |     19.994 |   1.52x |       6.565 |        9.997 |
|    4 |     48.409 |     47.073 |   0.97x |      12.102 |       11.768 |
|    8 |     69.829 |     94.050 |   1.34x |       8.728 |       11.756 |
|   16 |    111.468 |    189.588 |   1.70x |       6.966 |       11.849 |
|   32 |    201.065 |    379.832 |   1.88x |       6.283 |       11.869 |
|   64 |    377.774 |    763.196 |   2.02x |       5.902 |       11.924 |
|  128 |    641.421 |   1521.647 |   2.37x |       5.011 |       11.887 |
|  256 |   1133.065 |   3059.156 |   2.69x |       4.426 |       11.949 |
|  512 |   1966.887 |   6151.611 |   3.12x |       3.841 |       12.014 |
| 1024 |   3626.145 |  12418.983 |   3.42x |       3.541 |       12.127 |

{: .info}
**Note (size-2 row uses the dedicated path):** The $n=2$ row measures the **specialized size-2 multiexp** that ECDSA verify and pubkey recovery actually call (`secp256k1_ecmult` in libsecp256k1, exposed in my fork as `Point::ecmult`).
This leverages precomputed odd-multiples table for the fixed generator $G$. 
For reference, passing $n=2$ to the *generic* `secp256k1_ecmult_multi_var` instead, which treats $G$ as a random base, would give ≈24.6 µs, about **2× slower**.

{: .info}
**Note (batch-normalize patch in my fork):** The numbers above are from a [small patch](https://github.com/alinush/p256k1/tree/msm-benchmark) to `Point::multimult`: a batch-inversion replacement of $n$ inversions that gives a clean **~30% speedup at $n=1024$** (from 4734 µs down to 3644 µs).

### Future optimizations
{: #future-optimizations}

For large $n$, `blst` and `halo2curves` use Pippenger with **batched affine addition**: they keep Pippenger's bucket sums in *affine* coordinates and amortize many independent slope-inversions via Montgomery's simultaneous-inversion trick. 
To understand the potential speed-ups, I vibe-coded a small Rust [proof-of-concept](https://github.com/alinush/p256k1/tree/msm-benchmark) timing $K$ independent affine additions with (1) $K$ independent inversions vs. (2) one shared inversion.
(There's a unit test that verifies both paths agree element-wise.)
Run from the same fork via:

```bash
git clone --branch msm-benchmark https://github.com/alinush/p256k1.git
cd p256k1
cargo bench --bench affine_add_bench
```

| $K$ | Naive (µs) | Batched (µs) | Speedup | Naive µs / add | Batched µs / add |
|----:|-----------:|-------------:|--------:|---------------:|-----------------:|
|   2 |       4.99 |         3.79 |   1.32x |          2.50 |             1.90 |
|   4 |       7.35 |         4.23 |   1.74x |          1.84 |             1.06 |
|   8 |      12.52 |         5.20 |   2.41x |          1.57 |             0.65 |
|  16 |      22.65 |         6.74 |   3.36x |          1.42 |             0.42 |
|  32 |      42.81 |        10.07 |   4.25x |          1.34 |             0.32 |
|  64 |      83.45 |        16.69 |   5.00x |          1.30 |             0.26 |
|  128 |     163.94 |        30.41 |   5.39x |          1.28 |             0.24 |
|  256 |     328.90 |        57.49 |   5.72x |          1.29 |             0.23 |

{: .info}
**What this means for Pippenger MSMs:** The relevant comparison is batched-affine (≈0.23 µs/add) vs. `libsecp256k1`'s current mixed Jacobian+affine add (`secp256k1_gej_add_ge_var`, no inversion, ≈0.5-0.6 µs/add) $\Rightarrow$ a **~2-2.5× per-add speedup**. 
Since bucket-fill is roughly half of Pippenger's work, plumbing this into `secp256k1_ecmult_pippenger_wnaf` should give ~25-30% more on top of the batch-normalize patch.
**Caveat:** This only helps the Pippenger path ($n \ge 88$).
For $n < 88$ (i.e., ECDSA verify, recovery, and most small instances of batch-verify), `libsecp256k1` uses Strauss-WNAF, whose serial-accumulator inner loop has no parallel adds to batch.

## ark-secp256k1

The pure-Rust [`ark-secp256k1`](https://crates.io/crates/ark-secp256k1) crate (part of [arkworks](https://github.com/arkworks-rs/algebra)) exposes a generic Pippenger MSM via the [`VariableBaseMSM`](https://docs.rs/ark-ec/latest/ark_ec/scalar_mul/variable_base/trait.VariableBaseMSM.html) trait: `Projective::msm(&bases, &scalars)`.

Unlike `p256k1`, this is pure Rust: no FFI, no hand-tuned assembly.
As a result, things are slower.

### Run the benchmark

In the same [fork](https://github.com/alinush/p256k1/tree/msm-benchmark), I added:
1. a Criterion benchmark that times `<Projective as VariableBaseMSM>::msm(&bases, &scalars)`,
2. a naive `for i in 0..n { p += bases[i] * scalars[i] }` loop for $n \in \\{2, 4, \ldots, 1024\\}$,
3. a `run-arkworks-benches.sh` script that runs these and outputs a Markdown table.

```bash
git clone --branch msm-benchmark https://github.com/alinush/p256k1.git
cd p256k1
# The script needs `cargo`, `jq`, `awk`, and `bc`.
./run-arkworks-benches.sh
```

Benchmarks should take ~1-2 minutes to run.

### Results

Run on the same Apple M4 Max, release build:

| $n$   | MSM (µs)   | Naive (µs) | Speedup | µs per scalar mul (MSM) | µs per scalar mul (Naive) |
|-----:|-----------:|-----------:|--------:|------------------------:|--------------------------:|
|    2 |     88.712 |     88.666 |   0.99x |      44.356 |       44.333 |
|    4 |    131.302 |    173.934 |   1.32x |      32.825 |       43.483 |
|    8 |    187.550 |    355.432 |   1.89x |      23.443 |       44.429 |
|   16 |    292.609 |    775.267 |   2.64x |      18.288 |       48.454 |
|   32 |    491.861 |   1799.569 |   3.65x |      15.370 |       56.236 |
|   64 |    842.343 |   3720.552 |   4.41x |      13.161 |       58.133 |
|  128 |   1373.081 |   7650.410 |   5.57x |      10.727 |       59.768 |
|  256 |   2531.880 |  15444.088 |   6.09x |       9.890 |       60.328 |
|  512 |   4649.651 |  31023.133 |   6.67x |       9.081 |       60.592 |
| 1024 |   8119.509 |  62420.595 |   7.68x |       7.929 |       60.957 |

## gnark-crypto

[`gnark-crypto`](https://github.com/Consensys/gnark-crypto) is Consensys' Go cryptography library. 
Its `ecc/secp256k1` package is code-generated (per-curve specialization, including modulus-specific Montgomery arithmetic) and exposes [`MultiExp`](https://pkg.go.dev/github.com/consensys/gnark-crypto/ecc/secp256k1#G1Jac.MultiExp), implementing the Pippenger variant from [eprint 2012/549](https://eprint.iacr.org/2012/549.pdf).

For a fair comparison, I run `MultiExp` with `MultiExpConfig{NbTasks: 1}` (single goroutine), since `p256k1` and `ark-secp256k1` above are also single-threaded.

### Run the benchmark

I [forked](https://github.com/alinush/gnark-crypto/tree/secp256k1-msm-benchmark) `gnark-crypto` and added:
1. a Go benchmark `BenchmarkMSMSizes` in `ecc/secp256k1` that times `(*G1Affine).MultiExp(points, scalars, ecc.MultiExpConfig{NbTasks: 1})`,
2. a naive `for i := 0; i < n; i++ { tmp.ScalarMultiplication(&p[i], s[i]); acc.AddAssign(&tmp) }` loop for $n \in \\{2, 4, \ldots, 1024\\}$,
3. a `run-gnark-benches.sh` script that runs these and parses `go test -bench` output into a Markdown table.

```bash
git clone --branch secp256k1-msm-benchmark https://github.com/alinush/gnark-crypto.git
cd gnark-crypto
# The script needs `go` and `awk`.
./run-gnark-benches.sh
```

Benchmarks should take ~1-2 minutes to run.

### Results

Run on the same Apple M4 Max, release build (Go's default; optimizations + inlining are on unless you explicitly pass `-gcflags='all=-N -l'`):

| $n$  | MSM (µs)   | Naive (µs) | Speedup | µs per scalar mul (MSM) | µs per scalar mul (Naive) |
|-----:|-----------:|-----------:|--------:|------------------------:|--------------------------:|
|    2 |    162.226 |     53.448 |   0.33x |      81.113 |       26.724 |
|    4 |    242.297 |    125.605 |   0.52x |      60.574 |       31.401 |
|    8 |    317.981 |    273.368 |   0.86x |      39.748 |       34.171 |
|   16 |    442.898 |    561.851 |   1.27x |      27.681 |       35.116 |
|   32 |    654.000 |   1229.385 |   1.88x |      20.438 |       38.418 |
|   64 |    975.187 |   2856.921 |   2.93x |      15.237 |       44.639 |
|  128 |   1683.287 |   5882.025 |   3.49x |      13.151 |       45.953 |
|  256 |   2877.386 |  12113.487 |   4.21x |      11.240 |       47.318 |
|  512 |   4718.920 |  24435.621 |   5.18x |       9.217 |       47.726 |
| 1024 |   8077.244 |  50120.264 |   6.21x |       7.888 |       48.946 |

{: .note}
From speaking with [Youssef El Housni](https://yelhousni.github.io/), it seems like their secp256k1 implementation is unoptimized; it's just there for some witness generation when proving ECDSA signatures.

## halo2curves

The [`msm`](https://github.com/privacy-ethereum/halo2curves/blob/main/src/msm.rs) module exposes:
 - `msm_serial` (single-threaded), 
 - `msm_parallel` (rayon-based),
    + simple _"chunk the input across threads, run `msm_serial` on each chunk, sum"_ pattern
 - `msm_best` (picks based on input size):
    + for $\lceil \ln(n) \rceil < 10$ (i.e., $n \lesssim 22{,}000$, including all sizes in this post) it calls `msm_parallel`, which is rayon-parallelized but runs the *same* Pippenger as `msm_serial` per thread.
        * $\Rightarrow$ in our $n \leq 1024$ range, `msm_best` would use `msm_parallel`, which we do not want.
    + for $\lceil \ln(n) \rceil \ge 10$ it switches to a window-parallelized variant with a different memory layout.
        * this variant is not exposed as a `msm_*` function, apparently

The MSM is generic over `CurveAffine` and uses Pippenger with Booth signed-digit encoding.

As noted in the [GLV table](#glv) above, halo2curves' secp256k1 module does **not** plug into the library's `CurveEndo` trait, and `msm.rs` ignores `CurveEndo` regardless. So this is the slowest of the four implementations: pure-Rust, no GLV, *and* no curve-specific field arithmetic tuning for secp256k1's pseudo-Mersenne prime $p = 2^{256} - 2^{32} - 977$.

We benchmark **`msm_serial`** (not `msm_best`) so the comparison is apples-to-apples with the other single-threaded benches in this post. 

### Run the benchmark

I [forked](https://github.com/alinush/halo2curves/tree/secp256k1-msm-benchmark) `halo2curves` and added:
1. a Criterion benchmark `benches/secp256k1_msm_sizes.rs` that times `msm_serial(&scalars, &bases, &mut acc)`,
2. a naive `for i in 0..n { acc += bases[i] * scalars[i] }` loop for $n \in \\{2, 4, \ldots, 1024\\}$,
3. a `run-halo2curves-benches.sh` script that runs these and outputs a Markdown table.

```bash
git clone --branch secp256k1-msm-benchmark https://github.com/alinush/halo2curves.git
cd halo2curves
# The script needs `cargo`, `jq`, `awk`, and `bc`.
./run-halo2curves-benches.sh
```

Benchmarks should take ~1-2 minutes to run.

### Results

Run on the same Apple M4 Max, release build:

| $n$  | MSM (µs)   | Naive (µs) | Speedup | µs per scalar mul (MSM) | µs per scalar mul (Naive) |
|-----:|-----------:|-----------:|--------:|------------------------:|--------------------------:|
|    2 |    238.247 |    266.017 |   1.11x |     119.123 |      133.008 |
|    4 |    272.565 |    531.791 |   1.95x |      68.141 |      132.947 |
|    8 |    377.622 |   1064.668 |   2.81x |      47.202 |      133.083 |
|   16 |    581.653 |   2131.086 |   3.66x |      36.353 |      133.192 |
|   32 |    883.423 |   4256.997 |   4.81x |      27.606 |      133.031 |
|   64 |   1412.361 |   8522.399 |   6.03x |      22.068 |      133.162 |
|  128 |   2436.448 |  17030.856 |   6.99x |      19.034 |      133.053 |
|  256 |   4065.745 |  34042.049 |   8.37x |      15.881 |      132.976 |
|  512 |   6999.182 |  68019.231 |   9.71x |      13.670 |      132.850 |
| 1024 |  12951.051 | 136053.208 |  10.50x |      12.647 |      132.864 |
{: .table-display}

## References

For cited works, see below 👇👇

{% include refs.md %}
