(managing-problems)=
Managing Timeouts and Out of Memory Problems
============================================

In this chapter, we describe how to diagnose and remedy when the Certora Prover
ran out of time or out of memory.

Out-of-memory problems are signified by an `Extremely low available memory`
message in the Global Problems tab of the Prover reports, see
{ref}`memout-introduction` for more details. Timeouts are signified either by a
`Global timeout reached` message in the Global Problems tab, if the whole Prover
job timed out, or by an orange clock symbol next to the rule, if that
particular rule timed out, see {ref}`timeouts-introduction` for more details.

```{toctree}
memout.md
timeout.md
timeout-theory.md
```




