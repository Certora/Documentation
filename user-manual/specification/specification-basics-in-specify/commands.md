---
description: >-
  Specify exposes special instructions for controlling what is checked by the
  Prover, including how we (symbolically) interact with the checked code. In
  addition, Specify has special boolean operators.
---

# Commands

## Specify commands

* `require exp` - assume that `exp` is true at this point \(i.e., the tool will only consider executions in which `exp` holds\). For example, `require e.msg.sender == admin` would ignore any cases where the caller is not the admin.
* `assert exp` - check if `exp` is true, and output a counterexample if there is an input for which it is false. For example, `assert newBalance == oldBalance + amount` will check that a balance always equals the correct value after a transfer \(or will report an error, such as when an account transfers to itself and this assertion doesn't hold\). The optional string argument is displayed when the assertion is violated. 
* `foo@withrevert(args)` or `invoke foo(args)`

  - simulate a function named `foo` with arguments `args` allowing it to revert.

* `foo(args)`or `sinvoke foo(args)`

   - simulate a function named `foo` with arguments `args` and assume that it does not revert. This syntax is equivalent to:

```javascript
foo@withrevert(arg); // same as invoke foo(arg)
require !lastReverted;
```

#### Boolean operators that do not exist in Solidity

* Implication: `=>` `A => B` evaluates to true if either `A` is false or `B` is true. For example, `assert e.sender != admin => lastReverted`  could check that if the caller is not the admin, a given function must revert in all cases.
* Bi-directional implication: `<=>` `A <=> B` evaluates to true if and only if `A => B && B => A`. For example,  `assert e.sender != admin <=> lastReverted` checks that if the caller is not the admin, a given function reverts and that if the function reverted, it must be the case that the sender was not the admin \(basically saying that this is the only reason it would revert\).

