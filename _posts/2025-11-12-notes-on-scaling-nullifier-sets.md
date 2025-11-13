---
tags:
 - Merkle
 - nullifier
 - anonymous payments
title: Notes on scaling nullifier sets
#date: 2020-11-05 20:45:59
#published: false
permalink: nullifiers
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** Trying to organize some thoughts on how to scale nullifier sets.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

## Approach 1: Sharded Herkle trees

High-level:

 - Build depth-256 (or compressed, if possible) [homomorphic Merkle prefix tree](/please-solve#efficient-homomorphic-merkle-herkle-trees) over global nullifier sets (e.g., via SADS[^PSTY13])
 - Shard the tree into **"triangles"** (e.g., a top triangle with $k$ leaves and $k$ other bottom triangles, but can have multiple levels of triangles; in fact can add them dynamically, as the tree "extends downwards")
 - Each triangle is managed by its own **proof-serving node (PSN)**
 - Importantly, when a leaf $i$ changes by $\delta_i$ every PSN can locally update its portion of the path w/o waiting for other nodes or communicating with them $\Rightarrow$ extremely simple sharding
 - Proof serving nodes can be incentivized to serve proofs (see Hyperproofs[^SCPplus22])

## Approach 2: Tachyon

Just some loose notes for now (will go into more depth as I understand later) from a few resources:

 - Sean Bowe's [blog in April 2025](https://seanbowe.com/blog/tachyon-scaling-zcash-oblivious-synchronization/)
 - Sean Bowe's original [tweet announcement](https://x.com/ebfull/status/1907474914162127002)
 - [Replies between me and Wei Dai on Twitter](https://x.com/alinush407/status/1907507290543980818) regarding the interactive payment flow
 - Sean Bowe's notes on [a possible SNARK-friendly accumulator scheme](https://hackmd.io/@dJO3Nbl4RTirkR2uDM6eOA/BJOnrTEj1x) for this
 - Sean Bowe's [notes on Tachyon](https://seanbowe.com/blog/tachyaction-at-a-distance/)
 - [Tweet about my understanding of Tachyon](https://x.com/alinush407/status/1977123515158409616) in Oct. 2025
 - Mike O'Connor's [post](https://forum.aztec.network/t/reducing-nullifier-set-state-growth/155)
 - Mike O'Connor's [clarification](https://x.com/mike_connor/status/1977131650233274749) on how you precompute some nullifiers and then send one to whomever is trying to pay you. 
    + This makes the recursive proof more efficient because, I suppose, you can prove in batch that all of your precomputed nullifiers have not yet been spent: 

Some disadvantages:

 1. it requires out of band communication during payments.
 1. cannot recover funds from seedphrase only; need other dynamic state as well that is not on-chain
 1. no more viewing keys (?)
 1. cannot just give out your address to get paid: you have to give a place for the sender to include the extra info

Quotes from Sean Bowe: 

 > as the wallet state updates to reflect new blocks it will continually maintain a proof of its own correctness. Then, when it's time to spend our funds we will extend our transaction with this proof-carrying data.
 > This effectively attaches evidence that the transaction is valid up until a certain recent point in the history of the blockchain — the position of the anchor.
 > The result is that validators are now only responsible for ensuring that the transaction is correct in the presence of the additional transactions that appeared in the intervening time, which just involves checking that the most recent block(s) do not contain the revealed nullifier. [15] 
 > As a result, almost everything in a block can be permanently pruned by validators and ultimately all users of the system as well. Despite transactions sharing a common state by being indistinguishable from each other, nearly all state contention problems vanish in this new approach.

 > [15] Together with the proof of the wallet's validity, this demonstrates that the nullifier did not appear in another transaction that followed the block that created the note commitment being spent.
 > Notably, this loosens the condition that the nullifier has never been seen before in the history of the blockchain but still manages to prevent double-spending.

Is the key observation that the TXN proves that the note's nullifier did not appear in the nullifier set accumulated so far? 
But how do you construct that proof without the full set?
Ah!
You dont.
You just need the nullifiers created between the note’s creation and the note being spent.
And that’s what the wallet can prove recursively!

## Other approaches

 - Stateless validation: removes the validation state but introduces PSNs and needs [the right approach](#approach-1-sharded-herkle-trees)
 - [Epoch-based nullifiers](https://github.com/0xMiden/miden-vm/discussions/356): freezes old nullifier sets
 - Mutator sets [1](https://neptune.cash/blog/mutator-sets/) and [2](https://www.youtube.com/watch?v=Fjh1PxrgwQo): need to investigate

## References

For cited works, see below 👇👇

{% include refs.md %}
