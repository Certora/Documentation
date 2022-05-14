Method declarations
===================

A specification may have a `methods` block that consists of _method
declarations_. Each declares a function signature either in the contract being
verified or in [other contracts in the verification context](multicontract.md).

Use Cases
---------

In general, we can reference contract functions without declaring them in the
specification. Still, however, we may opt to declare an `external` or `public`
contract function in the following use cases:

1.  **Making the specification more self-contained and readable.**
    
    *   We can use the `methods` block to
        
        *   list all the contract functions that are expected to exist in
            verification context;
            
        *   specify the contracts' interface against which the specification is
            written (e.g., ERC20).
            
2.  **Reusing the specification against contracts that implement subsets of an
interface (e.g., ERC20).**
    
    *   Without a corresponding method declaration, a rule that refers to a
        contract function whose implementation is not found in the verification
        context would not pass the syntax check.
        
    *   Method declarations enable us to ignore rules that refer to functions
        not found in the current verification context and run the tool using
        only the relevant rules in the specification.
        
3.  **Declaring that the function is** `envfree`**, i.e., that it does not
    access the** [**execution environment of the
    EVM**](/docs/ref-manual/cvl/types.md)**, and, in particular, it is
    non-payable.**
    
    *   An `envfree` declaration allows the function to be referenced in either
        invoke commands or invoke expressions without giving an `env` type
        instance as the first input argument.
        
    *   If an implementation of the function exists in the contract, the tool
        would automatically generate rules to check that this implementation is
        indeed `envfree`.

Syntax
------

We demonstrate the syntax of method declarations through the example `methods`
block shown below.

```cvl
using B as b

methods {
    foo02(uint, uint) returns (uint)
    
    b.foo03(uint) returns (uint) envfree

    foo01(uint x, uint y) returns (uint) envfree
}
```

*   Line 4 declares that a function whose signature is `foo02(uint, uint)` and
    whose return type is `uint` should exist in `currentContract`, i.e., the
    contract being verified.
    
*   Line 6 declares that a function whose signature is `foo03(uint)` should
    exist in the [imported contract](multicontract.md) `B` and have `uint` as
    its return type. Note that, in contrast to Line 4, it uses
    [multi-contract](multicontract.md) and, in addition, declares
    `b.foo03(uint)` as [envfree](#envfree).
    
*   Line 8 is similar to Line 6; the notable difference is that it declares a
    function in `currentContract`.

Summary Declarations
--------------------

A _summary declaration_ is a special case of a method declaration. It declares
that a function signature should be summarized using the specified summary. For
more details about summaries, see {ref}`Function Summarization <summaries-sec>`.

As opposed to the declarations which we have considered thus far, summary
declarations always implicitly apply to functions' signatures in “any
contract”. That is, the summary applies to _any_ call, either external or
internal, in the contracts being verified, such that (1) it calls to the
declared signature (or
[sighash](https://docs.soliditylang.org/en/v0.8.6/abi-spec.html#function-selector));
and (2) satisfies the {ref}`summary application policy <summaries>` (i.e., either
`ALL` or `UNRESOLVED`).

The example `methods` block shown below demonstrates the syntax of summary
declarations.

```cvl
methods {
    foo03(uint) => ALWAYS(3) ALL
    
    foo02(uint, uint) => ALWAYS(2) UNRESOLVED
     
    0xd634d50a => ALWAYS(3) ALL // The sighash of foo3(uint)
    
    foo01(uint x, uint y) returns (uint) envfree => ALWAYS(1)
}
```

*   Line 2 declares that any call to a function whose signature is
    `foo03(uint)` should be summarized as `ALWAYS(3)` and according to an `ALL`
    policy.
    
*   Line 4 declares that any call to a function whose signature is `foo02(uint,
    uint)` should be summarized as `ALWAYS(2)`and according to an `UNRESOLVED`
    policy.
    
*   Line 6 is similar to Lines 2 and 4. The notable difference is that it uses
    the sighash of the function rather than its signature.
    
*   Line 8 combines a summary declaration with an `envfree` declaration. It
    declares an `ALWAYS(1)` summary for the signature `foo01(uint x, uint y)`
    in _any_ contract, whereas it declares that the function `foo01(uint x,
    uint y)` should exist in `currentContract` and its return type is `uint`.
    

```{note}
As shown in Line 8, we can omit the summary application policy (i.e., either
`ALL` or `UNRESOLVED`). In this case, the default policy would be used. See
{ref}`Function Summarization <summaries>` for more details.
```

Method Declarations and Multi-Contract
--------------------------------------

Finally, notice that the use of [multi-contract](multicontract.md) in method
declarations has the following restrictions:

1.  Multi-contract must not be used in summary declarations. Recall that
    summaries always implicitly apply to "any contract".
    
2.  Multi-contract should only be used in declarations that are _not_ summary
    declarations.
    
3.  When a valid `envfree` declaration is also a summary declaration (and
    therefore does not use multi-contract), the summary applies to "any
    contract" whereas the `envfree` declaration applies to `currentContract`.


(summaries-sec)=
Summarizing Solidity Functions
==============================

Contracts often interact with other contracts, and by default, these
interactions are abstracted away by the tool. Roughly, this means the Prover
tool assumes any outcome is possible.‌

This document details the exact behavior of the Prover in different scenarios,
and how these can be controlled in the specification.

Calls inside the specification
------------------------------

Calls inside the specification are always inlined. They must refer either to
the default contract (i.e., the one that the user indicated to be verified) or
to one of the imported contracts.

```cvl
using OtherContractInstance as otherContractInstance​rule callFun {
  uint x = fun1(); // inline fun1 of currentContract
  uint y = currentContract.fun1(); // same as above
  uint z = otherContractInstance.fun1(); // inline fun1 of otherContractInstance
}
```

Calls inside the code
---------------------

A call to an external contract that was not _linked_ is abstracted. It means
certain variables can be set to arbitrary values following this call. We often
refer to this call as being _havoc'd_, and we use the same term for variables
set to arbitrary values. For a havoc'd call:

*   The return values (`returndata`) can take any value
    
*   The return code of the call can take any value
    
*   The state of the calling contract (`this`) may or may not become havoc'd.
    
*   The balances may become havoc'd in full or in part.
    

A [method declaration](/docs/ref-manual/cvl/methods) in the spec file can be
associated with a _summary_ that tells the Prover how to handle a call to a
non-linked external contract. Currently, the available summaries are
`HAVOC_ALL`,`HAVOC_ECF`,`ALWAYS(n)`,`CONSTANT`, `PER_CALLEE_CONSTANT`,
`NONDET`, `AUTO`, and `DISPATCHER`. The below table shows the differences
between these summaries. Asterisks (\*) indicate havocing.

<table data-layout="default" class="confluenceTable"><colgroup><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"></colgroup><tbody><tr><td class="confluenceTd"><p><strong>Summary</strong></p></td><td class="confluenceTd"><p><strong>Return value</strong></p></td><td class="confluenceTd"><p><strong>Return code</strong></p></td><td class="confluenceTd"><p><strong>Current contract state</strong></p></td><td class="confluenceTd"><p><strong>Other contracts states</strong></p></td><td class="confluenceTd"><p><strong>Balances</strong></p></td></tr><tr><td class="confluenceTd"><p><code>HAVOC_ALL</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td></tr><tr><td class="confluenceTd"><p><code>HAVOC_ECF</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Havoc'd except for current contract's balance that may increase</p></td></tr><tr><td class="confluenceTd"><p><code>ALWAYS(n)</code></p></td><td class="confluenceTd"><p>n</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>CONSTANT</code></p></td><td class="confluenceTd"><p>Some constant <code>x</code> for all calls to the same method signature in any target contract</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>PER_CALLEE_CONSTANT</code></p></td><td class="confluenceTd"><p>Every target contract <code>c</code> will return the same constant <code>x_c</code> for all calls to the same method signature</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>DISPATCHER[(bool)]</code></p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td></tr><tr><td class="confluenceTd"><p><code>NONDET</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>success(1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged (up to current transfer)</p></td></tr><tr><td class="confluenceTd"><p><code>AUTO</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td></tr></tbody></table>

The `DISPATCHER` _summary_ handles each call to the declared method as if any
method with the same signature in any target contract may be called. By
default, in addition to calls to implementations in known target contracts, the
`DISPATCHER`has a havoc'd call to an unknown, untrusted target contract. This
havoc'd call is handled the same as in the `AUTO` summary (see below).

One can override the default mode of the`DISPATCHER` by enabling an
_optimistic_ mode. This mode assumes that only known contracts may be called.
It is enabled by specifying `DISPATCHER(true)`. Note that either
`DISPATCHER(false)`or `DISPATCHER` denote that the default mode is enabled.

The `AUTO` summary depends on the type of call, namely, the EVM opcode used by
the call. Static calls (`STATICCALL`) don't havoc any contract's state. Regular
calls and contract creations (`CALL`,`CREATE`) havoc all contracts' states
except for the current contract's (like `HAVOC_ECF`). Library calls
(`DELEGATECALL` and `CALLCODE`) havoc _only_ the current contract's state.

Some of the summaries change the balances. While the `HAVOC_ALL` summary fully
havocs the balances of the current contract and the target contract, other
balance changing summaries partially havoc these balances as follows:

*   The current contract's balance `x` will first be decreased by the
    transferred amount `t`. Then, the balance will be havoc'd to be at least
    `x-t`, i.e., in the end, it may not decrease by more than the transferred
    amount.
    
*   The target contract's balance will be incremented by exactly the
    transferred amount.
    

If the contract you are verifying relies heavily on modification of ETH
balances, it's recommended to identify the balance-modifying functions and mark
them `HAVOC_ALL` if necessary.

**A technical remark about** `returnsize`**:** For `CONSTANT` and `PER_CALLEE`
summaries, the summaries extend naturally to functions that return multiple
return values. The assumption is that the return size in bytes is a multiple of
32 bytes (as standard in Solidity). The `returnsize` variable is updated
accordingly and is determined by the size requested by the caller.

If you do not trust the target contract to return exactly the number of
arguments dictated by the Solidity-level interface, **do not use**`CONSTANT`
and `PER_CALLEE_CONSTANT`summaries.

In very special cases, one may set the `returnsize` optimistically even when
havocing, based on information about the invoked function's signature and the
available functions in the verification context, set with
`-optimisticReturnsize`.

We present simple examples to illustrate the differences between the
non-havocing summaries. We use a simple interface `IntGetter` that we will not
assume anything about:

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

Internal Function Summaries
===========================

Summaries Always Inserted
-------------------------

Summaries for **external** functions are only inserted when an implementation
of that function cannot be found, and so we default to some summary that we,
the verifier, sees fit. _However_, internal functions can always be found and
so it only makes sense to force-replace the body of the function (as opposed to
filling in for one that could not be found).‌

Feature Limitations:
--------------------

*   Function must have primitive parameter types and return types (`bool`,
    `address`, `uintX`, `bytesX`)
    
*   Functions must be pure
    

Allowed Summaries
-----------------

Not all summaries make sense in the context of an internal function. Only the
following summaries are allowed:

*   `ALWAYS(X)` the summary always returns `X` and has no side-effects
    
*   `CONSTANT` the summary always returns the same constant and has no side
    effects
    
*   `NONDET` the summary returns a havoc'd value
    
*   `Ghost` the summary returns the value return by the given ghost function
    with the given arguments
    

Example
-------

Consider the following toy contract where accounts earn continuously
compounding interest. Balances are stored as "day 0 principal" and current
balances are calculated from that principal using the
function `continuous_interest` which implements the standard continuous
interest formula.

```solidity
contract Interest {
  uint256 days;
  uint256 interest;
  mapping(address => uint256) principals;
  // decimals 18
  public uint256 constant e = 2718300000000000000;
  
  function balance(address account) public view returns (uint256) {
    return continuous_interest(principals[account], interest, days);
  }
  
  function advanceDays(uint256 n) public {
    days = days + n;
  }
  
  function continuous_interest(uint256 p, uint256 r, uint256 t)
      internal pure returns (uint256) {
    return p * e ^ (r * t);
  }
}
```

Now suppose we would like to prove that this balance calculation is monotonic
with respect to time (as days go by, balance never decreases). The following
spec would demonstrate this property.

```cvl
rule yield_monotonic(address a, uint256 n) {
  uint256 y1 = balance(a);
  require n >= 0;
  advanceDays(n);
  uint256 y2 = balance(a);
  assert y2 >= y1;
}
```

Unfortunately, the function `continuous_interest` includes some arithmetic that
is very difficult for the underlying SMT solver to reason about and two things
may happen.

1.  The resulting formula may be cause the underlying SMT formula to time out
    which will result in an `unknown` result
    
2.  The Prover will use "overapproximations" of the arithmetic operations in
    the resulting formula. Basically this means that we let allows some weird
    and unexpected behavior which _includes_ the behavior of the function,
    but _also_ includes more behavior. Basically, this means that a
    counterexample may not be a _real_ counterexample (i.e. not actually
    possible program behavior). To understand this better see our section
    on [overapproximation](approximation).
    

It turns out that in this case, we run into problem (2) where the tool reports
a violation which doesn't actually make sense. This is where function
summarization becomes useful, since we get to decide how we would like to
overapproximate our function! Suppose we would like to prove that, _assuming
the equation we use to calculate continuously compounding interest is
monotonic_, then it is also the case that the value of our principal is
monotonically increasing over time. In this case we do the following:

```cvl
methods {
  // tell the tool to use a ghost function as the summary for the function
  continuous_interest(uint256 p, uint256 r, uint256 t) =>
      ghost_interest(p, r, t)
}

// define the ghost function
ghost ghost_interest(uint256,uint256,uint256) {
  // add an axiom describing monotonicity of ghost_interest
  axiom forall uint256 p. forall uint256 r. forall uint256 t1. forall uint256 t2.
      t2 >= t1 => ghost_interest(p,r,t2) >= ghost_interest(p,r,t1);
}

rule yield_monotonic(address a, uint256 n) {
  // internally, when this call continuous_interest, the function will
  // be summarized as ghost_interest
  uint256 y1 = balance(a);
  require n >= 0;
  
  advanceDays(n);
  
  // internally, when this call continuous_interest, the function will
  // be summarized as ghost_interest
  uint256 y2 = balance(a);
  assert y2 >= y1;
}
```

By summarizing `continuous_interest` as a function who is monotonic with its
last argument (time) we are able to prove the property.


More Expressive Summaries
=========================

Ghost Summaries
---------------

What we refer to as [ghost functions](../anatomy/ghostfunctions.md) are simply
{ref}`uninterpreted functions <uninterp-functions>` uninterpreted functions.
Because these can be axiomatized, they can be used to express any number of
[approximating](approximation.md) semantics (rather than summarizing a function
as simply a constant). For example, say we wanted to give some approximation
for a multiplication function--this is an example of an operation that is very
difficult for an SMT solver. Perhaps we only care about the monotonicity of
this multiplication function. We may do something like the following:

```cvl
ghost ghost_multiplication(uint256,uint256) returns uint256 {
  axiom forall uint256 x1. forall uint256 x2. forall uint256 y. 
      x1 > x2 => ghost_multiplication(x1, y) > ghost_multiplication(x2, y);
  axiom forall uint256 x. forall uint256 y1. forall uint256 y2.
      y1 > y2 => ghost_multiplication(x, y1) > ghost_multiplication(x, y2);
}
```

Then we can summarize our multiplication function:

```cvl
methods {
  mul(uint256 x, uint256 y) => ghost_multiplication(x, y);
}
```

You may pass whichever parameters from the summarized function as arguments to
the summary in whichever order you want. However you may not put an expression
as an argument to the summary.

CVL Function Summaries
----------------------

[CVL Functions](../anatomy/functions.md) provide standard encapsulation of code
within a spec file and allow for control flow, local variables etc. (but not
loops). A subset of these are allowed as summaries, namely:

1.  They do not contain methods as parameters
    
2.  They do not contain calls to contract functions
    

For example, say we want to summarize a multiplication function again, but this
time we want to cut down the search space for the solver a bit. We might try
something like the following:

```cvl
function easier_multiplication(uint256 x, uint256 y) returns uint256 {
  require(x < 1000 || y < 1000);
  return to_uint256(x * y);
}
```

and just as above we summarize the multiplication function in the methods block:

```cvl
methods {
  mul(uint256 x, uint256 y) => easier_multiplication(x, y);
}
```

Note this specific summarization is very dangerous and may cause vacuity bugs.

In simple cases, these summaries may be used to replace harnesses, though the
fact that they cannot call contract functions limits the types of harnesses
that may be written.
