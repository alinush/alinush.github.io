---
tags:
 - basics
 - math
title: Basics of linear algebra
#date: 2020-11-05 20:45:59
#published: false
permalink: linear-algebra
sidebar:
    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

{: .info}
**tl;dr:** We cover a few basic linear algebra concepts: vectors, matrices, matrix-vector products, vector dot products, Haddamard products, etc.

<!--more-->

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

We typically assume all vector and matrix elements are from a finite field $\F$, but these definitions can be generalized.
(For example, in [this blogpost](/feist-khovratovich), we multiply a matrix made of field elements with a vector made up of indeterminate variables $X^0, X, X^2, \ldots, X^m$.)

## Row vectors vs. column vectors

A size-$m$ **row vector** $\vec{x}$ is denoted by:
\begin{align}
\vec{x} \in \F^{1\times m} 
 &\bydef (x\_i)\_{i\in[m]} = [x_1, x_2, \ldots, x_m]
\end{align}
A size-$n$ **column vector** $\vec{x}$ is denoted by:
\begin{align}
\vec{x} \in \F^{n\times 1} 
 &\bydef \begin{bmatrix} x_1\\\\\ x_2\\\\\ \vdots\\\\\ x_n\end{bmatrix} 
  \bydef [x_1, x_2, \ldots, x_n]^\top
  = (x\_i)\_{i\in[n]}^\top
\end{align}

**Notes:**
 - We most often work with column vectors. Thus, for simplicity, we let $\F^n \bydef \F^{n\times 1}$.
 - We use the **transpose operator** $\top$ to convert a row vector to a column vector (and viceversa).
    + i.e., $(\vec{x}^\top)^\top = \vec{x}$

## Dot products of vectors

Given two vectors $\vec{x}, \vec{y}$ both of size $m$, their **dot product** is defined as:

$$\vec{x}\cdot\vec{y} \bydef \sum_{i\in[m]} x_i y_i\in \F$$

We only use this definition of (dot) product whenever:
 - both vectors are row
 - both vectors are column
 - $\vec{x}$ is row and $\vec{y}$ is column

In contrast, when $\vec{x}\in\F^n$ (i.e., a column vector) and $\vec{y}\in\F^{1\times n}$ (i.e., a row vector), $\vec{x}\cdot\vec{y}$ yields an **outer product** or **tensor product** in $\F^{n\times n}$.
(We may talk about this in a later version of this blog.)

## Matrices

An $n$-row by $m$-column **matrix** $\mat{A}$ is denoted by:

\begin{align}
\mat{A} \in \F^{n\times m} &\bydef (A\_{i,j})\_{i\in[n],j\in[m]} = 
\begin{bmatrix}
A_{1,1} & A_{1,2} & \ldots & A_{1,m}\\\\\
A_{2,1} & A_{2,2} & \ldots & A_{2,m}\\\\\
\vdots & \vdots & \ddots & \vdots \\\\\
A_{n,1} & A_{n,2} & \ldots & A_{n,m}
\end{bmatrix}
\end{align}
 
We often use $\mat{A}_i$ as convenient notation for the $i$th row of the matrix $\mat{A}$.
So:
\begin{align}
\mat{A} = (\mat{A}\_i)\_{i\in[n]},\ \text{where}\ \mat{A}\_i \in \F^{1\times m}
\end{align}

## Matrix-vector multiplication

We can multiply a matrix $\mat{A}\in \F^{n\times m}$ by a size-$m$ column vector $\vec{x}\in\F^m$ as follows:
\begin{align}
\mat{A}\vec{x} = 
\begin{bmatrix}
A_{1,1} & A_{1,2} & \ldots & A_{1,m}\\\\\
A_{2,1} & A_{2,2} & \ldots & A_{2,m}\\\\\
\vdots & \vdots & \ddots & \vdots \\\\\
A_{n,1} & A_{n,2} & \ldots & A_{n,m}
\end{bmatrix}
\begin{bmatrix} x_1\\\\\ x_2\\\\\ \vdots\\\\\ x_m\end{bmatrix} 
\bydef
\begin{bmatrix}
A_{1,1}x_1 + A_{1,2}x_2 + \ldots + A_{1,m}x_m\\\\\
A_{2,1}x_1 + A_{2,2}x_2 + \ldots + A_{2,m}x_m\\\\\
\vdots\\\\\
A_{n,1}x_1 + A_{n,2}x_2 + \ldots + A_{n,m}x_m\\\\\
\end{bmatrix} 
\bydef
\begin{bmatrix}
\vec{a}_1 \cdot \vec{x}\\\\\
\vec{a}_2 \cdot \vec{x}\\\\\
\vdots\\\\\
\vec{a}_n \cdot \vec{x}\\\\\
\end{bmatrix} 
\end{align}
 
## Hadamard products

The Hadamard product of two size-$n$ column vectors $\vec{x},\vec{y}$ is defined as:
\begin{align}
\vec{x}\circ\vec{y} \bydef \begin{bmatrix}
x_1 y_1\\\\\
x_2 y_2\\\\\
\vdots\\\\\
x_n y_n
\end{bmatrix}
\end{align}

---

{% include refs.md %}
