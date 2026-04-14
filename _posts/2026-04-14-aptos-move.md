---
tags:
 - Move
title: Aptos Move
#date: 2020-11-05 20:45:59
#published: false
permalink: move
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** a few notes on Move (and maybe on Aptos too).
<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Misc

 - [Move 1 to Move 2](https://github.com/gregnazario/aptos-move-tools/tree/main/move1-to-move2), by Greg Nazario

## Keyless on-chain configs

{: .note}
Learn more about [Keyless here](/keyless).

### 0x1::keyless_account::Groth16VerificationKey

 - [`devnet` VK](https://fullnode.devnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::keyless_account::Groth16VerificationKey)
 - [`testnet` VK](https://fullnode.testnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::keyless_account::Groth16VerificationKey)
 - [`mainnet` VK](https://fullnode.mainnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::keyless_account::Groth16VerificationKey)

### 0x1::keyless_account::Configuration

 - [`devnet` configuration](https://fullnode.devnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::keyless_account::Configuration)
 - [`testnet` configuration](https://fullnode.testnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::keyless_account::Configuration)
 - [`mainnet` configuration](https://fullnode.mainnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::keyless_account::Configuration)

### 0x1::jwk_consensus_config::JWKConsensusConfig

 - [`devnet` providers](https://fullnode.devnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::jwks::SupportedOIDCProviders)
 - [`testnet` providers](https://fullnode.testnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::jwks::SupportedOIDCProviders)
 - [`mainnet` providers](https://fullnode.mainnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::jwks::SupportedOIDCProviders)

You can `echo` the hex bytes (without the `0x` prefix) through `xxd -r -p` to do a best-effort string decoding to see what’s there. e.g.,:

```bash
echo 68747470733a2f2f6163636f756e74732e676f6f676c652e636f6d2f2e77656c6c2d6b6e6f776e2f6f70656e69642d636f6e66696775726174696f6e | xxd -r -p
```

This will output:
```
https://accounts.google.com/.well-known/openid-configuration
```

{: .smallnote}
In the past, there was an attempt to migrate from `0x1::jwks::SupportedOIDCProviders` to `0x1::jwk_consensus_config::JWKConsensusConfig` but we nixed it.


### 0x1::jwks::PatchedJWKs

 - [`devnet` JWKs](https://fullnode.devnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::jwks::PatchedJWKs)
 - [`testnet` JWKs](https://fullnode.testnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::jwks::PatchedJWKs)
 - [`mainnet` JWKs](https://fullnode.mainnet.aptoslabs.com/v1/accounts/0x1/resource/0x1::jwks::PatchedJWKs)

## References

For cited works, see below 👇👇

{% include refs.md %}
