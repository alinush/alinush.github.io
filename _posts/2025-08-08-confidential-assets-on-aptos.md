---
tags:
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

## Introduction

We chose 16-bit chunks to ensure that the max pending balance chunks never exceed $2^{32}$ after around $2^{16}$ incoming transfers.
This, in turn, ensures fast decryption times.

## Resources

 - [aptos.dev docs](https://aptos.dev/build/smart-contracts/confidential-asset)

## Appendix

### BL DL benchmarks

|----------------+------------------------+-------------+--------------+--------------+
| Chunk size     | Algorithm              | Lowest time | Average time | Highest time |
|----------------|------------------------|-------------|--------------|--------------|
| 16-bit         | Bernstein-Lange[^BL12] | 1.67 ms     | 2.01 ms      | 2.96 ms      |
| 32-bit         | Bernstein-Lange[^BL12] | 7.38 ms     | 30.86 ms     | 77.00 ms     |
| 48-bit         | Bernstein-Lange[^BL12] | 0.72 s      | 4.03 s       | 12.78 s      |
|----------------+------------------------+-------------+--------------+--------------|

## References

For cited works, see below 👇👇

{% include refs.md %}
