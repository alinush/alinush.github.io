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

 - Signal's contact discovery enclave had memory safety issues that allowed the host to confuse it and caused the enclave to leak its own memory contents[^signal-sgx].

## TEE remote attestation forgery bugs

{: .note}
Many of these attacks impacted not only Intel SGX but other TEE platforms as well, like AMD SEV.

 - 2018, [Foreshadow](https://foreshadowattack.eu/): malicious OS can steal Intel SGX attestation key (for the first time!)
 - 2020, [SGAxe](https://sgaxe.com/): needs ring-0 access to steal SGX attestation key (this was the 2nd time!)
 - 2022, [ÆPIC Leak](https://aepicleak.com/): microarchitectural bug allows host root admin to steal SGX attestation key
 - 2025, [WireTap.fail](https://wiretap.fail/)[^SDAplus25], interposition physical attack for DDR4 systems
    + _"We have successfully extracted attestation keys, which are the primary mechanism used to determine whether code is running under SGX. This allows any hacker to masquerade as genuine SGX hardware, while in fact running code in an exposed manner and peeking into your data. We demonstrate concrete security breaks on real-world software utilizing SGX, such as Secret Network, Phala, Crust, and IntegriTEE."_
 - 2025, [TEE.fail](https://tee.fail)[^CSBplus26], interposition physical attack for DDR5 systems
 - 2025, [Battering RAM](https://batteringram.eu/), interposition physical attack for DDR4 systems
 - 2026, [DDRrop](https://ddropattack.eu/)[^DGJplus26], interposition physical attack for DDR5 systems by dropping writes
    + Intel TDX remote attestation forgery

## TEE liveness bugs

 - 2018, [Revocation of SGX credentials in light of Spectre/Meltdown left TEE enclaves paralyzed](https://community.intel.com/t5/Intel-Confidential-Computing/GROUP-OUT-OF-DATE-what-is-the-most-recent-microcode-version/m-p/1139549?countrylabel=Latin%25252520America&profile.language=en)
 - 2022, [TPM Attestation Failure on AMD Platforms with ASP fTPM](https://www.amd.com/en/resources/support-articles/faqs/pa-420.html)
    + Example impact: Gamers may be unable to compete in online cash tournaments.

## More academic paper attacks

So many[^VSYplus22]$^,$[^DWOplus25]$^,$[^ZGWplus24]$^,$[^MHHW18]$^,$[^TSS17].

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

