# How Ranger Works

**Ranger** is a bounded model checker. This means that, in contrast with "full"
formal verification, its initial state isn't arbitrary, but is instead reached
by a sequence of legal function calls.

(the-initial-state)=
## The Initial State

Ranger starts by initializing all storage to 0, assuming all ghosts'
`init_state` {ref}`axioms <ghost-axioms>`, and then calling the constructors
of all the contracts in the {term}`scene`. Additionally, if the .spec file has a
`function setup()` declared then it will run right after the constructors.

## Sequences

In Ranger's terminology, a sequence refers to setting the
{ref}`initial state <the-initial-state>` followed by a series of contract
function calls. The depth or range of a sequence is the number of functions the
sequence calls. Note that a sequence can call the same function twice, and they
are counted as two distinct calls.

## Ranger's flow

When a Ranger job starts, for each rule/invariant that's to be run it does the
following:

1. Verify that the initial state rule/invariant holds right after the
{ref}`initial state <the-initial-state>` (it could also hold vacuously, that's
fine in this case).
2. For each range `1 <= i <= N` (`N` is determined by the {ref}`--range`
option), create a sequence of `i` functions from the scene (could be from any
contract and could have duplicates), then call them providing each function with
independent and arbitrary input. Finally, call the rule/invariant and check that
it holds.
    * In the invariant case, before each function call we insert an assumption
    that the invariant is true. This is done for optimization reasons.

For each sequence `f_1 -> ... -> f_n` we first check the subsequence
`f_1 -> ... -> f_n-1` and only if it verifies will we continue to check the
longer sequence. This promises that if a violation is found it is the shortest
sequence with these functions that violates the rule/invariant.

```{note}
While in principle for a provided range N there are \sum_{i=0}^N a_i sequences,
in practice Ranger has several optimizations that prune a significant portion of
these sequences.
```
