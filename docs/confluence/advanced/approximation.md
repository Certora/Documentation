Approximation
=============

The Problem
-----------

Many potential questions we may like to ask about programs in any language are inherently undecidable. For example, in general, it is impossible to know whether or not a program will halt (known as the "Halting Problem"). In the case of the Certora Prover, questions about nonlinear arithmetic tend to be very difficult to answer (nonlinear arithmetic is undecidable in general).
Ultimately this means that the Prover will spend forever trying to get an answer and will eventually time out.

Solution 1: Overapproximation
-----------------------------

In essence, overapproximation means that we consider _more_ possible program states than are actually possible. Because this includes _all original behavior_, this approach is **sound**. That is to say, we will never falsely prove something correct when it is not. However, because we consider extra program behavior, there is a chance that we will find a bug in this extra program behavior that does not exist in the actual program.

Imagine we have the following logic expression snippet:

```
uint256 x;
uint256 y;
assume y > 1;
assume x > 1;
z := mul(x, y);
assert z > x && z > y;
```

We have to choose how we want the solver to model `mul`. The natural choice is to model it with ordinary integer arithmetic multiplication (i.e., `mul` will behave exactly as you expect). This choice means that the underlying solver will have to work within the restrictions of integer arithmetic multiplication to try to find a counterexample. Ultimately the solver would prove this program correct.

### Uninterpreted Function as an Overapproximation

But suppose the solver timed out on this example. We might make a different choice in how we model `mul` using an uninterpreted function (see {ref}`this section <uninterp-functions>` for a brief description of uninterpreted functions). In essence, any time the solver sees an uninterpreted function, it knows "any time this function receives the same values as arguments, it will produce the same output." Other than that, the solver has free reign to decide which outputs each input will produce. For example it could decide that `uninterp_mul(1, 5) -> 22`. Or it could decide `uninterp_mul(1, 5) -> 5`. Conversely, in if we had modeled multiplication as above, the solver would be forced to decide `integer_arithmetic_mul(1, 5) -> 5`. 

Notice that the solver could choose many behaviors for `uninterp_mul`, but _importantly_ these behaviors _include_`integer_arithmetic_mul`. This is what makes this an overapproximation--it considers program behavior that includes "actual" program behavior and more.

So what would the solver decide in this case? It would no longer prove the program correct and would give us a (seemingly nonsensical) counterexample, for example:

```
x = 5;
y = 10;
z = 5;
mul = lambda(a, b) if (a == 5) 5 else 299
```

In this case we have a _spurious counterexample_ caused by our overapproximation.

### Axiomatized Uninterpreted Function as an Overapproximation

There is a middle ground that we can take between precisely modeling program behavior and the above overapproximation. We can use uninterpreted functions and add axioms to them. In the above example, we let the solver decide everything about `uninterp_mul`. But it turns out we can give hints to the solver, to more closely approximate the behavior of `integer_arithmetic_mul`
