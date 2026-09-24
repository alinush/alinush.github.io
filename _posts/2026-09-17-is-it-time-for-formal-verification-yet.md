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


We call ourselves **software "engineers"**, but any sincere "engineer" who wrote more than 10,000 lines of code will tell you engineering has very little to do with what we do.
We're mostly duct-taping things.

Before building a bridge, a **bridge engineer**[^ada] computes stress, strain and deflection in their beams[^beams].
A software "engineer" just starts writing code.
A bridge engineer operates with a safety margin: the bridge should resist 2x to 4x the maximum expected load. A software "engineer" continues writing more code.
Some of this code may be tested, for some of its input values, on some of its execution branches.
But that's about it.
A bridge engineer signs off on their design[^tex-occ-1001-401] and is subject to professional negligence lawsuits if they seriously mess up[^tex-cprc-150]$^,$[^carlson-brigance].
A software "engineer" just ships the code.

What is the net result of our "engineering" practice?
Years later, when our code leaks your phone number, home address and the names of all your family members, our "engineering" company is "deeply sorry."
This happens several times per year now[^public-discourse].

A more honest name for our practice should be **software carpentry.**
It recognizes that, while we do have a skilled craft, safety calculations hardly enter into it.
My thesis is simple and, I gather, hardly controversial by now: to graduate from _"software carpentry"_ to _"software engineering"_, it would be sufficient for us to embrace **formal verification**[^sufficient-maybe-not-necessary].

Luckily, in the LLM age, formal verification is becoming easier to apply at larger scales[^kleppmann25].
Our first step should be to apply formal verification to our less complex software, software with _clean_ interfaces that admits _small_ specifications.
This would allow us to make reasonable assumptions about our software building blocks.
_"This library (only) sorts."_[^just-lean]
_"This binary (only) zips."_[^lean-zip]
_"This is a EUF-CMA signature scheme with no timing side-channels."_
Kind of how a bridge engineer can reasonably assume that he's been pouring concrete and not mud, you know?

Then, as our collective formal verification expertise expands, we can move on to more complex systems.
_"This query optimizer produces a plan semantically equivalent to the unoptimized query."_
_"This consensus protocol satisfies safety and liveness under $$f < n/3$$ Byzantine faults."_[^HHKplus15]$^,$[^etheorem]
_"This C compiler preserves program semantics from source to assembly"_.[^Lero09]$^,$[^compcert-bugs]

Indeed, there is plenty of formal verification work that predates the LLM age.
In 2009, work on _seL4_ started: an OS microkernel proven functionally correct[^KEHplus09].
Sure, a few years later, we found out seL4's specification did not account for _timing channels_[^CGMH14].
Nonetheless, this is great progress: so timing channels are the only thing we have to worry about now? Fantastic!
In 2015, AWS wrote a short paper explaining how they used TLA+ to model some of their system designs (e.g., DynamoDB and S3)[^NRZplus15].
Their paper insightfully points out how _"in order to find subtle bugs in a system design, it is necessary to have a precise description of that design."_
Absolutely!
In 2017, we saw progress towards a formally verified TLS implementation that covered the full protocol state machine.[^BBDplus17].
I could keep going with more examples[^fscq].

Embracing formal verification would bring **many advantages**.
First, we could safely unleash AI to generate and optimize our code.
Given that "engineers" are barely reviewing their AI-generated code anyway, why not actually enable them to safely (not) do so?
It will take a bit more work.
For example, we would need compiled (say) Lean programs to execute fast.
But, if that doesn't work out, we could give the _"final form of software development"_[^end-coding] a try.

Second, insted of testing our code, which never covers _all_ executions with _all_ values[^MSJ99], we could prove all executions perform what we expect them to.
Furthermore, instead of doing repeated, error-prone (LLM/manual) audits on our ever-changing, humongous codebases, we could reduce our audit surface to just the specs.
Assuming a sound theorem proving framework[^not-trivial], auditors would mostly try to poke holes through bad assumptions or incomplete modelling in the specs.

Third, and something that gets me very excited, we could obviate software dependency attacks!
Instead of trusting that an imported dependency does _only_ what we expect it to do, we would only need to update our proof after integrating the dependency.
If our proof passes, then the program *only* does what the spec says.
The _"only"_ part seems tricky, but doable?[^LV95]

Lastly, I am not arguing that formal verification will be **a panacea.**
There are many challenges.
To start, some software can be as complex to specify as it is to implement (e.g., EC2 cloud architectures come to mind).
Plus, all software evolves, not just in its implementation, but also in its specification.
Generally, formal verification rarely covers the full system.
So, naturally, bugs will creep in the uncovered parts.
For example, the compiler may still be unverified.
Or, even if your software is bulletproof, the execution environment may not offer formal guarantees and let you down: e.g., your operating system may kill your process, your file system may lose your writes, your CPU may not execute instructions correctly[^skylake-bug]$^,$[^amd-rdrand]$^,$[^arm-aes-errata].
Even worse, the formal verification language may itself have soundness or completness issues[^lean-kernel-bug].

But, assuming you too are a carpenter who's tired of your chairs always breaking, what other options do you have?

**PS:** As fate would have it, one day after drafting this post, [an Anthropic employee tweeted](https://x.com/bcherny/status/2102543349102338309) that he _"used Opus 5.5 to formally verify the Claude Agent SDK using Lean"_.
He _"sometimes combine[s] Lean and TLA+"_ but admits he _"do[es]n't know either language well, but [that] Claude is excellent at both."_
He clearly does not understand the specs that Claude generated.
(Forget about auditing them.)
Is what he did useless?
From a carpentry perspective, not at all.
He'll probably find some bugs -- business as usual.
Good for him.
Good for Antrhopic.
The price paid though: confusing formal verification for _abysmal_ verification[^lol].

**Acknowledgements:** Thanks to Vineeth Kashyap for his feedback on a draft version of this post.

## References

For cited works, see below 👇👇

{% include refs.md %}

[^lol]: Kind of reminds me of the ["It's closer to a British carbonara" meme](https://www.youtube.com/watch?v=8fgNixllFJg).

[^not-trivial]: Not a trivial assumption: we are finding Lean kernel bugs lately[^lean-kernel-bug], for example.

[^compcert-bugs]: CompCert[^Lero09] had bugs in its unverified parts: parsing bugs that produced a bad abstract syntax tree (AST), since the formal verification only modeled compilation from the AST[^YCER11], but also bugs in its C elaborator, in its Win64 ABI model and in its assembly printer[^cantina].

[^beams]: [Stress, Strain, and Deflection in Beams](https://onlinelibrary.wiley.com/doi/10.1002/9781119093657.ch5), a chapter in a structural engineering textbook.

[^kleppmann25]: [Formal verification and AI](https://martin.kleppmann.com/2025/12/08/ai-formal-verification.html), by Martin Kleppmann, 2025

[^end-coding]: ["The end of coding as we know it"](https://blog.zksecurity.xyz/posts/end-coding/), by zkSecurity

[^ada]: It is not lost on me that we've been questioning the "engineering" in "software engineering" for almost 30 years (as of 2026). See [this old comp.lang.ada USENET convo](/files/software-engineering-is-not-a-hoax.pdf) from 1997.

[^tex-occ-1001-401]: [Texas Occupations Code § 1001.401 - Seal Required](https://statutes.capitol.texas.gov/Docs/OC/htm/OC.1001.htm), Texas Statutes, current

[^tex-cprc-150]: [Chapter 150, Texas Civil Practice and Remedies Code — Certificate of Merit requirement](https://cite.case.law/sw3d/549/183/), discussed in Texas Court of Appeals case citing Ch. 150

[^carlson-brigance]: [Carlson, Brigance & Doering, Inc. v. Compton — Texas Appellate Court on Certificate of Merit and vicarious liability](https://lgwmlaw.com/?p=2175), LGWM Law summary of Tex. App. decision, Dec. 8, 2020

[^public-discourse]: Why does it matter if everyone can find out where you live, you ask? Try [doing anything of significance](https://tim.blog/2020/02/02/reasons-to-not-become-famous/) in today's world and you'll get a "fan club" in no time.

[^sufficient-maybe-not-necessary]: Not saying it is necessary to. Only saying it would be sufficient to.

[^cantina]: ["How We Found Three Bugs in a Compiler Proven Correct"](https://www.cantina.security/blog/how-we-found-three-bugs-in-a-compiler-proven-correct), by Cantina, August 18th, 2026. None of the three bugs contradicted CompCert's correctness theorem: they were in the unverified parts around it (the C elaborator, the Win64 ABI/register-allocation model, and the assembly-printing stage, where a newline in a source filename could inject arbitrary ARM instructions).

[^just-lean]: ["Just Lean: a verified, fast sort"](https://just-lean.mitscha-baude.at/), by Gregor Mitscha-Baude

[^lean-zip]: ["Why Lean is faster than Rust"](https://kim-em.github.io/blog/2026-7-24-why-lean-is-faster-than-rust/), by Kim Morrison, July 24th, 2026

[^fscq]: For example, [_FSCQ_](https://css.csail.mit.edu/fscq/): a file system with a machine-checked proof that it never loses data across crashes, specified using _Crash Hoare Logic_. See ["Using Crash Hoare Logic for Certifying the FSCQ File System"](https://css.csail.mit.edu/fscq/fscq.pdf), by Haogang Chen, Daniel Ziegler, Tej Chajed, Adam Chlipala, M. Frans Kaashoek and Nickolai Zeldovich, in SOSP'15.

[^lean-kernel-bug]: ["Postmortem for Kernel Soundness Bug #14576"](https://leodemoura.github.io/blog/2026-8-1-postmortem-for-kernel-soundness-bug-14576/), by Leonardo de Moura, August 1st, 2026

[^skylake-bug]: ["How I found a bug in Intel Skylake processors"](https://gallium.inria.fr/blog/intel-skylake-bug/), by Xavier Leroy, July 3rd, 2017

[^amd-rdrand]: ["Some AMD Processors Have a Hardware RNG Bug, Losing Randomness After Suspend Resume"](https://www.techpowerup.com/255294/some-amd-processors-have-a-hardware-rng-bug-losing-randomness-after-suspend-resume), TechPowerUp, May 2019

[^arm-aes-errata]: ["crypto: arm/aes-ce - work around Cortex-A57/A72 silicon errata"](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=f3456b9fd269c6d0c973b136c5449d46b2510f4b), by Ard Biesheuvel, Linux kernel commit, 2019

[^etheorem]: [_Etheorem_](https://github.com/etheorem/etheorem): a Lean 4 implementation of the Ethereum consensus specification
