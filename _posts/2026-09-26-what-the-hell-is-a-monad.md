---
type: note
tags:
 - programming languages
 - formal verification
 - Lean
title: What the hell is a monad?
#date: 2020-11-05 20:45:59
published: false
permalink: monad
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
\def\Type{\mathsf{Type}}
\def\Int{\mathsf{Int}}
\def\Bool{\mathsf{Bool}}
\def\pure{\mathsf{pure}}
\def\bind{\mathsf{bind}}
$</div> <!-- $ -->

Consider a _type constructor_ $M$ that takes a _type argument_ $A$ and produces a new type $M\langle A \rangle$  (e.g., `Option<int>`, `Vec<bool>`, `ProbabilityMassFunction<usize>`).

<!--more-->

{: .todo}
Clarify that an $m \in M\langle A\rangle$ can denote a (plain) value, or it can denote a computation (e.g., for $\mathsf{State}$, $m$ is a function waiting for an initial state).

Now, consider two functions whose return types are constructed this way:
\begin{align}
f &: A \to M\langle B\rangle\\\\\
g &: B \to M\langle C\rangle
\end{align}
Ordinarily, we would compose them as $(g \circ f)(a) \bydef g(f(a))$.
But that is ill-typed here: $f$ hands back an $M\langle B\rangle$, while $g$ wants a $B$.

A **monad** is a type constructor $M$ equipped with an operation that works around this, called **bind**:

$$\term{\bind\langle B, C\rangle} : M\langle B\rangle \times (B \to M\langle C\rangle) \to M\langle C\rangle$$

{: .note}
Think of $\bind$ as a generic function (C++, Rust terminology) that is templated by the $B$ and $C$ types.
We will not include the type arguments when they are irrelevant, or when they are clear from context.

Binding feeds an $M\langle B\rangle$ value into $g$, *in the way $M$'s "meaning" dictates*.
(We make this precise below.)
So, instead of applying $g$ to $f(a)$, we run $f(a)$ and **bind** its result to $g$'s argument:

$$(\term{g \circ_M f})(a) \bydef \bind(f(a), g)$$

$\emph{\circ_M}$ is the **monadic composition** operation we wanted: e.g., $g\circ_M f$, yields a function of type $A \to M\langle C\rangle$.
The **monad laws** simply say that $\circ_M$ behaves just like $\circ$: it is associative and it has an identity.

This brings us to the second operation that a monad must come with, typically denoted by $\pure$, which simply takes a value of type $A$ and "wraps" it into a value of type $M\langle A \rangle$: 

$$\term{\pure\langle A \rangle} : A \to M\langle A\rangle$$

Considering the intuition that monads are used to model effects, then $\pure(a)$ should return the $M\langle A\rangle$ value whose result is just $a$, with no effect.
Like $\bind$, its body depends on $M$.

{: .todo}
Then intuition about "effects" was not established so far.

$\pure$ for $\circ_M$ plays the role that the identity function $\term{\mathrm{id}(a)} \bydef a$ plays for $\circ$:

$$\pure\langle B\rangle \circ_M f = f \qquad\text{and}\qquad f \circ_M \pure\langle A\rangle = f$$

Monadic composition is sometimes referred to as **sequencing**: composing functions whose outputs are wrapped.

For example, let $M = \mathsf{Option}$: a value of type $\mathsf{Option}\langle B\rangle$ is either $\mathsf{Some}(b)$ for some $b \in B$, or $\mathsf{None}$, meaning the computation failed (e.g., Rust's [`Option<T>`](https://doc.rust-lang.org/std/option/)).
Now, let:

 - $f = \mathsf{open} : \mathsf{String} \to \mathsf{Option}\langle \mathsf{File}\rangle$ take a file path and open that file, which can fail (e.g., no such file)
 - $g = \mathsf{decode} : \mathsf{File} \to \mathsf{Option}\langle \mathsf{Picture}\rangle$ read a file and decode it as an image, which can also fail (e.g., not a valid PNG)

We cannot write $\mathsf{decode}(\mathsf{open}(\texttt{path}))$, since $\mathsf{decode}$ wants a $\mathsf{File}$, not an $\mathsf{Option}\langle \mathsf{File}\rangle$.
But we can write:

$$\mathsf{load}(\texttt{path}) \bydef \bind(\mathsf{open}(\texttt{path}), \mathsf{decode})$$

For $\mathsf{Option}$, $\bind$ is implemented to do the obvious thing. Specifically, for the call above:

 - if $\mathsf{open}(\texttt{path}) = \mathsf{Some}(\texttt{file})$, it returns $\mathsf{decode}(\texttt{file})$
 - if $\mathsf{open}(\texttt{path}) = \mathsf{None}$, it returns $\mathsf{None}$, and never calls $\mathsf{decode}$ at all

So $\mathsf{load} = \mathsf{decode} \circ_M \mathsf{open}$, a function of type $\mathsf{String} \to \mathsf{Option}\langle \mathsf{Picture}\rangle$.
(e.g., in C++23, and in Rust, you would write this as `open(path).and_then(decode)`.)

Lastly, for $\mathsf{Option}$, $\pure(a) = \mathsf{Some}(a)$.

## Definition

Let $\Type$ denote the collection of *all* types: e.g., $\Int$, $\Bool$, $\Int \to \Bool$.

A **monad** is a triple $(M, \pure\langle A\rangle, \bind\langle A,B\rangle)$:

- $M : \Type \to \Type$ — for each type $A$, a type $M\langle A\rangle$ of "$M$-computations returning $A$"
- $\pure\langle A\rangle : A \to M\langle A\rangle$ — given $a \in A$, $\pure(a)$ is the $M\langle A\rangle$ value whose result is $a$, with no effect
- $\bind\langle A,B\rangle : M\langle A\rangle \times (A \to M\langle B\rangle) \to M\langle B\rangle$ — given $m \in M\langle A\rangle$ and $f : A \to M\langle B\rangle$, $\bind(m, f)$ passes the result of $m$ to $f$, in the way $M$ dictates

One bit of notation there is standard in PL but not in cryptography.
$M : \Type \to \Type$ says that $M$ is a function **on types**: hand it a type, get back a type.
This is the formal way of writing that $M$ is a generic.

{: .note}
I use angle brackets, $M\langle A\rangle$, as in C++ or Rust notation: `M<A>`.
(Haskell or Lean instead use *juxtaposition*, writing `M A` with nothing but a space.)

Now, the laws, stated using the $\circ_M$ composition from the introduction.
For all $f : A \to M\langle B\rangle$, $g : B \to M\langle C\rangle$ and $h : C \to M\langle D\rangle$:

1. $\pure \circ_M f = f$ (identity)
2. $f \circ_M \pure = f$ (identity)
3. $h \circ_M (g \circ_M f) = (h \circ_M g) \circ_M f$ (associativity)

In other words, $\circ_M$ obeys exactly the laws that ordinary $\circ$ does, with $\pure$ playing the role of the identity function.[^bindlaws]

Now I can say precisely what "*in the way $M$'s meaning dictates*" meant earlier.
Notice what the three laws do **not** say: nothing whatsoever about what $\bind$ actually *does* with the value trapped inside an $M\langle A\rangle$.
They constrain only how compositions fit together.
So the pair $(\pure, \bind)$ is not determined by $M$ — you choose it, and **that choice is the effect being modelled**.
Two different monads can even share the same underlying $M$ and differ only in their $\bind$.

This is why the definition looks so thin: a monad is an interface, and all of the content lives in the implementation.
The two examples below each supply one, and it is worth watching, in each case, what $\bind$ does with a value of type $A$ that it cannot simply hand to $f$.

In Lean 4, `Monad M` gives you `pure` and `bind`; `LawfulMonad M` asserts the three laws.

So, in one sentence: **a monad is what you need for "effectful functions" $A \to M\langle B\rangle$ to compose like ordinary functions.** Nothing more.

## Another example: `State` monad for stateful computations

Sometimes, a computation needs to read and update some **state** as it goes: e.g., a counter of how many operations it has performed so far.
Without monads, every function would have to take the current state as an extra input and return the updated state as an extra output, and every caller would have to remember to pass the updated state along to the next function.
The $\mathsf{State}$ monad helps us do this plumbing better.

Fix a set $\Sigma$ of possible states (e.g., $\Sigma = \N$ for a counter).
Then, the monad $(M, \pure, \bind)$ is defined as follows.

**The type constructor $M$.** For any type $A$,

$$M\langle A\rangle \bydef \Sigma \to A \times \Sigma$$

In words, an $m \in M\langle A\rangle$ is a function which, given the current state $s \in \Sigma$, returns a result $a \in A$ together with an updated state $s' \in \Sigma$.
$M$ takes just the one type argument $A$ and the set of states $\Sigma$ is implicit in $M$.

**The $\pure$ operation.** Given $a \in A$, $\pure(a)$ returns a function of type $\Sigma \to A \times \Sigma$ (i.e., an element of $M\langle A\rangle$), which, on input a state $s$, simply returns $(a, s)$:

$$\pure(a) \bydef \left(s \mapsto (a, s)\right)$$

**The $\bind$ operation.** Given $m \in M\langle A\rangle$ and $f : A \to M\langle B\rangle$, $\bind(m, f) \in M\langle B\rangle$ is the function which, given a state $s$:

1. runs $m$ on $s$, obtaining a result $a$ and an updated state $s'$ (i.e., $(a, s') = m(s)$)
2. computes $f(a) \in M\langle B\rangle$, which is itself a function on states, and runs it on $s'$, obtaining a result $b$ and a final state $s''$ (i.e., $(b, s'') = f(a)(s')$)
3. returns $(b, s'')$

So, $\bind$ takes care of handing the state produced by $m$ to $f(a)$, which is exactly the plumbing we did not want to write by hand.
(The three laws can be checked by unfolding these definitions.)

**An example: handing out unique IDs.** Suppose we are creating users and bank accounts, and every user and every account needs a unique ID.
Let the state $\Sigma = \N$ be the next unused ID.
A user is a name together with its ID, and an account is its owner together with its account number:

$$\mathsf{User} \bydef \mathsf{String} \times \N \qquad\text{and}\qquad \mathsf{Account} \bydef \mathsf{User} \times \N$$

Now, consider:

 - $\mathsf{newUser} : \mathsf{String} \to M\langle \mathsf{User}\rangle$, which creates a user with the next unused ID: $\mathsf{newUser}(\mathit{name}) \bydef \left(s \mapsto ((\mathit{name}, s),\ s + 1)\right)$
 - $\mathsf{newAccount} : \mathsf{User} \to M\langle \mathsf{Account}\rangle$, which opens an account for a user, with the next unused ID as its number: $\mathsf{newAccount}(u) \bydef \left(s \mapsto ((u, s),\ s + 1)\right)$

Unfolding the definition of $\bind$, their composition is:

$$(\mathsf{newAccount} \circ_M \mathsf{newUser})(\mathit{name}) = \left(s \mapsto (((\mathit{name}, s),\ s + 1),\ s + 2)\right)$$

In words: starting from next unused ID $s$, the user gets ID $s$, their account gets number $s + 1$, and the next unused ID is now $s + 2$.
The two IDs are guaranteed to be distinct, even though neither function knows about the other, and nobody had to pass the counter along by hand.

## Another example: Monads for logging

Wikipedia gives a [nice example](https://en.wikipedia.org/wiki/Monad_(functional_programming)#Program_logging) of how to use monads to implementing error logging more easily.

[^bindlaws]: The same three laws, written in terms of $\bind$ instead of $\circ_M$, are the form you will find in Lean's `LawfulMonad` and in most PL texts: $\forall a \in A$ and $m \in M\langle A\rangle$, we have: $\bind(\pure(a), f) = f(a)$, and $\bind(m, \pure) = m$, and $\bind(\bind(m, f), g) = \bind(m, g \circ_M f)$. All three laws are needed: none of them follows from the other two.

## References

For cited works, and other relevant but uncited ones[^OGS08], see below 👇👇

{% include refs.md %}
