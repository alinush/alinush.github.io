---
tags:
 - Merkle
 - accumulators
 - anonymous payments
 - elliptic curves
title: Curve trees
#date: 2020-11-05 20:45:59
published: true
permalink: curve-trees
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** A few notes on the beautiful curve tree work by Campanelli, Hall-Andersen and Kamp.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## $\mathbb{V}$cash anonymous payments experiments

Ran a subset of the (modified) benchmarks, in a **single thread**, on my Apple Macbook Pro M1 Max.
The benchmared scheme does not implement a proper PRF-based nullifier scheme, AFAICT.
It does prove values are in-range using Bulletproofs.
(I think it combines the range proof statement with the curve tree statement over the curve used in the leaves, and proves it all in one.)

See [diff](/files/curve-tree-vcash-benches.diff) here.

Results over Pasta and Vellas curves:
```
Single_threadedPour_Curves:pasta_L:1024_D:4_ProofSize: 3970 bytes

Single_threadedPour_Curves:pasta_L:1024_D:4/prove
                        time:   [7.1789 s 7.2110 s 7.2427 s]

Single_threadedPour_Curves:pasta_L:1024_D:4_batch_verification/1
                        time:   [298.39 ms 299.27 ms 300.13 ms]

Single_threadedPour_Curves:pasta_L:1024_D:4_batch_verification/100
                        time:   [2.1153 s 2.1255 s 2.1355 s]
```

Results over secp256k1 and secp256r1 curves:
```
Single_threadedPour_Curves:secp&q_L:1024_D:4_ProofSize: 3970 bytes

Single_threadedPour_Curves:secp&q_L:1024_D:4/prove
                        time:   [8.4621 s 8.4874 s 8.5097 s]

Single_threadedPour_Curves:secp&q_L:1024_D:4_batch_verification/1
                        time:   [347.31 ms 348.01 ms 348.73 ms]

Single_threadedPour_Curves:secp&q_L:1024_D:4_batch_verification/100
                        time:   [2.4206 s 2.4312 s 2.4428 s]

```

{: .note}
The range proofs can probably be sped up using [DeKART](/dekart).

## References

For cited works, see below 👇👇

{% include refs.md %}
