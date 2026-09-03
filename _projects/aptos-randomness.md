---
card_id: aptos-randomness
date: 2024-02-01

title: >-
  Aptos distributed randomness
thumbnail: /pictures/projects/aptos-randomness.png

pdf:
  - url: /papers#wvuf

video:
  - url: /talks#wvuf
  - url: https://www.youtube.com/watch?v=CGu05ALsSpE
    title: "Move tutorial"
  - url: https://www.youtube.com/watch?v=FZI0WfLQuOM
    title: "zeroknowledge.fm podcast"

link:
  - url: https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-041-move-apis-for-public-randomness-generation.md
    title: "AIP-41"

code:
  - url: https://github.com/aptos-labs/aptos-core/tree/893d1ffea49dcfa933f0421b19fc6e31a9c808ab/crates/aptos-dkg
    title: "aptos-dkg crate"
---

Cryptographic infrastructure that enables Move developers to obtain unbiasable and unpredictable randomness as long as [no more than 50% of Aptos stake colludes](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-079-implementation-of-instant-on-chain-randomness.md#randomness-generation-using-vufs).
