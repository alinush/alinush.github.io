---
type: note
icon: "🆚"
tags:
title: "Confidentiality on Aptos vs. Arc vs. Canton"
#date: 2020-11-05 20:45:59
#published: false
permalink: aptos-arc-canton
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** This is an **incomplete** and **opinionated** take on three different approaches to confidential payments (and beyond).

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Aptos

 - <span style="color:green">**Good**</span>: Encrypts balances under the owning user's encryption key $\Rightarrow$ no one can see the balance, except the owning user; not validators; not full nodes; not attackers who break into them.
 - <span style="color:green">**Good**</span>: Encrypts transferred amounts under the sending and receiving users' encryption keys $\Rightarrow$ same guarantees
 - <span style="color:red">**Bad**</span>: Auditing functionality is somewhat restricted
    + Although governance-based auditors get full visibility into transferred amounts and encrypted balances[^available-balances], this is only _after_ auditing is enabled.
    + Retroactive auditing of previous transferred amounts is not possible. (This is a good or a bad thing, depending on whom you ask.)
 - <span style="color:red">**Bad**</span>: Trickier to implement key management for users inside wallets $\Rightarrow$ must do extra careful cryptographic work to enable seamless confidentiality UX in wallets like [Petra](https://petra.app)
    - Banks/customers may not like this, especially if they are clueless about blockchains
 - <span style="color:red">**Bad**</span>: 30x higher gas cost than public payments. (See [gas benchmarks here](/confidential-assets#gas-benchmarks-for-confidential_asset-v11-move-module).)

{: .note}
If confidentiality is what you care about most, go with Aptos.
If it is full privacy, of course, go with [Zcash](https://z.cash).

## Canton

{: .note}
I understand that Canton was built for permissioned enterprise networks where participants are known and regulated. 
Thus, operator visibility is viewed not as a bug but a feature for compliance.

 - <span style="color:red">**Bad**</span>: User's balances are stored in plaintext on their chosen validator/operator $\Rightarrow$ that operator/validator can see the balance $\Rightarrow$ attacker who breaks in can see it too $\Leftrightarrow$ you are trusting your validator operator $\Leftrightarrow$ weak privacy
    + Suggesting that validators/operators can encrypt balances under their own keys is no better, since the operator still holds the key
    + Suggesting that trusted hardware can make it better is tenuous (see [Arc](#arc) discussion on attacks)
 - <span style="color:red">**Bad**</span>: Amounts and balances are only encrypted "in flight" between full nodes / validators $\Rightarrow$ high trust assumption on these intermediaries
 - <span style="color:green">**Good**</span>: Easier to do key management
    - Banks/customers should like this
 - <span style="color:green">**Good**</span>: Easier to implement more complex auditing policies, precisely because validators see everything / the privacy guarantees are weaker
    - Banks/customers should also like this

### Claude's take

> Aptos confidential assets encrypt balances on the public ledger under keys the user owns, so secrecy is a cryptographic guarantee: only the key holder can read amounts, and no operator can.
>
> Canton keeps balances in plaintext in each participant node's local database and gets secrecy from routing --- the protocol simply never sends the data to non-stakeholders, with inter-node encryption under node keys covering transport only.
>
> So the trust anchor differs:
> - Aptos trusts math and the user's ability to protect their decryption keys.
> - Canton trusts your hosting participant operator, plus whatever leaks through divulgence, timing, and workflow metadata.

## Arc[^BGGplus26]

 - <span style="color:red">**Bad**</span>: Leverages **trusted hardware** to encrypt blockchain state on validators under a **master secret key (MSK)**
    - _Unfortunately_, trusted hardware is much easier to break **in practice** than _in theory_ 
    - It has been fully (and partially) broken several times in the past. See just a few recent attacks:
        - [batteringram.eu/batteringram.pdf](https://batteringram.eu/batteringram.pdf): _"arbitrary plaintext read/write access and extracting SGX's platform provisioning key, thereby dismantling trust in remote attestation"_
        - [tee.fail/files/paper.pdf](https://tee.fail/files/paper.pdf): _"extract secret key material (such as attestation keys in some cases) from machines in fully trusted status"_
        - [wiretap.fail/files/wiretap.pdf](https://wiretap.fail/files/wiretap.pdf): _"extract an SGX attestation key from a machine in fully trusted status"_ $\Rightarrow$ _"end-to-end attacks on both confidentiality and integrity guarantees of deployments with multi-million dollar market caps, allowing attackers to disclose confidential transactions or illegitimately obtain transaction rewards"_
 - <span style="color:red">**Bad**</span>: Uses a secret-shared MSK on validators (or, more loosely, their operators)
    + $\Rightarrow$ subject to collusion attacks by validators $\Rightarrow$ the MSK could be revealed $\Rightarrow$ privacy guarantees would be broken without even having to break the trusted hardware
    + The typical counterargument here is that _"more trusted hardware on each validator's KMS will fix this."_
        * But will it `¯\_(ツ)_/¯`? (See attacks above!)
 - <span style="color:green">**Good**</span>: Supports arbitrary privacy-preserving\* computations, beyond just payments
    - \*Of course, under the big caveat of relying on (repeatedly-broken-into) trusted hardware.
 - <span style="color:green">**Good**</span>: Easy key management
 - <span style="color:green">**Good**</span>: Very flexible auditing

### But $\exists$ secure trusted hardware!

One reasonable objection to _"trusted hardware keeps being broken into"_ is that such Intel SGX attacks[^signal-sgx] will not transfer to other trusted hardware platforms. 

I doubt it[^ZGWplus24]$^,$[^DWOplus25]$^,$[^MHHW18]$^,$[^TSS17].

Although there are ways to reduce the attack surface of trusted hardware (e.g., see Sanctum[^CLD15e] from my group at MIT back in the day), in practice, they tend to come with lower performance and/or less functionality.
And it so happens that trusted hardware companies mainly compete on performance, functionality and (I hope) developer-friendliness.
They hardly compete on security, because it's hard to: there's always someone else who can (mis)claim more security.
And such claims are hard to adjudicate by the market.

Thus, what ends up happening is a race to the bottom, sacrificing security for extra performance and functionality.

### Claude's take

> Aptos protects balances with pure cryptography: ciphertexts sit on-chain under the user's own key, so an attacker who compromises every validator still learns nothing about anyone's balance.
>
> Arc protects balances with a master secret key (MSK) housed inside trusted hardware on the validators. This gives Arc two failure modes Aptos doesn't have: (1) hardware-level attacks that extract the MSK from the enclave, which were demonstrated repeatedly in practice (see links above), and (2) validator collusion that reconstructs the secret-shared MSK without touching the hardware at all.
>
> The trade-off is expressivity: Arc's enclaves can run arbitrary confidential computation, not just payments, while Aptos's on-chain approach is limited to payments. But that expressivity assumes trusted hardware won't get broken into. So you're trading a _mathematical_ guarantee for a _physical_ one, and the physical one has a poor track record.

{: .note}
If I had to pick between Canton and Arc, I'd pick Arc due to its simpler design, clearer trust model (IMHO), and higher expressivity.

## References

For cited works, see below 👇👇

[^available-balances]: Specifically, only the available balance, not the pending. See [documentation](https://aptos.dev/build/smart-contracts/confidential-asset#confidential-balance).
[^signal-sgx]: [Signal's SGX-based contact discovery gets broken](https://x.com/v12sec/status/2092664320547254388)

{% include refs.md %}
