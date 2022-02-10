Types
=====

Like Solidity, CVL is a statically typed language.  There is overlap between
the types supported by Solidity and the types supported by CVL, but CVL has some
additional types and is also missing support for some Solidity types.

```
basic_type ::= "int*" | "uint*" | "address" | "bool"
             | "string" | "bytes*"
             | basic_type "[" [ number ] "]"

evm_type ::= basic_type
           | "(" evm_type { "," evm_type } ")"
           | evm_type "[" [number] "]"

cvl_type ::= basic_type
           | "mathint" | "calldataarg" | "storage" | "env" | "method"
           | id
```

The additional CVL types are:
 - {ref}`mathint` is an arbitrary precision integer that cannot overflow
 - {ref}`calldataarg <calldataarg>` and {ref}`method <method-type>` are used
   to represent arbitrary methods and arguments of the contract under verification
 - {ref}`storage <storage-type>` is used to represent a snapshot of the entire EVM storage
 - {ref}`sort` are used to represent unknown types


Solidity Types
--------------

CVL currently supports the following [solidity types][]:

 * `bool`, `int`, `uint`, and the sized variants such as `uint256` and `int8`.
 * `address`
 * `string`, `bytes`, and the sized `bytes` variants (`bytes1` through `bytes32`)
 * Tuples and single-dimensional arrays (both statically- and dynamically-sized)

The following are unsupported:
 * enums
 * user-defined value types
 * function types
 * structs
 * references
 * multi-dimensional arrays
 * mappings

[solidity types]: https://docs.soliditylang.org/en/v0.8.11/types.html

```{todo}
Is this the right place to describe basic operations and literal syntax, or does
that go under expressions?
```

### Array access

Array accesses in CVL behave slightly differently from Solidity accesses.  In
Solidity, an out-of-bounds array access will result in an exception, causing the
transaction to revert.

By contrast, out-of-bounds array accesses in CVL are treated as undefined
values: if `i > a.length` then the prover considers every possible value for
`a[i]` when constructing counterexamples.

CVL Arrays also have the following limitations:
 - Only single dimensional arrays are supported
 - The `push` and `pop` methods are not supported.

### Methods on Solidity types

```{todo}
address.balance, address.send, array.push, array.pop, etc.
```

### Handling unsupported Solidity types

```{todo}
Explain how to use `require` and `using` or other tricks for constraining
return addresses.
```

```{todo}
multi-dimensional arrays
```

```{todo}
reference types
```


Additional CVL types
--------------------

(mathint)=
### The `mathint` type

Arithmetic overflow and underflow are difficult to reason about and often lead
to bugs.  To avoid this complexity, CVL provides the `mathint` type that can
represent an integer of any size; operations on `mathint`s can never overflow
or underflow.

See {doc}`mathops` for details on mathematical operations and casting
between `mathint` and Solidity integer types.

(env)=
### The `env` type

Rules often reason about the effects of multiple transactions.  In different
transactions, the global [Solidity variables][solidity globals] (such as `msg.sender`
or `block.timestamp`) may have different values.

To support reasoning about multiple transactions, CVL groups some of the
solidity global variables into an "environment": an object of the special type
`env`.  Environments must be passed as the first argument of a call from CVL
into a contract function (unless the contract function is declared
{ref}`envfree`).

For example, to call a soldity function `deposit(uint amount)`, a spec must
explicitly pass in an additional environment argument:

```cvl
rule check_deposit() {
    env e;
    uint amount;
    deposit(e, amount); // increases e.msg.sender's balance by `amount`
}
```

The value of the Solidity global variables can be extracted from the `env`
object using a field-like syntax.  The following fields are available on an
environment `e`:

* `e.msg.address` - address of the contract being verified, e.g., `Bank`
* `e.msg.sender` - address of the sender of the message 
* `e.msg.value` - number of wei sent with the message
* `e.block.number` - current block number
* `e.block.timestamp` - current block's time stamp
* `e.tx.origin` - original message sender

The remaining solidity global variables are not accessible from CVL.

[solidity globals]: https://docs.soliditylang.org/en/v0.8.11/units-and-global-variables.html#special-variables-and-functions

(method-type)=
(calldataarg)=
### The `method` and `calldataarg` types

An important feature of CVL is the ability to reason about the effects of an
arbitrary method called with arbitrary arguments.  To support this, CVL
provides the `method` type to represent an arbitrary method, and the
`calldataarg` type to represent an arbitrary set of arguments.

For example, the following rule checks that _no method_ can decrease the user's
balance:

```cvl
rule balance_increasing() {
    address user;
    uint balance_before = balance(user);

    method f;
    env e;
    calldataarg args;

    f(e,args);

    uint balance_after = balance(user);
    assert balance_after >= balance_before, "balance must be increasing";
}
```

Since `f`, `e`, and `args` are not given values, the Prover will consider every
possible assignment.  This means that when evaluating the call to `f(e,args)`,
the Prover will check the rule on every method of the contract, with every
possible set of method arguments.

Properties of methods can be extracted from methods using a field-like syntax. 
The following fields are available on a method `m`:

*   `m.selector` - the hashcode of the method 
*   `m.isPure` - true when m is declared with the pure attribute
*   `m.isView` - true when m is declared with the view attribute
*   `m.numberOfArguments` - the number of arguments to method m

There is no way to examine the contents of a `calldataarg` variable, because
the type of its contents vary depending on which method the prover is checking.
The only thing you can do with it is pass it as an argument to a `method`
variable.  It is possible to work around this limitation; see {ref}`partially
parametric rules` for further details.

(storage-type)=
### The `storage` type

The Certora Prover can compare different hypothetical transactions starting
from the same state and compare their results.  For example, checking a
property like "if you stake more, you earn more" requires comparing the earnings
after two possible transactions starting in the same initial state: one where
you stake less, and one where you stake more.

Properties that compare the results of different hypothetical executions are
sometimes called hyperproperties.

CVL supports this kind of specification using the special `storage` type.  A
variable of type `storage` represents a snapshot of the EVM storage at a given
point in time.

The EVM storage can be reset to a saved storage value `s` by appending `at s` to
the end of a function call.  For example, the following rule checks that "if you
stake more, you earn more":

```cvl
rule bigger_stake_more_earnings() {
    storage initial;
    env e;

    uint less; uint more;
    require less < more;

    // stake less
    stake(e, less) at initial;
    earnings_less = earnings(e);

    // stake more
    stake(e, more) at initial;
    earnings_more = earnings(e);

    assert earnings1 < earnings2, "if you stake more, you earn more";
}
```

The `lastStorage` variable contains the state of the EVM after the most recent
contract function call.

(sort)=
### Uninterpreted sorts

```{todo}
Is this the only usage for the `type ::= id` production in the grammar?
```

