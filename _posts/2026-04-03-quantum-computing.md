---
tags:
 - quantum
 - Shor
title: Quantum computing
#date: 2020-11-05 20:45:59
#published: false
permalink: quantum
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** What has happened in quantum computing over the years.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## A history

In 2001, Vandersypen et al. claimed an "experimental realization" of Shor's quantum factoring algorithm[^VSBplus01].
Their results demonstrate feasibility of building very small, highly specialized quantum circuits.
Specifically, they show a quantum circuit tailored for factoring 15, **but** in designing this circuit they leveraged knowledge of its factorizaton (i.e., $3\times5 = 15$).
Naturally, the relevance of these results has been questioned, most notably by Smolin et al.[^SSV13] who write:

> While there is no objection to having a classical compiler help design a quantum circuit (indeed, probably all quantum computers will function in this way), it is not legitimate for a compiler to know the answer to the problem being solved. To even call such a procedure compilation is an abuse of language.

Others, have been less gentle and mocked this kind of "experimental realization"[^GN25e].

{: .todo}
Google's results: Willow, error-correction, new ECDLP algorithm.
Oratomic's result.
This result[^FFEB26].
[Craig Gidney's post](https://algassert.com/post/2500) and his past paper on Shor.

## References

For cited works, see below 👇👇

{% include refs.md %}
