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

# Introduction

Timeouts of the Certora Prover are an unpleasant reality.
% This page elaborates on the theoretical background of timeouts in a program 
% verification tool.
In this section we present a practical guide to diagnosing timeout reasons, and 
ways to resolve timeouts.

We start with a rough first classification of timeouts:
1.  Timeouts that happen before SMT solvers are running % (hard stop)
2.  Timeouts where the SMT queries *in sum* lead to a "global timeout" 
    (CertoraProver has a hard dead line of 2hrs for each cloud task)
3.  There is a single SMT query that is not being solved 

Types 1. and 2. are signified by a hard stop of the prover. 
That means the prover ran until the global timeout (set via `--globalTimeout`, typically 2 hours). 
A message like "hard stop reached" appears in the "Global problems" pane of the report, and error symbols next to one or many rules.
% which symbols? red exclamation mark, also "killed" symbol?

Type 3. is signified by a soft stop. This means an smt solver shut down due to hitting the limit for a single smt run (set via `--smt_timeout`). 
Under default settings this means that we give up for the individual rule since in order to obtain a proof of correctness we need to solve every subproblem we generate (see documentation on splitting for more details). % TODO link to splitting doc
Usually the run will have finished in less than two hours, and it will show the timeout sign (a yellow clock symbol) for individual rules.
% a little pic would be nice

% TODO: we should indicate which it is. -- can kind of be seen from from hard stop -- can be seen from whether there's a report. --> still need differentiation between suffocating on splits or not

In the remainder we will focus on the mitigation of SMT timeouts, i.e., types 2. and 3.

```{note}
Timeouts that are not SMT timeouts should be reported to Certora. 
Typically, they will either require developer effort, or significant limitations of the input.
```

% (Background page: SMT solver architecture vs timeouts)
[backgrr](timeouts/timeouts-theory.md)

# What causes timeouts? / Birth of a timeout

As a first step towards resolving a timeout, we need to diagnose its root causes.

 - nonlinear arithmetic
   - linear can be a problem, but only in large quantities, already a handful of nonlinear operations can lead to timeouts however
 - path count
 - Storage/Memory complexity
 - bitwise operations


## Intuitions on Kinds of Complexity

In the section on theoretical background we gave a few details on SMT solver architecture. 
We can use the parts of the SMT solver for some intuition on different kinds of complexity explosions.

| difficulty         | solver parts  |
|--------------------|---------------|
| path count         |  SAT, UF      |
| storage/memory     |  SAT, Arrays  |
| bitwise operations |  SAT, UF, LIA |
| arithmetic         |  LIA / NIA    |


Note that this list of reasons is a result of experience as much as theoretical considerations, so it might be extended and refined in the future.

## Complexity Feedback from Certora Prover

Certora Prover provides statistics on the problem sizes it encounters. 
These statistics are structured according to the timeout reasons given above.

From experience we are classifying the values of the statistics for a given problem as LOW, MEDIUM, or HIGH.
 - LOW means that the problem's complexity in the given area is unlikely to be a reason for a timeout
 - MEDIUM means that the problem's complexity in the given area is could be a reason for a timeout, the timeout might also be a result of the combined complexity with other measures
 - HIGH means that the problem's complexity in the given area is likely to be a reason for a timeout, even if it is the only aspect of the problem that shows high complexity

As of October 2023 these categories map to intervals as follows.

|    | LOW | MEDIUM | HIGH |
|----|-----|--------|------|
| path count | 0 to 2^20 | 20^20 to 2^80 | > 2^80 |
| nonlinear operations | 0 to 10 | 10 to 30 | > 30 |


# Mitigations
% what's a better word than mitigation? Resolution? Solving?

Timeout mitigation approaches fall into these categories.
1. Changing tool settings
2. Changing specs
3. Changing source code
    - harnessing
    - munging

## Changing Tool Settings


## Changing Specs


## Changing Source Code











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

