---
tags:
 - zero-knowledge proofs (ZKPs)
title: Deploying zero-knowledge proofs with training wheels
#date: 2020-11-05 20:45:59
#published: false
permalink: training-wheels
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** 
ZK relations are hard to implement.
Implement them twice: once in a ZK DSL and once in a sane language.
Enshrine a mandatory prover service that checks the sane implementation before creating a ZKP.
This way, bugs in the ZK DSL implementation cannot be exploited as long as the prover service is honest.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\R{\mathbf{M}}
$</div> <!-- $ -->

{% include defs-zkp.md %}

A [zero-knowledge proof (ZKP)](/zkps) proves knowledge of $\mathbf{w}$ s.t. $R(\mathbf{x}; \mathbf{w}) = 1$ without leaking any info about $\mathbf{w}$. 

If you deploy such a system, you need to implement the relation $R$ in some domain-specific language (DSL) like [circom](/circom).

For example, maybe $R$ checks that $\mathbf{w}$ contains a valid signature over some of the values in $\mathbf{x}$ and under the PK in $\mathbf{x}$.
Most likely though, your implementation will be buggy and may actually implement a _different_ relation $\mathbf{M}' \ne R$ instead.

Depending on how wrong you get it, attackers could very easily find a witness $\mathbf{w}$ s.t. $\mathbf{M}'(\mathbf{x}; \mathbf{w}) = 1$ for a verifier-controlled $\mathbf{x}$.

For example, maybe you actually (mis)implemented an $\mathbf{R}'$ that $\mathbf{w}$ contains a valid signature over some of the values in $\mathbf{x}$ but under **any** PK.
Sadly, from the point-of-view of the verifier $\mathbf{M}'= R$ because your ZK DSL implementation is the ground truth (and you got it wrong!).

So now you are in big trouble: an attacker can pretend to have a signature over the verifier-enforced PK in $\mathbf{x}$ because the implemented relation $\mathbf{M}'$ does not actually enforce that PK.

Training wheels (a.k.a., safety wheels) are a mitigation against this class of implementation bugs.

## Training wheels or safety wheels 

Recall that a [ZKP](/zkps) protocol is designed to prove knowlege of a witness $\witn$, such that $R(\stmt; \witn)= 1$, for some interesting relation $R$ in some application setting.

{: .note}
For example, for [Aptos Keyless accounts](/keyless), the relation $R$ is described in some detail [here](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-61.md#the-keyless-zk-relation-mathcalr).

But this relation $R$ can be rather complex and has to be implemented in a ZK DSL like [circom](/circom).

_In theory_, there is no problem: $R$ is implemented correctly; we are done.

**In practice**, we likely implemented a different relation $\R \ne R$.
We call this $\R$ the **misimplemented relation.**
Importantly, from the perspective of the verifier, who considers the ZK DSL implementation to be the ground truth, a ZKP for $\R$ is a ZKP for $R$.
As a (disastrous) result, a prover might be able to manfacture a $\witn$ s.t. $\R(\stmt; \witn) = 1$ effectively convincing the verifier that $\stmt \in R$ even though $\stmt\notin R$.

This matters because the stakes in ZK-based systems can be very high. For example:

 - If your relation $R$ was supposed to implement a validity rollup, then money could be stolen or minted out of thin air.
 - If your relation $R$ was supposed to implement an anonymous payment, same problem.
 - If your relation $R$ was supposed to secure a blockchain account (e.g., [keyless](/keyless), zkLogin[^BCJplus24], [zkEmail](https://github.com/zkemail)), then user funds could be stolen.

{: .note}
Even if using more developer-friendly ZK DSLs like Noir, I would predict that lots of manually-optimized circuits will still be written by ambitious devs trying to optimize performance.
So the point still stands: ZK DSL code is tricky to get right (because desires for efficiency tempt us into sin, lol).

So, the **key question** for us, as practitioners, becomes: 

<div align="center">
What can <b>we</b> do, <b>in practice</b>, to <em>mitigate</em> against such ZK DSL implementation bugs?
</div>

_One answer_ is to make the ZK DSL code that implements your relation private, as opposed to public.
This will prevent hackers from finding bugs.
But if the arithmetization of your relation is still available (e.g., the compiled [R1CS](/r1cs)), attacks may still be possible via reverse engineering.
(For example, not sure if some kind of SMT solver over finite fields could be used to exploit bugs in the wild.)

**A better answer**, I think, is to rely on **training wheels** (or safety wheels)[^tw-keyless].
Specifically:

 1. We <b>re</b>-implement the intended relation $R$ in a safer language like Rust
    + We call this the **sane implementation** of $R$
 1. We introduce a **prover service** that operates as follows
 1. Before creating a proof for $\stmt$, this service checks $R(\stmt; \witn) = 1$ **but via its sane Rust implementation**
 1. Only if the relation holds, the prover service computes the ZK proof
    - This prevents an adversary from exploiting us with a malicious $\stmt \notin R$ that passes the misimplemented relation (i.e., $\stmt \in \R$) because such a pair will not pass the Rust implementation check
 1. Finally, the service digitally-signs the ZK proof.
    + This allows verifies to enforce proving is done only through this service

This kind of digital signature is called a **training wheels signature**.

It serves to convices verifiers that the prover service has checked $\stmt \in R$ and therefore the ZKP $\pi$ computed for it could not have been maliciously produced for an $\stmt \in \R$ but $\stmt \notin R$. 
This effectively mitigates against ZK DSL implementation bugs **as long as the prover service is honest, of course.**

{: .error}
Of course, there is a big caveat: the prover service **must** be used to compute a proof.
This means, if the prover service is offline, the ZK-based service may not work anymore.
For some applications, like validity rollups, this is very bad.
Furthermore, it means the prover service learns the secret witness $\witn$.
In some applications, like anonymous payments, this is unnacceptable as it defeats the point of the ZKP.
This challenge can be addressed via [MPC proving services](#mpc-proving-services).

## MPC proving services

These days, there are MPC proving services that can help you compute your proof for $R(\stmt; \witn)$ without even learning $\witn$.
Typically, the _client_, who wants a proof computed, secret-shares its witness $\witn$ amongst the MPC nodes who compute the proof in an MPC fashion.

Unfortunately, this does not mesh well with the training wheels protection described above.
Why?
Since the prover service is now an MPC, we need our sane implementation of $R$ to work in an MPC.
(If it did not, then the MPC nodes would learn $\witn$ which defeats the point of an MPC.)
But MPC implementations of $R$ are as hard to do (efficiently) as our ZK DSL implementation of $R$.

Specifically, $R$ would have to be implemented (once again) as a circuit, so that it can be checked “in MPC.”
This would be no easier than our original task of implementing $R$ and not ending up with an implementation $\R \ne R$.

{: .note}
I suppose with some MPC libraries out there, you can implement your MPC functionality $f$ in, say, Python and it gets “compiled” down to a circuit / VM / \<something\>.
But the efficiency of this and the complexity of such a Python compiler are unclear to me.

## Conclusion

We need training wheels.
But we need privacy of the witness took.
$\Rightarrow$ zkSNARK MPC proving services should support training wheels protection (somehow)?
Or, proving services should be run in trusted execution environments (TEEs).

## References

For cited works, see below 👇👇

{% include refs.md %}

[^tw-keyless]: More info on training wheels for [Aptos Keyless accounts](/keyless) can be found [here](https://github.com/aptos-foundation/AIPs/blob/main/aips/aip-61.md#training-wheels).
