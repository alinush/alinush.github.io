---
type: note
tags:
 - digital signatures
 - post-quantum
title: "QSB: a hash-based signature scheme with proof-of-work signing"
published: false
permalink: qsb
#sidebar:
#   nav: cryptomat
---

<p hidden>$
\def\keygen{\mathsf{KeyGen}}
\def\sign{\mathsf{Sign}}
\def\verify{\mathsf{Verify}}
\def\Recover{\mathsf{ECDSA.PubkeyRecover}}
\def\ValidDER{\mathsf{ValidDER}}
\def\RIPEMD{\mathsf{RIPEMD160}}
\def\HASH{\mathsf{HASH160}}
\def\pp#1{\textcolor{green}{#1}}
\def\txnFields{\texttt{txnFields}}
\def\scriptCode{\texttt{scriptCode}}
$</p>

{: .info}
**tl;dr:** QSB[^Levy26] is a hash-based one-time [digital signature](/signatures) scheme where signing requires ${\sim}2^{47}$ hash evaluations (proof-of-work). It is post-quantum secure with 118-bit security against Shor-style attacks (??) and 59-bit security against Grover[^Grov96].
I would describe it as formidable but incredibly-contrived.
\
\
**KeyGen** samples, for each round $j \in \\{1,2\\}$ and pool index $i \in [\pp{n}]$ (where $\pp{n}$ is the **pool size**; e.g., $\pp{n} = 150$): a random HORS preimage $\mathsf{pre}\_{j,i} \randget \\{0,1\\}^{160}$, a random pool element $d\_{j,i} \randget \\{0,1\\}^{\pp{\ell}}$, and an ECDSA signature pair $\sigma\_j = (r\_j, s\_j)$ (additionally sampled for $j = 0$ too).
It outputs $\sk = (\mathsf{pre}\_{j,i})\_{j \in \\{1,2\\},\, i \in [\pp{n}]}$ and $\pk = ((\sigma\_j)\_{j \in \\{0,1,2\\}},\, (d\_{j,i},\, c\_{j,i})\_{j \in \\{1,2\\},\, i \in [\pp{n}]})$, where $c\_{j,i} = \RIPEMD(\mathsf{SHA256}(\mathsf{pre}\_{j,i}))$ are [HORS](#hors-one-time-signatures) commitments.
\
\
**Signing** $m$ under $(\sk,\pk)$: first, find a **pinning nonce** $\nu \in \\{0,1\\}^{64}$ such that $\ValidDER(\RIPEMD(\Recover(H(m, \nu), \sigma_0))) = 1$ (${\sim}2^{46}$ work). Then, grind for subsets $S_1, S_2 \subseteq [\pp{n}]$ such that, for each round $j \in \\{1,2\\}$, $\ValidDER(\RIPEMD(\Recover(H(m, \nu, S_j), \sigma_j))) = 1$, where $H(m, \nu, S_j)$ is a subset-dependent message hash and $\Pr_{r\gets \\{0,1\\}^{160}}[\ValidDER(r) = 1] \approx 2^{-46}$.
Each $S\_j$ is arbitrarily partitioned into **signed** indices $S\_j^s$ (preimages revealed) and **bonus** indices $S\_j^b = S\_j \setminus S\_j^s$ (affect the hash but no preimage revealed, [trading security for efficiency](#bonus-key-security-impact)).
The output signature is $\sigma = (\nu,\, (S\_j,\, (\mathsf{pre}\_{j,i})\_{i \in S\_j^s})\_{j \in \\{1,2\\}})$ — i.e., the nonce, the subsets, and a [HORS signature](#hors-one-time-signatures) on each $S\_j^s$.
\
\
**Verification** of $(m, \pk, \sigma)$: parse $\sigma$ (see above) and check (1) the pinning puzzle $\ValidDER(\RIPEMD(\Recover(H(m, \nu), \sigma\_0))) = 1$, and for each round $j \in \\{1,2\\}$: (2) $S\_j^s \subseteq S\_j$ with $\sizeof{S\_j^s} = \pp{t\_j^s}$ and $\sizeof{S\_j \setminus S\_j^s} = \pp{t\_j^b}$, (3) the [HORS check](#hors-one-time-signatures) $\HASH(\mathsf{pre}\_{j,i}) \equals c\_{j,i}$ for each $i \in S\_j^s$, and (4) the round puzzle $\ValidDER(\RIPEMD(\Recover(H(m, \nu, S\_j), \sigma\_j))) = 1$.
\
\
Security rests entirely on hash preimage resistance: Shor's algorithm provides zero advantage to a forger, while Grover's algorithm theoretically halves the bit-security (e.g., from ${\sim}118$ to ${\sim}59$ bits) but requires implementing the full hash chain as a reversible quantum circuit.
Unclear whether BHT-style[^Bern09] attacks apply.

<!--more-->

## Preliminaries

### Notation

 - Let $\lambda$ denote the security parameter (e.g., $\lambda = 128$)
 - Let $\Gr$ denote an [elliptic curve](/ecdsa#preliminaries) group of prime order $\term{p}$ with generator $\term{g}$
 - Let $\Fq$ denote the **base field** of the elliptic curve of order $\term{q}$, so each point $P \in \Gr$ has coordinates $(x,y) \in \Fq^2$
 - Let $\Zp$ denote the **scalar field** of order $\term{p}$
 - (Recall that for Bitcoin, $\Gr$ is the secp256k1 curve with $q > p$.)
 - Let $\term{f} : \Gr \to \Zp$ denote the [ECDSA conversion function](/ecdsa#the-ecdsa-conversion-function): $f(P)$ returns the integer representation of $P$'s $x$-coordinate, reduced modulo $p$
 - Let $\term{H} : \\{0,1\\}^* \to \Zp$ denote a collision-resistant hash function
    + **TODO:** Where is this used?
 - Let $\term{\RIPEMD} : \\{0,1\\}^* \to \\{0,1\\}^{160}$ denote the RIPEMD-160 hash function
    + $\RIPEMD(Q)$ for $Q \in \Gr$ really means $\RIPEMD(\mathsf{ser}(Q))$ where $\mathsf{ser} : \Gr \to \\{0,1\\}^*$ is the canonical byte serialization of curve points (e.g., 33-byte compressed encoding).
 - Let $\term{\HASH} : \\{0,1\\}^* \to \\{0,1\\}^{160}$ denote the composition $\RIPEMD \circ \mathsf{SHA\text{-}256}$
    + (Same point as for $\RIPEMD$)


### Bitcoin Script

QSB is designed to run inside **Bitcoin Script**, a minimal stack-based language that verifies transactions.
Understanding a few key concepts is necessary to see why the scheme is shaped the way it is.

#### Transactions and scripts

A Bitcoin transaction transfers funds by consuming **inputs** (previously-created outputs) and creating new **outputs**.
Each output carries a value (i.e., an amount of Bitcoin) and a **locking script** (called a `scriptPubKey`) — a small program that specifies the conditions under which the output['s value] can be spent.
To spend an output, the spender provides an **unlocking script** (called a `scriptSig`).
The two scripts are concatenated and executed on a stack machine; if the stack holds `TRUE` at the end, the spend is valid.

#### Available operations

Bitcoin Script is intentionally limited. The opcodes relevant to QSB are:

 - `OP_RIPEMD160` — pops a byte string $x$; pushes $\RIPEMD(x)$ (20 bytes)
 - `OP_SHA256` — pops a byte string $x$; pushes $\mathsf{SHA256}(x)$ (32 bytes)
 - `OP_HASH160` — pops a byte string $x$; pushes $\RIPEMD(\mathsf{SHA256}(x))$ (20 bytes)
 - `OP_CHECKSIGVERIFY` — pops a public key $Q$ and a signature $\sigma$; internally computes the **transaction hash** $z$ (see [sighash](#the-sighash-z) below), then checks [$\mathsf{ECDSA.Verify}(z, Q, \sigma) = 1$](/ecdsa#ecdsa-verify). **This is the only opcode that operates on the transaction hash** — and the script has no other way to access $z$.
 - `OP_CHECKMULTISIG` — pops $N$, then pops $N$ public keys $(Q_1, \ldots, Q_N)$, then pops $M$, then pops $M$ signatures $(\sigma_1, \ldots, \sigma_M)$ (plus a dummy element due to a [historical bug](https://github.com/bitcoin/bitcoin/blob/v28.0/src/script/interpreter.cpp#L1058-L1059)).
    + internally computes the transaction hash $z$ (same as `OP_CHECKSIGVERIFY`; see [sighash](#the-sighash-z) again)
    + for each $\sigma_i$,checks $\mathsf{ECDSA.Verify}(z, Q_{j_i}, \sigma_i) = 1$ where $1 \le j_1 < j_2 < \cdots < j_M \le N$ 
        * this uses a naive, greedy, left-to-right scan: for each $i = 1, 2, \ldots M$ (in this order), advance through the remaining public keys until you reach a pubkey $Q_{j_i}$ such that $\mathsf{ECDSA.Verify}(z, Q_{j_i}, \sigma_i) = 1$[^why-bitcoin-why]
        * since the public key pointer only moves forward, this enforces $j_1 < j_2 < \cdots < j_M$
        * so, signatures must be provided in the same order as their corresponding keys
    + additionally triggers [FindAndDelete](#find-and-delete) (see below).
 - `OP_DUP` — duplicates the top stack element
 - `OP_SWAP` — swaps the top two stack elements
 - `OP_ROLL` — pops an index $k$; moves the $k$-th element to the top of the stack ($k=0$ is the top of the stack $\Rightarrow$ a no-op, $k=1$ is equivalent to `OP_SWAP`, $k=2$ is the 2nd element from the top of the stack, down)
    + _Note:_ This is a move not a swap, even though the $k=1$ case can be viewed as a swap.
 - `OP_OVER` — copies the second-from-top element to the top
 - `OP_EQUALVERIFY` — pops two elements; aborts if they are not equal

#### The sighash $z$

{: .todo}
Clarify the DER format of a signature with a SIGHASH flag byte appended at the end which influence how $z$ is computed below.

When Bitcoin Script executes a signature check, it computes a **sighash** $z$ as:

$$z = \mathsf{SHA256}(\mathsf{SHA256}\!\left(\txnFields\ \|\ \scriptCode\right))$$

where:
 - `scriptCode` is (roughly) the locking script itself (i.e., the `scriptPubKey` modulo the changes from [FindAndDelete](#find-and-delete))
 - `txnFields` includes:
    + **inputs and outputs** (which funds are spent and where they go): this is what the signer wants to authenticate
    + the **sighash flag**, parsed from the end of the DER-encoded signature: controls which of the above fields are included in the hash
       * `SIGHASH_ALL` (the most common): commits to all inputs and all outputs
       * `SIGHASH_SINGLE`: commits to only the output at the same index as the input being signed
       * other flags exist but are less relevant here
    + **`locktime`** and **`nSequence`**: looking ahead to the [pinning puzzle](#pinning), both are effectively free parameters that the signer can "grind"
       * `locktime` specifies the earliest time (block height or Unix timestamp) a transaction can be included in a block
       * `nSequence` is a per-input field originally intended for transaction replacement
    + (also: transaction version and previous-output references, which are fixed and not interesting for QSB)

{: .info}
{: #grinding-safely}
**Grinding safely.** Looking ahead, QSB "grinds" some of the items above so as to yield a different `txnFields` and thus a different sighash $z$.
Since grinding `locktime` naively could produce a value far in the future (making the transaction unspendable until then), the signer should grind over a combination of free parameters — `nSequence`, output ordering, change address, minor fee adjustments, or `OP_RETURN` data — while keeping `locktime` within a reasonable range. The paper[^Levy26] lists all of these as valid grinding parameters and leaves the choice as an implementation detail.

#### FindAndDelete
{: #find-and-delete}

A legacy behavior (removed in SegWit) in how the sighash $z$ is computed.

Recall that $z$ is computed over the `scriptCode`, which starts as a copy of the `scriptPubKey`.
Before hashing, the interpreter scans the `scriptCode` and **removes** every occurrence of each signature being checked by the current `OP_CHECKSIGVERIFY` or `OP_CHECKMULTISIG`.
The original purpose was to avoid a circularity: the signature commits to $z$, which is a hash over the `scriptCode`, which would otherwise contain the signature itself — creating a circular dependency.
In practice, signatures normally live only in the `scriptSig` (unlocking script), not in the `scriptPubKey`, so FindAndDelete usually has nothing to remove and is a no-op.

**How QSB exploits FindAndDelete.**
QSB deliberately embeds $\pp{n}$ dummy signatures as data pushes inside the `scriptPubKey` itself.
The spender selects a subset of $\pp{t}$ of them and passes them to `OP_CHECKMULTISIG`.
FindAndDelete removes exactly those $\pp{t}$ byte sequences from the `scriptCode` before hashing.

Different subsets → different `scriptCode` → different sighash $z$.
This gives $\binom{\pp{n}}{\pp{t}}$ distinct sighash values from a single transaction.

#### Other constraints
Legacy Script (pre-SegWit) imposes hard limits:
 - At most **201 non-push opcodes**[^push-terminology]
 - At most **10,000 bytes** of script size

These constraints severely limit the scheme's parameters and are the reason for many of QSB's design trade-offs (e.g., bonus keys, two rounds instead of more).

### ECDSA key recovery

A standard property of [ECDSA](/ecdsa#pubkey-recovery) is that, given a signature $(r,s) \in (\Zps)^2$ and a message hash $z \in \Zp$, one can **recover** the public key $Q \in \Gr$ under which the signature verifies on $z$:

$\Recover(z, (r,s,v)) \rightarrow Q \in \Gr$:
 - Let $R \in \Gr$ be the point identified by $(r, v)$: there are up to 4 candidates (see below), and $v \in \\{0,1,2,3\\}$ selects which one
 - $Q \gets \left(R^{s} / g^{z}\right)^{r^{-1} \bmod p}$

This is a deterministic, public computation (given the recovery flag $v$). No private key is needed.

**Why up to 4 candidates?** Recall $f(R) = \bar{x}_R \bmod p$ where $\bar{x}_R$ is the integer representation of $R$'s $x$-coordinate in the base field $\Fq$. Given $r$, there are two sources of ambiguity:
 1. **Two $y$-coordinates**: each valid $x$-coordinate on the curve has two square roots ($y$ and $-y$)
 2. **Two $x$-coordinates**: both $x = r$ and $x = r + p$ (if $r + p < q$) reduce to $r \bmod p$

This gives up to $2 \times 2 = 4$ candidates. For secp256k1, the second case is negligible ($\Pr \approx 2^{-128}$) when $r$ comes from an honestly-generated random curve point, so in practice there are usually just 2 candidates. But in QSB, where $(r,s)$ pairs may be chosen arbitrarily, all 4 can arise.

{: .info}
In QSB, ECDSA key recovery is used purely as a **deterministic map** from scalars to group elements: $z \mapsto \Recover(z, \sigma)$, parameterized by a fixed triple $\sigma = (r,s,v)$.
It is _not_ a security assumption.
Even a quantum adversary who can solve discrete logarithms gains nothing from this usage: the map is public and has no secret.

### DER validity predicate

**DER** (Distinguished Encoding Rules) is a standard byte encoding for ECDSA signatures.
A 160-bit (20-byte) string $b$ is a **valid DER-encoded ECDSA signature** if it parses as:

$$\texttt{0x30}\ \|\ [\mathsf{len}]\ \|\ \texttt{0x02}\ \|\ [r\text{-}\mathsf{len}]\ \|\ [r]\ \|\ \texttt{0x02}\ \|\ [s\text{-}\mathsf{len}]\ \|\ [s]\ \|\ [\text{trailing byte}]$$

where all length fields are internally consistent, $r$ and $s$ are positive integers with no unnecessary leading zeros (i.e., MSB $< \texttt{0x80}$), and the trailing byte is unconstrained.

We define the **DER validity predicate**:

$$\ValidDER : \\{0,1\\}^{160} \to \\{0,1\\}$$

For a uniformly random $b \in \\{0,1\\}^{160}$:

$$\Pr[\ValidDER(b) = 1] \approx 2^{-46}$$

This probability is dominated by the structural constraints of the DER format (matching tags, consistent lengths, positivity of integers).

### HORS one-time signatures

**HORS** (Hash to Obtain Random Subset)[^RR02e] is a one-time signature scheme based on hash preimage resistance.
The "message" signed by HORS is a subset $S \subseteq [n]$ of indices; the signer proves knowledge of the corresponding preimages.

$\mathsf{HORS}$.$\keygen(1^\lambda, n) \rightarrow (\sk_H, \pk_H)$:
 - For each $i \in [n]$: $\mathsf{pre}_i \randget \\{0,1\\}^{160}$
 - For each $i \in [n]$: $c_i \gets \HASH(\mathsf{pre}_i)$
 - $\sk_H \gets (\mathsf{pre}_i)\_{i \in [n]}$
 - $\pk_H \gets (c_i)\_{i \in [n]}$

$\mathsf{HORS}$.$\sign(S, \sk_H) \rightarrow \sigma_H$, where $S \subseteq [n]$:
 - $\sigma_H \gets (\mathsf{pre}_i)\_{i \in S}$

$\mathsf{HORS}$.$\verify(S, \pk_H, \sigma_H) \rightarrow \\{0,1\\}$:
 - Parse $\sigma_H = (\mathsf{pre}_i)\_{i \in S}$
 - For each $i \in S$: **assert** $\HASH(\mathsf{pre}_i) \equals c_i$

{: .warning}
HORS is a **one-time** signature scheme: each key pair $(\sk_H, \pk_H)$ must sign at most one subset. Signing two different subsets $S \neq S'$ reveals preimages for $S \cup S'$, enabling forgeries on any subset $S'' \subseteq S \cup S'$.

## Key ideas

### The hash-to-sig puzzle

The core building block of QSB is the **hash-to-sig puzzle**: given a fixed ECDSA signature pair $\sigma = (r,s)$, find a scalar $z \in \Zp$ such that:

$$\ValidDER\left(\RIPEMD\left(\Recover(z, \sigma)\right)\right) = 1$$

Since $\Recover(z, \sigma)$ is a deterministic function of $z$, and $\RIPEMD$ is modeled as a random oracle, each candidate $z$ satisfies the predicate independently with probability ${\sim}2^{-46}$.
Solving the puzzle therefore requires trying ${\sim}2^{46}$ candidates --- a moderate proof-of-work.

{: .info}
**Why $\Recover$ and $\ValidDER$?** Both are artifacts of the restricted execution environment where QSB was designed to run[^Levy26]: the verifier cannot access the message hash $z$ directly (only through ECDSA signature verification), and the only available structural predicate on byte strings is DER validity (checked implicitly by ECDSA verification).
Abstractly, $\Recover$ could be replaced by any deterministic, injective map from scalars to byte strings, and $\ValidDER$ by any predicate $P$ with $\Pr[P(\cdot) = 1] \approx 2^{-46}$. (The scheme's security comes from the HORS signatures and two-round subset structure, not from the specific predicate.)

{: .info}
**Why is this quantum-safe?** The puzzle's difficulty depends only on the preimage resistance of $\RIPEMD$.
$\Recover$ is used as a public deterministic map, not as a security assumption.
Shor's algorithm, which breaks ECDSA by computing discrete logarithms, provides _no_ advantage here: the attacker still faces a brute-force search over hash outputs.

### Subset-dependent hashing

To produce $\binom{\pp{n}}{\pp{t}}$ distinct candidates for the hash-to-sig puzzle _from a single message_, QSB embeds a **pool** of $\pp{n}$ fixed, distinct byte strings $\mathbf{d} = (d_1, \ldots, d_n)$ in the public key (one pool per round).

For a subset $S \subseteq [\pp{n}]$ with $\sizeof{S} = \pp{t}$, define the **subset-dependent hash**:

$$H(m, \nu, S) = H\!\left(m \concat \nu \concat d_{i_1} \concat d_{i_2} \concat \cdots \concat d_{i_{\pp{n}-\pp{t}}}\right)$$

where $\\{i_1 < i_2 < \cdots < i_{\pp{n}-\pp{t}}\\} = [\pp{n}] \setminus S$.

That is, the hash input is the message and nonce concatenated with all pool elements **not** in $S$, in sorted order.
Removing different subsets changes the hash input, producing different scalars $H(m, \nu, S) \in \Zp$ with overwhelming probability (under the collision resistance of $H$).

The signer iterates over all $\binom{\pp{n}}{\pp{t}}$ subsets, checking whether $\ValidDER(\RIPEMD(\Recover(H(m, \nu, S), \sigma))) = 1$.
The subset that solves the puzzle becomes the **digest** for that round.

## The QSB signature scheme

### Parameters

| Parameter | Description | Example (Config A) |
|-----------|-------------|---------------------|
| $\pp{n}$ | Pool size per round | 150 |
| $\pp{\rho}$ | Number of digest rounds | 2 |
| $\pp{t_j^s}$ | Signed selections in round $j$ | $\pp{t_1^s} = 8,\ \pp{t_2^s} = 7$ |
| $\pp{t_j^b}$ | Bonus selections in round $j$ | $\pp{t_1^b} = 1,\ \pp{t_2^b} = 2$ |
| $\pp{t_j} = \pp{t_j^s} + \pp{t_j^b}$ | Total selections in round $j$ | $\pp{t_1} = 9,\ \pp{t_2} = 9$ |
| $\pp{\ell}$ | Pool element size (bits) | 72 |

**Signed** selections have their HORS preimages revealed in the signature, committing the signer to those specific indices.
**Bonus** selections participate in the subset-dependent hash (increasing $\binom{\pp{n}}{\pp{t_j}}$) but skip HORS verification, trading some security for efficiency (see [security impact](#bonus-key-security-impact) below).
Setting $\pp{t_j^b} = 0$ for all rounds gives the **baseline** scheme where every selection is signed.

### $\mathsf{QSB}$.$\keygen(1^\lambda) \rightarrow (\sk, \pk)$

**Nonce signatures.** For each $j \in [\pp{\rho})$:
 - Pick $r_j \in (0, p)$ such that there exists $R_j \in \Gr$ with $f(R_j) = r_j$
 - Pick $s_j \randget (0, p)$
 - Set $\sigma_j \gets (r_j, s_j)$

{: .info}
$\sigma_0$ is the **pinning** nonce signature.
$\sigma_1, \ldots, \sigma_\rho$ are the **round** nonce signatures.
These are arbitrary ECDSA-compatible pairs --- no private key is associated with them.
They serve only as parameters for the deterministic $\Recover$ map.

**Pool elements.** For each round $j \in [\pp{\rho}]$ and index $i \in [\pp{n}]$:
 - Sample $d_{j,i} \randget \\{0,1\\}^{\pp{\ell}}$ (distinct byte strings)

**HORS keys.** For each round $j \in [\pp{\rho}]$ and index $i \in [\pp{n}]$:
 - $\mathsf{pre}_{j,i} \randget \\{0,1\\}^{160}$
 - $c_{j,i} \gets \HASH(\mathsf{pre}_{j,i})$

**Return:**
$$\sk \gets \left(\mathsf{pre}_{j,i}\right)_{j \in [\pp{\rho}],\ i \in [\pp{n}]}$$
$$\pk \gets \left((\sigma_j)_{j \in [\pp{\rho})},\ (d_{j,i},\ c_{j,i})_{j \in [\pp{\rho}],\ i \in [\pp{n}]}\right)$$

### $\mathsf{QSB}$.$\sign(m, \sk) \rightarrow \sigma$

**Step 1: Pinning.**
{: #pinning}
Search for a nonce $\nu \in \\{0,1\\}^{64}$ such that:
 1. $z_0 \gets H(m \concat \nu)$
 2. $Q_0 \gets \Recover(z_0, \sigma_0)$
 3. $\ValidDER(\RIPEMD(Q_0)) = 1$

Increment $\nu$ until the predicate is satisfied (see [grinding safely](#grinding-safely) for how $\nu$ is varied in practice). Expected work: ${\sim}2^{46}$ attempts.

{: .info}
**Why pinning?** Pinning ensures that any modification to the signed data $(m, \nu)$ requires re-solving a ${\sim}2^{46}$-hard puzzle.
This is critical for [collision resistance](#collision-resistance): without it, a malicious signer could cheaply sample many message variants for birthday attacks on the digest.

**Step 2: Digest search.** For each round $j \in [\pp{\rho}]$:
 1. Iterate over all $\binom{\pp{n}}{\pp{t_j}}$ subsets $S_j \subseteq [\pp{n}]$ with $\sizeof{S_j} = \pp{t_j} = \pp{t_j^s} + \pp{t_j^b}$ (see [parameters](#parameters))
 2. For each $S_j$, compute:
    - $z_j \gets H(m, \nu, S_j)\ \textcolor{grey}{\text{// subset-dependent message hash}}$
    - $Q_j \gets \Recover(z_j, \sigma_j)$
    - If $\ValidDER(\RIPEMD(Q_j)) = 1$: accept $S_j$ as the **digest** for round $j$; break
 3. Partition $S_j = S_j^s \cup S_j^b$ with $\sizeof{S_j^s} = \pp{t_j^s}$ (signed) and $\sizeof{S_j^b} = \pp{t_j^b}$ (bonus)

If either round fails to find a valid subset among all $\binom{\pp{n}}{\pp{t_j}}$ candidates, return to Step 1 with a fresh $\nu$.

**Step 3: Output.**

$$\sigma \gets \left(\nu,\ \left(S_j^s,\ S_j^b,\ (\mathsf{pre}_{j,i})_{i \in S_j^s}\right)_{j \in [\pp{\rho}]}\right)$$

{: .warning}
**One-time use.** QSB is a **one-time** signature scheme: each key pair $(\sk, \pk)$ must be used to sign at most one message.
Signing two distinct messages reveals HORS preimages for two potentially-different subsets, which an adversary can combine to forge signatures on other messages.

### $\mathsf{QSB}$.$\verify(m, \pk, \sigma) \rightarrow \\{0,1\\}$

Parse $\sigma = \left(\nu,\ \left(S_j^s,\ S_j^b,\ (\mathsf{pre}_{j,i})_{i \in S_j^s}\right)_{j \in [\pp{\rho}]}\right)$.

**Pinning check:**
 1. $z_0 \gets H(m \concat \nu)$
 2. $Q_0 \gets \Recover(z_0, \sigma_0)$
 3. **assert** $\ValidDER(\RIPEMD(Q_0)) = 1$

**Round check (for each $j \in [\pp{\rho}]$):**
 1. $S_j \gets S_j^s \cup S_j^b$
 2. **assert** $\sizeof{S_j^s} = \pp{t_j^s}$ and $\sizeof{S_j^b} = \pp{t_j^b}$ and $S_j^s \cap S_j^b = \emptyset$
 3. For each $i \in S_j^s$: **assert** $\HASH(\mathsf{pre}_{j,i}) \equals c_{j,i}\ \textcolor{grey}{\text{// HORS check}}$
 4. $z_j \gets H(m, \nu, S_j)$
 5. $Q_j \gets \Recover(z_j, \sigma_j)$
 6. **assert** $\ValidDER(\RIPEMD(Q_j)) = 1\ \textcolor{grey}{\text{// hash-to-sig puzzle check}}$

## Correctness

The scheme is correct if signatures produced by $\mathsf{QSB}.\sign$ always verify under $\mathsf{QSB}.\verify$.

This follows directly from the construction:
 - The signer's search in $\sign$ explicitly finds $\nu$, $S_1$, $S_2$ satisfying all pinning and round puzzle checks. Since $H$, $\Recover$, $\RIPEMD$, and $\ValidDER$ are all deterministic, the verifier's recomputation yields the same results.
 - The HORS preimages are correct by construction: the signer generated them in $\keygen$ and reveals only those corresponding to the signed indices $S_j^s$.

## Security

QSB's security rests on two properties of the hash functions $H$, $\RIPEMD$, and $\HASH$:
 - **Preimage resistance:** Given $c = \HASH(\mathsf{pre})$, it is infeasible to find $\mathsf{pre}$.
 - **Collision resistance:** It is infeasible to find $x \neq x'$ with $H(x) = H(x')$.

No elliptic curve hardness assumption is needed.
All concrete security numbers below are for **Config A** ($\pp{n} = 150$, $\pp{t_1} = 9$, $\pp{t_2} = 9$, $\pp{\rho} = 2$).

### Second preimage resistance

An adversary who observes a valid signature $\sigma$ on message $m$ wants to find a different $(m', \nu')$ that verifies under the same public key (reusing the revealed HORS preimages).

The attack cost has two components:

**Pinning cost.** Each candidate $(m', \nu')$ requires solving the pinning puzzle: ${\sim}2^{46}$ work.

**Digest matching probability.** For a given pinned $(m', \nu')$ and round $j$:
 - The signed indices $S_j^s$ are fixed (their HORS preimages were revealed in $\sigma$), but the adversary can freely choose the $\pp{t_j^b}$ bonus indices
 - This gives $\binom{\pp{n} - \pp{t_j^s}}{\pp{t_j^b}}$ free attempts per round
 - Each attempt satisfies the round puzzle with probability ${\sim}2^{-46}$

For Config A ($\pp{t_1^s} = 8, \pp{t_1^b} = 1, \pp{t_2^s} = 7, \pp{t_2^b} = 2$):

\begin{align}
\text{Round 1:}\quad & \binom{142}{1} = 142 \approx 2^{7.1} \text{ free choices} \implies \Pr \approx 2^{7.1 - 46} = 2^{-38.9}\\\\\
\text{Round 2:}\quad & \binom{143}{2} = 10{,}153 \approx 2^{13.3} \text{ free choices} \implies \Pr \approx 2^{13.3 - 46} = 2^{-32.7}\\\\\
\text{Combined:}\quad & 2^{-38.9} \times 2^{-32.7} = 2^{-71.6} \text{ per pinned attempt}\\\\\
\text{Total cost:}\quad & 2^{46} \times 2^{71.6} \approx 2^{118}
\end{align}

### Collision resistance

A malicious signer wants to find two distinct messages $m \neq m'$ that produce valid signatures under the same $\pk$ (i.e., that yield the same HORS-signed digest).

The digest space is determined by $\binom{\pp{n}}{\pp{t_j}}$ subsets per round.
By the birthday bound, ${\sim}\sqrt{|\text{digest space}|}$ samples suffice to find a collision.
Each sample requires solving the pinning puzzle (${\sim}2^{46}$ work), which is the dominant cost.

For Config A, accounting for the signer's ability to assign which indices are "signed" vs. "bonus" (which multiplies the effective digest by $\prod_j \binom{\pp{t_j}}{\pp{t_j^s}}$):

\begin{align}
\text{Effective digest space:}\quad & {\sim}2^{80.4} \text{ bits}\\\\\
\text{Birthday bound:}\quad & {\sim}2^{40.2} \text{ samples}\\\\\
\text{Each sample costs:}\quad & {\sim}2^{46} \text{ (pinning)}\\\\\
\text{Total cost:}\quad & 2^{46} \times 2^{40.2} \approx 2^{78}
\end{align}

### Bonus key security impact

Bonus keys trade security for efficiency.
Each bonus selection in round $j$ gives the adversary $\binom{\pp{n} - \pp{t_j^s}}{\pp{t_j^b}}$ additional free subset choices, reducing second preimage resistance.
For collision resistance, the signer can choose how to partition $\pp{t_j}$ passing indices into signed and bonus, multiplying the birthday attack by $\binom{\pp{t_j}}{\pp{t_j^s}}$ per round.

Setting $\pp{t_j^b} = 0$ (the baseline) eliminates this trade-off:

| Config | 2nd preimage | Collision | Signing work |
|--------|-------------|-----------|--------------|
| Baseline ($\pp{t_j^b} = 0$) | $2^{138}$ | $2^{88}$ | ${\sim}2^{53.5}$ |
| Config A ($\pp{t_1^b} = 1,\ \pp{t_2^b} = 2$) | $2^{118}$ | $2^{78}$ | ${\sim}2^{47.7}$ |

Config A achieves ample security margins while drastically reducing signing cost.

### Quantum security

**Shor's algorithm only** (discrete logs broken, hash functions unaffected):

QSB's security is **unchanged**.
The scheme uses ECDSA key recovery as a public deterministic map, not as a security assumption.
All security levels remain identical to the classical case:

| Property | Classical | Shor only |
|----------|-----------|-----------|
| Second preimage | $2^{118}$ | $2^{118}$ |
| Collision | $2^{78}$ | $2^{78}$ |

This is the central result: Shor's algorithm provides **zero advantage** to the attacker.

**Shor + Grover** (hash search also sped up quadratically):

Grover's algorithm[^Grov96] provides a quadratic speedup on unstructured search, approximately halving all bit-security levels:

| Property | Classical | Shor + Grover |
|----------|-----------|---------------|
| Pinning cost | $2^{46}$ | ${\sim}2^{23}$ |
| Second preimage | $2^{118}$ | ${\sim}2^{59}$ |
| Collision | $2^{78}$ | ${\sim}2^{52}$ |

{: .info}
Grover's algorithm is far less threatening than Shor's in practice: it cannot be efficiently parallelized ($k$ quantum computers provide only a $\sqrt{k}$ speedup, not $k$) and requires all intermediate computations (hashing, key recovery) to be performed in reversible quantum circuits.
Shor is expected to be practical well before Grover reaches these target difficulties.

## Concrete parameters

The following table summarizes key configurations[^Levy26]:

| Config | $\pp{t_1^s} {+} \pp{t_1^b}$ | $\pp{t_2^s} {+} \pp{t_2^b}$ | Subsets/round | Digest bits | 2nd preimage | Collision | Signing work |
|--------|-----|-----|---------------|-------------|--------|-----------|------------|
| Baseline | $8 {+} 0$ | $8 {+} 0$ | $\binom{150}{8} \approx 2^{42.3}$ | 84.5 | $2^{138}$ | $2^{88}$ | ${\sim}2^{53.5}$ |
| Config A | $8 {+} 1$ | $7 {+} 2$ | $\binom{150}{9} \approx 2^{46.2}$ | 80.4 | $2^{118}$ | $2^{78}$ | ${\sim}2^{47.7}$ |

{: .info}
The **baseline** achieves stronger security but at higher signing cost: $\binom{\pp{150}}{\pp{8}} \approx 2^{42.3} < 2^{46}$, so the subset count falls short of the puzzle target, requiring ${\sim}180$ re-pins.
**Config A** adds bonus selections to bring $\binom{\pp{150}}{\pp{9}} \approx 2^{46.2} \geq 2^{46}$, eliminating re-pinning entirely.
The signing work of ${\sim}2^{47.7}$ hash evaluations corresponds to an estimated \$75--\$200 in GPU compute.

## Public key and signature sizes

**Public key** $\pk$ (per-round data $\times\, \pp{\rho} = 2$ rounds, plus nonce signatures):
 - $\pp{\rho} + 1 = 3$ nonce signatures: $3 \times 9 = 27$ bytes
 - $2\pp{n} = 300$ pool elements: $300 \times 9 = 2{,}700$ bytes
 - $2\pp{n} = 300$ HORS commitments: $300 \times 20 = 6{,}000$ bytes
 - **Total:** ${\sim}8{,}727$ bytes

**Signature** $\sigma$ (Config A):
 - Nonce $\nu$: ${\sim}8$ bytes
 - Subsets $S_1, S_2$: $9 + 9 = 18$ indices, at ${\sim}1$ byte each = ${\sim}18$ bytes
 - HORS preimages: $(\pp{t_1^s} + \pp{t_2^s}) = 15$ preimages $\times$ 20 bytes = 300 bytes
 - **Total:** ${\sim}326$ bytes

---

## References

For cited works, see below 👇👇

[^why-bitcoin-why]: This wastes $M-N$ signature verifications! 😱 Most likely, it was implemented this way due to developer laziness. (Fair.) Otherwise, an $N$-bit bitmap could have been included to indicate which pubkeys to verify against $\Rightarrow$ only $M$ verifications. Since the max $N$ is 20, such a bitmap would be very small too. I suppose, in the worst case, it could make a multisig transaction as expensive to verify as a BLS signature 🤷. Wasteful, but if you build sofware, you know.
[^push-terminology]: There are two types of opcodes in Bitcoin Script: (1) **push opcodes,** whose only job is to place literal data from the script itself onto the stack (e.g., `OP_0`, `OP_1`, ..., `OP_16`, raw byte pushes like _"push the next 33 bytes"_) and (2) **non-push opcodes**, or everything that performs computation -- even if the result gets pushed onto the stack (e.g., `OP_DUP`, `OP_RIPEMD160`, `OP_CHECKSIGVERIFY`)

{% include refs.md %}
