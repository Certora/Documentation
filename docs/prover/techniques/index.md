Techniques Used by Certora Prover
=================================

In this chapter we describe techniques used by the Certora Prover whose
understanding can be relevant for an expert usage of the Prover.

(control-flow-splitting)=
# Control Flow Splitting

Control flow splitting (or short "splitting") is one of the techniques that 
Certora Prover employs to speed up solving. It is best illustrated using the
*control flow graph* (CFG) of a given CVL rule.
% TODO: link to glossary somehow?

A single splitting step proceeds as follows:
 - pick a node with two successors in the CFG
 - generate two new CFGs; in the first (second) CFG, the edge to the first 
   (second) successor has been removed, also remove all nodes that become 
   unreachable through the edge removal

The following picture illustrates a single splitting step.

The splitting algorithm then splits recursively according to the `-mediumTimeout` and `-timemout` (short `-t`) settings.

 - check CFG with timeout `depth < -depth ? -mediumTimeout : -t`
   - if SAT: done
   - if UNSAT: if this was the last sub-CFG: terminate prover with UNSAT, otherwise wait for other sub-CFGs
   - if TIMEOUT
    - if depth > `-depth`: terminate prover with "TIMEOUT" result
    - else: split CFG, check the resulting sub-CFGs

Which branching nodes to pick for the next split is decided by a heuristic.

Settings
% TODO does this belong here? or is there a settings section?

The behavior of the splitting component of Certora Prover can be influenced through the following settings.

The maximum splitting depth can be set by the following setting.

```
--prover_args "-depth <seconds>"
```

The "medium timeout" determines how much time is given to checking a split at not 
max-depth before we split again.

```
--prover_args "-mediumTimeout <seconds>"
```

The regular SMT timeout determines how much time is maximally spent on checking a split on the maximum depth.
When this is exceeded, Certora Prover will return "TIMEMOUT", unless `-dontStopAtFirstSplitTimeout` is set.

```
-smt_timeout <seconds>
```

We can tell the Certora Prover to not stop when the first split has had a 
maximum-depth timeout. Note that this is only useful for SAT results, since 
for an overall UNSAT results, all splits need to be UNSAT, while for a SAT 
result it is enough that one split is UNSAT.

% TODO: talk about SAT / UNSAT -- violated/not-violated won't due it due to `satisfy`...

```
--prover_args "-dontStopAtFirstSplitTimeout <true/false>"
```

The splitting can be configured to skip the checks at low splitting levels, thus
generating sub-splits up to a given depth immediately. Note that the number of
splits generated here is equal to `2^n` where `n` is the initial splitting depth
(unless the program has less than `n` branchings, which will be rare in
practice).


```
--prover_args "-smt_initialSplitDepth <number>"
```