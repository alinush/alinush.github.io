---
tags:
 - digital signatures
 - post-quantum
title: Post-quantum signature schemes
#date: 2020-11-05 20:45:59
#published: false
permalink: post-quantum-signatures
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Some notes on post-quantum (PQ) signature schemes.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Notes 

This is a research blog post on the state-of-the-art PQ signature schemes.

Steps:

 - [x] Surveyed NIST's Round 2 additonal candidates[^nist-round-2-additional]
    * Filtered after Round 1. (See status report[^ABCplus24].)
    * See all schemes [here](/pictures/nist-round-1.png), with the advanced ones marked in $\textcolor{blue}{\text{blue}}$
        + **A criticism:** The MPC-in-the-Head schemes actually rely on all sorts of exotic assuptions. The caption makes it seem like they do not, which is confusing.
 - [x] Looked at [FAEST](#faest)
    - Not as fast to verify as SPHINCS+
    - Better if faster signing is desired (e.g., consensus signatures)
 - [x] Looked at [SLH-DSA (SPHINCS+)](#slh-dsa-sphincs)
    - This is ideal for the blockchain setting: minimal assumptions (just hashing), verification time descreases with signature size (by trading off signing time), standardized, sufficiently-succinct (e.g., 7.67 KiB)
 - [x] Found all FIPS standards[^fips]; not that many, hm.


## FAEST

{: .note}
See [FAEST website](https://faest.info/) for a full list of resources.

Notes:

 - introduced in 2023[^BBdplus23]
 - based on AES128/192/256 and **Vector Oblivious Linear Evaluation (VOLE) in the head (VOLEiTH)**
    + VOLEitH is constructed only from symmetric-key primitives
 - NIST cites it as _"somewhat complex"_ and says _"the security proof is very technical."_[^ABCplus24]

### Construction

\begin{align}
\pk &= (x,y)\\\\\
\sk &= k
\end{align}
such that:
\begin{align}
E_k(x) = y,\ \text{where}\ E\ \text{is a block cipher}
\end{align}

Signing works by doing a ZKPoK of $k$ using VOLEitH and the QuickSilver information-theoretic proof system[^YSWW21e] (under the Fiat-Shamir transform).

### Sizes

Secret and public keys are small: 32 bytes at 128-bit security.

Signature sizes are described below.

### Performance

Benchmarked on:
 > _"a single core of a consumer notebook with an AMD Ryzen 7 5800H processor, with a base clock speed of 3.2 GHz and 16 GiB memory."_ 
 > _"Simultaneous Multi-Threading was enabled."_
 > _The computer was running Linux 6.1.30, and the implementations were built with GCC 12.2.1."_

**Unoptimized** reference implementation is **too slow** (tens of milliseconds to verify):

<div align="center"><img style="width:60%" src="/pictures/faest-v1-ref-impl.png" /></div>

But **x86-64 AVX2** implementation could be **practical** at 128-bit security level (0.87 ms to verify 6,336-byte signatures):

{: .warning}
These numbers are **multi-threaded**!

<div align="center"><img style="width:80%" src="/pictures/faest-v1-x86_64-avx2-impl.png" /></div>

{: .note}
Perhaps this recent QuickSilver improvement[^BCCplus23e] will help?
I quote: _"For a circuit of size $\sizeof{C} = 2^{27}$, it shows up to 83.6× improvement on communication, compared to the general VOLE-ZK Quicksilver. In terms of running time, it is 70% faster when bandwidth is 10Mbps"_.\
\
[Pratik Sarkar suggests](https://x.com/pratiks_crypto/status/1998113981794529597) it likely does _not_.
And even if it does, it would require additively-homomorphic encryption like BGV, which would introduce additional assumptions.

## SLH-DSA (SPHINCS+)

{: .note}
See [SPHINCS website](https://sphincs.org/index.html) for a full list of resources.

 - FIPS-standardized[^FIPS205]
 - stateless, hash-based (hence the "SLH" acronym?)
 - _"an SLH-DSA key pair contains $2^{63}, 2^{64}, 2^{66}$, or $2^{68}$ **forest of random subsets (FORS)** keys"_
 - _"FORS allows each key pair to safely sign a small number of messages"_
 - _"An XMSS key consists of $2^{h'}$ WOTS$^+$ keys and can sign $2^{h'}$ messages"_
 - a rather-involved construction; would need to dig deeper to see if there's a simple design underneath
 - _"The SHA2-based parameter sets are 2x slower than the SHAKE-based ones"_

### Construction

Key generation, at a high-level, works like this:
```
(sk_seed, sk_prf, pk_seed) ← random()
root ← build_merkle_tree(sk_seed, pk_seed)
SK = (sk_seed, sk_prf, pk_seed, root)
PK = (pk_seed, root)
```

So, in the context of blockchain accounts, the user's mnemonic should be used to deterministically derive the `pk_seed`.
Otherwise, wallet recovery won't work.

### Sizes

Key and signature sizes from FIPS-205[^FIPS205]:

<div align="center"><img style="width:80%" src="/pictures/slh-dsa-sizes.png" /></div>

### `sphincs-shake-128f` benchmarks

{: .note}
16.69 KiB signature size, signing time is 17 ms and verification is 1.1 ms!

Benchmarking the **reference implementation** in C[^sphincsplus-git] on my Apple Macbook Pro, M1 Max below.
They only provide an ARM implementation for the SHAKE variant $\Rightarrow$ not sure what the SHA2 numbers would look like on ARM.

{: .todo}
Are these numbers single-threaded?

{: .todo}
Got this `kpc_get_thread_counters failed, run as sudo?` error (I think) during the `thash` benchmarks.

Building this variant on ARM via:
```
git clone https://github.com/sphincs/sphincsplus/
cd shake-a64/
make clean
make benchmark
```

The results, edited for clarity of exposition:
```
cc -Wall -Wextra -Wpedantic -Wmissing-prototypes -O3 -std=c99 -fomit-frame-pointer -flto -DPARAMS=sphincs-shake-128f  -o test/benchmark test/cycles.c hash_shake.c hash_shakex2.c thash_shake_robustx2.c address.c randombytes.c merkle.c wots.c utils.c utilsx2.c fors.c sign.c fips202.c fips202x2.c f1600x2_const.c f1600x2.s test/benchmark.c
wrong fixed counters count

arameters: n = 16, h = 66, d = 22, b = 6, k = 33, w = 16

Running 10 iterations.

thash                avg.        0.53 us
f1600x2              avg.        0.28 us
thashx2              avg.        0.58 us

Generating keypair.. avg.     1,294.10 us
  - WOTS pk gen 2x.. avg.       294.70 us
Signing..            avg.    17,255.30 us --> 17 ms
  - FORS signing..   avg.       853.00 us
  - WOTS pk gen x2.. avg.       176.80 us
Verifying..          avg.     1,096.50 us --> 1.1 ms

Signature size: 17,088 bytes (16.69 KiB)

Public key size: 32 bytes (0.03 KiB)
Secret key size: 64 bytes (0.06 KiB)
```

### `sphincs-shake-128s` benchmarks

{: .success}
**Clear winner:** hash-based, 7.67 KiB signatures created in 336 ms that verify in 0.4 ms!

Building this variant on ARM by via:
```
git clone https://github.com/sphincs/sphincsplus/
cd shake-a64/
gsed -i 's/shake-128f/shake-128s/g' Makefile
make clean
make benchmark
```

{: .warning}
Note that the `Makefile` was modified to build the shorter `s`-variant of SPHINCS+.

The results for `sphincs-shake-128s`, edited for clarity of exposition:
```
cc -Wall -Wextra -Wpedantic -Wmissing-prototypes -O3 -std=c99 -fomit-frame-pointer -flto -DPARAMS=sphincs-shake-128s  -o test/benchmark test/cycles.c hash_shake.c hash_shakex2.c thash_shake_robustx2.c address.c randombytes.c merkle.c wots.c utils.c utilsx2.c fors.c sign.c fips202.c fips202x2.c f1600x2_const.c f1600x2.s test/benchmark.c
wrong fixed counters count
Parameters: n = 16, h = 63, d = 7, b = 12, k = 14, w = 16

Running 10 iterations.

thash                avg.        0.94 us
f1600x2              avg.        0.38 us
thashx2              avg.        0.66 us

Generating keypair.. avg.    46,510.80 us
  - WOTS pk gen 2x.. avg.       178.80 us
Signing..            avg.   336,702.20 us --> 336.7 ms
  - FORS signing..   avg.    22,816.50 us
  - WOTS pk gen x2.. avg.       176.40 us
Verifying..          avg.       396.10 us --> 0.396 ms

Signature size: 7,856 bytes (7.67 KiB)

Public key size: 32 bytes (0.03 KiB)
Secret key size: 64 bytes (0.06 KiB)
```

### Performance of `RustCrypto/signatures`

{: .note}
Seems like a single-threaded implementation.

Bechmarked via:
```
git clone https://github.com/RustCrypto/signatures
cd slh-dsa/
cargo bench
```

{: .warning}
SHA2 variants are faster.
It may be because they leverage [native SHA2 instructions](https://developer.arm.com/documentation/ddi0602/2025-09/SIMD-FP-Instructions/SHA256SU0--SHA256-schedule-update-0-).

| Scheme                     | Signing Time | Verification Time  | Sig. size (bytes) |
|----------------------------|--------------|--------------------|-------------------|
| SLH-DSA-SHAKE-128**s**     | 1.06 s       | 0.98 ms            | 7,856             |
| SLH-DSA-SHAKE-192**s**     | 1.81 s       | 1.46 ms            | 16,224            |
| SLH-DSA-SHAKE-256**s**     | 1.58 s       | 2.11 ms            | 29,792            |
| SLH-DSA-SHAKE-128f         | 50.29 ms     | 3.14 ms            | 17,088            |
| SLH-DSA-SHAKE-192f         | 81.56 ms     | 4.35 ms            | 35,664            |
| SLH-DSA-SHAKE-256f         | 166.38 ms    | 4.59 ms            | 49,856            |
| SLH-DSA-SHA2-128**s**      | 137.45 ms    | 144.93 µs          | same              |
| SLH-DSA-SHA2-192**s**      | 285.07 ms    | 232.93 µs          | same              |
| SLH-DSA-SHA2-256**s**      | 254.05 ms    | 340.57 µs          | same              |
| SLH-DSA-SHA2-128f          | 6.61 ms      | 439.25 µs          | same              |
| SLH-DSA-SHA2-192f          | 12.38 ms     | 661.47 µs          | same              |
| SLH-DSA-SHA2-256f          | 24.27 ms     | 673.78 µs          | same              |

<!--
Original numbers:
sign: SLH-DSA-SHAKE-128s
                        time:   [1.0467 s 1.0654 s 1.0893 s]
sign: SLH-DSA-SHAKE-192s
                        time:   [1.8093 s 1.8197 s 1.8328 s]
sign: SLH-DSA-SHAKE-256s
                        time:   [1.5799 s 1.5827 s 1.5855 s]
sign: SLH-DSA-SHAKE-128f
                        time:   [50.081 ms 50.292 ms 50.802 ms]
sign: SLH-DSA-SHAKE-192f
                        time:   [81.099 ms 81.560 ms 82.367 ms]
sign: SLH-DSA-SHAKE-256f
                        time:   [165.23 ms 166.38 ms 168.39 ms]
sign: SLH-DSA-SHA2-128s time:   [137.21 ms 137.45 ms 137.75 ms]
sign: SLH-DSA-SHA2-192s time:   [278.83 ms 285.07 ms 294.38 ms]
sign: SLH-DSA-SHA2-256s time:   [253.64 ms 254.05 ms 254.46 ms]
sign: SLH-DSA-SHA2-128f time:   [6.6013 ms 6.6140 ms 6.6239 ms]
sign: SLH-DSA-SHA2-192f time:   [12.268 ms 12.382 ms 12.545 ms]
sign: SLH-DSA-SHA2-256f time:   [24.214 ms 24.279 ms 24.354 ms]

verify: SLH-DSA-SHAKE-128s
                        time:   [980.97 µs 983.51 µs 988.95 µs]
verify: SLH-DSA-SHAKE-192s
                        time:   [1.4479 ms 1.4635 ms 1.4714 ms]
verify: SLH-DSA-SHAKE-256s
                        time:   [2.1014 ms 2.1136 ms 2.1391 ms]
verify: SLH-DSA-SHAKE-128f
                        time:   [3.1024 ms 3.1490 ms 3.2435 ms]
verify: SLH-DSA-SHAKE-192f
                        time:   [4.3089 ms 4.3528 ms 4.3891 ms]
verify: SLH-DSA-SHAKE-256f
                        time:   [4.5738 ms 4.5958 ms 4.6214 ms]
verify: SLH-DSA-SHA2-128s
                        time:   [143.83 µs 144.93 µs 146.24 µs]
verify: SLH-DSA-SHA2-192s
                        time:   [230.55 µs 232.93 µs 234.93 µs]
verify: SLH-DSA-SHA2-256s
                        time:   [339.58 µs 340.57 µs 342.29 µs]
verify: SLH-DSA-SHA2-128f
                        time:   [435.58 µs 439.25 µs 442.55 µs]
verify: SLH-DSA-SHA2-192f
                        time:   [659.27 µs 661.47 µs 665.01 µs]
verify: SLH-DSA-SHA2-256f
                        time:   [672.90 µs 673.78 µs 674.49 µs]

-->

## TODO

### SIS-based schemes

{: .todo}
GPV hash-and-sign signatures and their plain-lattice descendants[^GPV07e].
(Also see [this](https://www.cs.columbia.edu/~tal/6261/SP13/lecture7-GPV.pdf?utm_source=chatgpt.com).)
"Fiat-Shamir with Aborts" signatures[^Lyub09]$,$[^Lyub12].
[Squirrels](https://csrc.nist.gov/csrc/media/Projects/pqc-dig-sig/documents/round-1/spec-files/Squirrels-spec-web.pdf).
[HuFu](https://csrc.nist.gov/csrc/media/Projects/pqc-dig-sig/documents/round-1/spec-files/HuFu-spec-web.pdf).
(Also see [this survey](https://csrc.nist.gov/csrc/media/events/workshop-on-cybersecurity-in-a-post-quantum-world/documents/papers/session9-oneill-paper.pdf?utm_source=chatgpt.com).)

### ML-DSA

{: .todo}
Investigate [ML-DSA](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.204.pdf), based on MLWE.

## References

For cited works, see below 👇👇

[^fips]: [FIPS publications](https://csrc.nist.gov/publications/fips)
[^sphincsplus-git]: [sphincs/sphincsplus](https://github.com/sphincs/sphincsplus.git)
[^nist-round-2-additional]: [Post-Quantum Cryptography: Additional Digital Signature Schemes (Round 2)](https://csrc.nist.gov/projects/pqc-dig-sig/round-2-additional-signatures)

{% include refs.md %}
