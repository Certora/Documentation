# Storage in Call Trace

## Introduction

When exploring the counterexample to an assertion in a CVL (Certora Verification Language) specification, the Prover provides a Call Trace that includes information about the state of the contracts. This trace contains details about the storage values at the beginning of the rule and tracks updates to the storage during the execution of the contracts' functions.

### Example Storage Data

![Example Storage Data](storage-calltrace1.png)

## How Can the Storage Change?

While specific storage slots or fields can be assigned new values, it is also possible for the storage of the entire contract to revert to the previous state. This can occur due to the failure of a Solidity require statement, an explicit Solidity revert statement, the restoration of storage to a previously saved state in CVL (e.g., `func() at init`), or the application of havoc (invoking functions that havoc the state of contracts).

## When Do We Show the Storage State?

In the Call Trace section, the storage state is presented in three key places:

1. At the beginning of the execution.
2. Right after the failed assert.
3. After internal function calls.

The presentation of the storage state can be toggled on or off using a button highlighted in red, as shown below:

![Example Storage Toggle](storage-calltrace2.png)

## What Do We Show?

For each contract in the specification, the Call Trace displays all storage access paths instantiated with concrete indices (as determined by the counterexample) used during the execution trace.
The information provided for each access path includes:

- Source-code name
- Value (if known, represented as `*` if unknown)
- Computational type
- Whether it was changed since the previous time the storage was shown

## Computational Types

There are four computational types:

1. **Concrete:** The value of this variable is explicitly set in the spec or contract, making it the same in all counterexamples.
2. **Don't Care:** The value of this variable is not used before it is written, so its initial value is not relevant.
3. **Havoc:** The SMT solver chooses a random value.
4. **Havoc Dependent:** The value results from some computation involving another havoc or havoc-dependent variable. Unlike havoc variables, if the values of all havoc variables are known, this value can be calculated.

If the type cannot be determined, it is displayed as Unknown.

## Limitations of the Current "Computational Type" Resolution

The current resolution for "computational types" has limitations:

- Only assignments and storage changes (store, havoc, restore) are considered.
- Requires or values that cause revert are not considered in the type resolution.
- Strings or bytes keys of maps are not supported in the Call Trace display.


## Reverts

When a contract execution encounters an issue that violates a require statement or explicitly invokes a revert, the entire state changes may be reverted to the previous state. This is crucial for understanding and debugging issues in contracts.
The call trace provides a clear view of the revert reason and the path that caused the revert as present in the following picture.
![Example Revert](storage-calltrace3.png)

## Havocs

Havoc operations introduce non-determinism into the contract execution, allowing the SMT solver to choose a random value. Identifying and understanding havoc points in the Call Trace is essential for comprehending the unpredictable aspects of the contract's behavior.
Havoc values are displayed in the Call Trace like the following picture.
![Example Havoc](storage-calltrace4.png)

## Call Resolution

A Call Resolution is a representation that correlates the summarization called during the execution trace with the corresponding storage changes. This helps in understanding the flow of the contract execution and associating storage modifications with specific summarization calls.
The Call Resolution is displayed in the Call Trace like the following picture.
![Example Call Resolution](storage-calltrace5.png)