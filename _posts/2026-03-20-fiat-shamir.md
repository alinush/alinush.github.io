---
type: note
tags:
 - Fiat-Shamir
 - sigma protocols
title: "Fiat-Shamir transform"
#date: 2020-11-05 20:45:59
#published: false
permalink: fiat-shamir
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Notes on the Fiat-Shamir transform and its security.

<!--more-->

## Related work

The Fiat-Shamir transform[^FS87] is a classic technique for making public-coin interactive proofs non-interactive by replacing the verifier's random challenges with hash function outputs.
It was introduced in the context of identification and signature schemes, but it generalizes to (almost?) any multi-round interactive proof.

Canetti et al.[^CCHplus19] give a rigorous treatment of the Fiat-Shamir transform, bridging the gap between its widespread practical use and its theoretical foundations.
They identify sufficient conditions under which Fiat-Shamir preserves soundness, working in both the random oracle model and the standard model.

Block et al.[^BGTZ24] study soundness notions for [interactive oracle proofs (IOPs)](/iop), including **round-by-round soundness**.
They show that $(k_1, \ldots, k_\mu)$-**special soundness** implies round-by-round soundness, which in turn implies that applying Fiat-Shamir yields a (knowledge?)-sound non-interactive proof.

{% include refs.md %}
