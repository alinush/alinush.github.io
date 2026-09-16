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
$</div> <!-- $ -->

## Links

 - [Andrew Miller's course](https://decentralize.ece.illinois.edu/ece-cs-598-am-cryptography-with-ideal-functionalities/)
     + [List of papers that introduce UC functionalities](/files/all-uc-papers.pdf), from a Google Doc in this course
        + For future reference, equivalent AI-generated [list for game-based proofs](/files/all-game-based-papers.pdf)
 - [UC hackathon](https://www.bu.edu/macs/workshops/uc-hackathon/)
 - [6.897 MIT course, Spring '04](https://courses.csail.mit.edu/6.897/spring04/materials.html)

## Papers

### Historical

 - first UC paper[^Canetti00]
 - "simpler" UC for MPC[^CCL14e]
 - "simpler" iUC paper[^CKKR19e]: still [not very simplified](https://x.com/alinush/status/2098805745533809030), IMO.
 - A very formally worked-out example of a UC proof for PAKE[^Xu25e]
 - EasyUC paper[^CSV19e]: UC proofs in EasyCrypt
 - IPDL paper[^MSSplus21e]: also mechanizes UC proofs, AFAICT

### Negative results

 - UC is not as modular as one may want: e.g., cannot compose $$\mathcal{F}_\mathsf{ZK}$$ with $$\mathcal{F}_\mathsf{Sig}$$ to get a ZKPoK of a signature for anonymous credentials, say[^CDT19e].
 - Also, it seems like UC functionalities are not really reused in practice: most papers redefine them (citation needed)

## References

For cited works, see below 👇👇

{% include refs.md %}
