Glossary
========

```{todo}
This document is incomplete.
```

````{glossary}

environment
  The environment of a method call refers to the global variables that solidity
  provides, including `msg`, `block`, and `tx`.  CVL represents these variables
  in a structure of type {ref}`env <env>`.  The environment does *not* include
  the contract state or the state of other contracts --- these are referred to
  as the {ref}`storage <storage-type>`.

havoc
  In some cases, the Prover should assume that some variables can change in an
  unknown way.  For example, an external function on an unknown contract may
  have an arbitrary effect on the state of a third contract.  In this case, we
  say that the variable was "havoced".  See {ref}`havoc-summary` and
  {ref}`havoc-stmt` for more details.

hyperproperty
  A hyperproperty describes a relationship between two hypothetical sequences
  of operations starting from the same initial state.  For example, a statement
  like "two small deposits will have the same effect as one large deposit" is a
  hyperproperty.  See {ref}`storage-type` for more details.

model
example
counterexample
  The terms "model", "example", and "counterexample" are used interchangably.
  They all refer to an assignment of values to all of the CVL variables and
  contract storage.  See {ref}`rule-overview`.

parametric rule
  A parametric rule is a rule that calls an ambiguous method, either using a
  method variable, or using an overloaded function name.  The Prover will
  generate a separate report for each possible instantiation of the method.
  See {ref}`parametric-rules` for more information.

quantifier
quantified expression
  The symbols `forall` and `exist` are sometimes referred to as *quantifiers*,
  and expressions of the form `forall type v . e` and `exist type v . e` are
  referred to as *quantified expressions*.  See {ref}`logic-exprs` for
  details about quantifiers in CVL.

sanity
  ```{todo}
  This section is incomplete.  See {ref}`--rule_sanity` for partial information.
  ```

scene
  The *scene* refers to the set of contract instances that the Prover knows
  about.

sound
unsound
  Soundness means that any rule violations in the code being verified are
  guaranteed to be reported by the Prover.  Unsound approximations such as
  loop unrolling or certain kinds of harnessing may cause real bugs to be
  missed by the Prover, and should therefore be used with caution.  See
  {doc}`approx/index` for more details.

summary
summarize
  A method summary is a user-provided approximation of the behavior of a
  contract method.  Summaries are useful if the implementation of a method is
  not available or if the implementation is too complex for the Prover to
  analyze without timing out.  See {doc}`/docs/ref-manual/cvl/methods` for
  complete information on different types of method summaries.
````


