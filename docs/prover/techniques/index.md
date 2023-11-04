Techniques Used by Certora Prover
=================================

In this chapter, we describe some of the techniques used inside the Certora
Prover. While this knowledge not essential for using the prover, it can
sometimes be helpful when the prover does not behave as expected, for instance
in case of a prover timeout.

(control-flow-splitting)=
# Control Flow Splitting


```{note}
In addition to the text-form documentation below,  there is a brief explanation 
of control flow splitting in the 
[webinar on timeouts](https://www.youtube.com/watch?v=mntP0_EN-ZQ).
```


Control flow splitting (or short "splitting") is one of the techniques that
Certora Prover employs to speed up solving. In the remainder of this section, we
will give an overview of how the technique works. This background should be
helpful when using the settings described [here](control-flow-splitting-options)
to prevent prover timeouts.

Splitting is best illustrated using the {term}`control flow graph` (CFG) of a given
CVL rule.

A single splitting step proceeds as follows:
 - Pick a node with two successors in the CFG, the *split point*.
 - Generate two new CFGs, we call them *splits*; both splits are copies of the 
   original CFG, except that in the first (second) split, the edge to the first 
   (second) successor has been removed. The algorithm also removes all nodes and 
   edges that become unreachable through the initial edge removal.

```{figure} split-step.png
:name: single_split()
:alt: A single splitting step
:align: center
:height: 300px

Illustration of a single splitting step
```


There is an internal heuristic deciding which branching nodes to pick for each
single splitting step.

Certora prover applies these single splitting steps recursively as follows:

```{code-block}
:name: recursive splitting algorithm
:caption: "Recursive splitting algorithm as pseudo code"

Input: input_program_cfg

worklist = []
worklist.add([input_program_cfg, 0])

while (worklist != [])
    [cfg, current_depth] = worklist.pop()

    res = smt_check(cfg, get_timeout_for(current_depth))
    when (res) 
        [SAT, model] -> return [SAT, model]
        UNSAT -> continue
        TIMEOUT -> 
            if (current_depth == max_depth)
                return timeout
            else
                [split_1, split_2] = split_single(cfg)
                worklist.add([split_1, current_depth + 1])
                worklist.add([split_2, current_depth + 1])
return UNSAT
```

Intuitively, the the algorithm explores the tree of all possible recursive
splittings along a fixed sequence of split points up to the maximum splitting
depth. We call the splits at maximum splitting depth split leafs.

The main settings with which the user can influence these process are the
following (each links to a more detailed description of the option):

 - [Maximum split depth](-depth) controls the maximum recursion depth
 - [Smt timeout](--smt_timeout) controls the timeout that is applied at maximum
   recursion depth; if this is exceeded, the prover will give up with a TIMEOUT 
   result, unless [the corresponding setting](-dontStopAtFirstSplitTimeout) says 
   to go on.
 - [Medium timeout](-mediumTimeout) controls the timeout that is applied when
   checking splits that are not at the maximal recursion depth. 
 - Setting the [initial splitting depth](-smt_initialSplitDepth) to a level 
   above 0 will make the prover skip the checking and immediately enumerate all 
   splits up to that depth.


(storage-and-memory-analysis)=
# Storage and Memory Analysis

The Certora Prover works on EVM bytecode as its input. To the bytecode, the
address space of both Storage and Memory are flat number lines. That two
contract fields `x` and `y` don't share the same memory is an arithmetic
property. With more complex data structures like mappings, arrays, and structs,
this means that every
["non-aliasing"](https://en.wikipedia.org/wiki/Aliasing_(computing)) argument
requires reasoning about multiplications, additions, and hash functions. Certora
Prover models this reasoning correctly, but this naive low-level modeling can
quickly overwhelm SMT solvers. In order to handle storage efficiently, Certora
Prover analyses Storage (Memory) accesses in EVM code in order to understand the
Storage (Memory) layout, thus making information like "an update to mapping `x`
will never overwrite the scalar variable `y`" much more obvious to the SMT
solvers. For scaling SMT solving to larger programs, these simplifications are
essential.

