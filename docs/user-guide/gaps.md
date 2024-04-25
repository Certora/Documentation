Understanding gaps between high and low level code
===================================================

The Certora Prover is analyzing low-level code, such as the EVM bytecode.
However, the CVL specification as well as the Rule Report and Call Trace are 
usually presenting information in terms of the high-level language (e.g., Solidity).

In this document we describe how some of the gaps between the high-level source
and the low-level bytecode can affect our understanding of the Prover's outputs,
and recommended solutions.

## Loops

### Determining the number of needed iterations

The Prover deals with loops by unrolling them a constant number of times 
(see {ref}`--loop_iter`).
Furthermore, it can add an assertion that the number of unrolled iterations
was sufficient to fully capture all of the loop's behavior, which is usually useful
in loops that are known to have a constant number of iterations.
Otherwise, the user can opt-in to assume the unroll bound was sufficient
(see {ref}`--optimistic_loop`).

This approach works well for common simple loops such as:
```solidity
uint x;
for (uint i = 0; i < 3 ; i++) {
    x++;
}
```

```{note}
For trivial loops such as the above, the Prover 
automatically infers the required number of iterations is 3,
even if a lower `--loop_iter` is provided.
```

The natural loop condition determining whether we enter the body of the loop or exit
is clearly `i < 3`, thus 3 iterations are sufficient to fully unroll the loop and render
the loop condition false.
If `--loop_iter 3` is defined, the Prover unrolls the loop 3 times,
and evaluates the loop exit condition one more time (a total of 4 evaluations of the loop exit condition).
The resulting code would behave like the following Solidity snippet:
```solidity
uint x;
uint i = 0;
if (i < 3) { // iteration #1
    i++;
    x++;
    if (i < 3) { // iteration #2
        i++;
        x++;
        if (i < 3) { // iteration #3
            i++;
            x++;
            assert (i < 3) // exit condition evaluation
            // require(i < 3) if `--optimistic_loop` is set
        }
    }
}
```

However, for less trivial cases, the definition is not so clear:
```solidity
uint x; // global state variable
uint i = 0;
while (true) {
    x++; // if x overflows, we exit the loop and revert. But is this the loop condition?
    if (i >= 3) {
        break;
    }
    i += 1;
}
```

Running the builtin sanity rule for the above code with `--loop_iter` of 2 or less
results in sanity violation (can find no paths reaching the end of the loop), 
as is expected.
Sanity is passing with `--loop_iter 3`.

However, running with `--loop_iter 3` actually shows 4 loop iterations
in the Call Trace output. 
The reason for that is that in cases the Prover cannot detect an exit condition
in the loop's head, it unrolls one extra time to evaluate a potential exit condition 
in the loop's body.
In our case, the bytecode representation shows that the loop's head is ending with
a non-conditional jump.
The equivalent Solidity-like version of the unrolled code would look as follows, 
(`c`-style `goto` and `label` commands were added for clarity):
```solidity
uint x; // global state variable
uint i = 0;
// iteration #1
x++;
if (i >= 3) {
    goto after_original_while_loop_end;
}
i += 1;

// iteration #2
x++;
if (i >= 3) {
    goto after_original_while_loop_end;
}
i += 1;

// iteration #3
x++;
if (i >= 3) {
    goto after_original_while_loop_end;
}
i += 1;

// iteration #4
x++;
if (i >= 3) {
    goto after_original_while_loop_end;
}
i += 1;

assert(false); // require(false) if `--optimistic_loop` is set

after_original_while_loop_end: ...
```
