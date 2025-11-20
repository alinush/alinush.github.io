---
tags:
 - domain-separation
title: Domain separation
#date: 2020-11-05 20:45:59
#published: false
permalink: domain-separation
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** How to think clearly about domain separation in your protocols.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## For hashing

{: .todo}
Explain Aptos's strategy.

## For proof systems

A _domain separator_ in the context of proof systems (e.g., $\Sigma$-protocols, ZK range proofs, etc.) should consist of three things[^sigma]:

1. **Protocol identifier**, which can often be split up into:
    - higher-level protocol identifier: e.g., _"Confidential Assets v1 on Aptos"_
    - lower-level relation identifier: e.g., _"PedEq"_
2. **Session identifier** 
    - chosen by the user
    - specifies the context where this proof is valid
    - e.g., _"Alice (`0x1`) is paying Bob (`0x2`) at time $t$")_
    - motivation is to prevent replay attacks (e.g., PoK of SK) or cross-protocol attacks
    - this one is trickier, I think: in some settings the "session" accumulates naturally in the statement being proven
        + e.g., in Aptos Confidential Assets, the "session" is represented by the confidential balances of the users & their addresses
3. **Statement identifier** 
    - i.e., be sure to hash the public statement being proven
    - here people forget that "public parameters" are part of the statement!
    - e.g., in a Schnorr proof it is crucial to hash the generator $G$!

This suggests that a domain separator `dst` should consist of:
 - a `protocol_id`
 - a `session_id`
 - a `statement`, which is already an argument to a proof system anyway

[^sigma]: These are thoughts inspired from talking to Michele Orrù and reading a few of the $\Sigma$-protocol standardization drafts. 

<!--
https://mmaker.github.io/draft-irtf-cfrg-sigma-protocols/draft-irtf-cfrg-fiat-shamir.html#section-4
https://www.openzeppelin.com/news/interactive-sigma-proofs-and-fiat-shamir-transformation-proof-of-concept-implementation-audit
https://github.com/mmaker/draft-irtf-cfrg-sigma-protocols/blob/f427eddc973bc9ef284c342913010b57f935d71a/draft-irtf-cfrg-sigma-protocols.md#generation-of-the-protocol-identifier-protocol-id-generation
https://github.com/mmaker/draft-irtf-cfrg-sigma-protocols/blob/f427eddc973bc9ef284c342913010b57f935d71a/poc/sigma_protocols.sage#L123
https://docs.zkproof.org/pages/standards/accepted-workshop4/proposal-sigma.pdf
-->

## References

For cited works, see below 👇👇

{% include refs.md %}
