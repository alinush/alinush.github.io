---
tags:
 - keyless
 - Groth16
title: Zero-knowledge proofs for Aptos Keyless
#date: 2020-11-05 20:45:59
#published: false
permalink: keyless-zkp
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Notes on our current use of Groth16 for [Aptos Keyless](/keyless) and how we might improve upon it.

<!--more-->

{% include pairings.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Research roadmap

Recall the goals discussed [before](/keyless#what-is-the-ideal-zksnark-scheme-for-keyless):

 1. $\le$ 1.4 ms single-threaded individual ZKP verification time
 1. make it trivial to upgrade the keyless NP relation
    * trusted setups are cumbersome
    * universal setups are less cumbersome
    * transparent are amazing
 1. safely implement the NP relation so as to avoid relying on [training wheels](/training-wheels)
 1. client-side proving
    + or at least, minimize costs of running a prover service
 1. small proof sizes (1.5 KiB?)

If we were to prioritize the problem we'd like solved first (our pain points) while accounting for likelihood of solving things:

 1. Remove circuit-specific trusted setup (**tame complexity**)
 1. Implement keyless relation safely in Rust, not as a circuit (**security**) $\Rightarrow$ zkVMs
 1. Remove proving service (**tame complexity**, **reduce costs**)
 1. Prove obliviously via wrapping (**privacy**) $\Rightarrow$ Spartan, wrapped WHIR, [wrapped] HyperPLONK

There are **several directions** 👇 for replacing the keyless ZKP.
In fact, no matter which way we go, there may be some common work:
 1. **Formal verification:** formally-verify Keyless circuits, or zkVM implementation, or ZKP wrapping circuits
 1. **Cryptography:** MLE PCSs, zkSNARKs, efficient circuit representations, etc.

### Groth16-based

 1. **Faster delegated proving:**
    + _Milestone 0:_ Upgrade to UltraGroth16 $\Rightarrow$ no more Fiat-Shamir
        + _Path 1:_ modify `ark-groth16` into `ark-ultra-groth16` and rewrite circuit
        + _Path 2_: modify `circom`
    + _Milestone 1:_ Combine with FREpack/Zinc techniques
    - _Mileston 2:_ Deploy VKs for different SHA2-message lengths
        + Inform optimal message lengths by building a histogram of `iss`-specific JWT sizes

Other directions we can explore here:

 1. GPU-based Groth16 prover service
    - We'd need to optimize the cloud costs
        + Cheaper CPU instance + add one or more GPUs to it? Compare:
            + [32-core CPU instance](https://gcloud-compute.com/t2d-standard-32.html?utm_source=chatgpt.com) is \$1.63 / hour
            + vs. [4-core CPU instance](https://gcloud-compute.com/t2d-standard-4.html?utm_source=chatgpt.com) is \$0.20 / hour plus [older NVIDIA T4 GPU](https://cloud.google.com/compute/gpus-pricing?utm_source=chatgpt.com&hl=en) is \$0.35 / hour
            + $\Rightarrow$ 3x cheaper, maybe
    - Ingonyama has made [great progress on this](https://medium.com/@ingonyama/icicle-snark-the-fastest-groth16-implementation-in-the-world-00901b39a21f); repo [here](https://github.com/ingonyama-zk/icicle-snark/tree/master)
 1. There may be a small $\le 10\%$ proving time reduction via a different way to make Groth16 ZK

#### Dismissed directions

**Client-side proving:**
Even if we reduce the # of constraints $n$ to 100,000, there will likely still be $m \approx n$ variables $\Rightarrow$ [proving key](/groth16#mathsfgroth16setup_mathcalg1lambda-r-rightarrow-mathsfprkvktd) size will be $\approx 2m \Gr_1 + m\Gr_2 + n\Gr_1 \approx 2m\Gr_1 + 2m\Gr_1 + m\Gr_1 = 5m\Gr_1 \Rightarrow$ 500,000 $\times$ 32 bytes $\approx$ 15 MiB.

If we ignore the proving key issues, there'd be a few ways to speed up client proving:
 - Faster EC arithmetic in JavaScript/WASM
    + How optimized is `snarkjs`? I suspect very well-optimized.
 - Faster prover implementation via WebGPU $\Rightarrow$ prove $<5$ seconds

**Outsource 50% of the Groth16 proving to the client:**
In principle, the server could do any subset of the proving work while the client could do the rest.
For example, the client could do FFTs and MSM for $h(X)$, server could do MSMs for $\one{A},\two{B},\one{C}$

The **show stopper** is, once again, that we need to ensure the proving key is small on the client because webapps would need to download it.
So, this means the client can only do $\Gr_1$ MSMs of size $\min{(m,n)}$, where $m = $ # of R1CS variables and $n = $ # of constraints.
So, for $2^{20}$ constraints, this gives $2^{20} \times$ 32 bytes = 32 MiB prover key.
Too much communication.

We'd also have to be very carefu; with the TW signature, which should only be computed over valid proofs.
The client should not trick server into signing a bad proof.

### Spartan-based (PQ)

 1. **Research:**
    - ZK sumcheck
        - _Path 1:_ DeKART's ZK sumcheck
    - Dense MLE ZK PCS:
        + _Path 1:_ Survey ZK MLE PCS and pick one whose verification involves a constant-number of pairings and minimizes opening time over MLEs with small entries
    - Sparse MLE PCS:
        * _Path 1:_ Implement and iterate over [Cinder](/cinder)
        * _Path 2:_ KZH + GIPA
        * _Path 3:_ WHIR?
        - _Path 4:_ Leverage uniformity in R1CS matrices
 1. **Client-side proving:**
    - <u>Main blocker</u>: the size-$(m-2)$ PCS SRS, where $m$ is the # of R1CS variables
        + Assuming the worst case where the public statement $(\mathbf{x}, 1)$ is of size 2 and the witness $\mathbf{w}$ takes up the rest of the R1CS variables
    - _Milestone 1:_ 
        * can prove sumcheck and dense ZK MLE PCS opening client-side in < 5s
        + can prove sparse MLE PCS opening server-side < 1s
    - _Milestone 2_: can prove fully client-side < 5s

### PLONK-based

See some [PLONK explorations below](#plonk).
 
 1. **Research:**
    - Evaluate prover times on circuit sizes and inputs representative of keyless
 1. **Client-side proving:**
    - <u>Main blocker</u>: size-$n$ PCS SRS, where $n$ is the size of the circuit (# of additions + # of multiplications)
        + Currently, $n \approx$ 6.4 million
        - HyperPLONK has the same challenge

### HyperPLONK-based (PQ)

 1. **Research:**
    - ZK sumcheck
    - Dense (ZK?) MLE PCS (similar difficulty as in Spartan)
    - Choice of custom gates to reduce prover time
    - Wrap sumcheck
 1. **Client-side proving:**
    + Same as in PLONK [above](#plonk-based), except maybe custom gates don't have as big of an impact on prover time
    + (Note: in univariate PLONK, custom gates affect quotient poylnomial degree but do not affect KZG SRS size because, apparently, PLONK splits up the quotient polynomial into size-$n$ chunks)

### WHIR-based (PQ)

See some [WHIR explorations below](#whir).

 1. **Research:**
    1. Understand what the $\Sigma$-IOP for (G)R1CS in the WHIR paper looks like.
    1. Add ZK
    1. Wrapping WHIR fast
 1. **Client-side proving:** < 5s
    - _Milestone 1:_
        + prove WHIR client-side in < 5s
        + wrap server-side < 1s
    - _Milestone 2_: can prove fully client-side < 5s

### zkVM-based (PQ)

{: .todo}
Jolt, Ligero could be viable options very soon.

## Engineering roadmap

There's several things that, if we spend effort on, they are likely to be fruitful no matter what research direction we take:
 
 1. Reducing circuit size from 1.5M to 1M
 1. Registration-based, monetarily-incentivized, curve-agnostic, on-chain powers-of-$\tau$ and Groth16 setups

## Groth16 

### Circuit size

As of October 29th, 2025:

 - 1,438,805 constraints
 - 1,406,686 variables

Not relevant for Groth16, but for other zkSNARKs like Spartan:
 - The matrix $A$ has 4,203,190 non-zero terms
 - The matrix $B$ has 3,251,286 non-zero terms
 - The matrix $C$ has 2,055,196 non-zero terms
 - Total number of nonzero terms: 9,509,672

{: .note}
I think our `task.sh` script in [the keyless-zk-proofs repo](https://github.com/aptos-labs/keyless-zk-proofs/tree/main/scripts) can be used to reproduce these "# of non-zero entries" numbers.

### rapidsnark (modified) proving time

These are the times taken on a [`t2d-standard-4`](https://gcloud-compute.com/t2d-standard-4.html) VM for an older version of the circuit with 1.3M constraints and variables. 

| **Operation**                  | **Time (millis)** |
| ------------------------------ | -----------------:|
| MSM $\one{A}$                  |              276  |
| MSM $\one{B}$                  |              248  |
| MSM $\two{B}$                  |              885  |
| MSM $\one{C}$                  |              366  |
| **Total $A, B, C$ MSM**        |            1,775  |
| Calculating C time             |               18  |
| iFFT A time                    |              242  |
| Shift A time                   |               11  |
| FFT A time                     |              237  |
| iFFT B time                    |              240  |
| Shift B time                   |               10  |
| FFT B time                     |              237  |
| iFFT C time                    |              239  |
| Shift C time                   |               11  |
| FFT C time                     |              238  |
| **Total FFT time**             |            1,465  |
| ABC time                       |               21  |
| MSM $h(X)$ time                |            2,785  |
| **Total**                      |         **6,209** |

## PLONK

{: .note}
All benchmarks were run on my 10-core Macbook Pro M1 Max.

### snarkjs compiler

\# of “PLONK constraints” for the keyless relation is 6,421,050 (addition + multiplication gates, I believe.)

{: .info}
How?
Set up a PLONK proving key using a downloaded BN254 12 GiB powers-of-tau file and used ran a `snarkjs` command:
`node --max-old-space-size=$((8192*2)) $(which snarkjs) plonk setup  main.r1cs ~/Downloads/powersOfTau28_hez_final_23.ptau plonk.zkey`

### EspressoSystems/jellyfish

For `jellyfish`, I modified the benchmarks to [fix a bug](https://github.com/EspressoSystems/jellyfish/issues/413), exclude batch verification benches and increase the circuit size to $2^{22}$.
(I tried using the exact 6.4M circuit size, but `jellyfish` borked. Maybe it only likes powers of two.)
The `git` diff shows:
```diff
diff --git a/plonk/benches/bench.rs b/plonk/benches/bench.rs
index 256f0d53..9b8aec21 100644
--- a/plonk/benches/bench.rs
+++ b/plonk/benches/bench.rs
@@ -12,6 +12,7 @@ use ark_bls12_377::{Bls12_377, Fr as Fr377};
 use ark_bls12_381::{Bls12_381, Fr as Fr381};
 use ark_bn254::{Bn254, Fr as Fr254};
 use ark_bw6_761::{Fr as Fr761, BW6_761};
+use ark_serialize::{CanonicalSerialize, Compress};
 use ark_ff::PrimeField;
 use jf_plonk::{
     errors::PlonkError,
@@ -22,8 +23,9 @@ use jf_plonk::{
 use jf_relation::{Circuit, PlonkCircuit};
 use std::time::Instant;
 
+const NUM_PROVE_REPETITIONS: usize = 1;
 const NUM_REPETITIONS: usize = 10;
-const NUM_GATES_LARGE: usize = 32768;
+const NUM_GATES_LARGE: usize = 4_194_304;
 const NUM_GATES_SMALL: usize = 8192;
 
 fn gen_circuit_for_bench<F: PrimeField>(
@@ -58,31 +60,33 @@ macro_rules! plonk_prove_bench {
 
         let start = Instant::now();
 
-        for _ in 0..NUM_REPETITIONS {
+        for _ in 0..NUM_PROVE_REPETITIONS {
             let _ = PlonkKzgSnark::<$bench_curve>::prove::<_, _, StandardTranscript>(
                 rng, &cs, &pk, None,
             )
             .unwrap();
         }
 
+        let elapsed = start.elapsed();
+        println!(
+            "proving time total {}, {}: {} milliseconds",
+            stringify!($bench_curve),
+            stringify!($bench_plonk_type),
+            elapsed.as_millis() / NUM_PROVE_REPETITIONS as u128
+        );
+
         println!(
             "proving time for {}, {}: {} ns/gate",
             stringify!($bench_curve),
             stringify!($bench_plonk_type),
-            start.elapsed().as_nanos() / NUM_REPETITIONS as u128 / $num_gates as u128
+            elapsed.as_nanos() / NUM_PROVE_REPETITIONS as u128 / $num_gates as u128
         );
     };
 }
 
 fn bench_prove() {
-    plonk_prove_bench!(Bls12_381, Fr381, PlonkType::TurboPlonk, NUM_GATES_LARGE);
-    plonk_prove_bench!(Bls12_377, Fr377, PlonkType::TurboPlonk, NUM_GATES_LARGE);
     plonk_prove_bench!(Bn254, Fr254, PlonkType::TurboPlonk, NUM_GATES_LARGE);
-    plonk_prove_bench!(BW6_761, Fr761, PlonkType::TurboPlonk, NUM_GATES_SMALL);
-    plonk_prove_bench!(Bls12_381, Fr381, PlonkType::UltraPlonk, NUM_GATES_LARGE);
-    plonk_prove_bench!(Bls12_377, Fr377, PlonkType::UltraPlonk, NUM_GATES_LARGE);
     plonk_prove_bench!(Bn254, Fr254, PlonkType::UltraPlonk, NUM_GATES_LARGE);
-    plonk_prove_bench!(BW6_761, Fr761, PlonkType::UltraPlonk, NUM_GATES_SMALL);
 }
 
 macro_rules! plonk_verify_bench {
@@ -91,7 +95,7 @@ macro_rules! plonk_verify_bench {
         let cs = gen_circuit_for_bench::<$bench_field>($num_gates, $bench_plonk_type).unwrap();
 
         let max_degree = $num_gates + 2;
-        let srs = PlonkKzgSnark::<$bench_curve>::universal_setup(max_degree, rng).unwrap();
+        let srs = PlonkKzgSnark::<$bench_curve>::universal_setup_for_testing(max_degree, rng).unwrap();
 
         let (pk, vk) = PlonkKzgSnark::<$bench_curve>::preprocess(&srs, &cs).unwrap();
 
@@ -99,6 +103,14 @@ macro_rules! plonk_verify_bench {
             PlonkKzgSnark::<$bench_curve>::prove::<_, _, StandardTranscript>(rng, &cs, &pk, None)
                 .unwrap();
 
+        let mut bytes = Vec::with_capacity(proof.serialized_size(Compress::Yes));
+        proof.serialize_with_mode(&mut bytes, Compress::Yes).unwrap();
+
+        println!(
+            "proof size: {} bytes",
+            bytes.len()
+        );
+
         let start = Instant::now();
 
         for _ in 0..NUM_REPETITIONS {
@@ -117,14 +129,8 @@ macro_rules! plonk_verify_bench {
 }
 
 fn bench_verify() {
-    plonk_verify_bench!(Bls12_381, Fr381, PlonkType::TurboPlonk, NUM_GATES_LARGE);
-    plonk_verify_bench!(Bls12_377, Fr377, PlonkType::TurboPlonk, NUM_GATES_LARGE);
-    plonk_verify_bench!(Bn254, Fr254, PlonkType::TurboPlonk, NUM_GATES_LARGE);
-    plonk_verify_bench!(BW6_761, Fr761, PlonkType::TurboPlonk, NUM_GATES_SMALL);
-    plonk_verify_bench!(Bls12_381, Fr381, PlonkType::UltraPlonk, NUM_GATES_LARGE);
-    plonk_verify_bench!(Bls12_377, Fr377, PlonkType::UltraPlonk, NUM_GATES_LARGE);
-    plonk_verify_bench!(Bn254, Fr254, PlonkType::UltraPlonk, NUM_GATES_LARGE);
-    plonk_verify_bench!(BW6_761, Fr761, PlonkType::UltraPlonk, NUM_GATES_SMALL);
+    plonk_verify_bench!(Bn254, Fr254, PlonkType::TurboPlonk, NUM_GATES_SMALL);
+    plonk_verify_bench!(Bn254, Fr254, PlonkType::UltraPlonk, NUM_GATES_SMALL);
 }
 
 macro_rules! plonk_batch_verify_bench {
@@ -168,19 +174,7 @@ macro_rules! plonk_batch_verify_bench {
     };
 }
 
-fn bench_batch_verify() {
-    plonk_batch_verify_bench!(Bls12_381, Fr381, PlonkType::TurboPlonk, 1000);
-    plonk_batch_verify_bench!(Bls12_377, Fr377, PlonkType::TurboPlonk, 1000);
-    plonk_batch_verify_bench!(Bn254, Fr254, PlonkType::TurboPlonk, 1000);
-    plonk_batch_verify_bench!(BW6_761, Fr761, PlonkType::TurboPlonk, 1000);
-    plonk_batch_verify_bench!(Bls12_381, Fr381, PlonkType::UltraPlonk, 1000);
-    plonk_batch_verify_bench!(Bls12_377, Fr377, PlonkType::UltraPlonk, 1000);
-    plonk_batch_verify_bench!(Bn254, Fr254, PlonkType::UltraPlonk, 1000);
-    plonk_batch_verify_bench!(BW6_761, Fr761, PlonkType::UltraPlonk, 1000);
-}
-
 fn main() {
-    bench_prove();
+    // bench_prove();
     bench_verify();
-    bench_batch_verify();
 }
```

<!--
`espressosystems/jellyfish` PLONK proof verification times:
```
verifying time for Bn254, PlonkType::TurboPlonk: 1356712 ns ==> 1.35 ms
verifying time for Bn254, PlonkType::UltraPlonk: 1405920 ns ==> 1.40 ms

RAYON_NUM_THREADS=1
verifying time for Bn254, PlonkType::TurboPlonk: 1548500 ns
verifying time for Bn254, PlonkType::UltraPlonk: 1721287 ns

proving time total Bn254, PlonkType::TurboPlonk: 104160 milliseconds
proving time for Bn254, PlonkType::TurboPlonk: 24833 ns/gate
proving time total Bn254, PlonkType::UltraPlonk: 190865 milliseconds
proving time for Bn254, PlonkType::UltraPlonk: 45505 ns/gate
```
-->

Then, to run the benchmarks, in the root of the repo as per the [README](https://github.com/EspressoSystems/jellyfish/?tab=readme-ov-file#plonk-proof-generationverification), I ran:
```
time cargo bench --bench plonk-benches --features=test-srs
```
To run single-threaded:
```
time RAYON_NUM_THREADS=1 cargo bench --bench plonk-benches --features=test-srs
```

Notes:

 1. It generates a circuit with just addition gates
    + It just insert $n$ gates where gate $i$ simply adds 1 to gate $i-1$
 1. By default runs multithread on all cores (judging from `htop` output)
 1. Single-threaded verification is a little bit slower
 1. TurboPLONK has custom gates and UltraPLONK adds lookups
    
**Uncertainties:**

 1. What is the relation being proved? The public input in the code is the empty vector.
 1. What values do the gates get assigned? Otherwise, hard to understand the MSM work being done.
    + It is unclear what gate 0 is initialized to: note that `cs.zero()` does not mean the gate is given the value 0!
 1. Will the UltraPLONK verifier costs always be 1.36 ms no matter what the circuit is?
 1. What overhead do custom gates add over vanilla PLONK?

| **Library** | Scheme     | # gates  | # threads | **Prove**   | **Verify** | **Proof**   |
| ----------- | ---------- | -------- | --------- | ----------- | ---------- | -----------:|
| jellyfish   | TurboPLONK | $2^{22}$ | default   | 104.16 secs | 1.36 ms    | 769 bytes   |
| jellyfish   | UltraPLONK | $2^{22}$ | default   | 190.86 secs | 1.41 ms    | 1,481 bytes |
| jellyfish   | TurboPLONK | $2^{13}$ | 1         | don't care  | 1.55 ms    | 769 bytes   |
| jellyfish   | UltraPLONK | $2^{13}$ | 1         | don't care  | 1.72 ms    | 1,481 bytes |


{: .todo}
Benchmark single-thread `jellyfish` proving times.
Play with the witness size: figure out how to initialize the first gate to 0 vs. $p/2$.
Benchmark the [CAP library](https://github.com/EspressoSystems/cap) to get a sense if custom gates add more verifier time.

### EspressoSystems/hyperplonk

{: .todo}
Run some benchmarks [here](https://github.com/EspressoSystems/hyperplonk/blob/main/hyperplonk/benches/bench.rs)

### dusk-network/plonk

{: .todo}
Benchmark `dusk-network/plonk` PLONK.

## WHIR

{: .todo}
Include Yinuo's numbers.

## Ligetron

Notes from the ZKProof presentation[^muthu-zkproof7] below:

 - Proving WASM executions.
 - ZK by default.
 - WebGPU acceleration.
 - Hash-based + code-interleaving.
 - Streaming prover ("witness and constraints can be streamed").
 - Proving key is allegedly small.
 - Based on MPCitH. See (Simons?) Berkley talk for more depth, potentially.
 - Prover is memory efficient: memory usage is proportional to what the WASM program uses.
 - To get memory efficiency they sacrifice proof length (otherwise, it's hard due to inherent time-space trade-offs in error-correcting codes based on the distance of the code).
 - Encodes full witness as a $\sqrt{n}$ by $\sqrt{n}$ matrix
 - Can "stream the matrix" into the IOP to ensure memory is $O(\sqrt{n})$

## References

For cited works, see below 👇👇

[^muthu-zkproof7]: [ZKVM - To Compile Or Precompile - Muthu Venkitasubramaniam](https://youtu.be/eZEwcOxSsj0?t=447)

{% include refs.md %}
