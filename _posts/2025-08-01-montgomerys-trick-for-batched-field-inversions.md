---
tags:
 - math
title: Montgomery's trick for batched field inversions
#date: 2020-11-05 20:45:59
permalink: batch-inversion
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** For now, just including my tweet, which I keep having to look up to show to people.


<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Tweet summary

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Today, I f***** around and [re]found out how slow inverting a field elements is 😱<br><br>Avoid it like the plague!<br><br>Or, use batch inversion, if applicable (e.g., <a href="https://t.co/8fgH1dtEzl">https://t.co/8fgH1dtEzl</a> 👇)<br><br>Or, if inverting a root of unity, don&#39;t do it; do this: 1/w^i = w^{n - i} <a href="https://t.co/slawvvp89r">pic.twitter.com/slawvvp89r</a></p>&mdash; alin.apt (@alinush407) <a href="https://twitter.com/alinush407/status/1836912804902682625?ref_src=twsrc%5Etfw">September 19, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## Conclusion and acknowledgements

{: .todo}
Analyze concrete complexity? At what batch sizes does this start making sense?

## References

For cited works, see below 👇👇

{% include refs.md %}
