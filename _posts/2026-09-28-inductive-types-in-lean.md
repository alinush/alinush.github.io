---
type: note
tags:
title: Inductive types in Lean
#date: 2020-11-05 20:45:59
#published: false
permalink: inductive-types
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

Common types in Lean (e.g., `Bool`) are not primitives of the language.
They are declared via one of Lean's main primitives: `inductive` types

## Examples

A boolean type:
```lean
inductive Bool where
  | false
  | true
```

An option type:
```lean
-- (α : Type) is like a template parameter
-- (ignore the "universe" u)
inductive Option (α : Type u) where
  | none
  | some (a : α)
```

[A list type](https://github.com/leanprover/lean4/blob/v4.31.0/src/Init/Prelude.lean#L2957-L2964):
```lean
-- A list is defined as either: 
--  1. the "nil" list, or
--  2. a constructor that works by taking a "head" element α and a so-called
--    "tail" list and concatenates them together.
inductive List (α : Type u) where
  | nil
  | cons (head : α) (tail : List α)
```

An "either, or" type:
```lean
inductive Sum (α β : Type u) where     -- A ⊕ B
  | inl (a : α)
  | inr (b : β)
```

A tuple type:
```lean
structure Prod (α β : Type u) where    -- A × B (a one-constructor inductive)
  fst : α
  snd : β
```

A "unit" type:
```lean
inductive Unit where                   -- (really PUnit, but same idea)
  | unit
```

The "empty" type:
```lean
inductive Empty                        -- ⊥: no constructors, so no values
```

{: .smallnote}
A caveat: a few types, like `Nat` and `String`, get extra special treatment from the compiler and kernel for efficiency, such as machine integers.

## Syntax

The `inductive` syntax is:
```lean
inductive Name (parameters) where
  | constructor₁ (fields...)
  | constructor₂ (fields...)
```

 - Each `|` line is a **constructor**: a way to build a value of the type.
 - A constructor's **fields** are the data you have to supply to use it (to build the type).
 - Every **value** of the type is built by one of the constructors, and nothing else is.

If you know Rust, you can think of this as an `enum`:
```rust
enum List<T>     { Nil, Cons(T, Box<List<T>>) }
enum Sum<A, B>   { Inl(A), Inr(B) }
```

Recall the `List` definition:
```lean
inductive List (α : Type u) where
  | nil
  | cons (head : α) (tail : List α)
```

This definition is recursive, because one of the things the `cons` constructor takes is a smaller `List α`.

So, `[1, 2, 3]` and `1  ::  2  ::  3  ::  []` are shorthand Lean notation for:

```lean
List.cons 1 (List.cons 2 (List.cons 3 List.nil))
```

This notation is ordinary library code too: [`::` is a one-line `infixr` for `List.cons`](https://github.com/leanprover/lean4/blob/v4.31.0/src/Init/Notation.lean#L427), while `[a, b, c]` is [a `syntax` declaration](https://github.com/leanprover/lean4/blob/v4.31.0/src/Init/Data/List/Notation.lean#L35) desugared by [a `macro_rules` block](https://github.com/leanprover/lean4/blob/v4.31.0/src/Init/Data/List/Notation.lean#L50-L62) that folds the elements into nested `List.cons` applications ending in `List.nil`.

Note that each `List` constructor is a function that produces a list:

```lean
List.nil  : List α
List.cons : α → List α → List α
```

`(α : Type u)` is a parameter, the element type.
This is what makes `List Nat` and `List String` to be of different types.
`u` is a universe level[^universes].
Ignore it for now.

## References

For cited works, see below 👇👇

{% include refs.md %}


[^universes]: [The Lean Language Reference: 4.3. Universes](https://lean-lang.org/doc/reference/latest/The-Type-System/Universes/)
