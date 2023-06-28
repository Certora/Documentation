Managing Timeouts
=================

```{todo}
This chapter is incomplete.  The old documentation has a section on
{doc}`troubleshooting </docs/confluence/perplexed>` that addresses timeouts.  There
is also some helpful information in the section on
{ref}`summarization <old-summary-example>`.
Some of the information in these references is out of date.
```

```{todo}
See {ref}`sanity <built-in-sanity>` and {ref}`deep sanity <built-in-deep-sanity>`
rules can be helpful in identifying timeouts.
```

What causes timeouts?
---------------------

Summarizing complex functions
-----------------------------

### Modular verification

(library_timeouts)=
Library-based systems
---------------------
Some of the systems we have are based on multiple library contracts which implement the business logic. They also forward storage updates to a single external contract holding the storage.

In these systems, it’s sensible to split the verification so as each library is operated on an individual basis.

If you encounter timeouts when trying to verify the main entry point contract to the system, check the impact of the libraries on the verification by summarizing all external library (delegate) calls as `NONDET`, using the option `summarizeExtLibraryCallsAsNonDetPreLinking` as follows:
```
certoraRun ... --prover_args '-summarizeExtLibraryCallsAsNonDetPreLinking true'
```

```{note}
This option is only applied for _external_ library calls, or `delegatecall`s.
Internal calls are automatically inlined by the Solidity compiler and are subject to summarizations specified in the spec file's `methods` block.
```

Alternatively, if you wish to apply a "catch-all" summary for all the methods of a specific library, you can write in the methods block of the spec:
```
methods {
    function MyBigLibrary._ external => NONDET;
    function MyBigLibrary._ internal => NONDET;
}
```
The above snippet has the effect of summarizing as `NONDET` all external calls to the library and _internal_ ones as well.
All summary types except ghost summaries can be applied. 

Flags for tuning the Prover
---------------------------

