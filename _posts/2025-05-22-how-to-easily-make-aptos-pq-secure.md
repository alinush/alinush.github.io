---
tags:
 - aptos
 - distributed key generation (DKG)
 - BLS
 - ECDSA
 - keyless
 - post-quantum
 - schnorr
title: How to easily make Aptos post-quantum secure
#date: 2020-11-05 20:45:59
#published: false
permalink: post-quantum-aptos
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** _"All is well. All is well."_ -- Ranchoddas Shamaldas Chanchad

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

I tend to get the _"Is Aptos post-quantum (PQ) secure?"_ or _"Can Aptos be made PQ-secure?"_ questions very often.

This post should serve as a good, initial answer. (I will evolve it in time.)

## Post-quantum (PQ) Aptos

Like all other blockchains that I know of, Aptos is currently **not** PQ-secure: it simply does not make sense to pay the cost of doing PQ crypto given what we know about scalable quantum computing. 

Nonetheless, upgradeable chains like Aptos can be easily made _almost-fully_ PQ-secure.

How?

 1. Assuming the BHT attack on hash functions does not actually scale in practice[^Bern09], hash function length can be kept the same.
 1. Consensus [BLS](/threshold-bls#preliminaries) multi-signatures can be changed to a PQ variant via a simple protocol upgrade. The Ethereum Foundation has done a lot of great work on this lately[^DKKW25e]
 1. We can add support for a new PQ-secure signature scheme. This way, new users are protected. Many interesting work in this space. Unclear what the best answer is. Personally, I like the idea of combining a [post-quantum zkSNARK scheme with a one-way function (OWF) to get a signature scheme](https://x.com/alinush407/status/1921915943795503301) in a clean way.
 1. [Ed25519 signatures](/schnorr#eddsa-and-ed25519-formulation) can be easily transformed into PQ-secure ones: the Ed25519 SK $\sk$ is derived from some secret bits $b$ via a hash function as $\sk = H(b)$. So even if a quantum computer obtains $\sk$ by computing a discrete log on the public key, we can nonetheless rely on the secrecy of the bits $b$ induced by the one-way hash function $H$. Then, we can do a PQ signature using $b$ as the secret key and $H(b)$ as the public key[^CLYC21e].
 1. Key rotation in Aptos requires a ZKPoK of the new secret key being rotated to. This can also be done using a post-quantum zkSNARK.
 1. [Keyless ZKPs](/keyless) can be transitioned to a PQ-secure zkSNARK (lattices, code-based, etc.)
 1. [Aptos randomnes](https://aptoslabs.medium.com/roll-with-move-secure-instant-randomness-on-aptos-c0e219df3fb1) will require:
    - post-quantum DKGs, which are an emerging area of research[^CLLplus24e]$^,$[^DDLplus24e]$^,$[^SS23e]. 
    - post-quantum VRFs
        - some previous work by Esgin et al.[^ESLR22e]
        + there are lattice-based key-homomorphic PRFs[^BLMR15e] that could be very useful for obtaining a PQ-VRF[^MK22e]

{: .warning}
I may have missed stuff. Please let me know!

## ECDSA signatures: the bane of my existence

There will be a problem with [ECDSA signatures](/ecdsa), since their secret keys are not derived in an Ed25519-like manner. 
As a result, the full secret key would be known to a quantum adversary.
(Unlike in Ed25519.)

Nonetheless, ECDSA accounts can be manually rotated to a PQ-secure account by their owners, once it is well-known that a quantum computer exists.

Unfortunately, not everyone will be aware of the quantum threat.
As a result, some inactive users will likely have their accounts stolen.

But, we would hope this number can be minimized as we work on increasing public awareness of the quantum threat.

{: .error}
Come to think about it, perhaps the [BIP-39](https://en.bitcoin.it/wiki/BIP_0039) and [BIP-32](https://en.bitcoin.it/wiki/BIP_0032) key deivation mechanism (from a 12-word or 24-word mnemonic down to an ECDSA secret key) can be leveraged to handle the problem in ECDSA as well, in a similar manner to Ed25519?
One difficulty will be the large # of PB-KDF2 iterations in BIP-39.

## Conclusion

_"Keep calm and deploy cutting-edge cryptography."_

Of course, this post does not address two fascinating questions: 

1. _How efficient would a post-quantum Aptos be?_ 
    + Let's see; this is a growing area of research!
    + Encouraging that some PQ crypto can actually be faster, in some cases.
        + [WHIR](https://dl.acm.org/doi/10.1007/978-3-031-91134-7_8)
        + [Merkle-hashing with the Ajtai hash function](https://x.com/0xAlbertG/status/1924750783033053623)
2. _How much time it would take to make these changes?_ 
    + Perhaps this is not as interesting to discuss: it really depends on engineering resources allocated. 
    + Plus, my sense is that there would be more than enough time:
        + We'd see how fast quantum computers improve,
        + We'd predict the date by which we'd need to be ready,
        + We'd allocate all resources to ensure we are ready.

## Conclusion and acknowledgements

Thanks to Dan Boneh for encouraging me to write this.

Your thoughts or comments are welcome on [this thread](https://x.com/alinush407/status/1927441785204146622).

## References

For cited works, see below 👇👇

{% include refs.md %}

