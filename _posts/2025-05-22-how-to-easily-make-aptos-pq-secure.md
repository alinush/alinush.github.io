---
tags:
 - Aptos
 - distributed key generation (DKG)
 - BLS
 - ECDSA
 - Aptos Keyless
 - post-quantum
 - Schnorr
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

# Post-quantum (PQ) Aptos

Like all other blockchains that I know of, Aptos is currently **not** PQ-secure: it simply does not make sense to pay the cost of doing PQ crypto given what we know about scalable quantum computing. 

{: .note}
The quantum threat is evolving though. I am tracking that evolution separately[^quantum].

Nonetheless, upgradeable chains like Aptos can be easily made _almost-fully_ PQ-secure.

How? In a few phases:
1. Patch consensus to be PQ secure and give users the option to rotate their accounts to be PQ safe.
2. Add mandatory PQ fallbacks to all Aptos account types (to the extent possible).
3. Quantum-proof Aptos's differentiating features 

## Phase 1: Consensus and account signatures

The goal here is to patch only the **core** blockchain functionality so that users, should they be proactive, can remain safe against quantum attacks.

### Hash functions

{: .success}
**Difficulty:** Zero.

Assuming the BHT attack on hash functions does not actually scale in practice[^Bern09], hash function length can be kept the same.

### PQ consensus

{: .warning}
**Difficulty:** Medium-high.

Consensus BLS[^bls] multi-signatures can be changed to a PQ variant via a simple protocol upgrade. The Ethereum Foundation has done a lot of great work on this lately[^DKKW25e].

Another path is to simply swap consensus signatures with 128-bit MACs: with 250 validators, a validator's message will now be "signed" by MAC'ing it for all 250 validators: 250 $\times$ 16 bytes $=$ 4,000 bytes per "signature."

### Add a PQ digital signature scheme
{: #pq-signatures }

{: .success}
**Difficulty:** Low; already-implemented and deployed on `mainnet` in AIP-137[^aip-137]. Not enabled yet.

We already added support for users to proactively migrate their funds to a PQ account, based on their own assessment of the quantum threat.

We chose the recently NIST-standardized **SLH-DSA-SHA2-128s** as the PQ signature scheme.
See AIP-137[^aip-137] for why, as well as some of my preliminary research into the PQ signature landscape[^pq-sigs].

### Account key rotation

{: .success}
**Difficulty:** Easy: just remove support for non-private-entry key rotation functions.

Some (but not all) key rotation functionality in Aptos requires a ZKPoK of the new secret key being rotated to. This can also be done using a post-quantum zkSNARK.

I would more simply preclude the problem by removing this functionality and only keeping the [entry-function-based key rotation](https://github.com/aptos-labs/aptos-core/blob/acb6c891cd42a63b3af96561a1aca164b800c7ee/aptos-move/framework/aptos-framework/sources/account.move#L294).

## Phase 2: Graceful fallbacks for account signatures

The goal here is to patch **all** Aptos user account types to be post-quantum safe, **without requiring** users to be proactive.

This will be needed if the quantum threat materializes before all users have had a chance to proactively migrate.
At that point, classic schemes must be disabled, or else their accounts would be instantly drained by the quantum adversary.
Then, the PQ fallback mechanism would be enabled, restoring user access while preventing quantum adversaries from stealing.

### Ed25519 Aptos accounts can fall back to post-quantum security
{: #pq-fallback }

{: .error}
**Difficulty:** High. Requires a custom PQ zkSNARK solution.

Chaum et al.[^CLYC21e] showed how some classical signature schemes can be made PQ-ready with a small change.
Specifically, they change ECDSA's key generation, obtaining a new ECDSA scheme that admits a post-quantum secure fallback mechanism via Winternitz one-time signatures (W-OTS+)[^Hlsi17e].
Specifically, once a quantum adversary reveals the ECDSA SK, the fallback mechanism treats this as a new public key, whose corresponding SK is a W-OTS+ one, which the quantum adversary cannot get.

Their techniques could be applied to the Ed25519[^ed25519] $\sk$, which is derived from some secret bits $b$ via a hash function as $\sk = H(b)$. 
Crucially, this is conceptually simpler than Chaum et al.'s approach: Ed25519's key generation need not be changed.
Instead, one can use a PQ zkSNARK to bootstrap a PQ signature scheme that proves knowledge of the secret bits $b$ under the new fallback PK $H(b)$ and, in the process, signs a message.

{: .smallnote}
This idea was sketched by Vitalik Buterin[^vitalik-stark], additionally discussing how to hard-fork to undo any missed quantum thefts.

### ECDSA signatures: the bane of my existence

{: .error}
**Difficulty:** High. Requires not only carefully-crafted zkSNARK, but also potentially proving in ZK the PBKDF2 derivation from BIP-39.

ECDSA signatures[^ecdsa] are more challenging, since their secret keys are not (necessarily) derived in an Ed25519-like manner. 
As a result, the full secret key would be known to a quantum adversary, unlike in Ed25519.

Nonetheless, [as explained above](#pq-fallback), ECDSA accounts can be manually rotated to a PQ-secure account by their owners, once it is well-known that a quantum computer exists.

Unfortunately, not everyone will be aware of the quantum threat.
As a result, some inactive users will likely have their accounts stolen.

Luckily, as hinted before, there is **light at the end of the tunnel**[^vitalik-stark]:

The BIP-39[^bip-39] and BIP-32[^bip-32] key derivation mechanism (from a 12-word or 24-word mnemonic down to an ECDSA secret key) can be leveraged to provide fallback PQ security for ECDSA accounts as well, in a similar manner to Ed25519.
This assumes that most ECDSA SKs are derived using a mnemonic or are derived using BIP-32.
One difficulty will be the large # of PB-KDF2 iterations in BIP-39.

{: .todo}
Perhaps we can avoid it by "stopping earlier" and using the BIP-32 child keys as the PQ SK?

### Hardware wallet-protected accounts

{: .error}
**Difficulty:** High.

In theory, all of the mechanisms discussed above for Ed25519 and ECDSA would work in a hardware wallet setting too.

In practice, there are many difficulties:

 1. Hardware wallets have slow compute and low memory; computing a zkSNARK proof in most of them will be virtually impossible
 2. Even if we could compute a zkSNARK proof there, convincing popular hardware wallets to adopt and implement our zkSNARK-based PQ signature scheme(s) will be an uphill battle.

I think therein may lie a great business opportunity: **build post-quantum hardware wallets**!

### Keyless accounts

{: .error}
**Difficulty:** High, for two reasons. First, needs OIDC providers like Google and Apple to transition from RSA-2048 to a PQ secure signature scheme. Second, needs PQ zkSNARK with fast verification that can efficiently wrap these new OIDC PQ signatures.

Once OIDC providers adopt PQ signatures, Keyless ZKPs[^keyless] can be transitioned to a PQ-secure zkSNARK (lattices, [code-based](/ecc), [sumcheck](/sumcheck), etc.)

For example, the [Spartan framework](/spartan) instantiated with a PQ MLE PCS would yield such a PQ secure zkSNARK.

The difficulty will be in reducing the **verifier time** (priority #1) and the **proof size** (priority #2).

## Phase 3: Privacy features and more

The goal here is to quantum-proof Aptos's differentiating features: randomness, encrypted pending TXNs and confidential assets.

### Aptos randomness

{: .error}
**Difficulty:** High, because 1-round, threshold VRFs that are post-quantum secure are not here yet, AFAIK.

One way to get Aptos randomness[^aptos-randomness] is via:
 1. Post-quantum DKGs, which are an emerging area of research[^CLLplus24e]$^,$[^DDLplus24e]$^,$[^SS23e]. 
 2. Post-quantum VRFs
     + Some previous work by Esgin et al.[^ESLR22e]
     + Some work has already been broken[^MZCN25]
     + There are lattice-based key-homomorphic PRFs[^BLMR15e] that could be very useful for obtaining a PQ-VRF[^MK22e]

Another way would be via post-quantum [SMURFs](/smurf), but those would imply efficient $n$-party non-interactive key exchange, so they are extremely unlikely without strong assumptions like multilinear maps or indistinguishability-obfuscation (iO).


### Encrypted pending transactions

{: .error}
**Difficulty:** High. Relies on batch threshold encryption.

**Batch threshold encryption**[^FPTX25e] is a new cryptographic primitive that Aptos is about to deploy to temporarily encrypt TXNs before they are executed, so as to mitigate maximal extractable value (MEV) attacks.

Unfortunately, a quantum adversary can break the threshold PK that changes and is published on chain every 2 hours.
We'd either have to assume slow quantum adversaries, or patch the feature.

Like Aptos randomness, this feature also requires a post-quantum DKG.

But, unlike Aptos randomness, this feature is more exotic: it relies on a newer primitive for which we have barely begun exploring lattice-based (plausibily PQ) instantiations[^BLT25e].

### Confidential transfers

{: .error}
**Difficulty:** High.

Confidential assets (CFAs)[^cfas] is a new feature on Aptos that lets users maintain secret balances and transfer secret amounts.
(However, it does not maintain secrecy of the sender's address, nor of the recipient's.)

CFAs need two kinds of protections:
1. **Post-quantum soundness:** This ensures that a quantum adversary cannot inflate the CFA supply and thus cannot steal the underlying Aptos fungible assets deposited in the confidential pool.
2. **Post-quantum privacy:** This ensures that a quantum adversary cannot decrypt the CFA balances nor the transferred amounts.

For _post-quantum soundness_, the migration away from our quantum-vulnerable Bulletproof ZK range proof is already in the works[^tweet-fs] and may make it to mainnet before the feature is enabled.

For _post-quantum privacy_, there are two routes
1. A PQ-secure additively-homomorphic encryption scheme that is efficient and ZK-friendly. Some are in the works, but not performant enough[^WESY26e].
1. Avoid the need for a (more?) expensive PQ-secure additively-homomorphic scheme by building a UTXO-like confidential asset feature inside our Aptos Move framework
    + It would seem that most post-quantum PKEs that we'd use are LWE-based and admit some form of homomorphism. So it's not clear that non-homomorphic schemes would be that much cheaper.

## Conclusion

_"Keep calm and deploy cutting-edge cryptography."_

Of course, this post does not address many fascinating questions: 

1. How hard are some of these research problems?
    + PQ zkSNARKs with sufficiently-fast verifier and small-enough proofs for on-chain verification
        * e.g., TXN signatures if based on such SNARKs need to kept as part of the TXN history
    + PQ 1-round threshold VRFs?
    + PQ batch threshold encryption?
    + SNARK-friendly PQ PKEs (for confidential assets) 
1. _How efficient would a post-quantum Aptos be?_ 
    + Let's see; this is a growing area of research!
    + Encouraging that some PQ crypto can actually be faster, in some cases.
        + WHIR[^ACFY24e]
        + Merkle-hashing with the Ajtai hash function[^ajtai-merkle]
        + ML-DSA signature verification times[^ml-dsa-bench]
1. _How much time it would take to make these changes?_ 
    + Perhaps this is not as interesting to discuss: it really depends on engineering resources allocated. 
    + ~~Plus, my sense is that there would be more than enough time:~~
        + ~~We'd see how fast quantum computers improve,~~
        + ~~We'd predict the date by which we'd need to be ready,~~
        + ~~We'd allocate all resources to ensure we are ready.~~

{: .note}
Not even a year passed and it's so clear how naive my thinking there was...
Turns out, nobody agrees on how fast quantum computers are improving.
Some folks think it's ridiculous to even talk about PQ safety so early. 
All in all, it's a madhouse out there and there's a real risk that, due to how hard it is to judge progress in the quantum field, blockchains will be caught by surprise.

## Acknowledgements

Thanks to [Dan Boneh](https://crypto.stanford.edu/~dabo/) for encouraging me to write this.

Your thoughts or comments are welcome on this thread[^discussion-thread].

[^quantum]: [Quantum computing](/quantum), Alin Tomescu, April 3rd, 2026
[^cfas]: [Confidential assets on Aptos](/confidential-assets), Alin Tomescu, August 8th, 2025
[^ml-dsa-bench]: [ML-DSA signature verification benchmarks](https://github.com/conor-deegan/benching-pq?tab=readme-ov-file#ml-dsa-variants), Conor Deegan, 2025
[^bls]: [Scalable BLS Threshold Signatures](/threshold-bls#preliminaries), Alin Tomescu, March 12th, 2020
[^ed25519]: [Schnorr Signatures: EdDSA and Ed25519](/schnorr#eddsa-and-ed25519-formulation), Alin Tomescu, May 31st, 2024
[^keyless]: [Keyless Blockchain Accounts on Aptos](/keyless), Alin Tomescu, June 13th, 2024
[^ecdsa]: [ECDSA Signatures](/ecdsa), Alin Tomescu, June 1st, 2024
[^pq-zksnark-owf]: [Post-quantum zkSNARK + OWF signature idea](https://x.com/alinush/status/1921915943795503301), Alin Tomescu, May 12th, 2025
[^aptos-randomness]: [Roll with Move: Instant Randomness on Aptos](https://aptoslabs.medium.com/roll-with-move-secure-instant-randomness-on-aptos-c0e219df3fb1), Aptos Labs, June 26th, 2024
[^bip-39]: [BIP-39: Mnemonic code for generating deterministic keys](https://en.bitcoin.it/wiki/BIP_0039), Marek Palatinus, Pavol Rusnak, Aaron Voisine, and Sean Bowe, 2013
[^bip-32]: [BIP-32: Hierarchical Deterministic Wallets](https://en.bitcoin.it/wiki/BIP_0032), Pieter Wuille, February 11th, 2012
[^ajtai-merkle]: [Merkle-hashing with the Ajtai hash function](https://x.com/0xAlbertG/status/1924750783033053623), 0xAlbertG, May 20th, 2025
[^discussion-thread]: [Discussion thread for this post](https://x.com/alinush/status/1927441785204146622), Alin Tomescu, May 28th, 2025
[^pq-sigs]: [Post-quantum signature schemes](/post-quantum-signatures), Alin Tomescu, December 8th, 2025
[^aip-137]: [AIP-137: Post-quantum Aptos accounts via SLH-DSA-SHA2-128s signatures](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-137-post-quantum-aptos-accounts-via-slh-dsa-sha2-128s.md), Alin Tomescu, December 9th, 2025
[^tweet-fs]: [Fiat, Shamir and Shor walk into a bar... 🍺](https://x.com/alinush/status/2037324705850372511), Alin Tomescu, March 26th, 2026
[^vitalik-stark]: [How to hard-fork to save most users’ funds in a quantum emergency](https://ethresear.ch/t/how-to-hard-fork-to-save-most-users-funds-in-a-quantum-emergency/18901), Vitalik Buterin, March 9th, 2024

## References

For cited works, see below 👇👇

{% include refs.md %}

