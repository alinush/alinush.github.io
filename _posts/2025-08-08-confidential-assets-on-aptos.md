---
tags:
 - aptos
 - ElGamal
 - zero-knowledge proofs (ZKPs)
 - range proofs
 - sigma protocols
title: Confidential assets on Aptos
#date: 2020-11-05 20:45:59
#published: false
permalink: confidential-assets
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Confidential assets are in town! But first, a moment of silence for [veiled coins](https://github.com/aptos-labs/aptos-core/pull/3444).

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Preliminaries

We assume familiarity with:

 - [Public-key encryption](/encryption)
    + In particular, [ElGamal](/elgamal)
 - ZK range proofs (e.g., [DeKART](/dekart))
 - [$\Sigma$-protocols](/sigma)

## Construction

### Chunk sizes

We chose 16-bit chunks to ensure that the max pending balance chunks never exceed $2^{32}$ after around $2^{16}$ incoming transfers.
This, in turn, ensures fast decryption times.

Why so many incoming transfers?
There could be use cases, such as payment processors, where seamlessly receiving many transfers is necessary.

## Resources

 - [aptos.dev docs](https://aptos.dev/build/smart-contracts/confidential-asset)

## Appendix

### BL DL benchmarks for Ristretto255

These were run on a Macbook M3.

|----------------+------------------------+-------------+--------------+--------------+
| Chunk size     | Algorithm              | Lowest time | Average time | Highest time |
|----------------|------------------------|-------------|--------------|--------------|
| 16-bit         | Bernstein-Lange[^BL12] | 1.67 ms     | 2.01 ms      | 2.96 ms      |
| 32-bit         | Bernstein-Lange[^BL12] | 7.38 ms     | 30.86 ms     | 77.00 ms     |
| 48-bit         | Bernstein-Lange[^BL12] | 0.72 s      | 4.03 s       | 12.78 s      |
|----------------+------------------------+-------------+--------------+--------------|

{: .warning}
Something is off here: BL should be faster than baby-step giant-step (BSGS), which would take $2^{16}$ group operations for a 32-bit DL $\Rightarrow$ 0.5 microseconds $2^{16} \approx 32$ ms.

## Related work

 - [Taurus Releases Open-Source Private Security Token for Banks, Powered by Aztec](https://www.taurushq.com/blog/taurus-releases-open-source-private-security-token-for-banks-powered-by-aztec/), see [repo here](https://github.com/taurushq-io/private-CMTAT-aztec?tab=readme-ov-file)
 - [Solana's confidential transfers](https://solana.com/docs/tokens/extensions/confidential-transfer)

## References

For cited works, see below 👇👇

{% include refs.md %}
