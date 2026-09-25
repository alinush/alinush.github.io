---
type: note
tags:
 - universal composability (UC)
title: Universal composability (UC)
#date: 2020-11-05 20:45:59
#published: false
permalink: uc
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** I wish there was better stuff around than UC for modelling security of cryptosystems. 

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\sid{\mathsf{sid}}
\def\F{\mathcal{F}}
\def\Fsig{\F_\mathsf{SIG}}
\def\Sim{\mathcal{S}}
$</div> <!-- $ -->

## Terminology

To wrap your head around the UC framework, there are several concepts you must understand: 

 - ideal functionality $\F$
    + a specification for what a cryptographic protocol should (not) do
 - protocol $\pi$
    + an concrete implementation of an ideal functionality
 - real-world adversary $\Adv$
 - ideal-world adversary $=$ simulator $\Sim$
 - environment
 - interactive Turing machine (ITM)
 - interactive Turing machine instance (ITI)
 - emulation/simulation
 - session
 - session ID $\sid$
    + each copy of an 
 - $\F$-hybrid model
    + when a protocol $\pi$ (concrete) has ideal access to an unbounded number of _copies_ of an ideal functionality $\F$ 
 - composition theorem

## Links

 - [Andrew Miller's course](https://decentralize.ece.illinois.edu/ece-cs-598-am-cryptography-with-ideal-functionalities/)
     + [List of papers that introduce UC functionalities](/files/all-uc-papers.pdf), from a Google Doc in this course
        + For future reference, equivalent AI-generated [list for game-based proofs](/files/all-game-based-papers.pdf)
 - [UC hackathon](https://www.bu.edu/macs/workshops/uc-hackathon/)
 - [6.897 MIT course, Spring '04](https://courses.csail.mit.edu/6.897/spring04/materials.html)


## Historical papers

 - first UC paper[^Canetti00]
 - "simpler" UC for MPC[^CCL14e]
 - "simpler" iUC paper[^CKKR19e]: still [not very simplified](https://x.com/alinush/status/2098805745533809030), IMO.
 - A very formally worked-out example of a UC proof for PAKE[^Xu25e]
 - EasyUC paper[^CSV19e]: UC proofs in EasyCrypt
 - IPDL paper[^MSSplus21e]: also mechanizes UC proofs, AFAICT

## Negatives

 - The initial UC ideal functionality for a digital signature $\Fsig$[^Canetti00], which should be simple, had to be redefined several times due to subtle issues
    + $\Fsig$ could not be shared/reused[^CR03e], such as when a player reuses the same signing keys across multiple authenticated key exchange sessions.
    + $\Fsig$ could not actually be realized in UC[^BH03e].
    + $\Fsig$ allowed the same $(m,\sigma,\pk)$ tuple to pass verification today but fail tomorrow, for some $\pk$'s: a non-deterministic verification / repudiation issue[^Cane03e]
    + [^BMT18e]
 - UC ideal functionalities are easy to get wrong $\Rightarrow$ should still formalize game-based security properties for them and prove them[^ACGplus25e]
    + Same could be said about non-UC ones too, arguably.
 - The composability you get is not always the composability you want: e.g., cannot compose $$\mathcal{F}_\mathsf{ZK}$$ with $$\mathcal{F}_\mathsf{Sig}$$ to get a ZKPoK of a signature for anonymous credentials, say[^CDT19e].
 - UC functionalities are not stable, nor often reused in practice: papers frequently redefine them[^GKZ08e].

## Appendix: Universal composition with joint state (JUC, or "juicy")

The problem:

 > All known composition theorems [..] assume that, at least as far as the honest parties are concerned, the local state of each one of the composed protocol instances is disjoint from the local states of all the other protocol instances run by the party.

**Q:** What counts as **state** here?

Canetti and Rabin add support for functionalities with **joint-state**[^CR03e]. e.g.,:
 - many users running many instances of a key-exchange protocol, exchanging keys with multiple other users, but using the same PKI functionality
 - secure communication protocols, where multiple protocol instances use the same instance of a public-key signature or encryption scheme
 
(In general, concurrent executions of the same ideal functionality that reuses a PKI or a CRS functionality.)

A diagram from the paper (think of $\rho$ as the CRS sub-protocol or the PKI sub-protocol):

![Universal composition with joint state: many independent copies of rho versus a single joint copy rho-hat](/pictures/juc-joint-state.png){: .align-center}

Their paper also gives a nice summary of what UC is, with more details in the appendix:

> In order to allow proving the universal composition theorem, the notion of emulation [..] is considerably stronger than previous ones.
> Traditionally, the model of computation includes the parties running the protocol and an adversary, $$\mathcal{A}$$, that controls the communication channels and potentially corrupts parties.
> "Emulating an ideal process" means that for any adversary $$\mathcal{A}$$ there should exist an "ideal process adversary" (or, simulator) $$\mathcal{S}$$ that causes the *outputs* of the parties in the ideal process to have similar distribution to the outputs of the parties in an execution of the protocol.
> In the UC framework the requirement on $$\mathcal{S}$$ is more stringent.
> Specifically, an additional entity, called the **environment** $$\mathcal{Z}$$, is introduced.
> The environment generates the inputs to all parties, reads all outputs, and in addition interacts with the adversary in an arbitrary way throughout the computation.
> A protocol is said to **securely realize** a given ideal functionality $$\mathcal{F}$$ if for any "real-life" adversary $$\mathcal{A}$$ that interacts with the protocol and the environment there exists an "ideal-process adversary" $$\mathcal{S}$$, such that *no environment* $$\mathcal{Z}$$ can tell whether it is interacting with $$\mathcal{A}$$ and parties running the protocol, or with $$\mathcal{S}$$ and parties that interact with $$\mathcal{F}$$ in the ideal process.
> In a sense, here $$\mathcal{Z}$$ serves as an "interactive distinguisher" between a run of the protocol and the ideal process with access to $$\mathcal{F}$$.


## References

For cited works, see below 👇👇

{% include refs.md %}
