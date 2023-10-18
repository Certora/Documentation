# Some Background on Timeouts in Certora Prover

In this section, we will discuss some background of timeouts happening in the Certora Prover.
We try to answer questions like "Why do you build a tool that times out?" and "Will there be an automatic program verifier that never times out?".
For more practical advice on timeout prevention, please consult the other parts of our documentation on [managing timeouts](index.md).

```{todo}
This section still needs to be written.
```


## Intuitions on Kinds of Complexity

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

% Note that this list of reasons is a result of experience as much as theoretical considerations, so it might be extended and refined in the future.



%, since SMT solvers are designed to solve problems that, according to theoretical computer science, are prone to showing "exponential" runtime behavior or worse.