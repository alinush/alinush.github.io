---
tags:
 - keyless
 - Groth16
title: Groth16 and Aptos Keyless
#date: 2020-11-05 20:45:59
#published: false
permalink: keyless-groth16
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Notes on our use of Groth16 for [Aptos Keyless](/keyless).

<!--more-->

{% include pairings.md %}

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Performance

## Circuit size

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

### Proving time breakdown

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

## Appendix: PLONK

\# of “PLONK constraints” for the keyless relation is 6,421,050 (addition + multiplication gates, I believe.)

Set up a PLONK proving key using a larger 12 GiB powers-of-tau file:
```
node --max-old-space-size=$((8192*2)) $(which snarkjs) plonk setup  main.r1cs ~/Downloads/powersOfTau28_hez_final_23.ptau plonk.zkey
```

{: .todo}
Benchmark PLONK proving time.

## References

For cited works, see below 👇👇

{% include refs.md %}
