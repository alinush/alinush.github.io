---
tags:
 - aptos
 - keyless
 - zero-knowledge proofs (ZKPs)
 - groth16
title: Keyless blockchain accounts on Aptos
#date: 2020-11-05 20:45:59
#published: false
#sidebar:
#    nav: cryptomat
permalink: keyless
---

{: .info}
**tl;dr:** What is a **keyless blockchain account**?
Put simply, _"Your blockchain account = Your Google account"_. 
In other words, this keyless approach allows you to derive a blockchain account from any of your existing OpenID Connect (OIDC) account (e.g., Google, Apple), rather than from a traditional secret key or mnemonic. 
There are no long-term secret keys you need to manage.
There is also no multi-party computation (MPC) system managing your account for you.
As a result, the risk of account loss is (more or less), the risk of losing your Google account.
Keyless is built using a [Groth16](/groth16) zero-knowledge proof to maintain privacy in both directions: prevent the blockchain from learning anything about your Google account & prevent Google from learning anything about your blockchain account and transaction activity.

<!--more-->

One day, I hope to edit this into a full blog post but, until then, here's a bunch of resources.

<p hidden>$$
\def\prover{\mathcal{P}}
\def\verifier{\mathcal{V}}
\def\Adv{\mathcal{A}}
\def\Badv{\mathcal{B}}
\def\vect#1{\mathbf{#1}}
$$</p>

## tl;dr

A quick 20 minute presentation on what this is & how it works:

<iframe width="560" height="315" src="https://www.youtube.com/embed/sKqeGR4BoI0?si=GJDBwVoTHdS-pML6" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## FAQ

### Who is this for?

So far, cryptocurrencies have been designed for power users who understand public-key cryptography.

In constrast, Keyless accounts are for any Web 2 user who has used the "Sign in with Google[^not-just-google]" flow before. (Basically, for everyone.)

Keyless accounts are primarily designed **for the bottom 90% of users**; _novice users_ who are not yet ready to manager their own 12-word seed phrase, mnemonic or secret key.

Such users often tend to:
 - lose their key, or
 - get phished for their key, or
 - accidentally-paste their key somewhere they shouldn't

But, keyless accounts were designed also **for first-time users**, who deserve and expect a smooth on-boarding experience when interacting with a dapp.

{: .warning}
**Newsflash:** Downloading a _new_ wallet for every _new_ chain and writing down a _new_ (extremely-sensitive) 12-word seed phrase is **not** smooth.
(It's not even sane.)
Reusing an existing 12-word seed phrase is not smooth either. Plus, would you want to? Do you trust this _new_ wallet on this _new_ chain?[^hardware-wallet]

### Can Google steal my keyless account?

_In principle_, keyless accounts can be set up so that, **if a malicious Google tries to steal your account, you have the power to stop it** by sending a cancellation TXN within a timeout period (e.g., 1 day)[^cancellation-txns].

*In practice* though, this **higher-security mode** of operation will not lead to the best user experience (e.g., across different devices[^esk-across-devices] or when a user's browser session is lost[^esk-not-in-local-storage]).
As a result, this is not the recommended mode on the [Aptos network](https://x.com/aptos), nor the most-widely supported one.

Instead, Aptos defaults to a **user-friendly mode** where users can access their account easily from different devices (even if the browser's history has been cleaned).
For this to work, Google must be allowed to sign TXNs on the user's behalf without a timeout period (see [flow](#flow-end-to-end-keyless-transacting)).
As a result, a malicious (or compromised) Google could abuse this power and steal a user's account. 

Is this okay?
Well, you have to [remember who keyless accounts are for](#who-is-this-for).

_First_, they are for **first-time users** who are not interested in (or know much about) 12-word mnemonics; they just want to easily sign up for your your dapp!
_Second_, they are for **novice users** who understand very little about the responsibility of custodying a 12-word seed phrase or mnemonic.

So, yes, this **is** okay, because the biggest threat for this user base is **key loss (or theft) caused by the user themselves.**
It's not Google.

Then, as a developer, if you want to (1) on-board users smoothly and (2) prevent them from shooting themselves in the foot, then **you should use keyless**[^optionality].

Put differently, Google can **protect** these users' keyless accounts much, **much** better than the users are able to secure a 12-word seed phrases.

{: .note}
Google's own bottom line depends on their ability to protect their OpenID Connect (OIDC) secret keys which secure your keyless account because **those same keys secure the widely-used "Sign in with Google" flow** all across the web!

### I have a very fast [zk]VM, why don't you use it?

Switching to an (actual) zkVM[^zkzk] would be amazing for a lot of reasons:
 1. **NP relation implementation is trivial**[^actually] and likely bug-free
 1. It would allow us to do **client-side proving** by removing the training wheels
 1. It would most-likely only need a **one-time universal setup** (or even a **transparent setup**!)

Currently, we use [Groth16](/groth16) to prove our $\approx$ 1.5 million[^unreasonable-confidence] R1CS [NP relation](#zk-relation-keyless-authentication).
The main reasons we chose this **circuit-based** zkSNARK, in order of relevance, are:
 1. **Fast verification time**
    - Currently, a size-3 multipairing and a size-14 Poseidon-BN254 hash
    - In a way, even this is too slow for us
    - We cannot afford to make it slower because it translates to higher TXN gas costs for our users
 2. **Small proofs**: currently $2\cdot 32 + 64 = 128$ bytes

Unfortunately, circuit-based SNARKs have a few drawbacks:
 1. **Extremely bug-prone circuit implementation** of the NP relation
    - $\Rightarrow$ need to formally-verify circuit $\Rightarrow$ need additional FV expertise, adds complexity and slows down our circuit development time
    - Until FV is ready, we have to enable [training wheels](/training-wheels) and rely on a proving service
 2. **Slow proving time** 
    - $\Rightarrow$ horrendously-slow to auto-scale our proving service $\Rightarrow$ must over-provision resources $\Rightarrow$ drives up costs (plus, DoS risks) 
    + e.g., it takes 25 seconds to prove the keyless relation using `snarkjs` on a Macbook M1 Pro in the browser
        + $\Rightarrow$ even if we remove the training wheels, we need faster proving time to do client-side proving
 3. Some schemes, such as Groth16, require a **circuit-specific trusted setup**
    - $\Rightarrow$ need MPC ceremony $\Rightarrow$ this adds operational complexity (e.g., find a high # of participants, spin up MPC coordination services, offer support to people who are having trouble contributing, publicly-reveal ceremony transcript)

Therefore, switching to [zk]VMs would only make sense if it:
 - [ ] preserves the **fast verification time**
      + There is a bit of wiggle room here, but not too much: maybe 1.5x to 2x slower
 - [ ] preserves the **small proofs** of Groth16
      + There is more wiggle room here: maybe we can 10-50x the proof size
 - [ ] **speeds up proving time** (over Groth16)
 - [ ] preserves the **zero-knowedge** property
 - [ ] adds **no new exotic security assumptions**
      + e.g., a SNARK-friendly hash function that has been published less than 5 years ago
 - [x] it is a universal setup scheme
      + All [zk]VMs seem to meet this requirement
 - [ ] the zkVM design is described comprehensively in an academic paper / technical document
 - [ ] the zkVM stack is formally-verified
      + The approach taken by Jolt[^KDT24e] of verifying the crucial components could suffice
      + This includes components such as Groth16 circuits that wrap the zkVM proof


#### Why not wrap a nozkVM proof?

Note that "wrapping" a nozkVM proof will likely not satisfy the fast proving time requirement.
Why?
Wrapping only makes sense if it does not add too much overhead: e.g., when proving really large relations (e.g., 15M R1CS constraints)
But the keyless relation is small: 1.5M R1CS constraints.
As a result, most of the proving time would be spent wrapping.
Furthermore, parameterizing the nozkVM to be more wrapping-friendly (e.g., via SNARK-friendly hashes) would likely slow down the nozkVM proving and/or add funky assumptions to our system.

This, of course, could change very soon. (And I hope it does!)

<!--
#### But what if I am really important and Google steals my keyless account?

Yes, if you are important Google, or the NSA, or Lazarus, or God knows who will steal your account.

But you are likely not.

### Can Google lock me out of my keyless account? 

{: .todo}
Yes.
How likely is this to happen?
Is it more likely for you to lock yourself out if you manage your 12-word seed phrase. Yes!

{: .todo}
Also, it depends how determined Google is to do this. (e.g., maybe you still have your email)

{: .todo}
Use a cold backup key?
zkEmail reset.

### Can Google ban my keyless dapp?

{: .todo}
Yes.
How likely is this to happen?
Unclear, but you can prepare for it: add a 2nd factor (e.g., add Apple or an SK or a zkEmail).
Or, recovery service.

### Can Google passively monitor TXNs?

{: .todo}
Passively-malicious Google vs. actively-malicious.

#### My TXNs

#### All TXNs

### What if my Google is hacked?

{: .todo}
2FA.
"You've done well so far."

### What if I lose my pepper?

{: .todo}
Designed to preclude that problem: pepper service has got your back.

### But this is not decentralized, right?

{: todo}
The design **is** decentralized: prover service can be de-centralized, so can pepper-service.
The current deployment is not there yet, but will be.

### But this is not privacy preserving, right?

{: todo}
Same: design **is**, but prover & pepper services are not yet privacy-preserving.

### What if this takes off? Won't Google own us all?

### TODO
2 out of 3 across same email but different providers
2 out of 3 across same provider but your friends' emails
securing $1,000 dollars vs. $1,000,000 dollars -- kind of like adding mfa in Web2

-->

## Drawings

### Flow: Keyless on-chain verification

Depicts what the blockchain validators need to do to verify a keyless TXN submitted by a user, Alice.

<div align="center"><img style="width:85%" src="/pictures/keyless-on-chain-verification.png" /></div>

### ZK relation: Keyless authentication

10,000-feet view of the ZK relation needed for keyless:

<div align="center"><img style="width:65%" src="/pictures/keyless-zk-relation.png" /></div>

For a 100-feet view of it, see [this AIP-61 sub-section](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-61.md#the-keyless-zk-relation-mathcalr).

### Flow: End-to-end keyless transacting 

Depicts the full keyless flow: the user generating an ESK and EPK, the user signing into the dapp with the EPK as the OIDC `nonce`, the dapp getting a JWT, exchanging it for a pepper, getting a ZKP from the prover service, the user signing a TXN with their ESK, the dapp sending the TXN containing the ZKP and ephemeral signature, and finally the blockchain verifying everything.

<div align="center"><img style="width:95%" src="/pictures/keyless-overview.png" /></div>

### Flow: Paying an email address via [https://aptosconnect.app](https://aptosconnect.app)

<div align="center"><img style="width:95%" src="/pictures/keyless-pay-to-email.png" /></div>

### Flow: End-to-end keyless ZKless-transacting (currently, disabled)

In case of emergency (e.g., a serious soundness issue in the ZK circuit), keyless supports a **ZKless** mode that is **not** privacy preserving.
This, of course, is currently **disabled** on Aptos mainnet.

We depicts this (simpler) ZKless flow: the user generating an ESK and EPK, the user signing into the dapp with the EPK as the OIDC `nonce`, the dapp getting a JWT, the user signing a TXN with their ESK, the dapp sending the TXN containing the ephemeral signature, and finally the blockchain verifying everything.

<div align="center"><img style="width:65%" src="/pictures/keyless-zkless-overview.png" /></div>

### ZK relation: Oblivious pepper service

The ZK relation needed to implement an [oblivious pepper service][oblivious-pepper]:

<div align="center"><img style="width:65%" src="/pictures/keyless-oblivious-pepper-relation.png" /></div>

### Flow: Fetching your pepper obliviously 

We depict the flow for a dapp to fetch its user's pepper _obliviously_ from the pepper service, without leaking the user's ID nor the application's ID to the service.

<div align="center"><img src="/pictures/keyless-oblivious-pepper-flow.png" /></div>

## Write-ups

1. I wrote a [high-level overview](https://aptos.dev/en/build/guides/aptos-keyless/how-keyless-works) of how keyless accounts work on the [Aptos](https://twitter.com/aptos) blockchain 
2. I wrote an [in-depth explanation](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-61.md) of how keyless accounts work (and their many caveats) in the 61st Aptos Improvement Proposal. 
3. _Osikhena Oshomah_ wrote a keyless tutorial for devs called [Aptos Keyless Auth](https://jamiescript.hashnode.dev/aptos-keyless-auth)

## Slides

 - [Keyless blockchain accounts from ZKPs](https://docs.google.com/presentation/d/1wMFBRe7WZpKRbcjuLaIzv4MlUtC9yf7tnvntnv4AiTQ/edit?usp=sharing), MIT and Northeastern University, February 2025
 - [Keyless blockchain accounts from ZKPs](https://docs.google.com/presentation/d/1LNX4RAx0d34WRl57OLCdBKgxXyDGht4ROJ15jRkDALg/edit?usp=sharing), NoirCon 1, February 2025
 - [Keyless blockchain accounts from ZKPs](https://docs.google.com/presentation/d/1XpkB0t-Ns4SuCosyin83ED4RLoSvFMGjH5746DCshow/), GKR bootcamp, January 2025
 - [How Keyless works](https://docs.google.com/presentation/d/1gew0fD0QFNqV9snmoYnhRtLsHBoMX0wykouVn1CJbXc), 2024-2025
 - [Aptos Keyless accounts](https://docs.google.com/presentation/d/1nmDYfTiFKgAmPvsodkyrniV4USNdGUIGuWYRYaAxKgI/edit?usp=sharing), zkSummit'11, April 2024

## Code

 - Keyless blockchain validator logic [here](https://github.com/aptos-labs/aptos-core/blob/2c96107ddf0e48b7b3a3e6c67ff6cce3844d1abc/aptos-move/aptos-vm/src/keyless_validation.rs#L158)
 - Keyless **governance** logic [here](https://github.com/aptos-labs/aptos-core/blob/2c96107ddf0e48b7b3a3e6c67ff6cce3844d1abc/aptos-move/framework/aptos-framework/sources/keyless_account.move#L3)
 - Keyless **prover service** [here](https://github.com/aptos-labs/keyless-zk-proofs/tree/main/prover)
    + Built on top of our own [`rust-rapidsnark`](https://github.com/aptos-labs/rust-rapidsnark)
    + Which, in turn, is built on top of our own _hardened_ [`rapidsnark`](https://github.com/aptos-labs/rapidsnark)
 - Keyless **ZK circuit** `circom` code [here](https://github.com/aptos-labs/keyless-zk-proofs/tree/main/circuit)
 - Keyless **pepper service** [here](https://github.com/aptos-labs/aptos-core/tree/main/keyless/pepper)
 - Keyless TypeScript **SDK** [here](https://github.com/aptos-labs/aptos-ts-sdk/tree/main/src/core/crypto)
 
## Educational (d)apps and code

 - **Example:** Sending a keyless TXN to the Aptos `mainnet` via the SDK [here](https://github.com/aptos-labs/aptos-ts-sdk/blob/2386c07361f9a80f994f8b3ea22991549958402a/examples/typescript/keyless_mainnet.ts#L27)
 - **Example:** Simple Keyless dapp on Aptos [here](https://github.com/aptos-labs/aptos-keyless-example/tree/main/examples/keyless-example) with guide [here](https://aptos.dev/en/build/guides/aptos-keyless/simple-example)
 - **Example:** Federated keyless dapp on Aptos [here](https://github.com/aptos-labs/aptos-keyless-example/tree/main/examples/federated-keyless-example)
 - **Example:** End-to-end dapp with Keyless [here](https://github.com/aptos-labs/aptogotchi-keyless) with guide [here](https://learn.aptoslabs.com/en/code-examples/keyless)

## Deployed applications

 1. [Aptos Connect](https://aptosconnect.app) web-wallet
 1. $\Rightarrow$ every Aptos dapp that can connect a wallet!
 1. [Merkle Trade](https://merkle.trade)

## Aptos Improvement Proposals (AIPs)

AIP for the whole keyless design:

 - [AIP-61: Keyless accounts](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-61.md)

AIPs for auxiliary keyless services:

 - [AIP-75: Prover service](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-75.md)
 - [AIP-81: Pepper service](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-81.md)
 - [AIP-67: Native JWK consensus](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-67.md)

AIPs for recent extensions to keyless:

 - [AIP-90: Add Apple as a supported OIDC provider](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-90.md)
 - [AIP-96: Federated Keyless](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-96.md)
    + Adds decentralized support for "federated" OIDC providers like Auth0, which have tenant-specific `iss`'s and JWKs and could not be scalably integrated into our [JWK consensus](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-67.md) mechanism
 - [AIP-108: "Audless" Federated Keyless](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-108.md)
 - Draft [AIP: Oblivious pepper service][oblivious-pepper]

## Tweets

A tweetstorm summarizing Aptos Keyless can be found below:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">What is an <a href="https://twitter.com/Aptos?ref_src=twsrc%5Etfw">@aptos</a> keyless account? 🧵<br><br>It&#39;s a blockchain account derived from (say) your Google account and an application (wallet, dapp, etc).<br><br>It&#39;s bound not just to you (e.g., you@gmail.com) but also to the application (e.g., <a href="https://twitter.com/PetraWallet?ref_src=twsrc%5Etfw">@PetraWallet</a>, or <a href="https://twitter.com/ThalaLabs?ref_src=twsrc%5Etfw">@ThalaLabs</a>, or <a href="https://twitter.com/VibrantXFinance?ref_src=twsrc%5Etfw">@VibrantXFinance</a>) <a href="https://t.co/L3qgRf1WoS">pic.twitter.com/L3qgRf1WoS</a></p>&mdash; Alin Tomescu (@alinush407) <a href="https://twitter.com/alinush407/status/1800949436371304955?ref_src=twsrc%5Etfw">June 12, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


## Presentations

### zkSummit'11 (2024)


In April 2024, I gave a **20-minute presentation** at zkSummit11.

[Go back up](#tldr-talk) to see it!

### GKR bootcamp (2025)

In January 2025, I gave a 1 hour bootcamp on keyless accounts: 
<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/Z83ct5BG05s?si=gJr5Tvoz6szcdk06" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

### NoirCon 1 (2025)

In February 2025, I gave a 25 minute workshop on keyless accounts at AZTEC's [NoirCoin 1](https://lu.ma/38g79n99?tk=Ek10r8):
<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/NX0EZBKpgrg?si=O8Ltq8hMtUzXfeRZ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Future work

### Noir

 - [Groth16 experimental `gnark` backend](https://github.com/lambdaclass/noir_backend_using_gnark)
 - [Noir-to-R1CS experimental](https://github.com/worldfnd/ProveKit/tree/main/noir-r1cs)
 - [Benchmarking individual Noir functions](https://x.com/Zac_Aztec/status/1906788898283376836)

## Resources

### Papers

 - FREpack[^SZ23e], useful for arithemtizing foreign arithmetic better.
 - Spartan for interactive R1CS[^WOSplus25e], useful for in-circuit lookups and other FS-based protocols.
 - Hekathon[^RMHplus24e], may be useful for splitting the proving task
 - [UltraGroth](https://hackmd.io/@Merlin404/Hy_O2Gi-h), Groth16 for interactive R1CS
    + Also, [see this note](https://zkresear.ch/t/discussions-on-lookups-in-groth16-ultragroth/290)
 - Reef[^AIMplus23e], potentially-useful for in-circuit regex matching
 - FLIP-and-prove R1CS[^NPR24e], potentially-useful for folding SHA2
     - Crescent[^PPZ24e], also compute ZKPoKs of signed JWTs

### Misc
 
 - [SoK: Hash functions in Zero Knowledge Proofs](https://github.com/ingonyama-zk/papers/blob/main/sok_zk_friendly_hashes.pdf), Karthik Inbasekar
 - [A Brief History of Lookup Arguments](https://github.com/ingonyama-zk/papers/blob/main/lookups.pdf), Tomer Solberg

### Code

 - [AnonAdhar code](https://github.com/anon-aadhaar/anon-aadhaar/blob/main/packages/circuits/src/helpers/signature.circom), by PSE, does RSA2048-SHA2-256 signature verification in `circom` within ~900K R1CS constraints
 - [TheFrozenFire/snark-jwt-verify](https://github.com/TheFrozenFire/snark-jwt-verify/tree/master)
 - [emmaguo13/nozee](https://github.com/emmaguo13/nozee)
 - [emmaguo13/zk-blind](https://github.com/emmaguo13/zk-blind)
 - [worldfnd/noir-r1cs](https://github.com/worldfnd/ProveKit/tree/main/noir-r1cs)
 - [worldcoin/semaphore-rs](https://github.com/worldcoin/semaphore-rs)
 - [WizardOfMenlo/whir](https://github.com/WizardOfMenlo/whir), WHIR in arkworks
 - [worldcoin/hyrax-pcs-commit](https://github.com/worldcoin/hyrax-pcs-commit)
 - [saleel/stealthnote](https://github.com/saleel/stealthnote)
 - [zkemail/noir-jwt](https://github.com/zkemail/noir-jwt)
 - [IrreducibleOSS/binius64/../zklogin.rs](https://github.com/IrreducibleOSS/binius64/blob/main/prover/examples/src/circuits/zklogin.rs)

## Apendix

{% include keyless-defs.md %}

This will serve as an appendix of technical information, useful when communicationg about keyless accounts internally and externally.

{: .note}
The notation below will not be explicitly defined; just exercise intuition! 
e.g., $\maxaudval$ is clearly the maximum number of bytes in $\audval$.

### BN254

Currently, the Aptos keyless relation is implemented using [circom](/circom) with a Groth16 backend over the BN254 elliptic curve[^bn254] of order $r$, where $2^{253} < r < 2^{254}$:

\begin{align}
& 2^{253} + 2^{252} + 2^{246} + 2^{245} + 2^{242} + 2^{238} + 2^{235} + 2^{234} + 2^{233} + 2^{230} + 2^{229} + 2^{228} + 2^{225} +\\\\\
& 2^{223} + 2^{222} + 2^{221} + 2^{216} + 2^{213} + 2^{212} + 2^{208} + 2^{207} + 2^{205} + 2^{197} + 2^{195} + 2^{192} + 2^{191} +\\\\\
& 2^{189} + 2^{188} + 2^{187} + 2^{182} + 2^{180} + 2^{174} + 2^{170} + 2^{168} + 2^{167} + 2^{165} + 2^{164} + 2^{162} + 2^{161} +\\\\\
& 2^{159} + 2^{152} + 2^{151} + 2^{144} + 2^{142} + 2^{140} + 2^{139} + 2^{134} + 2^{132} + 2^{131} + 2^{130} + 2^{128} + 2^{125} +\\\\\
& 2^{123} + 2^{117} + 2^{116} + 2^{113} + 2^{112} + 2^{111} + 2^{110} + 2^{109} + 2^{107} + 2^{102} + 2^{99 } + 2^{94 } + 2^{93} + \\\\\
& 2^{92 } + 2^{91 } + 2^{88 } + 2^{87 } + 2^{85 } + 2^{84 } + 2^{83 } + 2^{80 } + 2^{78 } + 2^{77 } + 2^{76 } + 2^{71 } + 2^{68} + 2^{64} + 2^{62} +\\\\\
& 2^{57 } + 2^{56 } + 2^{55 } + 2^{54 } + 2^{53 } + 2^{48 } + 2^{47 } + 2^{46 } + 2^{45 } + 2^{44 } + 2^{42 } + 2^{40 } + 2^{39} + 2^{36} + 2^{33} +\\\\\
& 2^{32 } + 2^{31 } + 2^{30 } + 2^{29 } + 2^{28 } + 2^0
\end{align}

The order $r$, in different formats:
 - `0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001` (hex)
 - `21888242871839275222246405745257275088548364400416034343698204186575808495617` (decimal).

<!-- 
In plaintext, $r$ is:
```
2^253 + 2^252 + 2^246 + 2^245 + 2^242 + 2^238 + 2^235 + 2^234 + 2^233 + 2^230 + 2^229 + 2^228 + 2^225 + 2^223 + 2^222 + 2^221 + 2^216 + 2^213 + 2^212 + 2^208 + 2^207 + 2^205 + 2^197 + 2^195 + 2^192 + 2^191 + 2^189 + 2^188 + 2^187 + 2^182 + 2^180 + 2^174 + 2^170 + 2^168 + 2^167 + 2^165 + 2^164 + 2^162 + 2^161 + 2^159 + 2^152 + 2^151 + 2^144 + 2^142 + 2^140 + 2^139 + 2^134 + 2^132 + 2^131 + 2^130 + 2^128 + 2^125 + 2^123 + 2^117 + 2^116 + 2^113 + 2^112 + 2^111 + 2^110 + 2^109 + 2^107 + 2^102 + 2^99 + 2^94 + 2^93 + 2^92 + 2^91 + 2^88 + 2^87 + 2^85 + 2^84 + 2^83 + 2^80 + 2^78 + 2^77 + 2^76 + 2^71 + 2^68 + 2^64 + 2^62 + 2^57 + 2^56 + 2^55 + 2^54 + 2^53 + 2^48 + 2^47 + 2^46 + 2^45 + 2^44 + 2^42 + 2^40 + 2^39 + 2^36 + 2^33 + 2^32 + 2^31 + 2^30 + 2^29 + 2^28 + 2^0
```
-->

{: .note}
The base field where the elliptic curve point coordinates $(x,y)$ lie in is $\Zp$ with $p = $ `21888242871839275222246405745257275088696311157297823662689037894645226208583`.
Note that $p$ is slightly larger than the elliptic curve's order $r$.


### BLS12-381

<!--
a 255-bit number,
its binary expansion has 134 bits set to 1,
a sum of powers of two with the following exponents,

0, 32–63 (except 64), 65–73 (except 74), 75–76, 78, 81–94, 95, 97, 106, 109, 111–112,
114–117, 119–121, 124, 126, 128, 130, 139–140, 142–144, 149, 151–152, 155, 163, 171–172,
174–176, 179–181, 184–185, 188–189, 195, 198, 200, 202–206, 208, 210–212, 215–216,
219, 221, 224–225, 228, 230, 232–234, 237, 239–240, 242–243, 245–249, 252–254-->

Currently, the Aptos keyless pepper service is using the BLS VUF[^BLS01] over the BLS12-381 elliptic curve[^bn254] of order $r$, where $2^{254} < r < 2^{255}$:

\begin{align}
& 2^{254} + 2^{253} + 2^{252} + 2^{249} + 2^{248} + 2^{247} + 2^{246} + 2^{245} + 2^{243} + 2^{242} + 2^{240} + 2^{239} + 2^{237} + 2^{234} +\\\\\
& 2^{233} + 2^{232} + 2^{230} + 2^{228} + 2^{225} + 2^{224} + 2^{221} + 2^{219} + 2^{216} + 2^{215} + 2^{212} + 2^{211} + 2^{210} + 2^{208} +\\\\\
& 2^{206} + 2^{205} + 2^{204} + 2^{203} + 2^{202} + 2^{200} + 2^{198} + 2^{195} + 2^{189} + 2^{188} + 2^{185} + 2^{184} + 2^{181} + 2^{180} +\\\\\
& 2^{179} + 2^{176} + 2^{175} + 2^{174} + 2^{172} + 2^{171} + 2^{163} + 2^{155} + 2^{152} + 2^{151} + 2^{149} + 2^{144} + 2^{143} + 2^{142} +\\\\\
& 2^{140} + 2^{139} + 2^{130} + 2^{128} + 2^{126} + 2^{124} + 2^{121} + 2^{120} + 2^{119} + 2^{117} + 2^{116} + 2^{115} + 2^{114} + 2^{112} +\\\\\
& 2^{111} + 2^{109} + 2^{106} + 2^{97} + 2^{95} + 2^{94} + 2^{93} + 2^{92} + 2^{91} + 2^{90} + 2^{89} + 2^{88} + 2^{87} + 2^{86} + 2^{85} + 2^{84} +\\\\\
& 2^{83} + 2^{82} + 2^{81} + 2^{78} + 2^{76} + 2^{75} + 2^{73} + 2^{72} + 2^{71} + 2^{70} + 2^{69} + 2^{68} + 2^{67} + 2^{66} + 2^{65} + 2^{63} +\\\\\
& 2^{62} + 2^{61} + 2^{60} + 2^{59} + 2^{58} + 2^{57} + 2^{56} + 2^{55} + 2^{54} + 2^{53} + 2^{52} + 2^{51} + 2^{50} + 2^{49} + 2^{48} + 2^{47} +\\\\\
& 2^{46} + 2^{45} + 2^{44} + 2^{43} + 2^{42} + 2^{41} + 2^{40} + 2^{39} + 2^{38} + 2^{37} + 2^{36} + 2^{35} + 2^{34} + 2^{33} + 2^{32} + 2^{0}
\end{align}

The order $r$, in different formats:
 - `0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001` (hex)
 - `52435875175126190479447740508185965837690552500527637822603658699938581184513` (decimal)
 - `0111001111101101101001110101001100101001100111010111110101001000001100110011100111011000000010000000100110100001110110000000010101010011101111011010010000000010111111111111111001011011111111101111111111111111111111111111111100000000000000000000000000000001` (binary)


### base64url

Recall that **base64** is a way to convert an **input** of $\ell$ bytes into an output of $m=\lceil 4\ell / 3\rceil$ **base64 characters** from an alphabet of size 64.

Base64 works by sequentially converting each group of 6 bits (so $2^6 = 64$ possibilities) to an 8-bit letter in this **base64 alphabet**.
Note that this blows up the **encoded length** by around $8/6 = 4/3 = 1.25\times$.

{: .note}
Why base64-encode stuff?
Because it is sometimes useful to take arbitrary bytes and convert them to a displayable string format.
(For example, hexadecimal is another such format, albeit the conversion.

The base64 algorithm encodes every 24-bit **input chunk** (i.e., every 3 bytes) into a 32-bit **output chunk** (i.e., 4 base64 characters), properly handling things when $\ell \bmod 3 \ne 0$ (see [this Wikipedia article](https://en.wikipedia.org/wiki/Base64#Examples)):

Specifically, the last input chunk could be of either length:
 - $\ell \bmod 3 = 2$ bytes
    + then, the algorithm **pads** this last 2-byte input chunk (16 bits) with 2 zero bits
        - the **padded** chunk's length is now 18 bits and thus divisible by 6
    - encode this 18-bit padded input chunk as 3-character output chunk
    - append an `=` **padding character** to the output chunk
        + to indicate that the last 2 zero bits in the padded input chunk are padding bits and should be removed
 - $\ell \bmod 3 = 1$ bytes
    - same, except pad this last 1-byte chunk (8 bits) to 12 bits using 4 zero bits
    - as a result, append two `=` padding characters to the resulting 2-character output chunk.

{: .note}
Padding is actually not necessary since it can be inferred from the output length: i.e., the output length $m \bmod 4$ can be either $0, 2$ or $3$[^omit-padding], in which case we can show that $\ell \bmod 3$ must have been either $0, 1$ or $2$, respectively.
Indeed, some implementations do omit padding (e.g., base64**url**-encoded JWTs and JWSs).

Now, **base64url** is a slight varation on **base64**: as explained in the [JWS RFC](https://datatracker.ietf.org/doc/html/rfc7515#appendix-C)[^jwt-rfc].
Specifically, `base64url(m)` is implemented by:

 1. Doing a vanilla `output = base64(input)` Base64 encoding
 2. Stripping the padding (`=`) characters at the end of `output`, if any
 3. Replacing `+` with `-` and replacing `/` with `_` in `output`

### Hashing the identity commitment (IDC) in the address

\begin{align}
\addridc \bydef \poseidon^\F_4\left(
    \begin{array}{l}
        \pepper[0..30],\\\\\
        \poseidon^\mathbb{S}\_{\maxaudval}(\audval),\\\\\
        \poseidon^\mathbb{S}\_{\maxuidval}(\uidval),\\\\\
        \poseidon^\mathbb{S}\_{\maxuidkey}(\uidkey)\\\\\
    \end{array}
\right)
\end{align}

{: .todo}
Define $\poseidon^\mathbb{S}_\ell(s)$.

### Strings inside ZK circuits

 - String indices start at 0:
    + $s[0]$ is the first character of $s$
    + $s[\len(s) - 1] \bydef s[-1]$ is the last character of $s$.
 - $s[i : j] \bydef \left[ s[0], s[i+1], \ldots, s[j] \right]$ denotes a substring starting at $i$ and ending at $j$ (inclusive).
 - No characters in $s[0:\len(s)-1]$ can be 0 (or null).
 - A string is **zero-padded** up to its **max length**, denoted by $\maxlen(s)$: i.e., $s[\len(s):\maxlen(s) - 1] = [0,\ldots,0]$

### Substring checks from polynomial checks

The **inputs** are:
 - a string $a$ of max length $N$
 - its actual length $\len(a) = n\le N$
 - a _substring_ $b[0\ldots L]$ of max length $L$
 - its actual length $\len(b)=\ell\le L$
 - a starting index $i\in [0,n)$ of $b$ in $a$

Pre-conditions:
 - $a$ is array of bytes
 - $a$ is zero-padded (i.e, $a[n : -1] = \vec{0}$)
 - $b$ is an array of bytes
 - $b$ is zero-paded (i.e, $b[\ell : -1] = \vec{0}$)

The **output** is a bit indicating that the following are all true:
 1. $0 < \ell < n$[^triviality]
 1. $0 \le i + (\ell - 1) < n$ (i.e., we need to "leave room" for $b$ in $a$)
 1. $a[i : i + (\ell - 1)] = b$ (i.e., $b$ is a substring of $a$ starting at index $i$)

Below, we will describe solutions to this problem as initially-interactive **protocols** between a **prover** $\prover$ and a **verifier** $\verifier$.
In the keyless relation, the prover $\prover$ is the user/dapp (or proving service) computing the zkSNARK proof and the verifier $\verifier$ is the relation logic itself.
Then, we convert the protocol to be non-interactive.

#### Monomial-based protocol

{: .todo}
Describe.

#### Lagrange-based protocol

The key idea is that we can represent the strings $a$ and $b$ as univariate polynomials $A(X)$ and $B(X)$, respectively, such that
\begin{align}
A(\omega^j) = a_j,\forall j\in[0,n)\\\\\
B(\omega^j) = b_j,\forall j\in[0,\ell)
\end{align}
where $\omega$ is a primitive $N$th root of unity (assume $N$ is a power of two).
Note that the degrees will be $n-1$ and $\ell-1$, respectively.

The key observation is that $b$ is a substring of $a$ starting at index $i$ if, and only if, $\exists Q(X)$ of degree $(n-1) - \ell$ such that:
\begin{align}
A(X) = Q(X) \underbrace{(X-\omega^i)\ldots(X-\omega^{i+(\ell-1)})}_{\bydef Z(X)} + B(X\omega^{-i})
\end{align}

<!--
    R(i) = B(0)
    R(i+1) = B(1)
    ...
    R(i+\ell - 1) = B(\ell-1)
    =>
    B(X) = R(X + i)
    =>
    B(X - i) = R(X)
-->

**Step 1:** $\prover$ sends $a, n, N, b, \ell, L, i, Q(X)$ to the $\verifier$. 

**Step 2:** $\verifier$ first checks:

 1. Is $0 < \ell < n$?
 2. Is $0 \le i + (\ell - 1) < n$?
 3. $\deg Q(X) \equals (n -  1) - \ell$

**Step 3:** $\verifier$ picks a random challenge $\alpha\in\F$ and checks.
\begin{align}
A(\alpha) = Q(\alpha) Z(\alpha) + B(\alpha \omega^{-i})
\end{align}
where:
\begin{align}
Z(X) &= \prod_{j = i}^{i + (\ell - 1)} (X - \omega^i)\\\\\
A(X) &= \sum_{j=0}^{n-1} a_i \ell_{i,N}(X)\\\\\
B(X) &= \sum_{j=0}^{\ell-1} b_i \ell_{i,N}(X)\\\\
\end{align}
Recall that the Lagrange polynomials for interpolating a vector of max size $N$ are:
\begin{align}
\ell_{i,N}(X) &= \frac{\omega^i (X^N - 1)}{N (X - \omega^i)}
\end{align}

Computing $Q(\alpha)$ is easy because we will have its coefficients.
But, to quickly compute $A(\alpha)$ and $B(\alpha)$, we use Lagrange interpolation: e.g.,:
\begin{align}
A(\alpha) &\bydef \sum_{j=0}^{n-1} a_i \ell_{i,N}(\alpha)\\\\\
    &= \sum_{j=0}^{n-1} a_i \frac{\omega^i (\alpha^N - 1)}{N (\alpha - \omega^i)}
\end{align}

{: .note}
In a circuit, we can hopefully have the $\omega^i$'s and $1/N$ as constants in the R1CS matrices.
(Cheaply? Without repeating them?)

#### Non-interactive 

To make the protocol above **non-interactive**, the verifier can pick the random challenge $\alpha$ via the Fiat-Shamir (FS) transform:
\begin{align}
\alpha \gets H(a, n, N, i, b, \ell, L, i, Q(X))
\end{align}

{: .warning}
This will involve more hashing work than the naive, non-Lagrange protocol.
It will also involve a degree-check on $Q(X)$ (is it cheaper than the mask in the current protocol?).
It will involve additionally interpolating $Z(\alpha)$ and $Q(\alpha)$.
And I think it may be more expensive to do the interpolation of $A(\alpha), B(\alpha)$.
So the mask-based protocol should be cheaper.

[oblivious-pepper]: https://github.com/aptos-foundation/AIPs/pull/544

## References

For cited works, see below 👇👇

[^bn254]: [BN254 for the rest of us](https://hackmd.io/@jpw/bn254), by Jonathan Wang
[^cancellation-txns]: This mode can be implemented via account abstraction or via smart contract wallets and would be most effective if your wallet (or some other trusted 3rd party) monitors the chain for key-rotation activities. If so, your wallet would submit the cancellation TXN. (This TXN can be pre-signed too.)
[^esk-across-devices]: Why? AFAICT, this flow will require transmitting an ephemeral secret key (ESK) across different devices in order to quickly get access to the same keyless account on all your devices.
[^esk-not-in-local-storage]: In this case, since the ESK is typically stored in the browser's _local storage_, it will be long gone and the user would have rely on Google's digital signatures to install a new ESK. But this installation would be subject to the timeout period.
[^hardware-wallet]: ...and very few new users can be assumed to have a hardware wallet so as to side-step the 12-word seed phrase problem (assuming the hardware wallet even supports the new chain that the new user is trying to experiment with).
[^jwt-rfc]: The JWT RFC merely defers to the [JW**S** RFC](https://datatracker.ietf.org/doc/html/rfc7515#section-2) as to what "base64url encoding" means
[^not-just-google]: I use "Google" as a canonical example of an OIDC provider. I stress that keyless accounts are **not** restricted with Google and are designed to work with any OIDC provider (e.g., Apple, GitHub, Facebook, etc.)
[^omit-padding]: First, observe that there is no possible last input chunk size that has a 1-character output chunk: the smallest input chunk size is 1 byte, which requires 2 base64 characters (after padding this input chunk to 12 bits). The other cases are when the last output chunk is either 2 or 3 characters. But those correspond to exactly the edge cases when $\ell \bmod 3 = 1$ and $\ell \bmod 3 = 2$.
[^optionality]: Plus, you can anyway later give optionality to your users and allow them to rotate their account to self-custody. Or, to have a backup secret key. Or, to only rely on Google as a recovery method with a timeout, as per the "highly-secure mode" [here](#can-google-steal-my-account). It's just like in the Web 2 world, users can add a 2nd authentication factor to their accounts.
[^triviality]: We are not interested in trivially checking that the empty string is a sub-string, nor that $b$ is a substring of itself. In fact, we may even get into trouble if we accidentally check that in the keyless relation.

{% include refs.md %}

[^actually]: In practice, what is more likely to happen is that the zkVM is not fast enough, even for our small keyless relation. As a result, we will try to "express" the NP relation more efficiently: e.g., it is much easier to take as input $(n,p,q)$ and output `true` if $p$ and $q$ are prime and if $n = pq$ rather than take $n$ as input, factor it into primes $p$ and $q$ and output $(p,q)$ if you succeed. Many such optimizations may be possible for the keyless relation. But they may be much more complicated than the example above, which means they could be misimplmented (even if we write Rust) and lead to a soundness bug.
[^unreasonable-confidence]: I am pretty confident the constraint count can be reduced to 1 million.
[^zkzk]: Sorry, I cannot, in good faith, call it a _"zkzkVM"_: it is simply too confusing. I would call the initial thing what it should've been called: a **"nozkVM"** and call the real thing zkVM!
