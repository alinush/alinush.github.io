---
tags:
 - benchmarks
title: "TIL: Field multiplications are faster than hashing!"
#date: 2020-11-05 20:45:59
published: true
permalink: field-muls-vs-hashing
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** I ran some benchmarks and was surprised to learn that multiplying two BLS12-381 scalar field elements is **~5.5x faster** than hashing 64 bytes with Blake3.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Benchmark results

| Operation | Time |
|-----------|------|
| Blake3 hash (64 bytes) | ~52.7 ns |
| BLS12-381 scalar field mul | ~9.5 ns |

Field multiplication wins handily.

## Why?

The scalar field multiplication in `blstrs` is a single 256-bit Montgomery multiplication implemented in hand-tuned assembly.
Blake3, while blazingly fast for a hash function, still has to run its compression function which involves many more operations.

## Reproduce it yourself

```bash
git clone https://github.com/alinush/bench-crypto
cd bench-blake3-vs-field
cargo bench
```

## References

For cited works, see below 👇👇

{% include refs.md %}
