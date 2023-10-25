# Introduction

In the following, we will give a basic classification of timeouts, explain some
candidate causes for timeouts, and show ways to sometimes prevent them. We give
a glimpse into the more theoretical background of timeouts in program
verification in [this section](timeouts-theory.md)

We classify Certora Prover timeouts as follows:
1.  timeouts that happen before SMT solvers are running 
2.  timeouts where the SMT queries in sum lead to a global timeout
3.  timeouts where a single SMT query could not be solved 

Types 1. and 2. are signified by a hard stop of the Prover. That means the
Prover ran into the timeout of the cloud job, which is set at 2 hours, and was
forcefully shut down from everything it was doing (it is possible to lower that
timeout using the `--globalTimeout` flag). A message like "hard stop reached"
appears in the "Global problems" pane of the report, and error symbols next to
one or many rules.

% made CERT-3797 so we get a clear indication to the user, hopefully
% then, CVT should indicate via report-logs
%  - whether there was a hard stop
%  - whether SMT has started


Type 3. is signified by a soft stop. This means an SMT solver shut down due to
hitting the limit for a single SMT run (set via `--smt_timeout`). When running
with default settings this means that we give up for the individual rule since
in order to obtain a proof of correctness we need to solve every subproblem we
generate (see documentation on [control-flow splitting](control-flow-splitting)
for more details). 

In the remainder we will focus on the mitigation of SMT timeouts, i.e., types 2.
and 3. Non-SMT Timeouts (Type 1.) should be reported to Certora. 

(timeout_causes)=
# What causes timeouts?

As a first step towards resolving a timeout, we need to diagnose its root
causes. In our experience, the following are some of the most common
reasons for SMT timeouts:

 - non-trivial amount of nonlinear arithmetic
 - very high path count
 - high storage/memory complexity

This list is not exhaustive, but the majority of timeouts we have observed so
far can be traced back to one or more of these causes. While these are not the
only sources of complexity, they provide a good idea of the probable timeout 
causes. 
% For instance, linear arithmetic usually only becomes a problem when
% the input program is rather large, which is also indicated by path count in most
% practical cases.


## Complexity feedback from Certora Prover

Certora Prover provides some help with diagnosing timeouts. We present these
features in this section.

### Difficulty statistics

Certora Prover provides statistics on the problem sizes it encounters. 
These statistics are structured according to the timeout reasons given above.

Currently, the Prover tracks the following statistics:
 - nonlinear operations count
 - path count
 - memory/storage complexity measures

% For a very short summary we give one summarizing number for each of the
% statistics, along with a LOW/MEDIUM/HIGH statement. This occurs as an INFO
% message in the Global Problems pane of the Prover reports.

The exact classifications are made from experience with these statistics.
 - LOW: unlikely to be a reason for a timeout
 - MEDIUM: might be a reason for a timeout; the timeout might also be a result
   of the combined complexity with other measures
 - HIGH: likely to be a reason for a timeout, even if it is the only aspect of
   the verification problem that shows high complexity

These categories map to intervals as follows (for the memory/storage complexity, 
we are still collecting data).

|    | LOW | MEDIUM | HIGH |
|----|-----|--------|------|
| Path count | 0 to 2<sup>20</sup> | 20<sup>20</sup> to 2<sup>80</sup> | > 2<sup>80</sup> |
| Nonlinear operations | 0 to 10 | 10 to 30 | > 30 |
% TODO: memory/storage complexity, once we have a feeling for that

(timeout_tac_reports)=
### Timeout TAC reports

For each verification item, there is a TAC graph linked in the verification
report. In case of a timeout this graph contains information on which parts of
the program were part of the actual timeout, and which were already solved
successfully. It also contains statistics on the above-described timeout causes.

Find more documentation on TAC reports in general [here](tac-reports).

In the timeout case, the TAC reports contain some additional information that
should help with diagnosing the timeout.

(timeout_prevention)=
# Timeout prevention

Timeout prevention approaches fall into these categories.
1. changing tool settings
2. changing specs
3. changing source code

Changing tool settings is least invasive and easy to do, thus it is usually
preferable to the other options. However, there are cases when parts of the
input code that are very hard to reason about need to be worked around.
Sometimes a combination of approaches is needed to resolve a timeout.


In the following we will discuss some concrete approaches to timeout prevention.
This collection will be extended over time based on user's experiences and tool
improvements.

```{note}
The old documentation has a section on
{doc}`troubleshooting </docs/confluence/perplexed>` that addresses timeouts, 
which might complement the information given here.  
There is also some helpful information in the section on
{ref}`summarization <old-summary-example>`.
Some of the information in these references is out of date.
```

## Prover settings

In this subsection we list some option combinations that have helped preventing
timeouts in the past. We group the options by timeout causes they are most
relevant for. 

### Dealing with a high path count

The Certora Prover internally divides each verification condition into smaller
subproblems and attempts to solve them separately. This technique is called
*control flow splitting*. For a more detailed explanation of how control flow
splitting works, see [this page](control-flow-splitting).

We list a few option combinations that can help in various settings. There is
a tradeoff between spending time in different places: The Prover can either try
to spend much time at a low splitting level in the hope that no further
splitting will be needed, or it can split quickly in the hope that the
subproblems will be much easier to solve. The first variant ("lazy splitting")
is weak when the shallow splits are too hard, and time spent on them is wasted.
The second variant ("eager splitting") is weak when we end up with too many
subproblems; the number of splits is worst-case exponential in the splitting
depth.

When the relevant source code is very large, the shallow splits have a chance of
being too large for the solvers, thus eager splitting might help.

```
--prover_args "-smt_initialSplitDepth 5 -depth 15"
```

When there are very many subproblems that are of medium difficulty there is a
chance that the Prover has to split too often (not being able to "close" any
sub-splits). Then, a lazier splitting strategy could help. We achieve lazier
splitting by giving the solver more time to find a solution before we split a
problem.

```
--prover_args "-mediumTimeout 30 -depth 5"
```

It can also help to have splitting run in parallel (the splits are solved
sequentially by default).

```
--prover_args "-splitParallel true"
```

### Dealing with nonlinear arithmetic

Nonlinear integer arithmetic is in general the hardest part of the formula's
that Certora Prover is solving (being undecidable in general).

#### Running with Yices

A different choice of solver sometimes helps. The *Yices* SMT solver ([home
page](https://yices.csl.sri.com/)) is not used by default since it is not
compatible with our default hashing scheme. 

The following setting sets a hashing scheme that is compatible with Yices. Since
Yices is in the default portfolio, it is included automatically then.

```
--prover_args "-smt_hashingScheme plainInjectivity"
```

Optionally, we can further prioritize the usage of Yices by decreasing the size
of the solver portfolio. With the `-solvers` option set as follows, the Certora
Prover will run only CVC5 and Yices. Furthermore, we can make the Certora Prover
use the ordering given in the `-solvers` option for prioritizing solvers using
the `-smt_overrideSolvers` option.

```
--prover_args "-solvers [yices, cvc5] -smt_overrideSolvers true"
```


(modular_verification)=
## Modular verification

Especially for large code bases, but also for instance when there are parts with
particularly complex behavior, it helps to modularize the verification process.
In the following we elaborate on modularization techniques that can help
preventing timeouts.


### "Sanity" rules

For isolating the timeout reason, it can be useful to verify the code with
respect to a trivial specification. This, to some extent, rules out the
specification as the source of complexity.

Sanity rules are such trivial specifications. For documentation on them, see
{ref}`sanity <built-in-sanity>` and {ref}`deep sanity <built-in-deep-sanity>`. 


(library_timeouts)=
### Library-based systems

Some of the systems we have are based on multiple library contracts which
implement the business logic. They also forward storage updates to a single
external contract holding the storage.

In these systems, it’s sensible to split the verification so as each library is
operated on an individual basis.

If you encounter timeouts when trying to verify the main entry point contract to
the system, check the impact of the libraries on the verification by summarizing
all external library (delegate) calls as `NONDET`, using the option
`summarizeExtLibraryCallsAsNonDetPreLinking` as follows:

```
certoraRun ... --prover_args '-summarizeExtLibraryCallsAsNonDetPreLinking true'
```

```{note}
This option is only applied for _external_ library calls, or `delegatecall`s.
Internal calls are automatically inlined by the Solidity compiler and are 
subject to summarizations specified in the spec file's `methods` block.
```

Alternatively, if you wish to apply a "catch-all" summary for all the methods of
a specific library, you can write in the methods block of the spec:

```
methods {
    function MyBigLibrary._ external => NONDET;
    function MyBigLibrary._ internal => NONDET;
}
```

The above snippet has the effect of summarizing as `NONDET` all external calls
to the library and _internal_ ones as well. All summary types except ghost
summaries can be applied. 
For more information on method summaries, see [this page](method-summarization).

## Simplifying the source code 
% aka  Munging / Verifiable-Code-Antipatterns

Simplifying the source code of the program under verification can be a valuable last resort for obtaining useful verification results.
In the following, we describe some code patterns that have proven to be very difficult for the Prover and thus are good targets for code simplification.
Note that the occurrence of these patterns is not always a problem, so they should be looked at in conjunction with the difficulty statistics and generally a holistic view of the program under verification.

### Passing complex structs

A common culprit for high memory complexity are complex datastructures that are
passed from the specification to the program, or also inside the program.
Especially problematic are `struct` types that contain many dynamically-sized
arrays. 

% TODO: which calls exactly? external calls? all of them?

```cvl
rule myRule() {
    MyStruct x;
    foo(x);

}
```

```solidity
struct MyStruct {
    // several dynamically-sized arrays
    bytes b;
    string s;
    uint[] u1;
    uint8[] u2;
}

function foo(MyStruct x) public {
    ...
}
```

### Memory and Storage in Inline Assembly

% Shows through storage/memory analysis failures ("Global Problems" pane).

% Q: could we have "background" boxes or so -- indicating information that helps with a deeper understanding, but does only indirectly relate to using the tool -- just some place for rambling :-) 

```{note}
Background: The Certora Prover works on EVM bytecode as its input. To the
bytecode, the address space of both Storage and Memory are flat number lines.
That two contract fields `x` and `y` don't share the same memory is an
arithmetic property. With more complex data structures like mappings, arrays,
and structs, this means that every "non-aliasing" argument requires reasoning
about multiplications, additions, and hash functions. Certora Prover models this
reasoning correctly, but this naive low-level modeling can quickly overwhelm SMT
solvers. In order to handle storage efficiently, Certora Prover analyses Storage
(Memory) accesses in EVM code in order to understand the Storage (Memory)
layout, thus making information like "an update to mapping `x` will never
overwrite the scalar variable `y`" much more obvious to the SMT solvers. For
scaling SMT solving to larger programs, these simplifications are essential.
```

For the storage case, CVT reports these problems as Storage Analysis Failures.
So when there is a timeout, it can help to eliminate these failures by
summarizing the code that led to them (which will usually contain inline
assembly with `sload` and `sstore` commands). `mstore` and `mload` commands in
inline assembly may pose similar difficulties.

