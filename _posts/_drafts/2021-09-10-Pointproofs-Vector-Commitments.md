---
layout: article
tags:
- vector-commitments
- aggregation
- bilinear maps
title: Pointproofs Vector Commitments
sidebar:
    nav: cryptomat
#date: 2020-11-05 20:45:59
#published: false
#sidebar:
#    nav: cryptomat
---

{: .info}
**tl;dr:** Pointproofs extends Libert-Yung vector commitments[^LY10] with (cross)aggregation of proofs.

## Notes and observations

### Somewhat incremental cross-aggregation

Pointproofs supports cross-aggregating **subvector** proofs $\pi_I$ that were obtained from a previous round of aggregating **individual** proofs $$(\pi_i)_{i\in I}$$, where $I\subset [n]$ is a set of vector positions.
In that sense, it can be thought of a being somewhat _incremental_.

<!-- TODO: This is different than the cross-aggregation of proofs from Hyperproofs which is not at all somewhat incremental in the above sense. -->

In fact, (I believe) Pointproofs can cross-aggregate individual proofs directly too (although the paper does not seem to discuss this).

<!--more-->

<p hidden>$$
\def\Adv{\mathcal{A}}
\def\Badv{\mathcal{B}}
\def\vect#1{\mathbf{#1}}
$$</p>

---

{% include refs.md %}
