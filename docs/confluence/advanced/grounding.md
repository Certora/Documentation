# Grounding 

## Flag

Grounding is on by default. To turn it off, use `--settings -smt_groundQuantifiers=false`

 
## Grounding General Idea

Grounding should make using quantifiers much easier on the solvers. For example,

```
assume forall x. f(x) = 0
```

A very natural init state axiom. Instead of giving it as is to the SMT-solvers, we automatically collect all instances of `f` in the formula we want to verify, e.g., `f(2), f(9), f(y + 3), f(z)`, and replace the original assert with:

```
assume f(2) = 0
assume f(9) = 0
assume f(y + 3) = 0
assume f(z) = 0
```

Simple enough! You can of course write more complex quantified statements, and they will be grounded in a similar fashion. However, this approach has its limitations. It will never say a rule is valid when it is not (i.e., grounding is sound), but it may generate false counter-examples. Read below on how to minimize the chance of this happening. 

Note that this works not only for assumes, but also for asserts, axioms, invariants, and anywhere else quantifiers are used. You can also use `exists` quantifiers.

I’ve seen examples where this changes a timeout to 3 seconds, cases where it didn’t really change the running time, and a rare case where it performed much worse than standard quantification. but in general, this should work much better in terms of running time. 

 
## Limitations

There are some cases we just can’t ground, some cases that are incomplete (i.e., give a wrong counter-example), but grounding is always sound (i.e., if we say a formula is valid then it surely is). Here are some guidelines and explanations.

 
### Alternating Quantifiers

```
assume forall x, exists y. f(x) = g(y)
```


Doesn’t currently work. We can make it work, so if you need it, give us a shout and we’ll make an effort :slight_smile: 

```
assume exists x, forall y ...
```

Does work! and also:

```
assert forall x, exists y.
```

For the first case,  we currently crash the tool. In such a case, preferably rewrite your spec rerun, or you can turn grounding off and see if the solvers manage it.

 
### Recursion

```
assume forall x. f(x) > f(x+1)
assert f(8) > f(6)
```

Any sort of such recursion will very likely give a wrong counter-example. We do not auto-detect it, so the responsibility to avoid it and to realize the counter-example is wrong is on the user.

 
### Variables That Are Not Arguments

```
forall x. x^2 != y
```

Can’t work, because for grounding we run over all instances of functions in the formula. Here there is no function and no instance. This won’t work either:
```
forall x, y. f(x) != 2y
```

Because of `y`. 

We will hard crash on such cases, so again, you can rewrite your spec or turn grounding off. To avoid it, make sure each quantified variable is used in as an argument of a function call within the quantified expression. It’s not always possible, but in this case we can write:

```
forall x. f(x) % 2 == 1
```
 
### Double Polarity

The polarity of a sub-formula is the direction of the effect it has on the output of the formula. Best explained by example:
```
a /\ (b \/ !c)
```

`b` has positive polarity, because switching it from `false` to `true`, may only make the formula change from `false` to `true`. In other words, the formula is weakly monotone increasing in `b`. The same goes for `a`. `c` on the other hand has negative polarity.

Sub-expressions can also have double polarity:
```
(a == b) /\ c
ite(a, b, c)
```

In both of these examples, `a` has double polarity, because the formula is not weakly monotone w.r.t. `a` (neither increasing nor decreasing). 

Grounding crashes when this happens, so either rewrite or turn it off. This is not about the sub-expressions of the quantified expression, but the quantified expression itself. For example:
```
ite(forall .., x, y)
```

is bad. But:
```
forall a, b. ite(a, b, b + 1) > 10
```

is totally fine.

 

 
### Simple Parameters

To make grounding sound, we had to make it work only when the quantified variables appear as the exact argument to some function. For example, 
```
forall x. f(2x) > 0
```

will most likely give a wrong counter-example because `2x` is not a quantified variable. It should be rewritten as:
```
forall y. (y % 2 = 0) => f(y) 
```

Another example:
```
forall x. f(x) = g(x+1)
```

We can’t make both arguments simple at the same time. However, the fact that `x` is simple in one place is many times enough. If it’s not (you got a bad counter-example) you can add another axiom:
```
forall x. f(x-1) = g(x)
```

It’s equivalent, yet for grounding it is different. The first quantifier will be grounded on all `f` instances, and the second on all `g` instances. There is also another solution:
```
forall x, y. y=x+1 /\ f(x) = g(y)
```

This is correct but is slightly less efficient because in general, the fewer variables we quantify over, the smaller the grounding effort will be. Think of it as nested loops.

Note:
```
forall x. f(3g(x) + 1) > 0
```

is actually fine because we only care for the innermost function application. So in this case it’s only `g(x)`.