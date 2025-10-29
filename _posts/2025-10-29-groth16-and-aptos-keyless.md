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

## References

For cited works, see below 👇👇

{% include refs.md %}
