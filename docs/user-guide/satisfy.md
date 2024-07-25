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

```{cvlinclude} ../../Examples/DEFI/ConstantProductPool/certora/spec/ConstantProductPool.spec
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
