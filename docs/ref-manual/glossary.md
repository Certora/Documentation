Glossary
========

```{glossary}

sound
unsound
  Soundness means that any rule violations in the code being verified are
  guaranteed to be reported by the prover.  Unsound approximations such as
  loop unrolling or certain kinds of harnessing may cause real bugs to be
  missed by the prover, and should therefore be used with caution.  See
  {doc}`approx/index` for more details.

havoc
  In some cases, the prover should assume that some variables can change in an
  unknown way.  For example, an external function on an unknown contract may
  have an arbitrary effect on the state of a third contract.  In this case, we
  say that the variable was "havoced".  See {ref}`havoc-summary` and
  {ref}`havoc-stmt` for more details.
```


