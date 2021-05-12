---
description: >-
  Learn about Specify's standard and special types, and how these types enable
  more thorough checks of your code.
---

# Types

## Predefined types

* `env` - represents the environment of the EVM during execution. For an instance `env e`, it contains the following fields:
  * `e.msg.address` - address of the contract being verified, e.g., `Bank`
  * `e.msg.sender` -  address of the sender of the message 
  * `e.msg.value` - number of wei sent with the message
  * `e.block.number` - current block number
  * `e.block.timestamp` - current block's time stamp
  * `e.tx.origin` - original message sender
* `method` - represents methods and their attributes. This type contains the following fields for an instance `method m`:
  * `m.name` - the name of the method m
  * `m.selector` - the hashcode of the method   
  * `m.isPure` - true when m is declared with the pure attribute
  * `m.isView` - true when m is declared with the view attribute
  * `m.numberOfArguments` - the number of arguments to method m
* `mathint` - represents an integer, positive or negative, of any value. Namely, it is not bounded by the number of bits that represent it.

## EVM types vs. mathematical types

In Specify, arithmetic operators \(+, -, \* and /\) are overloaded: they could mean a machine-arithmetic operation that can overflow, or a mathematical operation that does not overflow. The default interpretation used in almost all cases is the mathematical one. Therefore, the assertion below holds:

```javascript
uint x;
assert x + 1 > x;
```

The syntax supports Solidity’s integer types \(`uintXX` and `intXX`\) as well as the Specify-only type `mathint` representing the domain of mathematical integers \(ℤ\). Using these types allows controlling how arithmetic operators such as +, -, and \* are interpreted. Therefore, in the following variant on the above example, if we wish the + operation to be the overflowing variant, we can write the following:

```javascript
uint x;
uint y = x + 1;
assert y > x;
```

The assertion here will fail with `x = MAX_INT`, since then y is equal to 0. If we write instead:

```javascript
uint x;
mathint y = x + 1;
assert y > x;
```

The meaning is the same as in the first snippet since an assignment to a `mathint` variable allows non-overflowing interpretations of the arithmetic operators.

The only case in which arithmetic operators in expressions are allowed to overflow is within arguments passed to functions, or generally, whenever we interact with the code being checked. Solidity functions cannot take values that do not fit within 256 bits. Therefore the tool will report an overflow error if `mathint` variable is passed directly as a function argument.

```javascript
uint256 MAX_INT = 2^256 - 1;
foo(MAX_INT + 1); // equivalent to invoking foo(0)
assert MAX_INT + 1 == 0; // always false, because ‘+’ here is mathematical

mathint x = MAX_INT + 1;
foo(x); // error
```

## Maximal values of types

Sometimes it is useful to bound a `mathint` variable to the ranges allowed by a Solidity type. The following keywords describe the maximal values of their respectively named Solidity types:

* `max_uint` and `max_uint256`
* `max_uint160` and `max_address`
* `max_uint128`
* `max_uint96`
* `max_uint64`
* `max_uint32`
* `max_uint16`
* `max_uint8`

\`\`

