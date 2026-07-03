```{role} cvl(code)
:language: cvl
```

```{role} solidity(code)
:language: solidity
```


(producing-examples)=
Producing Positive Examples
===========================

Sometimes it is useful to produce examples of an expected behavior instead of
counterexamples that demonstrate unexpected behavior.  You can do this by
writing a rule that uses {ref}`satisfy` instead of the `assert` command.  For
each `satisfy` command in a rule, the Prover will produce an example that makes
the condition true, or report an error.

The purpose of the `satisfy` statement is to produce examples that demonstrate
some execution of the code.  Not every example is interesting &mdash; users
should inspect the example to ensure that it demonstrates the expected
behavior.

For {clink}`example </DEFI/ConstantProductPool/certora/spec/ConstantProductPool.spec>`,
we may be interested in showing that it is
possible for someone to deposit some assets into a pool and then immediately
withdraw them.  The following rule demonstrates this scenario:

```{cvlinclude} /DEFI/ConstantProductPool/certora/spec/ConstantProductPool.spec
:cvlobject: possibleToFullyWithdraw
:caption: Positive example
```

The Prover will produce an example that satisfies this condition.
Sometimes the example will be uninteresting, such as having
{cvl}`amount == 0` in the example for {cvl}`possibleToFullyWithdraw`.
In such cases we need to strengthen the conditions in order
to produce more interesting examples.
In {cvl}`possibleToFullyWithdraw` we added a
{cvl}`require amount > 0;` statement to prevent such a case.

Alternatively, we could have strengthened the {cvl}`satisfy`
condition by adding

```cvl
    satisfy (amount > 0) && ...
```

(witness-rules)=
Witness rules for implication assertions
----------------------------------------

An assertion of the form {cvl}`assert p => q;` is trivially true on every
execution where {cvl}`p` is false.  If the rule's assumptions (or an
over-approximating summary) make {cvl}`p` unreachable, the rule passes
without ever checking {cvl}`q` &mdash; and because executions still reach the
assertion, the {ref}`vacuity sanity check <sanity-vacuity>` will not flag
the rule.

A *witness rule* is a companion rule that uses {cvl}`satisfy` to demonstrate
that the antecedent is reachable:

```cvl
rule feeChargedOnLargeWithdrawal(env e, uint256 amount) {
    uint256 fee = withdraw(e, amount);
    assert amount > feeThreshold() => fee > 0;
}

// witness: the antecedent above is reachable
rule witnessLargeWithdrawal(env e, uint256 amount) {
    uint256 fee = withdraw(e, amount);
    satisfy amount > feeThreshold();
}
```

If the witness rule fails, the implication in the main rule was checked
against no executions and its result is meaningless; the assumptions or
summaries need to be fixed (see {doc}`patterns/vacuity`).  If the witness
passes, the produced example also documents a concrete execution in which
the interesting case occurs.

A witness rule is usually only one line different from the rule it
accompanies, and it turns a silent coverage gap into a visible failure, so
consider writing one for every implication-shaped assertion whose antecedent
is not obviously reachable.
