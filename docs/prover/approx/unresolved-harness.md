(unresolved-harness)=
Unresolved Call Harness
=======================

The `CertoraUnresolvedHarness` feature redirects external calls that
would normally be {term}`havoced <havoc>` (because their target is
unresolved) to a user-provided Solidity contract.  This gives the user
full control over the behavior of unresolved calls, as an alternative
to the default {ref}`AUTO summary <auto-summary>` or to
{ref}`catch-unresolved-calls entries <catch-unresolved-calls-entry>`.

```{contents}
```

Overview
--------

When the Prover encounters an external call whose target contract is
unknown, it normally applies a {ref}`havoc summary <havoc-summary>`.
While sound, havoc summaries are coarse: they allow the called code to
do almost anything, which often leads to spurious counterexamples.

The `CertoraUnresolvedHarness` feature offers a more precise
alternative.  When enabled, the Prover redirects every unresolved
external `CALL` to a Solidity contract named
`CertoraUnresolvedHarness`.  Before invoking the harness's `fallback`
function, the Prover writes the original call context (callee address,
sender, calldata size, expected return size, ETH value, and gas) into
seven fixed storage slots in the harness. The user can then implement arbitrary
return-value logic in the fallback, and — crucially — can summarize the
harness's helper functions from CVL.

Note that if the goal is to implement purely dispatching logic to existing
contracts in the scene, it is recommended to use
{ref}`catch-unresolved-calls entries <catch-unresolved-calls-entry>`.
The unresolved harness supports more fine-grained logic, such as modeling
methods that do not exist in the scene in any implementing contract, or
calls to precompiled contracts that do not use the ABI convention.
An additional use case is handling of proxy calls.
Finally, by capturing the call in a Solidity contract, you can perform
memory and calldata lookups that are sometimes harder to express in CVL
alone.

Enabling the feature
--------------------

Add the flag to `prover_args` in your `.conf` file and include the
harness contract in the scene:

```json
{
    "files": ["MyContract.sol", "CertoraUnresolvedHarness.sol"],
    "verify": "MyContract:MySpec.spec",
    "prover_args": ["-useUnresolvedHarness true"]
}
```

The harness contract **must** be named exactly
`CertoraUnresolvedHarness` and **must** appear in the `files` list.
See {ref}`-useUnresolvedHarness` for the CLI reference.
We provide a template in the next sections.

Storage slot layout
-------------------

The Prover writes the following values to the harness's storage
**before** invoking the fallback.  All seven slots must be declared as
public storage variables in exactly this order:

| Slot | Type      | Name             | Description                                       |
|------|-----------|------------------|---------------------------------------------------|
| 0    | `address` | `originalCallee` | The address the caller was trying to reach        |
| 1    | `address` | `callersSender`  | `msg.sender` of the context performing the call   |
| 2    | `address` | `executingAddr`  | The contract executing the call instruction       |
| 3    | `uint256` | `inSize`         | Size of the call's input data (calldata) in bytes |
| 4    | `uint256` | `outSize`        | Expected return-data size in bytes                |
| 5    | `uint256` | `callValue`      | ETH value sent with the call                      |
| 6    | `uint256` | `callGas`        | Gas forwarded to the call                         |

```{warning}
The slot positions are determined by declaration order in Solidity.
All seven variables must be the **first** seven storage declarations in
the contract, in the order shown above.  Additional storage variables
may be added after them.
```

```{warning}
These storage variables behave like non-persistent ghosts: if the
harness reverts, their values revert as well.  More importantly, if the
harness itself triggers another unresolved call (e.g. by calling an
unresolved contract that is in turn redirected back to the harness),
the seven slots are **overwritten** with the new call's context.  The
outer call frame will then see the new values, not the original ones.
This can be worked around by copying the slot values into local
(memory) variables before making any calls that might re-enter the
harness.
```

Template harness contract
-------------------------

The following contract can be used as a starting point:

```solidity
pragma solidity ^0.8.0;

contract CertoraUnresolvedHarness {
    // === Prover-written storage slots (must be first, in order) ===
    address public originalCallee;      // slot 0
    address public callersSender;       // slot 1
    address public executingAddr;       // slot 2
    uint256 public inSize;              // slot 3
    uint256 public outSize;             // slot 4
    uint256 public callValue;           // slot 5
    uint256 public callGas;             // slot 6

    // further fields can be customized

    // === Example optional external helpers (summarizable in CVL) ===

    // Single uint256 return
    function getResult(bytes4 selector)
        external returns (uint256)
    {
        return 42;
    }

    // Two-element return: (bool, uint256)
    function getResultPair()
        external returns (bool, uint256)
    {
        return (true, 42);
    }

    // === Fallback ===

    fallback() external payable {
        // how to extract the selector
        bytes4 selector;
        if (msg.data.length >= 4) {
            selector = bytes4(msg.data[:4]);
        }

        // example: modeling based on assumed expected output
        if (outSize == 64) {
            // Two-element return
            // use `this.` to allow summarizing `getResultPair` as an external function in CVL
            (bool flag, uint256 val) = this.getResultPair(); 
            bytes memory ret = abi.encode(flag, val);
            assembly { return(add(ret, 0x20), mload(ret)) }
        } else if (inSize == 0 && outSize == 0) {
            // Truly no-op call — return nothing
        } else {
            // Default: single uint256 return
            uint256 result = this.getResult(selector);
            bytes memory ret = abi.encode(result);
            assembly { return(add(ret, 0x20), mload(ret)) }
        }
        // returning values must use `abi.encode` and the assembly block using `return` opcode
    }
}
```

```{note}
To return values from the fallback, use `abi.encode` to construct the
return buffer and the `return` opcode via inline assembly.  A regular
Solidity `return` statement does not work in a fallback that needs to
return arbitrary bytes.
```

### Example usage in this template

1. **External helper functions** — `getResult` and `getResultPair`
   make external calls to `this`, so they appear as separate external methods
   that can be {ref}`summarized <summaries>` in CVL.  By invoking them, the fallback
   delegates to these helpers, letting you control return values from
   your spec.

2. **Branching on `outSize`** — the Prover writes `outSize` of the original call
   to storage slot 4 (`outSize` field)
   before the fallback runs, so the fallback can return the correct
   number of bytes for different call sites.

3. **The `selector` variable** — extracted from `msg.data` and passed
   to `getResult`, allowing CVL summaries to differentiate behavior
   based on which function was originally called.

CVL specification example
-------------------------

```cvl
using CertoraUnresolvedHarness as harness;

methods {
    // Declare harness slot getters as envfree
    function harness.originalCallee()
        external returns (address) envfree;
    function harness.callersSender()
        external returns (address) envfree;
    function harness.executingAddr()
        external returns (address) envfree;
    function harness.inSize()
        external returns (uint256) envfree;
    function harness.outSize()
        external returns (uint256) envfree;
    function harness.callValue()
        external returns (uint256) envfree;
    function harness.callGas()
        external returns (uint256) envfree;

    // Summarize the helper — or leave unsummarized for the
    // concrete value (42)
    // function harness.getResult(bytes4)
    //     external returns (uint256) => NONDET;
}

rule checkCalleeIsRecorded {
    env e;
    address t;
    require t != 0;
    myFunction(e, t); // calls a single unresolved method with target `t`
    assert harness.originalCallee() == t; // harness captures the target `t` 
}
```

Interaction with CALL opcode hooks
-----------------------------------

When the feature is active, redirected calls are still executed as
`CALL` opcodes, so they trigger {ref}`CALL hooks <call-hooks>`.
In addition, the harness fallback may itself issue `CALL`s to its own
helpers (e.g. `this.getResult()`).

If you use {ref}`CALL hooks <call-hooks>`, you may want to
filter out the harness's own calls.  Use the
{ref}`executingContract <executingContract>` special variable:

```cvl
using CertoraUnresolvedHarness as harness;

persistent ghost mathint redirectedCallCount {
    init_state axiom redirectedCallCount == 0;
}

hook CALL(uint g, address addr, uint value,
          uint argsOffset, uint argsLength,
          uint retOffset, uint retLength) uint rc {
    if (executingContract != harness) {
        // Only fires for calls originating outside the harness
        redirectedCallCount = redirectedCallCount + 1;
    }
}
```

Limitations
-----------

```{caution}
- **Delegate calls** (`DELEGATECALL`, `CALLCODE`) are **not**
  redirected; they continue to receive
  {ref}`havoc summaries <havoc-summary>`.
- **Explicit CVL summaries take priority** — if you have a matching
  summary in your `methods` block, it is used instead of the harness
  redirect.
- The harness contract **must** have a `fallback` function; the Prover
  resolves unresolved calls to this function.
```
