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
Some of the systems we have are based on multiple library contracts which implement the business logic. They also forward storage updates to a single external contract holding the storage.

In these systems, it’s sensible to split the verification so as each library is operated on an individual basis.

If you encounter timeouts when trying to verify the main entry point contract to the system, check the impact of the libraries on the verification by enabling the option to automatically summarize all external library (delegate) calls as `NONDET`:
```
certoraRun ... --prover_args '-summarizeExtLibraryCallsAsNonDetPreLinking true'
```

```{note}
This option is only applied for _external_ library calls, or `delegatecall`s.
Internal calls are automatically inlined by the Solidity compiler and are subject to summarizations specified in the spec file's `methods` block.
```

When enabled, this option also allows you to specify which libraries to _not_ summarize:
```
certoraRun ... --prover_args '-summarizeExtLibraryCallsAsNonDetPreLinking true -librariesToSkipNonDet library1,library2,...'
```
where `library1` and `library2` are two example library names.

```{note}
The option `-librariesToSkipNonDet` has no effect if `-summarizeExtLibraryCallsAsNonDetPreLinking` is not set to true.
```


Flags for tuning the Prover
---------------------------

