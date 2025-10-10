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

{% include time-complexities.md %}

## Notation

{% include time-complexities-prelims-no-pairings.md %}

## Preliminaries

We assume familiarity with:

 - [Public-key encryption](/encryption)
    + In particular, [Twisted ElGamal](/elgamal#twisted-elgamal)
 - ZK range proofs (e.g., Bulletproofs[^BBBplus18], [BFGW](/bfgw), [DeKART](/dekart))
 - [$\Sigma$-protocols](/sigma)

### Baby-step giant step (BSGS) discrete log algorithm

Naively, computing the discrete log $a$ on $a \cdot G$, when $a\in[2^\ell)$ could be done in constant-time via a single lookup in a $2^\ell$-sized **pre-computed table**.

The BSGS algorithm allows for **reducing the table** size to $\sqrt{2^\ell} = 2^{\ell/2}$ while _increasing the time_ to $\GaddG{2^{\ell/2}}$. 

{: .todo}
Explain the algorithm.

## FAQ

### Why not go for a general-purpose zkSNARK-based design?

**Question:** Why did Aptos go for a **special-purpose** design based on the Bulletproofs ZK range proof and $\Sigma$-protocols, rather than a design based on a **general-purpose** zkSNARK (e.g., Groth16, PLONK, or even Bulletproofs itself)?

**Short answer:** Our special-purpose design best addresses the tension between **efficiency** and **security**.

**Long answer:** General-purpose zkSNARKs are not a panacea:

1. They remain slow when computing proofs
    + This makes it slow to transact confidentially on your browser or phone.
2. They *may* require complicated multi-party computation (MPC) setup ceremonies to bootstrap securely
    + This makes it difficult and risky to upgrade confidential assets if there are bugs discovered, or new features are desired
3. Implementing any functionality, including confidential assets, as a general-purpose "ZK circuit" is a dangerous minefield (e.g., [circom](/circom))
    + It is **very** difficult to do both *correctly* & *efficiently*[^sok] 
    + To make matters worse, getting it wrong means user funds would be stolen.

Still, general-purpose zkSNARK approaches, if done right, do have advantages:
1. Smaller TXN sizes
2. Cheaper verification costs.

So why opt for a **special-purpose** design like ours?

Because we can nonetheless achieve competitively-small TXN sizes and cheap verification, while also ensuring:

1. Computing proofs is fast
    + This makes it easy to transact on the browser, phone or even on a hardware wallet
2. There is no MPC setup ceremony required
    + This makes upgrades easily possible
3. The implementation is much easier to get right
    + We can sleep well at night knowing our users' funds are safe

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
Something is off here: BL should be **much** faster than [BSGS](#baby-step-giant-step-bsgs-discrete-log-algorithm).
e.g., on 32 bit values, BL takes $30.86$ ms on average, while BSGS similarly takes $2^{16}$ group operations $\Rightarrow$ 0.5 microseconds $\times 2^{16} \approx 32$ ms.

## Related work

There is a long line of work on confidential asset-like protocols, both in Bitcoin's UTXO model, and in Ethereum's account model.
Our work builds-and-improves upon these works:

 - 2015, Confidential assets[^Maxw15]
 - 2018, Zether[^BAZB20]
 - 2020, PGC[^CMTA19e]
 - 2025, [Taurus Releases Open-Source Private Security Token for Banks, Powered by Aztec](https://www.taurushq.com/blog/taurus-releases-open-source-private-security-token-for-banks-powered-by-aztec/), see [repo here](https://github.com/taurushq-io/private-CMTAT-aztec?tab=readme-ov-file)
 - 2025, [Solana's confidential transfers](https://solana.com/docs/tokens/extensions/confidential-transfer)

## References

For cited works, see below 👇👇

[^sok]: Writing efficient and secure ZK circuits is extremely difficult. I quote from a recent survey paper[^CETplus24] on implementing general-purpose zkSNARK-based systems: _"We find that developers seem to struggle in correctly implementing arithmetic circuits that are free of vulnerabilities, especially due to most tools exposing a low-level programming interface that can easily lead to misuse without extensive domain knowledge in cryptography."_


{% include refs.md %}
