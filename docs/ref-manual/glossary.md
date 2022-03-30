Glossary
========

```{todo}
This document is incomplete.
```

````{glossary}

sound
unsound
  Soundness means that any rule violations in the code being verified are
  guaranteed to be reported by the Prover.  Unsound approximations such as
  loop unrolling or certain kinds of harnessing may cause real bugs to be
  missed by the Prover, and should therefore be used with caution.  See
  {doc}`approx/index` for more details.

havoc
  In some cases, the Prover should assume that some variables can change in an
  unknown way.  For example, an external function on an unknown contract may
  have an arbitrary effect on the state of a third contract.  In this case, we
  say that the variable was "havoced".  See {ref}`havoc-summary` and
  {ref}`havoc-stmt` for more details.

quantifier
quantified expression
  The symbols `forall` and `exist` are sometimes referred to as *quantifiers*,
  and expressions of the form `forall type v . e` and `exist type v . e` are
  referred to as *quantified expressions*.  See {ref}`logic-exprs` for
  details about quantifiers in CVL.

parametric rule
  A parametric rule is a rule that calls an ambiguous method, either using a
  method variable, or using an overloaded function name.  The prover will
  generate a separate report for each possible instantiation of the method.
  See {ref}`parametric-rules` for more information.

sanity
  ```{todo}
  This section is incomplete.  See {ref}`--rule_sanity` for partial information.
  ```

````


