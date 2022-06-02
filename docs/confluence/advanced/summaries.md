Summarizing Solidity Functions
==============================

Contracts often interact with other contracts, and by default, these interactions are abstracted away by the tool. Roughly, this means the Prover tool assumes any outcome is possible.‌

This document details the exact behavior of the Prover in different scenarios, and how these can be controlled in the specification.

Calls inside the specification
------------------------------

Calls inside the specification are always inlined. They must refer either to the default contract (i.e., the one that the user indicated to be verified) or to one of the imported contracts.

```cvl
using OtherContractInstance as otherContractInstance​rule callFun {
  uint x = fun1(); // inline fun1 of currentContract
  uint y = currentContract.fun1(); // same as above
  uint z = otherContractInstance.fun1(); // inline fun1 of otherContractInstance
}
```

Calls inside the code
---------------------

A call to an external contract that was not _linked_ is abstracted. It means certain variables can be set to arbitrary values following this call. We often refer to this call as being _havoced_, and we use the same term for variables set to arbitrary values. For a havoced call:

*   The return values (`returndata`) can take any value
    
*   The return code of the call can take any value
    
*   The state of the calling contract (`this`) may or may not become havoced.
    
*   The balances may become havoced in full or in part.
    

A [method declaration](/docs/ref-manual/cvl/methods) in the spec file can be associated with a _summary_ that tells the Prover how to handle a call to a non-linked external contract. Currently, the available summaries are `HAVOC_ALL`,`HAVOC_ECF`,`ALWAYS(n)`,`CONSTANT`, `PER_CALLEE_CONSTANT`, `NONDET`, `AUTO`, and `DISPATCHER`. The below table shows the differences between these summaries. Asterisks (\*) indicate havocing.

<table data-layout="default" class="confluenceTable"><colgroup><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"></colgroup><tbody><tr><td class="confluenceTd"><p><strong>Summary</strong></p></td><td class="confluenceTd"><p><strong>Return value</strong></p></td><td class="confluenceTd"><p><strong>Return code</strong></p></td><td class="confluenceTd"><p><strong>Current contract state</strong></p></td><td class="confluenceTd"><p><strong>Other contracts states</strong></p></td><td class="confluenceTd"><p><strong>Balances</strong></p></td></tr><tr><td class="confluenceTd"><p><code>HAVOC_ALL</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td></tr><tr><td class="confluenceTd"><p><code>HAVOC_ECF</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Havoc'd except for current contract's balance that may increase</p></td></tr><tr><td class="confluenceTd"><p><code>ALWAYS(n)</code></p></td><td class="confluenceTd"><p>n</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>CONSTANT</code></p></td><td class="confluenceTd"><p>Some constant <code>x</code> for all calls to the same method signature in any target contract</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>PER_CALLEE_CONSTANT</code></p></td><td class="confluenceTd"><p>Every target contract <code>c</code> will return the same constant <code>x_c</code> for all calls to the same method signature</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>DISPATCHER[(bool)]</code></p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td></tr><tr><td class="confluenceTd"><p><code>NONDET</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>success(1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged (up to current transfer)</p></td></tr><tr><td class="confluenceTd"><p><code>AUTO</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td></tr></tbody></table>

The `DISPATCHER` _summary_ handles each call to the declared method as if any method with the same signature in any target contract may be called. By default, in addition to calls to implementations in known target contracts, the `DISPATCHER`has a havoced call to an unknown, untrusted target contract. This havoced call is handled the same as in the `AUTO` summary (see below).

One can override the default mode of the`DISPATCHER` by enabling an _optimistic_ mode. This mode assumes that only known contracts may be called. It is enabled by specifying `DISPATCHER(true)`. Note that either `DISPATCHER(false)`or `DISPATCHER` denote that the default mode is enabled.

The `AUTO` summary depends on the type of call, namely, the EVM opcode used by the call. Static calls (`STATICCALL`) don't havoc any contract's state. Regular calls and contract creations (`CALL`,`CREATE`) havoc all contracts' states except for the current contract's (like `HAVOC_ECF`). Library calls (`DELEGATECALL` and `CALLCODE`) havoc _only_ the current contract's state.

Some of the summaries change the balances. While the `HAVOC_ALL` summary fully havocs the balances of the current contract and the target contract, other balance changing summaries partially havoc these balances as follows:

*   The current contract's balance `x` will first be decreased by the transferred amount `t`. Then, the balance will be havoced to be at least `x-t`, i.e., in the end, it may not decrease by more than the transferred amount.
    
*   The target contract's balance will be incremented by exactly the transferred amount.
    

If the contract you are verifying relies heavily on modification of ETH balances, it's recommended to identify the balance-modifying functions and mark them `HAVOC_ALL` if necessary.

**A technical remark about** `returnsize`**:** For `CONSTANT` and `PER_CALLEE` summaries, the summaries extend naturally to functions that return multiple return values. The assumption is that the return size in bytes is a multiple of 32 bytes (as standard in Solidity). The `returnsize` variable is updated accordingly and is determined by the size requested by the caller.

If you do not trust the target contract to return exactly the number of arguments dictated by the Solidity-level interface, **do not use**`CONSTANT` and `PER_CALLEE_CONSTANT`summaries.

In very special cases, one may set the `returnsize` optimistically even when havocing, based on information about the invoked function's signature and the available functions in the verification context, set with `-optimisticReturnsize`.

We present simple examples to illustrate the differences between the non-havocing summaries. We use a simple interface `IntGetter` that we will not assume anything about:

```solidity
interface IntGetter {
  function get() external returns (uint)
  function get2() external returns (uint)
}
```

`ALWAYS` summary:

```solidity
// code
contract CallsExternalContracts {
  IntGetter g1;
  IntGetter g2;
  
  function getFromG() external returns (uint) { return g.get(); }
  function getFromG2() external returns (uint) { return g.get2(); }
}
```

```cvl
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

```solidity
// code
contract CallsExternalContracts {
  IntGetter g1;
  IntGetter g2;
  
  function getFromG() external returns (uint) { return g.get(); }
  function getFromG2() external returns (uint) { return g.get2(); }
}
```

```cvl
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

```solidity
// code
contract CallsExternalContracts {
  IntGetter g1;
  IntGetter g2;
  
  function getFromG() external returns (uint) { return g.get(); }
  function getFromG2() external returns (uint) { return g.get2(); }
}
```

```cvl
// spec
methods {
  get() => CONSTANT
  get2() => NONDET
  
  getFromG() returns (uint256) envfree
  getFromG2() returns (uint256) envfree
}

rule check {
  // Should be verified - two calls return the same value 
  assert getFromG() == getFromG();
  
  // Should be violated - two calls may return different values
  assert getFromG2() == getFromG2();
}
```

How `PER_CALLEE_CONSTANT` works:

```solidity
// code
contract CallsExternalContracts {
  IntGetter g1;
  IntGetter g2;
  
  function getFromG() external returns (uint) { return g.get(); }
  function getFromG2() external returns (uint) { return g2.get(); }
}
```

```cvl
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
