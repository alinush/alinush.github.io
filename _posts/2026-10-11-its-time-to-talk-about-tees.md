---
type: note
tags:
 - trusted execution environments (TEEs)
title: It's time to talk about TEEs
#date: 2020-11-05 20:45:59
#published: false
permalink: tee
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

This post surveys some concerning attacks on TEEs.
The goal is to persuade you to re-consider how you deploy TEE-based applications, if you should deploy them at all.
<!--more-->

Trusted hardware companies (Intel, AMD, etc.) mainly compete on performance, functionality and (one hopes) developer-friendliness.
They may try to compete on security, but this is hard, in my opinion: there's always someone else who can (mis)claim more security and such claims are hard to adjudicate by the market.
Furthermore, the complexity of modern CPU architectures and the pervasiveness of side-channels makes TEE security claims tenuous.

In any case, (some of) the TEE attacks follow below.

## Bugs in the enclave code

Enclaves are meant to protect secrets and integrity of computation from the environment (e.g., host OS, or even the physical environment).
But even if the enclave platform is secure, bugs in the code running in the enclave can lead to disaster.

 - Signal's contact discovery enclave had memory safety issues that allowed the host to confuse it and caused the enclave to leak its own memory contents[^signal-sgx].

## TEE remote attestation forgery bugs

{: .note}
Many of these attacks impacted not only Intel SGX but other TEE platforms as well, like AMD SEV.

 - 2018, [Foreshadow](https://foreshadowattack.eu/): malicious OS can steal Intel SGX attestation key (for the first time!)
 - 2020, [SGAxe](https://sgaxe.com/): needs ring-0 access to steal SGX attestation key (this was the 2nd time!)
 - 2022, [ÆPIC Leak](https://aepicleak.com/): microarchitectural bug allows host root admin to steal SGX attestation key
 - 2024, [BadRAM](https://badram.eu/)[^DWOplus25], tampered DIMM SPD chip on AMD SEV-SNP systems
    + A host root admin with one-time physical access (~$10 to reprogram the DIMM) can run a backdoored VM while the genuine AMD chip signs a report attesting to the benign VM (no key is extracted, but the attestation is false).
 - 2025, [WireTap.fail](https://wiretap.fail/)[^SDAplus25], interposition physical attack for DDR4 systems
    + _"We have successfully extracted attestation keys, which are the primary mechanism used to determine whether code is running under SGX. This allows any hacker to masquerade as genuine SGX hardware, while in fact running code in an exposed manner and peeking into your data. We demonstrate concrete security breaks on real-world software utilizing SGX, such as Secret Network, Phala, Crust, and IntegriTEE."_
 - 2025, [TEE.fail](https://tee.fail)[^CSBplus26], interposition physical attack for DDR5 systems
 - 2025, [Battering RAM](https://batteringram.eu/), interposition physical attack for DDR4 systems
 - 2026, [DDRrop](https://ddropattack.eu/)[^DGJplus26], interposition physical attack for DDR5 systems by dropping writes
    + Intel TDX remote attestation forgery

You may say: _"I don't care; my threat model precludes physical attacks."_
No it doesn't, silly: your remote attestation verifier accepts a quote from _any_ Intel CPU in good standing.
And the attacker’s CPU is one of them.
A break of one is a break of all, unless...

Unless: you pin your verifier to only accept your own PCK certificates[^epid], which implicitly excludes the attacker’s CPU.
This works for so-called [scalable SGX](https://www.intel.com/content/www/us/en/content-details/843058/supporting-intel-sgx-on-multisocket-platforms.html) (the only flavor left) and requires you to carefully manage a PKI.
So, effectively requires you to wield a footgun.
Good luck!

## TEE liveness bugs

DoS is explicitly outside the threat model of SGX, TDX, SEV-SNP and Nitro (b.c. the host can simply refuse to schedule the enclave).
So, here, we focus on liveness issues due to issues with the TEE platform itself.

 - 2018, [Revocation of SGX credentials in light of Spectre/Meltdown left TEE enclaves paralyzed](https://community.intel.com/t5/Intel-Confidential-Computing/GROUP-OUT-OF-DATE-what-is-the-most-recent-microcode-version/m-p/1139549?countrylabel=Latin%25252520America&profile.language=en)
 - 2022, [SGX.fail](https://sgx.fail)[^VSYplus22] details how slowly TCB recoveries roll out and how platforms can be left "out of date" for long stretches
 - 2022, [TPM Attestation Failure on AMD Platforms with ASP fTPM](https://www.amd.com/en/resources/support-articles/faqs/pa-420.html)
    + Example impact: Gamers may be unable to compete in online cash tournaments.

## More academic paper attacks

So many[^VSYplus22]$^,$[^ZGWplus24]$^,$[^MHHW18]$^,$[^TSS17].

In theory, there are ways to reduce the attack surface of trusted hardware.
For example, see Sanctum[^CLD15e] from my group at MIT back in the day (shameless plug). 
Unfortunately, in practice, these more principled designs tend to come with lower performance and/or less functionality.

## Conclusion

Don't put valuable secrets in your TEEs, or they're likely to become public, especially if physical attacks are in your threat model[^nuance].

## References

For cited works, see below 👇👇

{% include refs.md %}

[^signal-sgx]: [Signal's SGX-based contact discovery gets broken](https://x.com/v12sec/status/2092664320547254388)
[^nuance]: For a more nuanced take, see [Andrew Miller's post](https://medium.com/initc3org/tee-based-smart-contracts-and-sealing-pitfalls-eccd5d751329).
[^epid]: It is my understanding that the "old" 2015 SGX architecture based on EPID is now retired.
