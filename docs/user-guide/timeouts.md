Managing Timeouts
=================

```{todo}
This chapter is incomplete.  The old documentation has a section on
{doc}`troubleshooting </docs/confluence/perplexed>` that addresses timeouts.  There
is also some helpful information in the section on
{ref}`summarization <old-summary-example>`.
Some of the information in these references is out of date.
```

What causes timeouts?
---------------------

Summarizing complex functions
-----------------------------

### Modular verification

Library-based systems
---------------------
Some systems are based on multiple library contracts implementing the business logic and forwarding all storage updates to a single external contract holding the storage.

In such systems it makes sense to split the verification to operate on each library individually.

If you enconter timeouts when trying to verify the main entry point contract to the system you can check the impact of the libraries on the verification by enabling the option to automatically summarize all external library (delegate) calls as `NONDET`:
```
certoraRun ... --prover_args '-summarizeExtLibraryCallsAsNonDetPreLinking true'
```

```{note}
This option is applied only for _external_ calls, or `delegatecall`s.
Internal calls are automatically inlined by the Solidity compiler and are subject to summarizations specified in the spec file's `methods` block.
```

You can also specify which libraries to _not_ summarize when this option is enabled:
```
certoraRun ... --prover_args '-summarizeExtLibraryCallsAsNonDetPreLinking true -librariesToSkipNonDet library1,library2,...'
```
where `library1` and `library2` are two example library names.


Flags for tuning the Prover
---------------------------

