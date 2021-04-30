---
description: >-
  Introduces the main concepts and constructs for writing rules for the Certora
  Prover.
---

# Specification Basics in Specify

## Rules in Specify <a id="docs-internal-guid-f00bf0a3-7fff-54aa-2502-6483d21f219d"></a>

The Certora Prover verifies that a smart contract satisfies a set of rules written in a language called _Specify_. Each rule is checked on all possible inputs. Of course, this is not done by explicitly enumerating the inputs, but rather through symbolic techniques. Rules can check that a public contract method has the correct effects on the contract state or returns the correct value, etc... The syntax for expressing rules somewhat resembles Solidity, but also supports more features that are important for verification. 

Consider the following contract interface to implement a simple bank:

```text
contract Bank {
    mapping (address => uint) public funds;
    uint public totalFunds;
 
    // get the current fund of an account   
    function getFunds(address account) public returns (uint)
    // get the total funds in the bank 
    function getTotalFunds() public returns (uint)
    // deposit an amount to an account
    function deposit(uint amount) public payable
    // transfer an amount to an account  
    function transfer(address account, uint amount) public 
    // withdraw all amounts
    function withdraw() returns (bool) public
}
```

And here is a rule for verifying that withdraw either reverts or returns true.

```text
// file bank.spec
rule withdraw_succeeds {
   env e; // env represents the bytecode environment passed on every call
   // invoke function withdraw and assume that it does not revert
   bool success = sinvoke withdraw(e);  // e is passed as an additional arg
   assert success, “withdraw must succeed”; // verify that withdraw succeed
}
```

The rule calls withdraw with an arbitrary EVM environment \(e\) in an arbitrary initial state. It assumes that the function does not revert \(in the command sinvoke where “s” stands for successful\).  The assert command checks that success is true on all potential executions. Notice that each Solidity function has an extra argument, which is the EVM environment.

### Predefined types

* `env` - represents the environment of the EVM during execution. This type contains the following fields, for an instance `env e`:
  * `e.msg.address` - address of the contract being verified, e.g., `Bank`
  * `e.msg.sender` -  sender of the message 
  * `e.msg.value` - number of wei sent with the message
  * `e.block.number` - current block number
  * `e.block.timestamp` - current time stamp
  * `e.tx.origin` - original message sender
* `method` - represents methods and their attributes. This type contains the following fields for an instance `method m`:
  * `m.name` - the name of the method m
  * `m.selector` - the hashcode of the method   
  * `m.isPure` - true when m is declared with the pure attribute
  * `m.isView` - true when m is declared with the view attribute
  * `m.numberOfArguments` - the number of arguments to method m
* `mathint` - represents an integer, positive or negative, of any value. Namely, it is not bounded by the number of bits that are used to represent it.

### EVM Types vs. Mathematical Types <a id="docs-internal-guid-7d0ceb11-7fff-17d2-2190-1de01b23b4c4"></a>

In Specify, arithmetic operators \(+, -, \* and /\) are overloaded: they could mean a machine-arithmetic operation that can overflow, or a mathematical operation that does not overflow. The default interpretation used in almost all cases is the mathematical one. Therefore, the below assertion holds:

```text
uint x;
assert x+1 > x;
```

The syntax supports Solidity’s integer types \(`uintXX` and `intXX`\) as well as the Specify-only type `mathint` representing the domain of mathematical integers \(ℤ\). Using these types allows controlling how arithmetic operators such as +, -, and \* are interpreted. Therefore, in the following variant on the above example, if we wish the + operation to be the overflowing variant, we can write the following:

```text
uint x;
uint y = x + 1;
assert y > x;
```

The assertion here will fail with `x=MAX_INT`, since then y is equal to 0. If we write instead:

```text
uint x;
mathint y = x + 1;
assert y > x;
```

The meaning is the same as in the first snippet, since an assignment to a `mathint` variable allows non-overflowing interpretations of the arithmetic operators.

The only case in which arithmetic operators in expressions are allowed to overflow is within arguments passed to invoke, or generally, whenever we interact with the code being checked. Solidity functions cannot take values that do not fit within 256 bits. Therefore the tool will report an overflow error if `mathint` variable is passed directly as an invoke argument.

```text
uint MAX_INT = ...;
invoke foo(MAX_INT + 1); // equivalent to invoke foo(0)
assert MAX_INT + 1 == 0; // always false, because ‘+’ here is mathematical

mathint x = MAX_INT + 1;
invoke foo(x); // error
```

### Standard identifiers

The Specify language includes the following standard identifiers: 

* `bool lastReverted` - true when the last function call reverted, for example “did the transfer revert?”.
* `address currentContract` - the address of the current contract that is checked, e.g. the address of `Bank`.
* `storage lastStorage` - The current state of the contract. Useful for enforcing hyperproperties of smart contracts.

```text
// file bank.spec 
// A rule with two free variables: 
//     -to - the address the transfer is passed to 
//     -amount - the amount of money to pass
rule transfer_reverts() {
   env e; 
   address to; 
   uint256 amount;
   // invoke function transfer and assume the caller is w.msg.from
   uint256 balance = sinvoke getFunds(e, e.msg.sender);
   invoke transfer(e, to, amount);
   // check that transfer reverts if the sender does not have enough funds 
   assert balance < amount => lastReverted , "insufficient funds"; 
}
```

### Specify commands

* `require exp` - assume that `exp` is true at this point \(i.e., the tool will only consider executions in which `exp` holds\). For example, `require e.msg.sender == admin` would ignore any cases where the caller is not the admin.
* `assert exp` - check if `exp` is true, and output a counterexample if there is an input for which it is false. For example, `assert newBalance == oldBalance + amount` will check that a balance always equals the correct value after a transfer \(or will report an error, such as when an account transfers to itself and this assertion doesn't hold\). The optional string argument is displayed when the assertion is violated. 
* `invoke foo(args)`or `foo@withrevert(args)` - simulate a function named `foo` with arguments `args` allowing it to revert.
* `sinvoke foo(args)` or `foo(args)` - simulate a function named `foo` with arguments `args` and assume that it does not revert. This syntax is equivalent to:

```text
invoke foo(arg);
require !lastReverted;
```

#### Boolean operators that do not exist in Solidity

* Implication: `=>` `A => B` evaluates to true if either `A` is false or `B` is true. For example, `assert e.sender != admin => lastReverted`  could check that if the caller is not the admin, a given function must revert in all cases.
* Bi-directional implication: `<=>` `A <=> B` evaluates to true iff `A => B && B => A` For example,  `assert e.sender != admin <=> lastReverted` checks that if the caller is not the admin, a given function reverts and that if the function reverted, it must be the case that the sender was not the admin \(basically saying that this is the only reason it would revert\).

### Parametric rules

To simulate the execution of all functions in the contract, you can define a method argument in the rule and use it in `invoke` \(`sinvoke`\) statements. For example:

```text
// file bank.spec 
rule others_can_only_increase_balance() {
   method f; // an arbitrary function in the contract
   env e;  // the execution environment
   address other; // a different account
   // assume msg.sender is a different address
   require e.msg.sender != other;
   // get balance before the function call
   uint256 _balance = sinvoke getFunds(e,other);
   // exec some method
   calldataarg arg; // any argument
   sinvoke f(e,arg); // successful (potentially state-changing!)
   //get balance after
   uint256 balance_ = sinvoke getFunds(e,other);
   // balance should not be reduced by any operation
   // may increase due to a transfer from msg.sender to other
   assert _balance <= balance_ ,"withdraw from others balance"; 
}
```

The Prover verifies that the conditions hold against any function call with any arguments.

### Invariants in Specify

Invariants are a specification of a condition that should always be true once an operation is concluded. Syntax:

* `invariant invariantName(args_list) exp` - Assume `exp` holds before execution of any method and verify exp must hold afterwards. The invariant "step" case above is equivalent to a rule:

```text
rule invariantAsRule(method f) {
    require exp;
    calldataarg arg; 
    sinvoke f(e,arg);
    assert exp;
}
```

#### Declaring functions used in the invariant

In the spec file, you need to define the Solidity functions used in the invariants. Here `env` ranges over all environments.

```text
// file bank.spec 
methods {
    init_state() 
    getFunds(address) returns uint256
}

invariant address_zero_cannot_become_an_account(env e) 
          getFunds(e, 0)==0
```

#### envfree functions

When a function is not using the environment, it can be declared as `envfree` to omit the call’s `env` argument. For example, `getFunds` is not using any of the environment variables:

```text
// file bank.spec 
methods {
    init_state() 
    getFunds(address) returns uint256 envfree
}
invariant address_zero_cannot_become_an_account() 
          getFunds(0)==0
```



