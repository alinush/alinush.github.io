---
#type: note
tags:
 - formal verification
title: On software carpentry
#date: 2020-11-05 20:45:59
#published: false
permalink: fv 
#sidebar:
#    nav: cryptomat
article_header:
  type: cover
  image:
    src: /pictures/golden-gate-bridge.jpg
---

{: .info}
**tl;dr:** _"Beware of bugs in the above code; I have only proved it correct, not tried it."_ --Donald Knuth
<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->


We call ourselves **software "engineers."**
Yet any sincere "engineer" who wrote more than 10,000 lines of code will tell you "engineering" has very little to do with what we do.
We're mostly duct-taping things.

Before building a bridge, a **bridge engineer**[^ada] computes stress, strain and deflection in their beams[^beams].
A software "engineer" just starts writing code.
A bridge engineer operates with a safety margin: the bridge should resist 2x to 4x the maximum expected load. A software "engineer" continues writing more code.
Some of this code may be tested, for some input values, but that's about it.
A bridge engineer signs off on their design[^tex-occ-1001-401] and is subject to professional negligence lawsuits if they seriously mess up[^tex-cprc-150]$^,$[^carlson-brigance].
A software "engineer" just ships the code.

The net result of our "engineering" practice?
Years later, when that code leaks your phone number, home address and the names of all your family members, the "engineering" company is "deeply sorry."
This happens several times per year now[^public-discourse].

A more honest name for our practice should be **"software carpentry."**
It recognizes that, while we do have a skilled craft, safety calculations hardly enter into it.
My thesis is simple (and, I hope, hardly controversial by now): to graduate from _"software carpentry"_ to _"software engineering"_, it would be sufficient for us to embrace **formal verification**[^sufficient-maybe-not-necessary].

Luckily, in the **LLM age**, we could actually do this.
Formal verification is becoming easier to apply to increasingly larger projects[^kleppmann25].
The **first step** is to apply formal verification to our less complex software, software with _clean_ interfaces that admits _small_ specifications.
In other words, formal verification for our building blocks:

 - "this library sorts"[^just-lean]
 - "this binary zips"[^lean-zip]
 - "this is a EUF-CMA signature scheme implementation with no side-channels"

Then, we could push the boundary beyond simple buildings blocks to more complex systems:

 - "this query optimizer produces a plan semantically equivalent to the unoptimized query"
 - "this consensus protocol satisfies safety and liveness under $$f < n/3$$ Byzantine faults"[^erm]

If we did so, there'd be **many advantages**:

 1. We can safely unleash AI to optimize our codebase.
     + This requires progress in compiling (say) Lean programs to be faster.
     + Or, it requires what has been referred to as _"the final form of software development"_[^end-coding] to manifest.
 1. Folks are barely reviewing AI-generated code anyway. Formal verification can enable them to safely not do so.
 1. Instead of tests that cannot cover _all_ executions with **all** values[^MSJ99], we prove all executions perform what we expect them to.
 1. Instead of repeated, error-prone (LLM/manual) audits on our ever-changing, large codebases, we can reduce audit scope to the specs, which are implementation-agnostic.
 1. Instead of trusting that an imported dependency does something, we don't; we update our proof after integrating the dependency. If the proof passes, then program *only* does what the spec says.
     + The _only_ part will be a bit tricky, but doable.

There already is plenty of **encouraging work** showcasing the viability of formal verification (pre-LLM age):

 1. **seL4**, an entire OS microkernel, proven functionally correct[^KEHplus09].
 1. **CompCert**, a full C compiler, proven to preserve program semantics from source to assembly[^Lero09].
 1. **IronFleet**, a Paxos-based replicated state machine plus a lease-based sharded key-value store, with proofs of both safety and liveness[^HHKplus15].
 1. **Everest TLS stack**, a formally verified TLS implementation (miTLS), covering the full protocol state machine, not just the handshake crypto[^BBDplus17].
 1. **AWS's use of TLA+**, not a proof of an entire system, but industrial-scale application of formal methods to distributed systems bugs at production complexity[^NRZplus15].

As caveated above, formal verification will **not** be **a panacea**:

 1. Some software can be as complex to specify as it is to implement (e.g., EC2 cloud architectures come to mind).
 2. Software evolves, not just in its implementation, but also in its specification.
 3. Formal verification rarely covers the full system $\Rightarrow$ bugs creep in in uncovered parts.
    + For example, seL4 had bugs due to _timing channels_[^CGMH14].
    + CompCert had bugs in its unverified parts: parsing bugs that produced a bad abstract syntax tree (AST), since the formal verification only modeled compilation from the AST[^YCER11], but also bugs in its C elaborator, in its Win64 ABI model and in its assembly printer[^cantina].
 4. Formally-verified systems are often compiled with an _unverified_ compiler
 5. Formally-verified systems often execute in an _unverified_ environment: the operating systems, the x86_64 CPU, etc.
 6. The formal verification framework/language may itself have soundness or completness issues[^lean-kernel-bug].

So, if you are tired of being a carpenter whose chairs keep breaking "for no reason," what other options do you have?

## References

For cited works, see below 👇👇

{% include refs.md %}

[^beams]: [Stress, Strain, and Deflection in Beams](https://onlinelibrary.wiley.com/doi/10.1002/9781119093657.ch5), a chapter in a structural engineering textbook.

[^kleppmann25]: [Formal verification and AI](https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html), by Martin Kleppmann, 2025

[^end-coding]: ["The end of coding as we know it"](https://blog.zksecurity.xyz/posts/end-coding/), by zkSecurity

[^ada]: As of 2026, we've been questioning the "engineering" in "software engineering" for almost 30 years. See [this old comp.lang.ada USENET convo](/files/software-engineering-is-not-a-hoax.pdf) from 1997.

[^tex-occ-1001-401]: [Texas Occupations Code § 1001.401 - Seal Required](https://statutes.capitol.texas.gov/Docs/OC/htm/OC.1001.htm), Texas Statutes, current

[^tex-cprc-150]: [Chapter 150, Texas Civil Practice and Remedies Code — Certificate of Merit requirement](https://cite.case.law/sw3d/549/183/), discussed in Texas Court of Appeals case citing Ch. 150

[^carlson-brigance]: [Carlson, Brigance & Doering, Inc. v. Compton — Texas Appellate Court on Certificate of Merit and vicarious liability](https://lgwmlaw.com/?p=2175), LGWM Law summary of Tex. App. decision, Dec. 8, 2020

[^public-discourse]: Why does it matter if everyone can find out where you live, you ask? Try [doing anything of significance](https://tim.blog/2020/02/02/reasons-to-not-become-famous/) in today's world and you'll get a "fan club" in no time.

[^sufficient-maybe-not-necessary]: Not saying it is necessary to. Only saying it would be sufficient to.

[^cantina]: ["How We Found Three Bugs in a Compiler Proven Correct"](https://www.cantina.security/blog/how-we-found-three-bugs-in-a-compiler-proven-correct), by Cantina, August 18th, 2026. None of the three bugs contradicted CompCert's correctness theorem: they were in the unverified parts around it (the C elaborator, the Win64 ABI/register-allocation model, and the assembly-printing stage, where a newline in a source filename could inject arbitrary ARM instructions).

[^just-lean]: ["Just Lean: a verified, fast sort"](https://just-lean.mitscha-baude.at/), by Gregor Mitscha-Baude

[^lean-zip]: ["Why Lean is faster than Rust"](https://kim-em.github.io/blog/2026-7-24-why-lean-is-faster-than-rust/), by Kim Morrison, July 24th, 2026

[^lean-kernel-bug]: ["Postmortem for Kernel Soundness Bug #14576"](https://leodemoura.github.io/blog/2026-8-1-postmortem-for-kernel-soundness-bug-14576/), by Leonardo de Moura, August 1st, 2026

[^erm]: Okay, fine: maybe safety and liveness specs for consensus protocols will not exactly be small.
