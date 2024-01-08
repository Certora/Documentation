(grounding)=
# Quantifier Grounding 

{term}`Quantified expressions <quantifier>` are a very powerful tool for writing
specifications, but they can also lead to incredibly long running times.  For
this reason, the Prover uses an approximation called "grounding".

It is not possible to ground every expression perfectly.  While grounding is
{term}`sound` (i.e. it will not allow a rule to be verified if it is not true),
there are cases where it may generate {term}`counterexample`s even for rules
that should pass.  For example, a counterexample may not obey a `require`
statement that contains a quantifier.

You can prevent spurious counterexamples by turning off grounding (by passing
{ref}`-smt_groundQuantifiers`), but without grounding the Prover may run
considerably slower, and is likely to time out.

The remainder of this document explains grounding in more detail, and lists the
specific kinds of quantified expressions that may lead to spurious
counterexamples.  We also include some suggestions for rewriting your
quantified statements to avoid spurious counterexamples.

```{contents}
```

## How grounding works

Quantifier grounding transforms a {term}`quantified <quantifier>` statement
into a series of non-quantified statements.  For example, suppose a
specification contains the following {ref}`ghost axiom <ghost-axioms>`:

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

## Limitations on grounding

In some cases, there is an easy way to rewrite your expression with fewer
quantifiers.  For example, the following quantified statement requires that
`f(x)` is always odd, but it is written in a way that violates {ref}`one of the
restrictions on quantifiers <grounding-arguments>`:

```cvl
require forall uint x . forall mathint y . f(x) != 2 * y;
```

However, there is a much simpler way to require that `f(x)` is odd by using `%`:

```cvl
require forall uint x . f(x) % 2 == 1;
```

This rewritten statement obeys the rules listed below, and therefore will not
produce any spurious counterexamples.

The remainder of this section describes specific cases where the Prover cannot
ground quantified statements, and gives advice on how to work around those
limitations.

(grounding-alternating)=
### Alternating Quantifiers

Alternating quantifiers (those containing `forall` followed by `exist` or
vice-versa) complicate the process of grounding, so there are limitations to
what statements you can write and which of them are grounded.

In most contexts, you may not have a `forall` expression contained inside of an
`exists` statement.  For example, this is allowed:

```cvl
assert forall address x . forall uint y . exists uint z . exists uint w . e(x,y,z,w);
```

but this is disallowed:

```cvl
assert forall address x . exists address y . exists address z . forall address w . e(x,y,z,w);
```

In the latter case, the `forall address w` is contained inside the `exists address z`.

Logical negations and `require` statements reverse the rules for `forall` and
`exists` statements: in those contexts, you cannot nest an `exists` expression
inside of a `forall` statement.  Including another negation will again reverse
the rules.  For example, the following are allowed:

```cvl
require    exists address x . forall uint y . e(x,y);
assert   !(exists address x . forall uint y . e(x,y));
require  !(forall address x . exists uint y . e(x,y));
assert !(!(forall address x . exists uint y . e(x,y)));
```

but these are disallowed:

```cvl
require  forall address x . exists uint y . e(x,y);
assert !(forall address x . exists uint y . e(x,y));
```

One common way to work around these limitations is by replacing `exists`
expressions with concrete expressions that produce the values that should exist.

For example, suppose your contract function always returned twice its input:

```solidity
function f(uint x) external returns(uint) { return 2 * x; }
```

You might like to prove that if `x` is positive, then it's possible for `f` to
output something smaller than `f(x)`:

```cvl
assert forall uint x . (x > 0) => (exists uint y . f(y) < f(x));
```

This is clearly true; for example `f(x - 1)` is always smaller than `f(x)`, as
is `f(0)`.  However, to work around the nested quantifier restriction, we have
to help the Prover find the correct value for `y`.  We could replace this
statement with either of the following two:

```cvl
assert forall uint x . (x > 0) => f(0) < f(x);
assert forall uint x . (x > 0) => f(x-1) < f(x);
```

(grounding-recursion)=
### Recursion

Quantified statements that relate a function with itself on two different
inputs may give incorrect counterexamples.  For example, the following `forall`
statement refers to `f` twice:

```
rule recursiveQuantifier {
    require forall uint x . f(x) > f(x-1);
    assert f(8) > f(6);
}
```

Although we can see that the assertion must be true, we would need to combine
the statements `f(8) > f(7)` and `f(7) > f(6)` to prove it, and the grounding
mechanism is unable to do this.

In these cases, you may see a counterexample that doesn't satisfy the `require`
statement; in this case the best option is to disable grounding with
{ref}`-smt_groundQuantifiers`.

(grounding-arguments)=
### Variables must be arguments

In order for grounding to work, every variable appearing in a quantified
statement must be used at least once as an argument to a ghost or contract
function.  For example, neither of the following examples are allowed:

```cvl
require forall mathint x . x * 2 != y;
require forall uint x . forall mathint y . f(x) != 2 * y;
```

In the first example, `x` is not used as an argument to a function, while in the
second case, `y` is not.


Although you are allowed to call functions on complicated expressions that use
quantified variables, doing so may produce spurious counterexamples.  For
example, the following is allowed, but is likely to produce spurious
counterexamples (because `x` itself is not an argument to a function):

```cvl
require forall uint x . f(2 * x) == 0;
```

This particular example requires that all even inputs to `f` produce `0` as
output; it could be rewritten as follows:

```cvl
require forall uint y . (y % 2 == 0) => f(y);
```

If you use a quantified variable in an argument to two different functions,
you may produce spurious counterexamples.  For example:

```cvl
require forall uint x . f(x) <= g(x+1) && g(x+1) != 0;
```

Here, `x + 1` is used as an argument to `g`, but `x` is not; you may get
counterexamples where `g(x+1) == 0` for some `x`.  In that case, you can add an
additional equivalent require that does use the quantified variable as an argument
to `g`:

```cvl
require forall uint x . f(x) < g(x+1) && g(x+1) != 0;
require forall uint x . f(x-1) < g(x) && g(x) != 0;
```

This will make `x` a direct argument to `g`, so the expression will be
grounded properly.

(grounding-polarity)=
### Double Polarity

The polarity of a sub-formula is the direction of the effect it has on the
output of the formula. This is best demonstrated through an example:

```cvl
a && (b || !c)
```

In this example, `b` possesses a positive polarity because changing `b` from `false` to `true`
can't make the formula `false` if it wasn't before.  Informally, making `b`
"more true" can only make the whole formula "more true".

In this example, `a` also possesses positive polarity: if the formula was true when `a` was
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

Grounding is disallowed when the quantified expression has double polarity in the
rule.  For example, the following is disallowed, because the `forall` statement
has double polarity.
```cvl
rule r {
    ...
    assert (forall uint x . f(x) > 0) <=> y;
}
```

In many cases you can split a rule with a quantifier in a double-polarity
position into multiple rules with single-polarity quantifiers.  For example, the
above assertion could be split into two rules:

```cvl
rule r1 {
    ...
    assert (forall uint x . f(x) > 0) => y;
}

rule r2 {
    ...
    assert y => (forall uint x . f(x) > 0);
}
```

Verifying `r1` and `r2` is logically equivalent to verifying `r`, but the
quantified expression appears with single polarity in each of the two rules.

