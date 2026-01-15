---
tags: aptos
title: Cryptography on Aptos
#date: 2020-11-05 20:45:59
#published: false
permalink: aptos-crypto
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** (Almost?) all of the cryptography deployed on Aptos. For users, for developers and for general security.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Cryptography in the Move VM 

Everything we built, we tried to do it with:
1. Our users in mind, who can range from the inexperienced, craving ease of use and safety, to the "crypto-maxis", craving flexibility and power
2. Our smart contract developers in mind, who may be trying to implement fancy-shmancy dapps that require some magic cryptography

### Signature verification in Move

Lots of dapps require verifying [digital signatures](/signatures) in Move: e.g., verifying data feeds from off-chain oracles is typically done by verifying a signature over the feed from the oracle.

In this sense, we support many schemes in Move:

 - [ECDSA-over-secp256k1](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-stdlib/sources/cryptography/secp256r1.move)
 - ([Multi](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-stdlib/sources/cryptography/multi_ed25519.move)-)[Ed25519](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-stdlib/sources/cryptography/ed25519.move)
 - [BLS-over-BLS12-381](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-stdlib/sources/cryptography/bls12381.move): individual, multisignatures and aggregate signatures

In addition, our support for [elliptic curve arithmetic in Move](#elliptic-curve-arithmetic) can be used to implement any other desired signature scheme.

### Account key rotation

In Aptos, the **authentication factor** that secures your blockchain address can be rotated.
Typically, this is a secret key (e.g., Ed25519), but it can also be more wild, untamed things like:
 - any $t$-out-of-$n$ Ed25519 secret keys,
 - or, [your Google account](/keyless)
 - or, a [Web2 passkey](#passkey accounts),
 - or, [other Aptos accounts](#multisig-accounts)

Importantly, key rotation works by default, for any Aptos account (or any EOA account, if you "speak Ethereum"): it does not require relying on complicated smart contract wallets or account abstraction.

To learn more about account key rotation, see [our documentation](https://aptos.dev/build/guides/key-rotation).

### Multisig accounts

In Aptos, one can set up their Aptos account to be controlled by any $t$-out-of-$n$ other Aptos accounts via our [multisig accounts](https://aptos.dev/build/guides/first-multisig) feature!

Recently, we released [Petra Vault](https://vault.petra.app/): a web-wallet allowing users to do exactly this, seamlessly.

Even better, some or all of the $n$ accounts could be [Google or Apple-based keyless accounts](/keyless), which (I think) makes for a very user-friendly multisig experience, while maintaining good security!

### Passkey accounts

Your Aptos account can be secured via Web2 passkeys, which are increasingly popular and user-friendly.
We [announced passkeys a while ago](https://forum.aptosfoundation.org/t/aptos-implents-passwordless-passkeys/4533), but SDK support is not yet here.

You could build your own, or light a fire under our proverbial a\*\*\*\* by [opening an issue](https://github.com/aptos-labs/aptos-core/issues).

### Account abstraction

Like Ethereum, Aptos supports [account abstraction (AA)](https://aptos.dev/build/sdks/ts-sdk/account/account-abstraction).

Unlike Ethereum, we also support something called [derivable account abstraction (DAA)](https://aptos.dev/build/sdks/ts-sdk/account/derivable-account-abstraction) which, unlike AA, it allows for deterministically deriving an account's address from the account's abstract public key and its type.

### Keyless accounts

My favorite feature on Aptos is [keyless accounts](/keyless).

This allows you to create an Aptos account secured by your Google account, or your Apple account, or any OIDC provider you want!
Although there are many web wallets that let you do such a thing, they are **not as secure** because they either:
1. Custody your key for you
2. Build a decentralized MPC to custody the key for you
3. Rely on trusted hardware to custody the key for you
4. (Any combination of the above.)

In other words, these prior approaches **introduce additional trust**. 
Aptos Keyless **does not**.
e.g., your Google account = your blockchain account.
This means:
 - The **only** way for an attacker to steal your blockchain account is to steal your Google account.
 - As long as you have access to your Google, you have access to your blockchain account[^well-1].

For documentation, see [this](https://aptos.dev/build/guides/aptos-keyless/how-keyless-works).

### On-chain randomness

Want to build a lottery on-chain?
Airdrop NFTs fairly?
Look no further than our developer-friendly [on-chain randomness APIs in Move](https://aptos.dev/build/smart-contracts/randomness).

If you are an academic, you should check out our EUROCRYPT'25[^DPTX24e] paper describing the cryptography!

### Elliptic curve arithmetic
 
In 2022, I added support for [Ristretto255 elliptic curve arithmetic](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-stdlib/sources/cryptography/ristretto255.move) in Move,

In 2023, we were a bit unhinged and decided to add a `0x1::aptos_stdlib::crypto_algebra` module in Move for **generic** elliptic-curve arithmetic.
We currently instantiated these generic algorithms for:
 - [BN254 arithmetic](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-stdlib/sources/cryptography/bn254_algebra.move) 
 - [BLS12-381 arithmetic](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-stdlib/sources/cryptography/bls12381_algebra.move)

...and we hope to add more!

### Groth16

What's very nice about the `0x1::aptos_stdlib::crypto_algebra` module above is that we can now implement cryptography in Move **generically** over any curve!

And so we did: here's a [Groth16 verifier](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/move-examples/groth16_example/sources/groth16.move) in Move!

You may find Zhoujun's [snarkjs-to-aptos tool](https://github.com/zjma/snarkjs-to-aptos) useful for serializing your VKs, proofs and public statements for this Move verifier.

### Confidential assets

 > _"Key to a person’s dignity is her ability to decide to whom she will reveal information about herself."_ -- Hester Peirce, SEC Commissioner, in [her keynote at the Science of Blockchain Conference, 2025](https://www.youtube.com/watch?v=_2gnJjvodws&t=7156s)

It really does suck when everyone can see:
1. How much money you have.
2. How much money you are sending.
3. Who you are and whom you are transacting with.

Confidential assets fix (1) and (2), but not (3).
For that, you need [Zcash](https://z.cash)-like approaches.

We started working on our [first prototype](https://github.com/aptos-labs/aptos-core/pull/3444) as early as September 2022.

Recently, we just finished our [second prototype](https://aptos.dev/build/smart-contracts/confidential-asset).

You can see it in action in this [Venmo-like demo](https://confidential.aptoslabs.com) on our testnet.

In particular, we take advantage of [keyless accounts](/keyless) to offer a truly seamless **and** confidential payments experience **on-chain** for our users: no secret keys!
(Not even decryption keys for your confidential balance!)

## Conclusion

At Aptos, we put the "crypto" in "cryptocurrency."

### Future work

More may be coming:

 - ZK range proofs[^BDFplus25e]
 - Batch threshold decryption[^AFP24e]

### Acknowledgements

Most of this work was not done alone, but with the gracious help of our current (and past) Aptos cryptography team members:
1. Benny Pinkas
2. Zhoujun Ma
3. Michael Straka
4. Sourav Das
5. Rex Fernando
6. Trisha Datta
7. Kamilla Nazirkhanova
8. Andrei Tonkinh

## References

For cited works, see below 👇👇

[^well-1]: In full disclosure, this assumes you are not relying on the Aptos Keyless pepper service for blinding your (say) email address inside your blockchain address, which our SDK defaults you to.

{% include refs.md %}
