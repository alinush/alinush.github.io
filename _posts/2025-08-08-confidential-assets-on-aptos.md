---
tags:
 - aptos
 - ElGamal
 - zero-knowledge proofs (ZKPs)
 - range proofs
 - sigma protocols
title: Confidential assets on Aptos
#date: 2020-11-05 20:45:59
#published: false
permalink: confidential-assets
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Confidential fungible assets (CFAs) are in town! But first, a moment of silence for [veiled coins](https://github.com/aptos-labs/aptos-core/pull/3444).

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\table{\mathsf{tbl}}
\def\jG#1{\green{#1\cdot G}}
\def\bsgsPrecompute{\mathsf{BSGS.Precompute}}
\def\bsgsSolve{\mathsf{BSGS.Solve}}
\def\msG{\green{-s \cdot G}}
\def\sqm{\ceil{\sqrt{m}}}
$</div> <!-- $ -->

{% include time-complexities.md %}

## Notation

{% include prelims-time-complexities-no-pairings.md %}
 - We assume a prime-order group $\term{\Gr}$ of prime order $\term{p}$
 - We use additive group notation: $a \cdot G$ denotes scalar multiplication in $\Gr$, where $a\in \Zp$ and $G\in\Gr$

### Confidential asset notation

{: .todo}
If we decide to use $b$ for the base, use $w$ for the chunk size!

 - $b$ -- chunk size in bits
 - $B=2^b$ -- chunk size as an integer
 - $\ell$ -- # of avaiable balance chunks
    + In Aptos, balances are 128 bits $\Rightarrow \ell\cdot b = 128$ 
 - $n$ -- # of pending balance chunks **and** the # of transferred amount chunks
    + In Aptos, transferred amounts are 64 bits $\Rightarrow n \cdot b = 64$ 
 - $t$ -- each account can receive up to $2^t-1$ incoming transfers, after which it needs to be _rolled over_
    - i.e., the owner must send a TXN that rolls over their pending into their available balance
    - $\Rightarrow$ pending balance chunks are always $< \emph{2^b(2^t - 1)}$
    - $\Rightarrow$ available balance chunks are always $< 2^b + \emph{2^b(2^t - 1)} = 2^b(1 + 2^t - 1) = 2^b 2^t = 2^{b+t}$ 
        + assuming we only roll over into _normalized_ available balances (i.e., with chunks $< 2^b$)

{: .todo}
Not sure why our initial implementation used $2^t - 2$ instead of $2^t-1$.
May want to write a unit test and make sure my math works.

## Preliminaries

We assume familiarity with:

 - [Public-key encryption](/encryption)
    + In particular, [Twisted ElGamal](/elgamal#twisted-elgamal)
 - ZK range proofs (e.g., Bulletproofs[^BBBplus18], [BFGW](/bfgw), [DeKART](/dekart))
 - [$\Sigma$-protocols](/sigma)

### Naive discrete log algorithm

Naively, computing the **discrete logarithm (DL)** $a$ on $a \cdot G$ when $a\in[m)$ can be done in constant-time via a single lookup in an $m$-sized **precomputed table**:

\begin{align}
(\jG{j})_{j\in [m)}
\end{align}

### Baby-step giant step (BSGS) discrete log algorithm

The BSGS algorithm can compute a DL on $a\in[m)$ with much less memory but with more computation.
Specifically:
 - it **reduces the table size** from $m$ to $\sqm$
 - it _increases the time_ from $O(1)$ to $\GaddG{(\sqm-1)}$.

Let $\term{s}\bydef\sqm$.

The key idea is that we can represent the value $a$ as a 2-digit number $(i,j)$ in base-$\emph{s}$:
\begin{align}
a = i\cdot s + j,\ \text{where}\ i,j\in[s)
\end{align}
As a result finding the discrete log $a$ of $H\bydef a\cdot G$, can be reduced to finding its two digits $i,j\in[s)$ such that:
\begin{align}
H &= (i \cdot s + j)\cdot G\Leftrightarrow\\\\\
H &= i \cdot (s \cdot G) + j \cdot G\Leftrightarrow\\\\\
\label{eq:bsgs-check}
H + i \cdot (\msG) &= \jG{j}
\end{align}

Now, imagine we have all $(\jG{j})_{j\in[s)}$ and $\msG$ precomputed.
Then, finding $a$ can be reduced to computing all the left hand sides (LHS) of Eq. $\ref{eq:bsgs-check}$ for all possible $i\in[s)$ and checking if there exists $j\in[s)$ such that the LHS equals the right hand side (RHS).
If it does, then $a = i\cdot s+ j$!

More concretely, we compute:
\begin{align}
V_0 &\gets H\\\\\
V_1 &\gets V_0 \msG = H + 1 \cdot (\msG)\\\\\
V_2 &\gets V_1 \msG = H + 2 \cdot (\msG)\\\\\
 &\hspace{.7em}\vdots\\\\\
V_i &\gets V_{i-1} \msG = H + i \cdot (\msG)\\\\\
\end{align}
Then, for each computed $V_i$, we check (in constant-time) whether there exists a $j\in[s)$ such that $V_i = \jG{j}$.
In other words, we check if Eq. \ref{eq:bsgs-check} holds for some $i,j\in[s)$.
If it does, then we solved for the correct DL $a = i\cdot s + j$!

Note that this algorithm will take at most $s-1$ group additions in $\Gr$, so it is very efficient!

{: .note}
The maximum value $a$ can take in this base-$s$ representation is $(s-1) \cdot s + (s-1) = (s-1)(s+1) = s^2 - 1$.
Since $\sqm \ge \sqrt{m}$, by squaring it, it follows that $\sqm^2 \ge \sqrt{m}^2\Leftrightarrow s^2 \ge m$.
This means $a=m-1$ can be represented in base-$s$, so the algorithm will be able to solve DL for all $a\in[m)$.
(Not only: it may also be able to solve it for slightly higher values, e.g., $s=4$ for both $m = 15,16$).

We give formal algorithms for BSGS below.

#### $\mathsf{BSGS.Precompute}(m\in \N, G\in\Gr) \rightarrow \table$

Recall that $\term{s}\bydef\sqm$.

Compute the table in $\GaddG{(s-1)}$ time and return it:
\begin{align}
\table \gets (s, (\jG{j})_{j\in[s)}, \msG) \in \N \times (\N\times \Gr)^s \times \Gr
\end{align}

#### $\mathsf{BSGS.Solve}(\table, H\in\Gr) \rightarrow a \in [m)\times \\{\bot\\}$

Parse the table:
\begin{align}
(s, (j,\jG{j})_{j\in[s)}, \msG) \parse \table
\end{align}

Let $V_0 = H$.

For each $i\in[1, s)$:
 - $V_i \gets V_{i-1} + (\msG)$
 - **if** $\exists j\in[s)$ such that $V_i \equals \jG{j}$, **then** return $i\cdot s + j$

If we reached this point, this means no $i,j\in[s)$ were found.
This, in turn, means $a \ge s^2 \ge m$.

Therefore, return $\bot$.

## Related work

There is a long line of work on confidential asset-like protocols, both in Bitcoin's UTXO model, and in Ethereum's account model.
Our work builds-and-improves upon these works:

 - 2015, Confidential assets[^Maxw15]
 - 2018, Zether[^BAZB20]
 - 2020, PGC[^CMTA19e]
 - 2025, [Taurus Releases Open-Source Private Security Token for Banks, Powered by Aztec](https://www.taurushq.com/blog/taurus-releases-open-source-private-security-token-for-banks-powered-by-aztec/), see [repo here](https://github.com/taurushq-io/private-CMTAT-aztec?tab=readme-ov-file)
 - 2025, [Solana's confidential transfers](https://solana.com/docs/tokens/extensions/confidential-transfer)

Explain the algorithm.

## Upgradeability

There will be many reasons to upgrade our confidential asset protocol (CFA):

1. Performance improvements
2. Bugs in $\Sigma$-protocols or ZK range proof
3. Post-quantum security

Depending on which aspect of the protocol must change, upgrades can range from trivial to very tricky.

<!-- Notes:
Will be difficult to change some things

- Encryption scheme
    - When we add a new encryption scheme, say [CL15], we would need to support sending from the old scheme to the new one
        - $\Rightarrow$ we at least need a new equality ZK proof between ElGamal-encrypted transferred amounts & [CL15]-encrypted ones
    - As we add more, we end up with $n$ schemes and I think $O(n^2)$ protocols to support sending from any two schemes
        - e.g., if $n = 4$, we need $1→2, 1→3, 1→4, 2→3, 2→4,3→4$
- Chunking of available/pending balance
    - If we change the chunking on the available balance, then the verifier needs to support proofs for both kinds of chunking. Or reject the proofs for the old kind & ask the sender to re-chunk its balance.
        - Maybe there’s a hope to just re-chunk automatically on the Move side during a send? But this may create some large field elements that will be difficult to decrypt for the sender 😬
-->

### Upgrading ZKPs

This can be done trivially: just add a new enum variant while maintaining the old one for a while.

If there is a soundness bug, the old variant must be disallowed.

This will break old dapps, unfortunately, but that is inherent in order to protect against theft.

{: .todo}
Define the CFA algorithms so as to reason about upgradeability more easily.

### Upgrading encryption scheme

We may want to upgrade our encryption scheme for efficiency reasons or for security (e.g., post-quantum).

#### Option 1: Force users to upgrade balance ciphertext

One way[^hm] to support such an upgrade is to force the owning user to re-encrypt their old balance under the new encryption scheme.
Then, we'd only allow transfers between users who are upgraded to the new scheme.
(Option two would be to implement support for sending confidential assets from an old balance into a new balance.)

Such upgrades may happen repeatedly, so we must ensure complexity does not get out of hand: e.g., if over the years we've upgraded our encryption scheme $n-1$ times, then there may be a total of $n$ ciphertext types flying around ($n\ge 1$).

Naively, we'd want to support converting any old scheme to any new scheme, but that would require too many re-encryption implementations: $(n-1) + (n-2) + \ldots + 2 + 1 = O(n^2)$.

A solution would be to only implement re-encryption from scheme $i$ to scheme $i+1$, for any $i\in[n-1]$.
This could be slow, since it requires $n-1$ re-encryptions.
If so, we can do it in $O(\log{n})$ re-encryption in a skip list-like fashion.
(By allowing upgrades to skip intermediate schemes, we would reduce the number of required re-encryptions.)

**Another challenge:** post-upgrade, existing dapps, now with an out-of-date SDK, will not know how to handle the new encryption scheme. So, such upgrades are **backwards incompatible.**

For example, old dapps will be "surprised" to see that the user's balance is no longer encrypted under the old scheme (i.e., the SDK sees that the balance enum is a new unrecognized variant).
If so, the SDK should display a user-friendly error like _"This dapp must be upgraded to support new confidential asset features."_

It's unclear whether there's something better we could do to maintain backwards compatibility.
I think the main problematic scenario is:
1. Alice used a new dapp that converted her entire balance to the new scheme
2. Alice uses an old dapp that panics when it cannot handle the new scheme

We may want to strongly recommend that dapps/wallets only allow the user to manually upgrade their ciphertexts?
This way, at least users understand that upgrading may make their assets inaccessible on older dapps.

### Option 2: Universal transfers

Again, the assumption is that, over the years, we've upgraded our encryption scheme $n-1$ time $\Rightarrow$ there may be a total of $n$ ciphertext types flying around ($n\ge 1$).

To deal with this, we could simply build functionality that allows to transfer CFAs between any scheme $i,j\in[n]$.

During a send, the SDK should prefer encrypting the amounts for the recipient under the highest supported scheme $j$ their account supports.
(Or, encrypt for the max $j$ supported by the contract; it's just that the user, depending on what dapp/wallet they are using, may not be able to access that balance.)

The key question is: should we enforce "progress" by only allowing to send from a scheme $i$ to a scheme $j$ when $j\ge i$? 
This way, we would ensure that older ciphertexts don't proliferate?

## FAQ

### How does auditing currently work?

Aptos governance can decide, for each token type, who is the auditor for TXNs for that token:
```rust
    /// Sets the auditor's public key for the specified token.
    ///
    /// NOTE: Ensures that new_auditor_ek is a valid Ristretto255 point
    public fun set_auditor(
        aptos_framework: &signer, token: Object<Metadata>, new_auditor_ek: vector<u8>
    ) acquires FAConfig, FAController
```

This updates the following token-type-specific resource:
```rust
    /// Represents the configuration of a token.
    struct FAConfig has key {
        /// Indicates whether the token is allowed for confidential transfers.
        /// If allow list is disabled, all tokens are allowed.
        /// Can be toggled by the governance module. The withdrawals are always allowed.
        allowed: bool,

        /// The auditor's public key for the token. If the auditor is not set, this field is `None`.
        /// Otherwise, each confidential transfer must include the auditor as an additional party,
        /// alongside the recipient, who has access to the decrypted transferred amount.
        auditor_ek: Option<twisted_elgamal::CompressedPubkey>
    }
```

{: .note}
There is no global auditor support implemented; only token-specific.
(An older version of the code had global auditing only.)
However, we **do** allow optional and unrestricted auditors: one can encrypt TXN amounts under any EK they please.
In other words, only the first auditor EK is required to be the set to the token-specific auditor.

{: .note}
We do not require a ZKPoK when setting a token-specific EK, to simplify deployment and implementation.
It can be easily added in the future.

### Why 16-bit chunk sizes?

We chose $b=16$-bit chunks for two reasons.

First, it allows us to use the [naive DL algorithm](#naive-discrete-log-algorithm) to instantly decrypt TXN amounts.
This should make confidential dapps very responsive and fast.

Second, if $t=16$, it ensures that the pending balance chunks never exceed $2^b(2^t-1)\approx 2^{32}$, even if there were 65,535 incoming transfers (i.e., $2^t - 1$).
This, in turn, ensures fast decryption times for pending (and available) balances.

Why do we think there could be so many incoming transfers?
They may arise in some use cases, such as payment processors, where it would be important to seamlessly receive many transfers.
In fact, $2^{16}$ may not even be enough there.
(Fortunately, the $t$ parameter is easy to increase as we deploy faster DL algorithms.)

### What are the main tensions in the current ElGamal-based design

The **main tension** is between:
 1. The ElGamal ciphertext (and associated proof) sizes: i.e., the # of chunks $n$ and $\ell$
 2. The decryption time for a TXN's amount: i.e., the chunk size $b$
    - We must be able to compute $n$ DLs on $b$ bit values in less than 10ms in the browser
        + This seems to restrict us to $b \le 16$ (see [benchmarks here](#bsgs-for-ristretto255-in-javascript)) 
    - We must have $\ell \cdot b=128$ and $n \cdot b = 64$
        + From above, we get $\ell = 8$ and $n=4$
    + This also indirectly influences the balance decryption times: balance chunks DLs are $(b+t)$-bit
        + DL times are fast for 32 bits $\Rightarrow t = 16$
        + **Fortunately**, as we improve our DL algorithms, we can simply increase $t$, in a backwards compatible fashion.

We can make decryption arbitrarily fast by encrypting smaller chunks, but we would increase confidential transaction sizes and also the cost to verify them due to more $\Sigma$-protocol verification work.
This would drive up gas costs.

{: .info}
**Important open question:** Minimizing the impact of higher $n$ and $\ell$ on our $\Sigma$-protocols using some careful design would be very interesting!
\
\
**Follow up question:** How fast is [univariate DeKART](/dekart)?
\
\
Note that if we use DeKART, as we make the chunk size $b$ smaller, even though the # of chunks $\ell$ (and $n$) increase, the range proof size and the verification time will actually decrease!
And we can speed up the verification time further: instead of proving that the chunks are in $[2^b)$, we can prove that they are in $[(2^k)^{b/k})$ and get a $k$ times smaller proof with faster verification (TBD).
<!--Actually, should we switch from base 2 to base $\hat{b}$?
$2^{128} = 2^{8\cdot 16} = (2^8)^{16}\bydef \emph{\hat{b}^{16}}$ and $2^{64} = 2^{8\cdot 8} = (2^8)^8 \bydef \emph{\hat{b}^8}$.
The DL algorithm does not care whether you express $B$ as $2^16$ or $4^8$. It only cares about $B$.
The base only matters when verifying proofs: i.e., 
for $[2^\ell)$, the verifier is doing an MSM linear in $\ell$ and $2-1\ell$ field muls, but
for $[(2^k)^{\ell / k})$, the verifier is doing an MSM linear in $\ell/k$ and $2^k \ell / k$ field muls.
If we set $k = 8$, we get $2^8/8 = 32 \times$ more field multiplications, but the baseline is $2\ell \approx 32$, so the $8$ times smaller MSM will more than make up for it.
On the other hand, regardless of $\ell$ we compute 3 pairings, so that may undo a lot of progress.
We will see.
-->

So we have to find a sweet spot.
Currently, we believe this to be either $b=8$-bit or $b=16$-bit chunks.
(TBD.)

A **secondary tension** is between:
 1. The # of incoming transfers $2^t - 1$ we allow without requiring a rollover from the pending balance into the available balance
 2. The max discrete log instance we are willing to ever solve for via specialized algorithms like BL DL[^BL12]
    + This instance would arise when decrypting the pending or the available balance

One of the difficulties is that BL DL[^BL12] is a probabilistic algorithm. 
This seems harmless, in theory, but we've actually encountered failures that are hard to debug when confidential apps are deployed.
Plus, decryption times can vary a lot $\Rightarrow$ unpredictable UX; see [benchmarks here](#bl-dl-benchmarks-for-ristretto255-in-rust).
Furthermore, our current BL DL implementation is in WASM (compiled from Rust) which increases the size of confidential dapps, complicates our code and makes debugging harder.

So, for ease of debugging, ease of implementing and for a consistent UX, we'd prefer deterministic algorithms that are guaranteed to terminate in a known amount of steps, like BSGS.
This way, we can guarantee none of our users will ever run into issues.

Unfortunately, deterministic algorithms are slower: BSGS on values in $[m)$ takes $O(\sqrt{m})$ time and space while BL DL only takes $O(m^{1/3})$ time and space.
This means that the highest $m$ we can hope to use with BSGS is in $[2^{32}, 2^{36})$, or so (see some [benchmarks](#bsgs-for-ristretto255-in-javascript)).
So, our $b+t=32$.

### How many types of discrete log instances do you have to solve?

Recall that:
1. Transfered amounts are 64-bits and chunked into $b$-bit chunks.
2. Balances are 128-bit and also $b$-bit chunked $\Rightarrow$ they have double the # of chunks
    + Also, balances "accumulate" transfers in

So, we have to solve two types of DL instances.
1. We need to _repeatedly_ decrypt TXN amounts $\Rightarrow$ need **very fast** DL algorithm for $b$-bit values
2. We need to one time decrypt the pending and available balance $\Rightarrow$ we need a _reasonably-fast_ DL algorithm for $\approx (b + t)$-bit values, if we want to support up to $\emph{2^t}$ incoming transfers

### To what extent can users provide hints in their TXNs and/or accounts to speed up decryption?

First, for TXN amounts, the chunk sizes are picked so that decryption is very fast.
We will likely implement $O(1)$-time decryption with a table of size $2^{16} \cdot 32 = 2^{21}$ bytes $= 2$ MiB.
As a result, there is no hint that the sender can include to make this decryption faster.

{: .info}
**Open question:** How much can we hope to reduce this table size?
Ideally, we are looking to have $\mathcal{H} : \\{ j\cdot G : j\in[m)\\} \rightarrow [m)$ with $\mathcal{H}(j\cdot G) = j,\forall j\in[m)$.
Such an ideal hash function may need at least $2^m \cdot \log_2{m} = 2^{m+\log_2\log_2{m}}$ bits.
\
\
**Follow up question:** Would this help reduce storage for BSGS?
I think so, yes!

Second, for pending balances, it's tricky because they change constantly as the user is getting paid.
Viewed differently, the hints are the decrypted amounts in all TXNs received since the last rollover which, as explained above, are very fast to fetch.

{: .info}
**A key question:**
Should we decrypt pending balances by doing $n$ DLs of size $<2^b(2^t - 1)$ each?
Or should we give ourselves a way to fetch the last $2^t$ TXNs, instantly decrypt them and add them up?
\
**Decision:**
To minimize impact on our own full nodes and/or indexers, and since we'll need a DL algorithm for available balances anyway (see below), we should decrypt pending balances manually.
We can of course change this in the future.

Third, for available balances, this is where the sender can **indeed** store a hint for themselves.
The sender can do so:
1. After sending a TXN out, which decreases their avaiable balance
2. After normalizing their available balance

If:
1. Dealing with incorrect hints is not too expensive/cumbersome to implement
2. Storing the hint is not too expensive, gas-wise.
3. Decrypting the hint is significantly faster than doing $\ell$ DLs of size $< 2^{b+t}$ each

...then the complexity may be warranted.

On the other hand, if using $b+t = 32$ bits, then I estimate that a 32-bit discrete log via BSGS will take around 1 second in the browser (i.e., 13 ms $\times$ 10x slowdown${}\times \ell$ chunks $= 13 \times 10 \times 8$ ms $= 1.04$ seconds) 

{: .info}
**Decision:** Either way, we need a DL algorithm for $(b+t)$-bit values in case the hint is wrong/corrupted by bad SDKs. So, for now, we adopt the simpler approach, but we should leave open the possiblity of adding hints in the future.
We can allow for "extensions" fields in a user's confidential asset balance.
Maybe make it an `enum`.

### How smart can the SDK be to avoid decryption work?

Should the SDK just poll for a change in the encrypted balances on-chain and decrypt them? (Simple, but slow if user is receiving lots of transfers.)

Or should the SDK be more "smart" and be aware of the last decrypted balance and the transactions received since, including rollovers and normalizations? (Complex, but much more efficient.)

One challenge with the "smart" approach is that the SDK may need to fetch up to $2^t-1$ payment TXNs plus extra rollover and normalization TXNs.

{: .todo}
This is an **open question** for our SDK people.

### Why not go for a general-purpose zkSNARK-based design?

**Question:** Why did Aptos go for a **special-purpose** design based on the Bulletproofs ZK range proof and $\Sigma$-protocols, rather than a design based on a **general-purpose** zkSNARK (e.g., Groth16, PLONK, or even Bulletproofs itself)?

**Short answer:** Our special-purpose design best addresses the tension between **efficiency** and **security**.

**Long answer:** General-purpose zkSNARKs are not a panacea:

1. They remain slow when computing proofs
    + This makes it slow to transact confidentially on your browser or phone.
2. They *may* require complicated multi-party computation (MPC) setup ceremonies to bootstrap securely
    + This makes it difficult and risky to upgrade confidential assets if there are bugs discovered, or new features are desired
3. Implementing any functionality, including confidential assets, as a general-purpose "ZK circuit" is a dangerous minefield (e.g., [circom](/circom))
    + It is **very** difficult to do both *correctly* & *efficiently*[^sok] 
    + To make matters worse, getting it wrong means user funds would be stolen.

Still, general-purpose zkSNARK approaches, if done right, do have advantages:
1. Smaller TXN sizes
2. Cheaper verification costs.

So why opt for a **special-purpose** design like ours?

Because we can nonetheless achieve competitively-small TXN sizes and cheap verification, while also ensuring:

1. Computing proofs is fast
    + This makes it easy to transact on the browser, phone or even on a hardware wallet
2. There is no MPC setup ceremony required
    + This makes upgrades easily possible
3. The implementation is much easier to get right
    + We can sleep well at night knowing our users' funds are safe

## Appendix: Links

Documentation:
 - [aptos.dev docs](https://aptos.dev/build/smart-contracts/confidential-asset)

Implementation:
 - [$\Sigma$-protocols in Move](https://github.com/aptos-labs/aptos-core/pull/17660/)
 - [Move module](https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/aptos-experimental/sources/confidential_asset/confidential_asset.move )
 - [TypeScript SDK](https://github.com/aptos-labs/aptos-ts-sdk/tree/main/confidential-assets)
 - [Confidential payments demo](https://github.com/aptos-labs/confidential-payments-example)

Apps:
 - [Confidential payments demo (deployed)](https://confidential.aptoslabs.com)

## Appendix: Benchmarks

### BSGS for Ristretto255 in JavaScript

For now, just take the Rust benchmarks in the next section and multiply them by 10-20x.
This means a 32-bit balance chunk could take 130-260 ms to decrypt ($\GaddG{2^{16}}$ time).
Increasing it to 36-bits would 4x the time: 520ms-1.04s ($\GaddG{2^{18}}$ time).

{: .todo}
Figure out the fastest library and use it. Probably [`noble-curves`](https://github.com/paulmillr/noble-curves)?

### BSGS for Ristretto255 in Rust

A Ristretto255 point addition in `curve25519-dalek`, on a Macbook Pro M1 Max in low power mode, takes:
```
ristretto255/point_add  time:   [201.41 ns 201.88 ns 202.47 ns]
                        thrpt:  [4.9391 Melem/s 4.9534 Melem/s 4.9651 Melem/s]
```

So, we expect a BSGS DL on a 32-bit balance chunk to require $2^{16}$ such additions: so, 13.23 ms.

For 16-bit chunks, this time decreases to $2^8$ additions: so, 51 $\mu$s.

So, if a TXN amount has 8 chunks of 16 bits each, we could decrypt it in 404 $\mu$s. 

So, we could support 1 second / 404 $\mu$s $\approx$ 2475 TXN decryptions per second.

{: .note}
Even if JavaScript is 20x slower $\Rightarrow$ we should still be able to support 100 TXNs / second in the browser.
Plus, reducing chunk size further speeds things up.
\
**Decision:** Stick with 16 bit chunks and use the [naive DL algorithm](#naive-discrete-log-algorithm): store all solutions in tables of $2^{16}$ group elements ($2^{16}\times 32$ bytes $\Rightarrow 2$ MiB) and compute the DL in constant time! 
<!-- 16 chunks of 8-bit each give $2^4$ additions to decrypt: so, 3.20 $\mu$s per chunk $\Rightarrow $ 51.2 $\mu$s per TXN $\Rightarrow$ 19,500 TXN decryptions per second in Rust (or 1000 in the browser).-->
We have to be conservative because a user may be using multiple confidential apps at the same time and/or the browser may be busy doing other things.

### BL DL benchmarks for Ristretto255 in Rust

These were run on a Macbook M3.

|----------------+------------------------+-------------+--------------+--------------+
| Chunk size     | Algorithm              | Lowest time | Average time | Highest time |
|----------------|------------------------|-------------|--------------|--------------|
| 16-bit         | Bernstein-Lange[^BL12] | 1.67 ms     | 2.01 ms      | 2.96 ms      |
| 32-bit         | Bernstein-Lange[^BL12] | 7.38 ms     | 30.86 ms     | 77.00 ms     |
| 48-bit         | Bernstein-Lange[^BL12] | 0.72 s      | 4.03 s       | 12.78 s      |
|----------------+------------------------+-------------+--------------+--------------|

{: .warning}
Something is off here: BL should be **much** faster than [BSGS](#baby-step-giant-step-bsgs-discrete-log-algorithm).
e.g., on 32 bit values, BL takes $30.86$ ms on average, while BSGS similarly takes $2^{16}$ group operations $\Rightarrow$ 0.5 microseconds $\times 2^{16} \approx 32$ ms.

## Appendix: Implementation challenges

### Move serialization of handle-based "native" structs like `RistrettoPoint`

We cannot easily deserialize structs like:
```rust
    /// A sigma protocol *proof* always consists of:
    /// 1. a *commitment* $A \in \mathbb{G}^m$
    /// 2. a *response* $\sigma \in \mathbb{F}^k$
    struct Proof has drop {
        A: vector<RistrettoPoint>,
        sigma: vector<Scalar>,
    }
```
...because `RistrettoPoint` just contains a Move VM handle pointing to an underlying Move VM Rust struct.

We instead have to define a special de-serializable type:
```rust
    struct SerializableProof has drop {
        A: vector<CompressedRistretto>,
        sigma: vector<Scalar>,
    }
```
...because `CompressedRistretto` is serializable: it just wraps a `vector<u8>`.

Then, we have to write some custom logic in Move that deserializes bytes into a `Proof` by going through the intermediate `SerializableProof` struct.

But we cannot even write `from_bcs::from_bytes<SerializableProof>(bytes)` in Move, because a publicly-exposed `from_bytes` would allow anyone to create any structs they want, which breaks Move's "structs as capabilities" security model.

So, in the end, we just have to write a function like this for every struct we need deserialized:
```rust
fun deserialize_proof(A: vector<vector<u8>>, sigma: vector<vector<u8>>): Proof
```

Annoying.

Alternatively, but probably more expensive, since we are writing Aptos framework code, we could make `aptos_framework::confidential_asset` a `friend` of `aptos_framework::util` and call unsafe BCS deserialization code to obtain an intermediate `SerializableProof` struct:
```
use aptos_framework::util;

fun deserialize_proof_bcs(bytes: vector<u8>): Proof {
	let proof: SerializableProof = util::from_bytes(bytes);
    
	sigma_protocols::proof::from_serializable_proof(proof)
}
```
...but we still have to, more, or less, manually write code for each struct that converts between its "serializable" counterpart and its actual counterpart.

So, by that point, we may as well just implement `deserialize_proof()` and `deserialize_<struct>()` in general for all of our structs.

Annoying.

## References

For cited works, see below 👇👇

[^hm]: I wonder if this is generally true...

[^sok]: Writing efficient and secure ZK circuits is extremely difficult. I quote from a recent survey paper[^CETplus24] on implementing general-purpose zkSNARK-based systems: _"We find that developers seem to struggle in correctly implementing arithmetic circuits that are free of vulnerabilities, especially due to most tools exposing a low-level programming interface that can easily lead to misuse without extensive domain knowledge in cryptography."_


{% include refs.md %}
