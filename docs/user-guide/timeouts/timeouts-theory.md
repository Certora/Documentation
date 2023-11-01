Timeouts in Certora Prover - Theoretical Background
====================================================

In this section, we will discuss some background of timeouts happening in the
Certora Prover. We try to answer questions like "Why do you build a tool that
times out?" and "Will there be an automatic program verifier that never times
out?". For more practical advice on timeout prevention, please consult the other
parts of our documentation on [managing timeouts](index.md).

## Complexity of the SMT problem

Certora Prover is roughly similar in architecture to a compiler. However,
instead of executables, Certora Prover outputs SMT formulas. These formulas are
then sent to an SMT solver, and the result is translated back to a
counterexample call trace, or a "Not Violated" result.

All SMT solvers share a general architecture. At the center of an SMT solver,
there is a SAT solver. The SAT solver operates on a Boolean abstraction of the
input formula, and communicates with theory solvers to refine the abstraction
according to the theories used by the formula. The problem of solving
propositional formulas (aka SAT) is famously NP-complete. In practice this means
that there are classes of propositional formulas for which all known SAT solvers
show exponential run-time behavior. Exponential running time is usually equated
with intractability ("we have an algorithm, but it's impractical because it runs
too long"). Most of the theories involved are at least NP-complete, already in
their conjunctive fragments (which SMT theory solvers use). Nonlinear integer
arithmetic stands out in that it is undecidable.


## Usefulness of worst-case intractable problems

When seeing the complexity results of the previous section, it is easy to give
up on the problems of SAT and SMT. Indeed, there were long periods in computer
science history when SAT was considered unsolvable. However, it is important to
understand that these complexity results describe the worst case behavior. It
turns out that there is a large class of formulas where SAT is tractable, even
on inputs with millions of variables, and SAT solvers are used with great
success in industries like chip design for decades now.

For the usage of Certora Prover this means that timeouts can happen, but that
often there are slight variations on the input that do not impact the property
being proven and that make the problem tractable. This practice is likely to 
require experience, which we collect in this chapter.

## Intuitions on kinds of complexity

In the section on the [theoretical background of verification
timeouts](timeouts-theory.md) we gave a few details on SMT solver architecture.
We can use the parts of the SMT solver for some intuition on different kinds of
complexity explosions.

| Difficulty         | Solver parts  |
|--------------------|---------------|
| Path count         |  SAT          |
| Storage/memory     |  SAT          |
| Arithmetic         |  LIA / NIA    |
% | bitwise operations |  SAT, UF, LIA |

Since control flow is encoded into Boolean logic by the Certora Prover, it
weighs most heavily on the SAT-solving part of the SMT solver. Storage or Memory
accesses lead to case splits, which are also Boolean in nature. On the other
hand, arithmetic is resolved by specialized solvers; different algorithms are
required for the linear and the nonlinear cases.
