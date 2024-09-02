---
tags:
title: Bulletproofs IPA for multiexp
#date: 2020-11-05 20:45:59
#published: false
sidebar:
    nav: cryptomat
---

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\prove{\mathsf{Prove}}
\def\ver{\mathsf{Ver}}
\def\A{\mathbf{A}}
\def\B{\mathbf{B}}
\def\bb{\mathbf{b}}
$</div>

{: .info}
**tl;dr:** This is a post-mortem write-up on how I failed to use the Bulletproofs IPA to convince a verifier that a multi-exponentiation $\A^\bb = \prod_i (A_i)^{b_i}$ was done correctly.
The problem is that the Bulletproof verifier has to "fold" the $\A$ vector by using **individual** exponentiations, which would be even slower than the verifier naively doing the $\A^\bb$ multiexp.

<!--more-->

## Notation

 - We are assuming a multiplicative group $\Gr$ of order $p$
 - "In the exponent", we will have an associated field $\F$ of the same order $p$.
 - **Bolded**, lower-case symbols such as $\bb=[b_0,\dots,b_{n-1}]\in\F^n$ typically denote vectors of field elements.
 - **Bolded**, UPPPER-case symbols such as $\A = [A_1, \dots, A_m]\in \Gr^m$ typically denote vectors of group elements.
 - $\|\A\|$ denotes the size of a vector $\A$
 - $\A^x = [A_1^x, \dots, A_m^x], \forall x\in \F$
 - $\A^\bb = \prod_{i=1}^m A_i^{b_i},\forall b\in\F^m$
 - $\A \circ \B = [ A_1 B_1, A_2 B_2, \dots, A_m B_m]$
 - $\textbf{A}\_L=[A\_1,\dots,A\_{m/2}]$ and $\textbf{A}\_R=[A\_{m/2+1},\dots, A\_m]$ denote the left and right halves of $\A$

## (Pointless) Bulletproofs IPA for multiexp

The protocol below assumes the size of the vector $\A$ and $\bb$ are both equal to $m = 2^k$ for some integer $k \ge 0$.

<table style="border-collapse: collapse; border: 1px solid grey; table-layout: fixed; width: 455px;">
<tr><td style="border: none;">
  $\underline{\prove(\A, \bb)}$
</td><td style="border: none; text-align: right;">
  $\underline{\ver(V, \A, \bb)\rightarrow \{0,1\}}$
</td></tr>

<tr><td style="border: none; text-align: center;" colspan="2">
  $\rule[2.5pt]{9em}{0.5pt}\fbox{If $m = 1$}\rule[2.5pt]{9em}{0.5pt}$
</td></tr>

<tr><td style="border: none; text-align: center;" colspan="2">
  $\xrightarrow{\mbox{$\A = [A_1], \bb = [b_1]$}}$
</td></tr>

<tr><td style="border: none;"></td><td style="border: none; text-align: right;">
  <b>return</b> 1 iff. $V \equals A_1^{b_1}$
</td></tr>

<tr><td style="border: none; text-align: center;" colspan="2">
  $\rule[2.5pt]{7em}{0.5pt}\fbox{Else (i.e., if $m \ge 2$)}\rule[2.5pt]{7em}{0.5pt}$
</td></tr>

<tr><td style="border: none;">
  $V_L = (\A_R)^{\bb_L}$<br />
  $V_R = (\A_L)^{\bb_R}$
</td><td style="border: none;"></td></tr>

<tr><td style="border: none; text-align: center;" colspan="2">
  $\xrightarrow{\mbox{$V_L, V_R$}}$
</td></tr>

<tr><td style="border: none; text-align: center;" colspan="2">
  $\xleftarrow{\mbox{$x\randget \F$}}$
</td></tr>

<tr><td style="border: none;">
  $\color{red}\A' = \A_L \circ (\A_R)^x$<br />
  $\bb' = \bb_L \circ (\bb_R)^{(x^{-1})}$
</td><td style="border: none;"></td></tr>

<tr><td style="border: none;"></td><td style="border: none; text-align: right;">
  Computes ${\color{red}\A'},\bb'$ just like the prover<br />
  $V' = (V_L)^x \cdot V \cdot (V_R)^{(x^{-1})}$
</td></tr>
</table>

---

{% include refs.md %}
