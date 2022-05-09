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

parametric rule
  ```{todo}
  This section is incomplete.
  ```

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

````


