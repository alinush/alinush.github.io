---
tags: 
 - number theory
title: Linear Diophantine equations
#published: false
sidebar:
    nav: cryptomat
---

Equations of the form $\sum_i a_i x_i = 0$ where the $x_i$'s are _integer_ unknowns are called **linear Diophantine equations.**
Their integer solutions can be computed using greatest common denominator (GCD) tricks.
In this post, we go over a few basic types of such equations and their integer solutions.
<!--more-->

<p hidden>$$
\def\lcm{\ \text{lcm}}
$$</p>

## $ax+by = t$

<details>
<summary><b>Theorem:</b> This equation has an integer solution $\Leftrightarrow \gcd(a,b) \mathrel\vert t$.
</summary>
<p markdown="1" style="margin-left: .3em; border-left: .15em solid black; padding-left: .5em;">
_Proof_ ("$\Rightarrow$"): Assume an integer solution $(x_0, y_0)$ exists when $\gcd(a,b) \nmid t$.
Since $\gcd(a,b)$ divides both $a$ and $b$, it divides any linear combination of them, including $ax_0 + by_0 = t$, which implies it divides $t$.
Contradiction.
<br /><br />

_Proof_ ("$\Rightarrow$"):
If $\gcd(a,b) = 1$, then an integer solution $x_0,y_0$ can be obtained using the Extended Eucliden algorithm, which finds $(u,v)$ such that $au + bv = \gcd(a,b)$.
The solution is:
\begin{align}
    x_0 &= u\cdot t / \gcd(a,b)\\\\\
    y_0 &= v\cdot t / \gcd(a,b)
\end{align}
This is because $ax_0 + ay_0 = (au + bv) \frac{t}{\gcd(a,b)} = \gcd(a,b) \frac{t}{\gcd(a,b)} = t$.
</p>
</details>

<details>
<summary><b>Theorem:</b> When $\gcd(a,b) \mathrel\vert t$, if $(x_0, y_0)$ is an integer solution to such an equation, then all integer solutions can be characterized as:
\begin{align}
    x &= x_0 - k b/\gcd(a,b)\\\
    y &= y_0 + k a/\gcd(a,b)
\end{align}
Here, $k$ is an arbitrary integer and either $a\ne 0$ or $b\ne 0$ (since otherwise $\gcd(a,b) = 0$ and $\gcd(a,b)\mathrel\vert t$ implies $t=0$, which means all integers $(x,y)$ are solutions).
</summary>
<p markdown="1" style="margin-left: .3em; border-left: .15em solid black; padding-left: .5em;">
_Proof:_ First, one can easily verify that the proposed $(x,y)$ are indeed solutions that satisfy $ax+by=t$:
\begin{align}
    ax + by &= ax_0 + kab / \gcd(a,b) + by_0 - kab/gcd(a,b)\\\
            &= ax_0 + by_0 = t
\end{align}

The more difficult part is to argue that every solution has this form!
Assume $a\ne 0$ since the other $b\ne 0$ case is symmetric.
Assume $(x,y)$ to be an integer solution and note that, since $(x_0, y_0)$ is a solution, this means:
\begin{align}
    a(x-x_0) + b(y - y_0) &= 0\Leftrightarrow\\\
    a(x - x_0) &= b(y_0 - y)\Leftrightarrow\\\
    \frac{a}{\gcd(a,b)}(x-x_0) &= \frac{b}{\gcd(a,b)} (y_0 - y)
\end{align}
This implies $\frac{a}{\gcd(a,b)} \mathrel\vert \frac{b}{\gcd(a,b)} (y - y_0)$.
Since $\gcd(\frac{a}{\gcd(a,b)}, \frac{b}{\gcd(a,b)}) = 1$[^Heff03], this means $\frac{a}{gcd(a,b)} \mathrel\vert (y-y_0)$, which means $\exists k$ such that:
\begin{align}
    a/\gcd(a,b) \cdot k &= (y-y_0)\Leftrightarrow\\\
    y &= y_0 + k a / \gcd(a,b)
\end{align}
Next, substitute $y$ in $a(x-x_0) = b(y_0 - y)$, to get:
\begin{align}
    a(x-x_0) &= b(y_0 - y_0 - k a / \gcd(a,b))\Leftrightarrow\\\
    x - x_0 &=  (- b k a / \gcd(a,b)) / a\\\
      &= x_0 - k b / \gcd(a,b)
\end{align}
Note that since $a\ne 0$, we are allowed to divide by $a$ above.
</p>
</details>

### $ax+by = 0$

In this case, since $x_0 = 0$ and $y_0 = 0$ is one integer solution, all integer solutions are of the form:
\begin{align}
    x &= -kb/\gcd(a,b)\\\\\
    y &= ka/\gcd(a,b)
\end{align}

## $ax+by+cz = t$

<details>
<summary><b>Theorem:</b> This equation has an integer solution $\Leftrightarrow \gcd(a,b,c) \mathrel\vert t$.
</summary>
<p markdown="1" style="margin-left: .3em; border-left: .15em solid black; padding-left: .5em;">
_Proof_ ("$\Rightarrow$"):
Proceeds analogously to the $ax+by = t$ case [before](#axby--t).
<br /><br />

_Proof_ ("$\Leftarrow$"): 
We will generalize the proof from the $ax+by = t$ case [before](#axby--t).
<br /><br />

$\gcd(a,b,c) \mathrel\vert t \Rightarrow \gcd(a, \gcd(b, c)) \mathrel\vert t \Rightarrow ax + \gcd(b,c)w = t$ has an integer solution $(x_0, w_0)$.
<br /><br />

Let $\gcd(b,c) = d$.
We know $\exists (y_0, z_0)$ such that:
\begin{align}
b y_0 + c z_0 = d
\end{align}
Replacing in the previous equation, we have:
\begin{align}
    ax_0 + \gcd(b,c)w_0 &= t\Leftrightarrow\\\
    ax_0 + dw_0 &= t\Leftrightarrow\\\
    ax_0 + (b y_0 + c z_0) w_0 &= t\Leftrightarrow\\\
    ax_0 + b w_0 y_0 + c w_0 z_0 &= t
\end{align}
Thus, an integer solution is $(x_0, y_0 w_0, z_0 w_0)$.
</p>
</details>

**Theorem** _(from Sec 6.2 in [^Cohe07])_: In this case, if $(x_0, y_0, z_0)$ is one integer solution, then all integer solutions are of the form:
\begin{align}
    x &= x_0 + m b / \gcd(a,b) - \ell c / \gcd(a,c)\\\\\
    y &= y_0 + k c / \gcd(b,c) - m a / \gcd(a, b)\\\\\
    z &= z_0 + \ell a / \gcd(a, c) - k b / \gcd(b, c)
\end{align}
Here, $m,\ell,k$ are integers and at least one of $a,b$ or $c$ are $\ne 0$.

<!--
_Proof:_ It is easy to check that proposed integers $x,y,z$ are indeed valid solutions.

The more difficult part is to argue that every $(x,y,z)$ solution has this form!
Assume $a\ne 0$ since the other $b\ne 0$ case is symmetric.
Assume $(x,y,z)$ to be an integer solution and note that, since $(x_0, y_0, z_0)$ is a solution, this means:
\begin{align}
    a(x-x_0) + b(y - y_0) + c(z-z_0) &= 0\Leftrightarrow\\\\\
    a(x - x_0) &= b(y_0 - y) + c(z_0 - z)\Leftrightarrow\\\\\
\end{align}
**TODO: continue**
-->

### $ax+by+cz = 0$

In this case, all integer solutions are of the form:
\begin{align}
    x &= m b / \gcd(a,b) - \ell c / \gcd(a,c)\\\\\
    y &= k c / \gcd(b,c) - m a / \gcd(a, b)\\\\\
    z &= \ell a / \gcd(a, c) - k b / \gcd(b, c)
\end{align}
Here, $m,\ell,k$ are arbitrary integers.

<!-- TODO: proof 
    See page 10 here: https://people.math.sc.edu/howard/Classes/580f/hw5.pdf
    See https://math.stackexchange.com/questions/3325185/find-all-the-integral-solutions-to-the-equation-323x391y437z-10473/3327153#3327153
-->

This could also be simplified in terms of the _lowest common multiple (LCM)_, since $a b = \gcd(a,b) \lcm(a,b)\Rightarrow b / \gcd(a,b) = \lcm(a,b) / a$:
\begin{align}
    x &= m \lcm(a,b) / a - \ell \lcm(a,c) / a = \frac{m\lcm(a,b) - \ell\lcm(a,c)}{a}\\\\\
    y &= k \lcm(b,c) / b - m \lcm(a, b) / b = \frac{k\lcm(b,c) - m\lcm(a,b)}{b}\\\\\
    z &= \ell \lcm(a, c) / c - k \lcm(b, c) / c = \frac{\ell\lcm(a,c) - k\lcm(b,c)}{c}
\end{align}


#### An example

In a [Catalano-Fiore vector commitment](/catalano-fiore) (VC)[^CF13e] of size $n=3$, collision resistance is implied by the fact that the following equation with $(\ell+1)$-bit primes $e_1,e_2,e_3$ does not have any $\ell$-bit integer solutions:

$$e_2 e_3 v_1 + e_1 e_3 v_2 + e_1 e_2 v_3 = 0$$

The only integer solutions given by the formula above are at least $\ell+1$ bit wide:
\begin{align}
    %x &= \frac{m   \lcm(e_2 e_3, e_1 e_3) - \ell\lcm(e_2 e_3, e_1 e_2)}{e_2 e_3}\\\\\
    %  &= \frac{m   e_1 e_2 e_3 - \ell e_1 e_2 e_3}{e_2 e_3} = (m-\ell)e_1\\\\\
    x &= m (e_1 e_3) / \gcd(e_2 e_3, e_1 e_3) - \ell (e_1 e_2) / \gcd(e_2 e_3, e_1 e_2) =\\\\\
      &= m (e_1 e_3) / e_3 - \ell (e_1 e_2) / e_2 = m' e_1\ (\text{where}\ m'=m-\ell)\\\\\
    y &= k' e_2\\\\\
    z &= \ell' e_3
\end{align}

## $\sum_{i\in[n]} a_i x_i = t$

**Theorem:** This equation has an integer solution $\Leftrightarrow \gcd(a_1, \dots, a_n) \mathrel\vert t$.

_Proof:_ The "$\Rightarrow$" direction proceeds as [before](#axbycz--t).

The "$\Leftarrow$" direction proceeds by induction.
The statement $P(n)$ being proved by induction is:

$$\forall a_i\in \mathbb{Z}, \gcd(a_1, \dots, a_n) \mathrel\vert t\Rightarrow \sum_{i\in[n]} a_i x_i = t\ \text{has an integer solution.}$$

We prove $P(n)$ is true for all $n \ge 2$.
First, $P(2)$ is clearly true as we've shown [before](#axby--t).
Second, we must show $P(n) \Rightarrow P(n + 1)$.
This we do analogously to the proof for $n=3$ from [before](#axbycz--t).
Let $d = \gcd(a_1, \dots, a_n)$.
We know that $\gcd(a_1, \dots, a_{n+1}) = \gcd(d, a_{n+1})$.
Since $d \mathrel| t$ (because $P(n)$ is true), this implies $\exists$ integers $s_0, w_0$ such that:
\begin{align}
    d s_0 + a_{n+1} w_0 = t \Leftrightarrow
\end{align}

Since $P(n)$ is true, we know there exist integers $s_1,\dots, s_n$ such that:
\begin{align}
    \sum_{i\in[n]} a_i s_i = d
\end{align}

Replacing $d$ in the previous equation, we get:
\begin{align}
    d s_0 + a_{n+1} w_0 &= t \Leftrightarrow\\\\\
    \left(\sum_{i\in[n]} a_i s_i\right) s_0 + a_{n+1} w_0 &= t
\end{align}
Thus, a solution can be found by setting $x_i = s_0 s_i,\forall i\in[n]$ and $x_{n+1} = w_0$.

[^Cohe07]: **Number Theory: Volume I: Tools and Diophantine Equations**, by Cohen, H., 2007, [[URL]](https://books.google.com/books?id=8zC8VPQV8psC)
[^CF13e]: **Vector Commitments and their Applications**, by Dario Catalano and Dario Fiore, *in Cryptology ePrint Archive, Report 2011/495*, 2011, [[URL]](https://eprint.iacr.org/2011/495)
[^Heff03]: **Elementary Number Theory**, by Jim Hefferson and W. Edwin Clark, 2004, [[URL]](http://joshua.smcvt.edu/numbertheory/book.pdf)
