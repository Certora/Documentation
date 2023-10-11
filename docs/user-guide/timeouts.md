Managing Timeouts
=================

Timeouts of the Certora Prover are an unpleasant reality.
In this chapter we present a practical guide to diagnosing the causes of timeouts and ways to prevent them.
% This page elaborates on the theoretical background of timeouts in a program % verification tool.  


# Introduction

We start with a rough classification of Certora Prover timeouts:
1.  Timeouts that happen before SMT solvers are running 
2.  Timeouts where the SMT queries *in sum* lead to a "global timeout" 
    (CertoraProver has a hard dead line of 2hrs for each cloud task)
3.  There is a single SMT query that is not being solved 

Types 1. and 2. are signified by a hard stop of the prover. 
That means the prover ran until the global timeout (set via `--globalTimeout`, typically 2 hours) and was forcefully shut down from everything it was doing. 
A message like "hard stop reached" appears in the "Global problems" pane of the report, and error symbols next to one or many rules.
% which symbols? red exclamation mark, also "killed" symbol?
% made CERT-3797 so we get a clear indication to the user, hopefully

Type 3. is signified by a soft stop. This means an smt solver shut down due to hitting the limit for a single smt run (set via `--smt_timeout`). 
Under default settings this means that we give up for the individual rule since in order to obtain a proof of correctness we need to solve every subproblem we generate (see documentation on splitting for more details). 
% TODO link to splitting doc
%Usually the run will have finished in less than two hours, and it will show the timeout sign (a yellow clock symbol) for individual rules.
% a little pic would be nice

% TODO: we should indicate which it is. -- can kind of be seen from from hard stop -- can be seen from whether there's a report. --> still need differentiation between suffocating on splits or not

In the remainder we will focus on the mitigation of SMT timeouts, i.e., types 2. and 3.

```{note}
Timeouts that are not SMT timeouts should be reported to Certora. 
Typically, they will either require developer effort, or significant limitations of the input.
```

For some more general background on SMT timeouts, please see [this page](timeouts/timeouts-theory.md).

(timeout_causes)=
# What Causes Timeouts?

As a first step towards resolving a timeout, we need to diagnose its root causes.
In our experience so far, the following are some of the most common reasons for SMT timeouts.

 - Non-trivival amount of onlinear arithmetic
 - Very high path count
 - High storage/memory complexity

This list is not exhaustive by any means, but the majority of timeouts we have observed so far can be traced back to one or more of these causes.
Note that these are not the only sources of complexity; however, for instance linear arithmetic usually only becomes a problem when the input program is rather large, of which the path count is a good indication.

## Intuitions on Kinds of Complexity

In the section on the [theoretical background of verification timeouts](timeouts/timeouts-theory.md) we gave a few details on SMT solver architecture. 
We can use the parts of the SMT solver for some intuition on different kinds of complexity explosions.

| difficulty         | solver parts  |
|--------------------|---------------|
| path count         |  SAT          |
| storage/memory     |  SAT          |
| arithmetic         |  LIA / NIA    |
% | bitwise operations |  SAT, UF, LIA |

Since control flow is encoded into Boolean logic by the Certora Prover, it weighs most heavily on the SAT-solving part of the SMT solver. 
Storage or Memory accesses lead to case splits, which are also Boolean in nature.
On the other hand, arithmetic is resolved by specialized solvers; different algorithms are required for the linear and the nonlinear cases.

% Note that this list of reasons is a result of experience as much as theoretical considerations, so it might be extended and refined in the future.

## Complexity Feedback from Certora Prover

Certora Prover provides statistics on the problem sizes it encounters. 
These statistics are structured according to the timeout reasons given above.

### Immediate feedback, "HIGH, MED, LOW"

From experience we are classifying the values of the statistics for a given problem as LOW, MEDIUM, or HIGH.
 - LOW: unlikely to be a reason for a timeout
 - MEDIUM: might be a reason for a timeout, the timeout might also be a result of the combined complexity with other measures
 - HIGH: likely to be a reason for a timeout, even if it is the only aspect of the problem that shows high complexity

As of October 2023 these categories map to intervals as follows.

|    | LOW | MEDIUM | HIGH |
|----|-----|--------|------|
| path count | 0 to 2^20 | 20^20 to 2^80 | > 2^80 |
| nonlinear operations | 0 to 10 | 10 to 30 | > 30 |


(timeout_tac_reports)=
### Timeout TAC Reports

For each verification item there is a TAC graph linked in the verification report.
In case of a timeout this graph contains information one which parts of the program were part of the actual timeout, and which were already solved successfully.
It also contains statistics on the above-described timeout causes.

```{todo}
We will provide more detailed documentation on the TAC reports soon.
```

(timeout_prevention)=
# Timeout Prevention

Timeout prevention approaches fall into these categories.
1. Changing tool settings
2. Changing specs
3. Changing source code

Checking tool settings is least invasive and easy to do, so it is preferred. 
However, there are cases when parts of the input code that are very tricky need to be worked around.
Sometimes a combination of approaches is needed to resolve a timeout.


In the following we will discuss some concrete approaches to timeout prevention.
This collection will be extended over time based on user's experiences and tool improvements.
%At the start of each subsection we will give an intuition which kinds of timeous can be prevented by the strategy described in that subsection.


(modular_verification)=
### Modular verification

Especially for large code bases, but also for instance when there are parts with particularly high verification-complexity, it makes sense to modularize the verification process.
In this subsection we elaborate on modularization techniques that can help preventing timeouts.


#### "Sanity" Rules

For isolating the timeout reason, it can be useful to verify the code with respect to a trivial specification.
This, to some extent, rules out the specification as the source of complexity.

For documentation on sanity rules, see {ref}`sanity <built-in-sanity>` and {ref}`deep sanity <built-in-deep-sanity>`. 


(library_timeouts)=
#### Library-based systems

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


```{note}
The old documentation has a section on
{doc}`troubleshooting </docs/confluence/perplexed>` that addresses timeouts, which might complement the information given here.  
There is also some helpful information in the section on
{ref}`summarization <old-summary-example>`.
Some of the information in these references is out of date.
```

