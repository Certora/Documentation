---
description: >-
  A drill-down into basic function summarization capabilities in the Certora
  Prover.
---

# Function Summarization

## Summarizing Solidity Functions

Contracts often interact with other contracts, and by default these interactions are abstracted away by the tool. Roughly, this means the Prover tool assumes any outcome is possible.

This document details the exact behavior of the Prover in different scenarios, and how these can be controlled in the specification.

### Calls inside the specification

Calls inside the specification are always inlined. They must refer either to the default contract \(i.e., the one that the user indicated to be verified\) or to one of the imported contracts.

```text
using OtherContractInstance as otherContractInstance

rule callFun {
    uint x = fun1(); // inline fun1 of currentContract
    uint y = currentContract.fun1(); // same as above
    uint z = otherContractInstance.fun1(); // inline fun1 of otherContractInstance
}
```

### Calls inside the code

A call to an external contract that was not _linked_ is abstracted. It means certain variables can be set to arbitrary values following this call. We often refer to this call as being _havoc'd_ and we use the same term for variables set to arbitrary values. For a havoc'd call:

* The return values \(`returndata`\) can take any value
* The return code of the call can take any value
* The state of the calling contract \(`this`\) may or may not become havoc'd.
* The balances may become havoc'd in full or in part.

A method declaration in the spec file can be associated with a _summary_ that tells the prover how to handle a call to a non-linked external contract. Currently, the available summaries are `HAVOC_ALL`,`HAVOC_ECF`,`ALWAYS(n)`,`CONSTANT`, `PER_CALLEE_CONSTANT`, `NONDET`, `AUTO`, and `DISPATCHER`. The below table shows the differences between these summaries. Asterisks \(\*\) indicate havocing.

| Summary | Return value | Return code | Current contract state | Other contracts states | Balances |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `HAVOC_ALL` | \* | \* | \* | \* | \* |
| `HAVOC_ECF` | \* | \* | Unchanged | \* | Havoc'd except for current contract's balance that may increase |
| `ALWAYS(n)` | n | success \(1\) | Unchanged | Unchanged | Unchanged |
| `CONSTANT` | Some constant `x` for all calls to the same method signature in any target contract | success \(1\) | Unchanged | Unchanged | Unchanged |
| `PER_CALLEE_CONSTANT` | Every target contract `c` will return the same constant `x_c` for all calls to the same method signature | success \(1\) | Unchanged | Unchanged | Unchanged |
| `DISPATCHER[(bool)]` | See below | See below | See below | See below | See below |
| `NONDET` | \* | success\(1\) | Unchanged | Unchanged | Unchanged \(up to current transfer\) |
| `AUTO` | \* | \* | Depends on call type\* | Depends on call type\* | Depends on call type\* |

The _`DISPATCHER` summary_ handles each call to the declared method as if any method with the same signature in any target contract may be called. By default, in addition to calls to implementations in known target contracts, the `DISPATCHER`has a havoc'd call to an unknown, untrusted target contract. This havoc'd call is handled the same as in the `AUTO` summary \(see below\).

One can override the default mode of the`DISPATCHER` by enabling an _optimistic_ mode. This mode assumes that only known contracts may be called. It is enabled by specifying `DISPATCHER(true)`. Note that either `DISPATCHER(false)`or `DISPATCHER` denote that the default mode is enabled.

The `AUTO` summary depends on the type of call, namely, the EVM opcode used by the call. Static calls \(`STATICCALL`\) don't havoc any contract's state. Regular calls and contract creations \(`CALL`,`CREATE`\) havoc all contracts' state except for the current contract's \(like `HAVOC_ECF`\). Library calls \(`DELEGATECALL` and `CALLCODE`\) havoc _only_ the current contract's state.

Some of the summaries change the balances. While the `HAVOC_ALL` summary fully havocs the balances of the current contract and the target contract, other balance changing summaries partially havoc these balances as follows:

* The current contract's balance `x` will first be decreased by the transferred amount `t`. Then, the balance will be havoc'd to be at least `x-t`, i.e., in the end, it may not decrease by more than the transferred amount.
* The target contract's balance will be incremented by exactly the transferred amount.

{% hint style="info" %}
If the contract you are verifying relies heavily on modification of ETH balances, it's recommended to identify the balance-modifying functions and mark them `HAVOC_ALL` if necessary.
{% endhint %}

A technical remark about `returnsize`: For `CONSTANT` and `PER_CALLEE` summaries, the summaries extend naturally to functions that return multiple return values, where the assumption is that the return size in bytes is a multiple of 32 bytes \(as standard in Solidity\). The `returnsize` variable is updated accordingly and is determined by the size requested by the caller. 

{% hint style="info" %}
If you do not trust the target contract to return exactly the number of arguments dictated by the Solidity-level interface, **do not use**`CONSTANT` and `PER_CALLEE_CONSTANT`summaries. 
{% endhint %}

In very special cases, one may set the `returnsize` optimistically even when havocing, based on information about the invoked function's signature and the available functions in the verification context, set with `-optimisticReturnsize`.

We present simple examples to illustrate the differences between the non-havocing summaries. We use a simple interface `IntGetter` that we will not assume anything about:

```text
interface IntGetter {
    function get() external returns (uint)
    function get2() external returns (uint)
}
```

`ALWAYS` summary:

```text
// code
contract CallsExternalContracts {
    IntGetter g1;
    IntGetter g2;
    
    function getFromG() external returns (uint) { return g.get(); }
    function getFromG2() external returns (uint) { return g.get2(); }
}

// spec
methods {
    get() => ALWAYS(7)
    getFromG() returns (uint256) envfree
    getFromG2() returns (uint256) envfree
}

rule check {
    assert getFromG() == 7; // Should be verified
    assert getFromG2() == 7; // Should be violated
}
```

`ALWAYS` vs. `CONSTANT`:

```text
// code
contract CallsExternalContracts {
    IntGetter g1;
    IntGetter g2;
    
    function getFromG() external returns (uint) { return g.get(); }
    function getFromG2() external returns (uint) { return g.get2(); }
}

// spec
methods {
    get() => ALWAYS(7)
    get2() => CONSTANT
    getFromG() returns (uint256) envfree
    getFromG2() returns (uint256) envfree
}

rule check {
    assert getFromG() == 7; // Should be verified
    assert getFromG2() == getFromG(); // Should be violated
}
```

`CONSTANT` vs. `NONDET`:

```text
// code
contract CallsExternalContracts {
    IntGetter g1;
    IntGetter g2;
    
    function getFromG() external returns (uint) { return g.get(); }
    function getFromG2() external returns (uint) { return g.get2(); }
}

// spec
methods {
    get() => CONSTANT
    get2() => NONDET
    getFromG() returns (uint256) envfree
    getFromG2() returns (uint256) envfree
}

rule check {
    assert getFromG() == getFromG(); // Should be verified - two calls return the same value
    assert getFromG2() == getFromG2(); // Should be violated - two calls may return different values
}
```

How `PER_CALLEE_CONSTANT` works:

```text
// code
contract CallsExternalContracts {
    IntGetter g1;
    IntGetter g2;
    
    function getFromG() external returns (uint) { return g.get(); }
    function getFromG2() external returns (uint) { return g2.get(); }
}

// spec
methods {
    get() => PER_CALLEE_CONSTANT
    getFromG() returns (uint256) envfree
    getFromG2() returns (uint256) envfree
}

rule check {
    assert getFromG() == getFromG(); // Should be verified
    assert getFromG2() == getFromG2(); // Should be verified    
    assert getFromG() == getFromG2(); // Should be violated
}
```

