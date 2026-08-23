---
tags:
 - secret sharing
title: How should a blockchain keep a secret?
#date: 2020-11-05 20:45:59
permalink: how-should-a-blockchain-keep-a-secret
#published: false
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
---

{: .info}
**tl;dr:** 
We spoke about how a blockchain should keep a secret at the _Next-Generation Secure Distributed Computing_ seminar at Schloss Dagstuhl.
We sketched an approach based on trusted execution environments (TEEs) that could be practical, yet could still present interesting research challenges.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div>
<!-- $ 
-->

## TEE-based anti-collusion discussion

{: .note}
These are notes from the discussion at Dagstuhl on Sep. 5, 2024 with
Sourav Das, Filip Rezabek, Sisi Duan, Giuliano Losa, Fan Zhang and myself.
(Hope I did not miss anyone.)
These notes will be made public on the Dagstuhl website soon.
Only posting them here early for visibility, since I often have to reference them in my discussions.


We started from the premise that, if we are to rely on trusted-execution environments (TEEs) to prevent collusion in decentralized secret-sharing infrastructures, this must not worsen the current privacy of these infrastructures.
For example, it would be unacceptable for a break in the TEE to lead to the shared secret being revealed.
Therefore, this excludes naive solutions that try to avoid a distributed key generation (DKG) by simply storing the shared secret in the TEE.

We then quickly realized an inherent trade-off in relying on TEEs to prevent collusion: if the TEE is to prevent colluding validators from reconstructing the secret when they are not supposed to, then it follows that if the TEE is unavailable / crashed / buggy, then the underlying secret sharing infrastructure will lose its liveness.
Otherwise, if it did not, that would imply colluders could reconstruct the shared secret by (say) crashing the TEE.

Note that, in live systems such as blockchains where the secret sharing infrastructure may be used for generating randomness via threshold verifiable random functions (tVRFs), TEEs could crash. 
If so, losing the liveness of the blockchain would be very problematic. But we quickly realized that there may be a way to mitigate even against this (to be described later).

We proposed a simple architecture. 
Currently, the validators maintain a $t$-out-of-$n$ secret sharing $(s_1, s_2, \ldots, s_n) \gets \mathsf{DKG}(s, t, n)$ of a secret $s$. 
Therefore, $t$ or more validators can collude to reveal $s$, which would be bad. 

This collusion could happen very early: at the distributed key-generation (DKG) phase, validators could agree on sharing a secret $s$ that everyone knows.

To prevent this, we assume each validator will have a TEE.
Then, we assume the TEEs can establish their own, independent, $t$-out-of-$n$ sharing $(s_1', s_2', \ldots, s_n') \gets \mathsf{DKG}(s', t, n)$ of a different, independent, secret $s'$.
As a result, the final secret will be $s+s'$, instead of just $s'$.
This means that, if we can restrict the usage of the TEE-secured $s'$ secret, we could make it impossible for colluding validators to reveal $s+s'$ or any function of it, such as a (threshold) VRF, which we focus on hereafter.

Note that this already prevents collusion where validators try to pre-agree on the shared secret $s$ outputted by the DKG protocol, since the TEE will effectively "randomize" the final shared secret as $s+s'$.

To make sure a validator $i$ cannot "trick" its TEE to reveal a VRF under its share $s_i$', we would require the TEE to maintain an append-only view of the blockchain's consensus (e.g., keep track of the latest block header) and only produce a VRF share under $s_i'$ if _"it is time to"_, according to this view.
This ensures that the TEE will never compute its VRF share "too early", which would make the randomness predictable.

Note that once the TEE correctly computes its VRF share under $s_i'$, it can be combined with the validator's VRF share under $s_i$.
This yields a "collusion-free" VRF share under $s_i+s_i'$ and, if enough validators combine their "collusion-free" shares, this yields a VRF under $s+s'$, which is what is needed in the higher-level randomness beacon protocol.

We conceptualized this as storing "half" of a validator's secret key share (i.e., $s_i'$) inside the TEE , and the other "half" (i.e., $s_i$) inside the validator.
Note that the "TEE half" is to prevent collusion while the "validator half" is to prevent leakage of the final secret $s+s'$ when the TEEs are all compromised (which is not unfathomable anymore).

We also had many other ideas and thoughts around this:
 - It may be possible to reduce reliance on TEEs: e.g., when using a PVSS-based DKG, if PVSS transcripts from more than > ⅔ of validators are required, then only need > ⅓ of validators to have TEEs to make sure one validator contributes honestly.
 - The necessary TEE functionality should be abstracted, since it may come from one of many providers (e.g., Intel SGX, AWS Nitro, AMD)
    + Need attestation: i.e., enclave signs PVSS transcript it deals
    + Need sealing: i.e., enclave persists its share of the secret key share
 - Need to consider how **resharing** an existing secret might complicate the story, if at all
 - Another interesting requirement is **upgradeability**: e.g., the block format/signatures might change and the TEE needs to be upgraded.
    + May need to put enclave hashes on a chain to allow for upgradeability
    + For example, the blockchain would expect that the PVSS be signed together with the so-called “PVSS-dealing-enclave-hash”
    + Would require reproducible builds that give the same enclave hash to all validators
    + May need “re-sealing” functionality inside the TEE, to allow it to re-encrypt its share for a new enclave hash that is stored on-chain
    + Interestingly, we get tamper-evidence because the enclave hashes are posted on the chain, should the validators post malicious enclaves.

{: .note}
A similar TEE approach may have been sketched out by Shutter Network [here](https://shutternetwork.discourse.group/t/rfp-shuttertee-fortified-shutter-keypers-via-sgx/447?ref=blog.shutter.network) and overviewed [here](https://blog.shutter.network/shuttertee-layered-security-via-meshing-threshold-cryptography-and-state-of-the-art-tee-2/).

## Secret sharing in the proof-of-stake (PoS) setting

{: .note}
I ranted a little on research challenges around PoS secret sharing.
My slides can be found [here](https://docs.google.com/presentation/d/1lRR3scw_w-MhgiTGNgF--VeSxkQUdXmjgVGEG-dPTWY/edit?usp=sharing).

**Abstract:** In this talk, we survey results & challenges around **generating**, **maintaining** and **using** a shared secret amongst the validators of a proof-of-stake (PoS) blockchain.

In the first part, we discuss techniques for generating a secret.
We start with secret sharing in the threshold setting and then in the weighted setting that arises in PoS blockchains.
We then introduce publicly-verifiable secret sharing (PVSS), explaining why it could be an ideal primitive to build distributed key generation (DKG) protocols from.
Lastly, we discuss the new "silent setup" setting[^BGJplus23]$^,$[^DCXplus23e]$^,$[^GJMplus23e]$^,$[^GKPW24e] for bootstrapping threshold cryptosystems without a DKG or any explicit secret sharing (previously known as _"ad hoc groups"_ in the literature).

In the second part, we discuss the threat of collusion attacks in the PoS attacks, where validators stand to profit by exposing the shared secret or a function of it (e.g., the plaintext obtained after threshold decryption under the shared secret).
We present three different collusion attacks which are all detectable-but-unpunishable. 
We then give a TEE-based approach that could prevent collusion and call for more research in this direction.

In the third part, we discuss some new techniques used to speed up threshold cryptosystems.
We begin by reminding practitioners that Lagrange interpolation in threshold cryptosystems can **and should** be done via an optimized quasilinear time algorithm, instead of quadratic[^TCZplus20].
Then, we present new results on threshold cryptosystems that use group elements as secret key[^BO22e]$^,$[^DPTX24e]$^,$[^GJMplus21].
Lastly, we present an exciting new direction on batching threshold cryptosystems so that communication during aggregation is independent of the batch size.

Overall, we highlight important research problems in both the theory and the practice of threshold cryptography.

## Follow-up reading

Matthieu Rambaud suggested:
 - [Partially Non-Interactive Two-Round Lattice-Based Threshold Signatures
](https://eprint.iacr.org/2024/467)
 - The derived $\\{0,1\\}$-LSSS in [Threshold Fully Homomorphic Encryption](https://eprint.iacr.org/2017/257)
 - A tradeoff with $n^2$-sized shares: [Improved Universal Thresholdizer from Iterative Shamir Secret Sharing](https://eprint.iacr.org/2023/545)

<!--
## Pictures from Dagstuhl

<div class="swiper swiper-demo">
 <div class="swiper__wrapper">
  <div class="swiper__slide"><a href="/pictures/2024-09-05-dagstuhl-ngsdc.jpg"><img height="30%" src="/pictures/2024-09-05-dagstuhl-ngsdc.jpg" /></a></div>
 </div>
 <div class="swiper__button swiper__button--prev fas fa-chevron-left"></div>
 <div class="swiper__button swiper__button--next fas fa-chevron-right"></div>
</div>
-->

<!-- The carousel is initialised automatically by /assets/js/swiper.js. -->

---

{% include refs.md %}
