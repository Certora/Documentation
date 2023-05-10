# Quantifier grounding 

Quantifier grounding transforms a {term}`quantified` statement into series of
non-quantified statements.  For example, suppose a specification contains the
following `ghost` axiom:

```cvl
ghost f(uint x) returns (mathint) {
    init_state axiom forall uint x . f(x) == 0
}
```

This statement logically says that `f(0) == 0` and `f(1) == 1` and `f(2) == 0`
and so on.  In practice, however, the verification may only make use of a small
finite number of these facts.  Grounding is the process of automatically
replacing the `forall` statement with the specific unquantified statements that
are necessary.

For example, if the program and specification only ever access `f(2)`, `f(9)`,
`f(y+3)`, and `f(z)`, then the axiom above would be automatically replaced
with:

```cvl
ghost f(uint x) returns (mathint) {
    init_state axiom f(2)   == 0;
    init_state axiom f(9)   == 0;
    init_state axiom f(y+3) == 0;
    init_state axiom f(z)   == 0;
}
```

The Prover will also ground more complex quantified expressions, and will ground
them anywhere that you can write a quantified statement (e.g. `assert` and
`require` statements, ghost axioms, and invariants).  Grounding also works with
`exists` quantifiers.

## Limitations

It is not possible to ground every expression perfectly.  While grounding is
{term}`sound` (i.e. it will not allow a rule to be verified if it is not true),
there are cases where it may generate spurious {term}`counterexample`s.

You can prevent spurious counterexamples by turning off grounding (by passing
{ref}`-smt_groundQuantifiers`), but without grounding the Prover may run
considerably slower, and is likely to time out.  For example, a rule that was
verified in 3 seconds with grounding timed out after two hours without
grounding.  There are also some cases where the Prover runs faster without
grounding, but these are rare.

The remainder of this document describes specific cases where the Prover cannot
ground quantified statements, and gives advice on how to work around those
limitations.

### Alternating Quantifiers

Alternating quantifiers (those containing `forall` followed by `exist` or
vice-versa) complicate the process of grounding, so there are limitations to
what statements you can write and which of them are grounded.

```{todo}
It is not clear what the difference between the first and third example is
here, or what about the following does not work.  Is it that one is a `require`
and the other is an `assert`?
```

```
require forall mathint x . exists mathint y. f(x) == g(y);
```


Currently, this does not work. We can make it work though, so if you need it,
reach out to us and we’ll make an effort.

```
require exists mathint x . forall mathint y . p(x,y);
```

This works, as well as:

```
assert forall x, exists y.
```

Currently, for the first case, the tool crashes. In such a case, it is
preferable to rewrite your spec, or turn grounding off and see if the solvers
manage it.

```{todo}
Crashes how?  It would be good to include an error message here so that googlers
can find it.
```
 
### Recursion

Quantified statements that relate a function with itself on two different inputs
are likely to give incorrect counterexamples.  For example, the following
`forall` statement refers to `f` twice:

```
rule recursiveQuantifier {
    require forall mathint x . f(x) > f(x-1);
    assert f(8) > f(6);
}
```

Although we can see that the assertion must be true, we would need to combine
the statements `f(8) > f(7)` and `f(7) > f(6)` to prove it, and the grounding
mechanism is unable to do this.

```{todo}
What does the counterexample look like?
```

```{warning}
The Prover will not detect recursive quantified statements like this, so this
would be something good to check for when you encounter spurious counterexamples.
```

### Variables That Are Not Arguments

In order for grounding to work, every variable appearing in a quantified
statement must be used as an argument to a function.  For example, neither of
the following examples will work:

```{todo}
"must be used" or "must only be used"?
```

```
require forall mathint x . x * 2 != y;
require forall mathint x . forall mathint y . f(x) != 2y;
```

Grounding is based on the application of functions, so the grounded variables
must be arguments to functions.  In this case, `x` and `y` are not arguments to
functions.

In such cases, we will hard crash, so again you can rewrite your spec or turn
grounding off. To avoid this, ensure that each quantified variable is used as
an argument of a function call within the quantified expression.

```{todo}
Crash how?
```

```{todo}
What is the following example showing?
```

This may not
always be possible, but we can write:

```
forall x. f(x) % 2 == 1
```
 
### Double Polarity

The polarity of a sub-formula is the direction of the effect it has on the
output of the formula. This is best demonstrated through an example:

```cvl
a && (b || !c)
```

In this example, `b` possesses a positive polarity because change `b` from `false` to `true`
can't make the formula `false` if it wasn't before.  Informally, making `b`
"more true" can only make the formula "more true".

In this example, `a` also posseses positive polarity: if the formula was true when `a` was
`false`, it must also be `true` when `a` is `true`.

On the other hand, `c` has a negative polarity because changing `c` from `true`
to `false` can only make the statement "more false".  If can't become `true` if
it wasn't true before.

Sub-expressions can also have double polarity.  For example, consider the
formula
```
a <=> b
```
In this example, `a` has double polarity, because making `a` true could cause
the formula to become `false` when it was true before, but it could also cause
the formula to become `true` when it wasn't before.

Grounding crashes when the variable in the quantifier has double polarity in
the quantified expression.  In that case, you can either rewrite the quantified
statement or {ref}`turn grounding off <-smt_groundQuantifiers>`.

```{todo}
Crashes how?  Error message?
```

```{todo}
I don't understand the following examples
```

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
