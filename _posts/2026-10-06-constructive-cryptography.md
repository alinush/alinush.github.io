---
type: note
tags:
 - security definitions
 - constructive cryptography
title: Constructive cryptography
#date: 2020-11-05 20:45:59
#published: false
permalink: cc
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Constructive cryptography (CC) is a definitional framework for security proofs by Uli Maurer.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Introduction

**Constructive cryptography (CC)**[^Maur12] was developed in parallel with the **abstract cryptography** framework by Maurer and Renner[^MR11] and borrows from it significantly.
Both are based on _abstract theory of systems_[^citation-needed].

## Negatives

 - Still relies on simulators, although potentially much more modularly: one just has to build a simulator per "construction step" 
 - Still needs straight-line, black-box simulation
 - Weak support for tightness. (May be surmountable by modifying the CC framework itself.)
    + Security is measured as the best advantage $\varepsilon$ over a class of distinguishers (Sec. 4.5).
        * But composition forces an asymptotic distinguisher class, so $\varepsilon$ is effectively "negligible". 
        * So, CC is no more concrete than UC on advantage or on running time.
    + CC can't express a reduction's running-time "overhead": the time it spends beyond running the distinguisher
    + Plus, generic parallel composition loses a factor of $n$ over $n$ instances $\Rightarrow$ tight (e.g., multi-user) bounds must be proved directly for the $n$-instance construction rather than obtained by composition.
 - Global/shared setup (ledgers, global ROs) not addressed.
 - Maurer's formalization in Def. 3 cannot define ZKPs (or anything with a dishonest protocol party): it fixes $A$ and $B$ as honest, with only $E$ adversarial (pg. 47-48). 
    + But: CC is merely a special case of _abstract cryptography_[^MR11], which can handle dishonest parties.

## Positives

 - Definitions are less bureaucratic 
 - Availability ("Correctness") is part of the definition.
 - Separates "what crypto achieves" from proof technicalities: good for teaching and design ("type-safe protocols", per Maurer).

## References

For cited works, see below 👇👇

{% include refs.md %}
