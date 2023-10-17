Managing Timeouts
=================

```{toctree}
:maxdepth: 2

timeouts-theory.md
```

Timeouts of the Certora Prover are an unpleasant reality. In this chapter we
present a practical guide to diagnosing the causes of timeouts and ways to
prevent them. 
% This page elaborates on the theoretical background of timeouts in a program 
% verification tool.  


# Introduction

We start with a rough classification of Certora Prover timeouts:
1.  Timeouts that happen before SMT solvers are running 
2.  Timeouts where the SMT queries *in sum* lead to a "global timeout" 
3.  Timeouts where a single SMT query could not be solved 

Types 1. and 2. are signified by a hard stop of the prover. That means the
prover ran until the global timeout (set via `--globalTimeout`, typically 2
hours) and was forcefully shut down from everything it was doing. A message like
"hard stop reached" appears in the "Global problems" pane of the report, and
error symbols next to one or many rules.

% which symbols? red exclamation mark, also "killed" symbol?
% made CERT-3797 so we get a clear indication to the user, hopefully

Type 3. is signified by a soft stop. This means an smt solver shut down due to
hitting the limit for a single smt run (set via `--smt_timeout`). When running
with default settings this means that we give up for the individual rule since
in order to obtain a proof of correctness we need to solve every subproblem we
generate (see documentation on splitting for more details). 

% TODO link to splitting doc
%Usually the run will have finished in less than two hours, and it will show the timeout sign (a yellow clock symbol) for individual rules.
% a little pic would be nice

% TODO: we should indicate which it is. -- can kind of be seen from from hard stop -- can be seen from whether there's a report. --> still need differentiation between suffocating on splits or not

In the remainder we will focus on the mitigation of SMT timeouts, i.e., types 2.
and 3.

```{note}
Timeouts that are not SMT timeouts should be reported to Certora. 
Typically, they will either require developer effort, or significant 
limitations of the input.
```

For some more general background on SMT timeouts, please see 
[this page](timeouts-theory.md).

(timeout_causes)=
# What Causes Timeouts?

As a first step towards resolving a timeout, we need to diagnose its root
causes. In our experience so far, the following are some of the most common
reasons for SMT timeouts.

 - Non-trivival amount of onlinear arithmetic
 - Very high path count
 - High storage/memory complexity

This list is not exhaustive by any means, but the majority of timeouts we have
observed so far can be traced back to one or more of these causes. Note that
these are not the only sources of complexity; however, for instance linear
arithmetic usually only becomes a problem when the input program is rather
large, of which the path count is a good indication.

## Intuitions on Kinds of Complexity

In the section on the [theoretical background of verification
timeouts](timeouts-theory.md) we gave a few details on SMT solver architecture.
We can use the parts of the SMT solver for some intuition on different kinds of
complexity explosions.

| Difficulty         | Solver parts  |
|--------------------|---------------|
| Path count         |  SAT          |
| Storage/memory     |  SAT          |
| Arithmetic         |  LIA / NIA    |
% | bitwise operations |  SAT, UF, LIA |

Since control flow is encoded into Boolean logic by the Certora Prover, it
weighs most heavily on the SAT-solving part of the SMT solver. Storage or Memory
accesses lead to case splits, which are also Boolean in nature. On the other
hand, arithmetic is resolved by specialized solvers; different algorithms are
required for the linear and the nonlinear cases.

% Note that this list of reasons is a result of experience as much as theoretical considerations, so it might be extended and refined in the future.

## Complexity Feedback from Certora Prover


#### Difficulty Statistics

Certora Prover provides statistics on the problem sizes it encounters. 
These statistics are structured according to the timeout reasons given above.

Currently, the Prover tracks the following statistics:
 - Path count
 - Nonlinear operations count
 - Memory/storage complexity
 - Bitwise operation complexity (under construction)


#### Immediate feedback, "HIGH, MED, LOW"

For a very short summary we give a LOW/MEDIUM/HIGH statement for some of the
statistics. This occurs as an INFO message in the Global Problems pane of the
Prover reports.

The exact classifications are made from experience with these statistics.
 - LOW: unlikely to be a reason for a timeout
 - MEDIUM: might be a reason for a timeout, the timeout might also be a result
   of the combined complexity with other measures
 - HIGH: likely to be a reason for a timeout, even if it is the only aspect of
   the verification problem that shows high complexity

As of October 2023 these categories map to intervals as follows.

|    | LOW | MEDIUM | HIGH |
|----|-----|--------|------|
| Path count | 0 to 2^20 | 20^20 to 2^80 | > 2^80 |
| Nonlinear operations | 0 to 10 | 10 to 30 | > 30 |

(timeout_tac_reports)=
### Timeout TAC Reports

For each verification item, there is a TAC graph linked in the verification
report. In case of a timeout this graph contains information one which parts of
the program were part of the actual timeout, and which were already solved
successfully. It also contains statistics on the above-described timeout causes.

Find more documentation on tac reports in general [here](tac-reports).

In the timeout case, the tac reports contain some additional information that
should help with diagnosing the timeout.

#### Statistics- and Explanation-Box

#### Split- and Heuristical Difficulty-Coloring

#### TAC Source Code Box

(timeout_prevention)=
# Timeout Prevention

Timeout prevention approaches fall into these categories.
1. Changing tool settings
2. Changing specs
3. Changing source code

Checking tool settings is least invasive and easy to do, so it is preferred.
However, there are cases when parts of the input code that are very tricky need
to be worked around. Sometimes a combination of approaches is needed to resolve
a timeout.


In the following we will discuss some concrete approaches to timeout prevention.
This collection will be extended over time based on user's experiences and tool
improvements.

%At the start of each subsection we will give an intuition which kinds of timeous can be prevented by the strategy described in that subsection.

```{note}
The old documentation has a section on
{doc}`troubleshooting </docs/confluence/perplexed>` that addresses timeouts, 
which might complement the information given here.  
There is also some helpful information in the section on
{ref}`summarization <old-summary-example>`.
Some of the information in these references is out of date.
```

## Prover Settings

In this subsection we list some option combinations that have helped preventing
timeouts in the past. We group the options by timeout causes they are most
relevant for. 

### Dealing With a High Path Count

The Certora Prover internally divides each verification condition into smaller
subproblems and attempts to solve them separately. This technique is called
*control flow splitting*. For a more detailed explanation of how control flow
splitting works, see [this page](control-flow-splitting).

We list a few option combinations that can help in different settings. There is
a tradeoff of where time is spent: The Prover can either try to spend much time
at a low splitting level in the hope that no further splitting will be needed,
or it can split quickly in the hope that the subproblems will be much easier to
solve. The first variant ("lazy splitting") is weak when the shallow splits are
too hard, and time spent on them is wasted. The second variant ("eager
splitting") is weak when we end up with too many subproblems; the number of
splits is worst-case exponential in the splitting depth.

When the relevant source code is very large, the shallow splits have a chance of
being too large for the solvers, thus eager splitting might help.

```
--prover_args "-smt_initialSplitDepth 5 -depth 15"
```

When there are very many subproblems that are of medium difficulty there is a
chance that the prover has to split too often (not being able to "close" any
subsplits). Then, a lazier splitting strategy could help. We achieve lazier
splitting by giving the solver more time to find a solution before we split a
problem.

```
--prover_args "-mediumTimeout 30 -depth 5"
```

It can also help to have splitting run in parallel; this goes together with
choosing a smaller solver portfolio, so the available cores can be used for
different splits, rather than different solvers.

```
--prover_args "-smt_splitParallel true -solvers [z3:def,cvc5:def]"
```

### Dealing With Nonlinear Arithmetic

Nonlinear integer arithmetic is in general the hardest part of the formula's
that Certora Prover is solving (being undecidable in general).

#### Running with Yices

A different choice of solver sometimes helps. The *Yices* smt solver ([home
page](https://yices.csl.sri.com/)) is not used by default since it is not
compatible with our default hashing scheme. 

The following setting sets a hashing scheme that is compatible with Yices. Since
Yices is in the default portfolio, it is included automatically then.

```
--prover_args "-smt_hashingScheme plainInjectivity"
```

Optionally, we can further prioritize the usage of Yices by decreasing the size
of the solver portfolio. With the `-solvers` option set as follows, Certora
Prover will run only CVC5 and Yices. Furthermore, we can make Certora prover use
the ordering given in the `-solvers` option for prioritizing solvers using the
`-smt_overrideSolvers` option.

```
--prover_args "-solvers [yices, cvc5] -smt_overrideSolvers true"
```


(modular_verification)=
## Modular verification

Especially for large code bases, but also for instance when there are parts with
particularly complex behavior, it helps to modularize the verification process.
In the following we elaborate on modularization techniques that can help
preventing timeouts.


### "Sanity" Rules

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

## Simplifying the Source Code 
% aka  Munging / Verifiable-Code-Antipatterns

Simplifying the source code of the program under verification can be a valuable last resort for obtaining useful verification results.
In the following, we describe some code patterns that have proven to be very difficult for the Prover and thus are good targets for code simplification.
Note that the occurrence of these patterns is not always a problem, so they should be looked at in conjunction with the difficulty statistics and generally a holistic view of the program under verification.

### Passing Complex Structs

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
    // several dynamically-size arrays
    bytes b1;
    bytes b2;
    uint[] u1;
    uint8[] u2;
}

function foo(MyStruct x) public {
    ...
}
```

### Memory and Storage in Inline Assembly

% In particular sload/mload/sstore/mstore.

% Shows through storage/memory analysis failures ("Global Problems" pane).

% Q: could we have "background" boxes or so -- indicating information that helps with a deeper understanding, but does only indirectly relate to using the tool

Background: The Certora Prover works on EVM bytecode as its input. To the
bytecode, the address space of both Storage and Memory are flat number lines.
That two contract fields `x` and `y` don't share the same memory an arithmetic
property. With more complex data structures like mappings, arrays, and structs,
this means that every "non-aliasing" argument requires reasoning about
multiplications, additions, and hash functions. Certora Prover models this
reasoning correctly, but this naive low-level modelling can quickly overwhelm
SMT solvers. In order to handle storage efficiently, Certora Prover analyses
Storage (Memory) accesses in EVM code in order to understand the Storage
(Memory) layout, thus making information like "an update to mapping `x` will
never overwrite the scalar variable `y`" much more obvious to the SMT solvers.
For scaling SMT solving to larger programs, these simplifications are essential.

For the storage case, CVT reports these problems as Storage Analysis Failures.
So when there is a timeout, it can help to eliminate these failures by
summarizing the code that led to them (which will usually contain inline
assembly with `sload` and `sstore` commands).

% TODO memory case ?..

% this means that inline assembly using the `sload`/`mload`/`sstore`/`mstore` opcodes is a potential culprit for timeouts.

% The following example snippet shows inline assembly being used to make up a custom storage layout.
% 
% ```solidity
%         // ...
%         assembly {
%             // ...
%             mstore(0x00, id)
%             mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, caller()))
%             let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
%             let ownershipPacked := sload(ownershipSlot)
%             // ...
%         }
% ```
%source https://github.com/Vectorized/solady/blob/main/src/tokens/ERC721.sol
