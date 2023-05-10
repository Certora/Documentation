# Grounding 

## Flag

Grounding is usually set to “On” by default. To turn it off, use the command
`--settings -smt_groundQuantifiers=false`.

 
## Grounding General Idea

Grounding should make it much easier to use quantifiers on the solvers.
Example:

```
assume forall x. f(x) = 0
```

A very natural init state axiom. Instead of giving it as is to the SMT-solvers,
we automatically collect all instances of `f` in the formula we want to verify,
e.g., `f(2), f(9), f(y + 3), f(z)`, and replace the original assert with:

```
assume f(2) = 0
assume f(9) = 0
assume f(y + 3) = 0
assume f(z) = 0
```

Simple enough! You can also write more complex quantified statements, which
will be grounded in a similar fashion. However, this approach has its
limitations. It will never validate a rule when it is not valid (i.e.,
grounding is sound), but it may generate false counter-examples. Read below on
how to minimize the chance of this happening.

Note that this works for assumes, as well as asserts, axioms, invariants, and
anywhere else quantifiers are used. You can also use exists quantifiers.

There are examples where this changes a timeout to 3 seconds, cases where it
didn’t really change the running time, and a rare case where it performed much
worse than standard quantification. However, in general, this should work much
better in terms of running time.

 
## Limitations

There are some cases we just can’t ground, and some cases that are incomplete
(i.e. give a wrong counter-example). Nevertheless, grounding is always sound
(i.e. if we say a formula is valid then it definitely is). Here are some
guidelines and explanations.
 
### Alternating Quantifiers

```
assume forall x, exists y. f(x) = g(y)
```

Currently, this does not work. We can make it work though, so if you need it,
reach out to us and we’ll make an effort.

```
assume exists x, forall y ...
```

This works, as well as:

```
assert forall x, exists y.
```

Currently, for the first case, the tool crashes. In such a case, it is
preferable to rewrite your spec, or turn grounding off and see if the solvers
manage it.
 
### Recursion

```
assume forall x. f(x) > f(x+1)
assert f(8) > f(6)
```

Any recursion of this kind will most likely give a wrong counter-example. It is
not auto-detected, hence the responsibility to avoid it and realize the
counter-example is wrong is on the user.

 
### Variables That Are Not Arguments

```
forall x. x^2 != y
```

This cannot work, as we run over all instances of functions in the formula
during grounding. In this case, there is no function and instance and therefore
it would not work. Neither would:

```
forall x, y. f(x) != 2y
```

Because of `y`. 

In such cases, we will hard crash, so again you can rewrite your spec or turn
grounding off. To avoid this, ensure that each quantified variable is used as
an argument of a function call within the quantified expression. This may not
always be possible, but we can write:

```
forall x. f(x) % 2 == 1
```
 
### Double Polarity

The polarity of a sub-formula is the direction of the effect it has on the
output of the formula. This is best demonstrated through an example:

```
a /\ (b \/ !c)
```

`b` possesses a positive polarity, as switching it from `false` to `true` only
makes the formula change from `false` to `true`. This means that the formula is
weakly monotone increasing in `b`. The same goes for `a`. `c` on the other hand
has a negative polarity.

Sub-expressions can also have double polarity:
```
(a == b) /\ c
ite(a, b, c)
```

In both of these examples, `a` has double polarity, because the formula is not
weakly monotone w.r.t. `a` (neither increasing nor decreasing). 

Grounding crashes when this happens, so we can either rewrite or turn it off.
This is not about the sub-expressions of the quantified expression but the
quantified expression itself.

```
ite(forall .., x, y)
```

is bad. But:
```
forall a, b. ite(a, b, b + 1) > 10
```

is totally fine.

 

 
### Simple Parameters

To make the grounding sound, we had to make it work only when the quantified
variables appear as the exact argument to some function. 

_Example:_ 
```
forall x. f(2x) > 0
```

This will most likely give a wrong counter-example because `2x` is not a
quantified variable. It should be rewritten as:

```
forall y. (y % 2 = 0) => f(y) 
```

_Example:_
```
forall x. f(x) = g(x+1)
```

We can’t simplify both arguments at once. However, the fact that `x` is simple
in one place is more often than not enough. If it’s not (you get a bad
counter-example), you can add another axiom:
```
forall x. f(x-1) = g(x)
```

It’s equivalent, though different for grounding. The first quantifier will be
grounded on all `f` instances, and the second on all `g` instances. There is
also another solution:
```
forall x, y. y=x+1 /\ f(x) = g(y)
```

This is correct, although slightly less efficient because the fewer the
variables we quantify over, the smaller the grounding effort will be. You can
think of it as nested loops.

Note:
```
forall x. f(3g(x) + 1) > 0
```

This is good because we only care about the innermost function application. So
in this case, it’s only `g(x)`.
