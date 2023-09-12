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
  The terms "model", "example", and "counterexample" are used interchangeably.
  They all refer to an assignment of values to all of the CVL variables and
  contract storage.  See {ref}`rule-overview`.

overapproximation
underapproximation
  Sometimes it is useful to replace a complex piece of code with something
  simpler that is easier to reason about.  If the approximation includes all of
  the possible behaviors of the original code (and possibly others), it is
  called an "overapproximation"; if it does not then it is called an
  "underapproximation".  For example, a {ref}`NONDET <view-summary>` summary is
  an overapproximation because every possible value that the original
  implementation could return is considered by the Prover, while an
  {ref}`ALWAYS <view-summary>` summary is an underapproximation if the
  summarized method could return more than one value.

  Proofs on overapproximated programs are {term}`sound`, but there may be
  spurious {term}`counterexample`s caused by behavior that the original code
  did not exhibit.  Underapproximations are more dangerous because a property
  that is successfully verified on the underapproximation may not hold on the
  approximated code.

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
  This section is incomplete.  See {ref}`--rule_sanity` and {ref}`built-in-sanity` for partial information.
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
  {doc}`/docs/prover/approx/index` for more details.

summary
summarize
  A method summary is a user-provided approximation of the behavior of a
  contract method.  Summaries are useful if the implementation of a method is
  not available or if the implementation is too complex for the Prover to
  analyze without timing out.  See {doc}`/docs/cvl/methods` for
  complete information on different types of method summaries.

vacuous
vacuity
  A logical statement is *vacuous* if it is technically true but only because
  it doesn't say anything.  For example, "every integer that is both greater
  than 5 and less than 3 is a perfect square" is technically true, but only
  because there are no numbers that are both greater than 5 and less than 3.

  Similarly, a rule or assertion can pass, but only because the `require`
  statements rule out all of the {term}`model`s.  In this case, the rule
  doesn't say anything about the program being verified.
  The {doc}`../prover/checking/sanity` help detect vacuous rules.

tautology
  A tautology is a logical statement that is always true.

wildcard
exact
  A methods block entry that explicitly uses `_` as a receiver is a *wildcard
  entry*; all other entries are called *exact entries*.  See
  {doc}`/docs/cvl/methods`.

````


