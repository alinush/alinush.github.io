---
#type: note
tags:
 - formal verification
title: Is it time for formal verification yet?
#date: 2020-11-05 20:45:59
#published: false
#permalink: TODO
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** "Beware of bugs in the above code; I have only proved it correct, not tried it." --Donald Knuth
<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->


I am so tired of writing buggy code. We call ourselves software "engineers." Yet any sincere "engineer" who wrote more than 10,000 lines of code will tell you "engineering" has very little to do with what we do. We're mostly duct-taping things.

A bridge engineer[^ada] computes [stress, strain and deflection in their beams](https://onlinelibrary.wiley.com/doi/10.1002/9781119093657.ch5) before building it. A software "engineer" just starts writing code.

A bridge engineer operates with a safety margin: the bridge should resist 2x to 4x the maximum expected load. A software "engineer" continues writing more code.

A bridge engineer signs off on their design[^tex-occ-1001-401] and is subject to professional negligence lawsuits if they seriously mess up[^tex-cprc-150]$^,$[^carlson-brigance]. A software "engineer" just ships the code.

Years later, when that code leaks your phone number, home address and the names of all your family members, the "engineering" company is "deeply sorry." This happens several times per year now[^public-discourse].

A more honest description of our practice is "software carpentry." It recognizes that, while we do have a skilled craft, calculations hardly enter into it.

**Thesis:** To move from "software carpentry" land into "software engineering" land, we should embrace **formal verification**[^sufficient-maybe-not-necessary]. 

It will not solve _all_ of our problems. After all, some software can be as complex to spec as it is to implement (e.g., EC2 cloud architectures come to mind). Also, software evolves, not just in its implementation, but also in its specifications.

Still, why not start by applying formal verification to amenable building blocks? This would get us much closer to engineering land. For example:

 - "this is a EUF-CMA signature scheme implementation with no side-channels"
 - "this query optimizer produces a plan semantically equivalent to the unoptimized query"
 - "this consensus protocol satisfies safety and liveness under $$f < n/3$$ Byzantine faults"

We could then push the boundary beyond simple buildings blocks to more complex systems.

Formal verification would bring many advantages:

 1. We can safely unleash AI to optimize our codebase.
     + This requires progress in compiling proved Lean programs to be faster.
     + Or, it requires what has been referred to as ["the final form of software development"](https://blog.zksecurity.xyz/posts/end-coding/) to manifest.
 1. Folks are barely reviewing AI-generated code anyway. Formal verification can enable them to safely not do so.
 1. Instead of tests that cannot cover _all_ executions with **all** values[^MSJ99], we prove all executions perform what we expect them to.
 1. Instead of repeated, error-prone (LLM/manual) audits on our ever-changing, large codebases, we can reduce audit scope to the specs, which are implementation-agnostic.
 1. Instead of trusting that an imported dependency does something, we don't; we update our proof after integrating the dependency. If the proof passes, then program *only* does what the spec says.
     + The _only_ part will be a bit tricky, but doable.

## References

For cited works, see below 👇👇

{% include refs.md %}

[^ada]: As of 2026, we've been questioning the "engineering" in "software engineering" for almost 30 years. See [this old comp.lang.ada USENET convo](/files/software-engineering-is-not-a-hoax.pdf) from 1997.

[^tex-occ-1001-401]: [Texas Occupations Code § 1001.401 - Seal Required](https://statutes.capitol.texas.gov/Docs/OC/htm/OC.1001.htm), Texas Statutes, current

[^tex-cprc-150]: [Chapter 150, Texas Civil Practice and Remedies Code — Certificate of Merit requirement](https://cite.case.law/sw3d/549/183/), discussed in Texas Court of Appeals case citing Ch. 150

[^carlson-brigance]: [Carlson, Brigance & Doering, Inc. v. Compton — Texas Appellate Court on Certificate of Merit and vicarious liability](https://lgwmlaw.com/?p=2175), LGWM Law summary of Tex. App. decision, Dec. 8, 2020

[^public-discourse]: Why does it matter if everyone can find out where you live, you ask? Try [doing anything of significance](https://tim.blog/2020/02/02/reasons-to-not-become-famous/) in today's world and you'll get a "fan club" in no time.

[^sufficient-maybe-not-necessary]: Not saying it is necessary to. Only saying it would be sufficient to.
