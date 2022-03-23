Introduction
============

This User Guide contains information about the Certora Prover and Certora
Verification Language.  It is intended to explain how to use the Prover to
verify smart contracts.  It is organized by topic and focuses on the most
useful features instead of including comprehensive details.  For details, see
the {doc}`/docs/ref-manual/index`.

```{todo}
This documentation is currently undergoing significant reorganization and
editing.  Some of the pages are missing; where possible we have included
pointers to the {doc}`/docs/confluence/index` on given topics.
```

The Certora Prover is based on well-studied techniques from the formal
verification community. _**Specifications**_ define a set of rules that call
into the contract under analysis and make various assertions about its
behavior. Together with the contract under analysis, these rules are compiled
to a logical formula called a _**verification condition**_, which is then
proved or disproved by an SMT solver. If the rule is disproved, the solver also
provides a concrete test case demonstrating the violation.

The rules of the specification play a crucial role in the analysis. Without
adequate rules, only very basic properties can be checked (e.g., no assertions
in the contract itself are violated). To effectively use Certora Prover, users
must write rules that describe the high-level properties they wish to verify on
their contracts. This user manual describes the different features of the
specification language. Another primary goal is to help the reader learn how to
think about and write high-level properties.

