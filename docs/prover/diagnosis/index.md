Diagnostic Tools in the Certora Prover
======================================


(tac-reports)=
# TAC Reports

% TODO: writing "verification condition" should write "rule", or what?..

TAC Reports provide an under-the-hood view on a given verification condition as
well as the result that the prover produced for that verification conditon, if
available. There are four variants of TAC reports, one each for the results SAT,
UNSAT, TIMEOUT, and one contains no information from the result. In the
following, we will discuss these variants one by one. We'll begin with the TAC
report without prover result information, since its constituents are present in
the other variants as well.

## Plain TAC reports

![Example of a plain TAC report](rebase-tac-report-plain-annotated.png)

At the center of a TAC report is a visualization of the verification condition's
{term}`control flow graph` (CFG).[^nested-cfg] There are two kinds of nodes.
Regular nodes and call nodes. Regular nodes have a solid outline, while call
nodes have a dashed outline. Clicking on a regular nodes will made the source
code box (discussed below) focus on the corresponding source code; clicking on a
call node will replace the currently displayed CFG with the CFG that belongs to
the called method. 

```{note}
Only external calls are explicit in the TAC report's CFGs. Internal calls are 
inlined on the TAC source code level.
```

[^nested-cfg]: Strictly speaking, there is a set of CFGs available for each
    verification condition. Every external call has its own CFG, and the CFGs
    are related by call nodes which lead from a call site to the corresponding
    callee's CFG. Intuitively, this set can be viewed as one CFG with nested 
    sub-CFGs for the calls.

The upper-mid left part of a TAC report contains the source code box.



### TAC source code box

## SAT TAC reports


## UNSAT TAC reports

```{todo}
This section still needs to be written.
```

## Timeout TAC reports

### Statistics- and explanation-box

### Split- and heuristical difficulty-coloring

### TAC source code box


```{todo}
This section still needs to be written.
There is a brief explanation of how to use TAC reports in the 
[webinar on timeouts](https://www.youtube.com/watch?v=mntP0_EN-ZQ).
```
