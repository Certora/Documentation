Types
=====

Like Solidity, CVL is a statically typed language.  There is overlap between
the types supported by Solidity and the types supported by CVL, but CVL has some
additional types and is also missing support for some Solidity types.

The additional CVL types are:
 - {ref}`mathint` is an arbitrary precision integer that cannot overflow
 - {ref}`method-type` are used
   to represent arbitrary methods and arguments of the contract under verification
 - {ref}`storage-type` is used to represent a snapshot of the entire EVM storage
 - {ref}`env` is used to represent the Solidity global variables `msg`, `block`, and `tx`
 - {ref}`sort` are used to represent unknown types

```{contents}
```

Syntax
------

The syntax for types in CVL is given by the following [EBNF grammar](ebnf-syntax):

```
basic_type ::= "int*" | "uint*" | "address" | "bool"
             | "string" | "bytes*"
             | basic_type "[" [ number ] "]"
             | id "." id

evm_type ::= basic_type
           | "(" evm_type { "," evm_type } ")"
           | evm_type "[" [ number ] "]"

cvl_type ::= basic_type
           | "mathint" | "calldataarg" | "storage" | "env" | "method"
           | id
```

See {doc}`basics` for the `id` and `number` productions.


(solidity-types)=
Solidity Types
--------------

You can declare variables in CVL of any of the following [solidity types][]:

 * `int`, `uint`, and the sized variants such as `uint256` and `int8`
 * `bool`, `address`, and the sized `bytes` variants (`bytes1` through `bytes32`)
 * `string` and `bytes`
 * {ref}`Single-dimensional arrays <arrays>` (both statically- and dynamically-sized)
 * {ref}`Enum types, struct types, and type aliases <user-types>` that are
   defined in Solidity contracts.

The following are not directly supported in CVL, although you can interact with
contracts that use them (see {ref}`type-conversions`):
 * Function types
 * Multi-dimensional arrays
 * Mappings

[solidity types]: https://docs.soliditylang.org/en/v0.8.11/types.html

(math-types)=
### Integer types

CVL integer types are mostly identical to Solidity integer types.  See
{ref}`math-ops` for details.

(arrays)=
### Array access

Array accesses in CVL behave slightly differently from Solidity accesses.  In
Solidity, an out-of-bounds array access will result in an exception, causing the
transaction to revert.

By contrast, out-of-bounds array accesses in CVL are treated as undefined
values: if `i > a.length` then the Prover considers every possible value for
`a[i]` when constructing counterexamples.

CVL arrays also have the following limitations:
 - Only single dimensional arrays are supported
 - The `push` and `pop` methods are not supported.
You can use [harnessing](/docs/prover/approx/harnessing) to work around these limitations.

(user-types)=
### User-defined types

Specifications can use structs, enums, or user-defined value types that are
defined in Solidity contracts.

Struct types have the following limitations:
 - Assignment to struct fields is unsupported.  You can achieve the same effect
   using a {ref}`require <require>` statement.  For example, instead of `s.f = x;` you can
   write `require s.f == x;`.  However, be aware that `require` statements can
   introduce {term}`vacuity` if there are multiple conflicting constraints.

All user-defined type names (structs, enums, and user-defined values) must be
explicitly qualified by the contract name that contains them.

 - For types defined within a contract, the named contract must be the contract
   containing the type definition.  Note that if a contract inherits a type from
   a supertype, the contract that actually contains the type must be
   named, not the inheriting contract.

 - For types defined at the file level, the named contract can be any contract
   in the {term}`scene` from which the type is visible.

```{warning}
If you do not qualify the type name with a contract name, the type name will be
misinterpreted as a {ref}`sort <sort>`.
```

For example, consider the files `parent.sol` and `child.sol`, defined as follows:

```{code-block} solidity
---
caption: parent.sol
---
type ParentFileType is uint64;

contract Parent {
    enum ParentContractType { member1, member2 }
}
```

```{code-block} solidity
---
caption: child.sol
---
import 'parent.sol';

type ChildFileType is bool;

contract Child is Parent {
    type alias ChildContractType is uint128;
}
```

Given these definitions, types can be named as follows:

```{code-block} cvl
---
caption: child.spec
---

// valid types
Parent.ParentFileType     valid1;
Child .ParentFileType     valid2;
Parent.ParentContractType valid3;

// invalid types
Child .ParentContractType invalid1; // user-defined types are not inherited
Parent.ChildFileType      invalid2; // ChildFileType is not visible in Parent
```

Additional CVL types
--------------------

(mathint)=
### The `mathint` type

Arithmetic overflow and underflow are difficult to reason about and often lead
to bugs.  To avoid this complexity, CVL provides the `mathint` type that can
represent an integer of any size; operations on `mathint`s can never overflow
or underflow.

See {ref}`math-ops` for details on mathematical operations and casting
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
{ref}`envfree <envfree>`).

For example, to call a Solidity function `deposit(uint amount)`, a spec must
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

* `e.msg.sender` - address of the sender of the message 
* `e.msg.value` - number of Wei sent with the message
* `e.block.number` - current block number
* `e.block.timestamp` - current block's time stamp
* `e.block.basefee` - current block's base fee
* `e.block.coinbase` - current block's coinbase
* `e.block.difficulty` - current block's difficulty
* `e.block.gaslimit` - current block's gas limit
* `e.tx.origin` - original message sender

The remaining solidity global variables are not accessible from CVL.

[solidity globals]: https://docs.soliditylang.org/en/v0.8.11/units-and-global-variables.html#special-variables-and-functions

(method-type)=
(calldataarg)=
### The `method` and `calldataarg` types

```{versionchanged} 5.0
Formerly, parametric method calls would only call methods of `currentContract`;
now they call methods of all contracts.  This version also introduced the
`f.contract` field.
```

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
the Prover will check the rule on every method of every contract on the
{term}`scene`, with every possible set of method arguments.

See {ref}`parametric-rules` for more information about how rules that declare
method variables are verified.

Variables of type `method` can only be declared as an argument to the rule or
directly in the body of a rule.  They may not be nested inside of `if`
statements or declared in CVL functions.  They may be passed as arguments to
CVL functions.

Properties of methods can be extracted from `method` variables using a
field-like syntax.  The following fields are available on a method `m`:

* `m.selector`   - the ABI signature of the method 
* `m.isPure`     - true when m is declared with the pure attribute
* `m.isView`     - true when m is declared with the view attribute
* `m.isFallback` - true when `m` is the fallback function
* `m.numberOfArguments` - the number of arguments to method m
* `m.contract`   - the receiver contract for the method

There is no way to examine the contents of a `calldataarg` variable, because
the type of its contents vary depending on which method the Prover is checking.
The only thing you can do with it is pass it as an argument to a contract
method call. It is possible to work around this limitation; see
{ref}`partially parametric rules` for further details.

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
variable of type `storage` represents a snapshot of the EVM storage and
the state of {ref}`ghosts <ghost-functions>` at a given point in time.

The EVM storage can be reset to a saved storage value `s` by appending `at s` to
the end of a function call.  For example, the following rule checks that "if you
stake more, you earn more":

```cvl
rule bigger_stake_more_earnings() {
    storage initial = lastStorage;
    env e;

    uint less; uint more;
    require less < more;

    // stake less
    stake(e, less) at initial;
    earnings_less = earnings(e);

    // stake more
    stake(e, more) at initial;
    earnings_more = earnings(e);

    assert earnings_less < earnings_more, "if you stake more, you earn more";
}
```

The `lastStorage` variable contains the state of the EVM after the most recent
contract function call.

Variables of `storage` type can also be compared for equality, allowing simple
rules that check the equivalence of different functions.  See
{ref}`storage-comparison` for details.

(sort)=
### Uninterpreted sorts

```{todo}
This section is incomplete.  See [the old documentation](/docs/confluence/anatomy/ghostfunctions).
```

(type-conversions)=
Conversions between CVL and Solidity types
------------------------------------------

When a specification calls a contract function, the Prover must convert the
arguments from their CVL types to the corresponding Solidity types, and must
convert the return values from Solidity back to CVL.  The Prover must also apply
these conversions when inlining {ref}`hooks <hooks>` and {ref}`function
summaries <function-summary>`.

There are restrictions on what types can be converted from CVL to Solidity and
vice-versa.  In general, if a contract uses a type that is not convertible, you
can still interact with it, but you cannot access the corresponding values. For
example, if a contract function returns a type that isn't convertible to CVL,
you can call the function from CVL but you cannot access its return type.
Similarly, if the function accepts an argument of a type that is not
representable in CVL, you can still call the function from CVL, but only by
providing it a generic {ref}`` `calldataarg` argument <calldataarg>``.

The following restrictions apply when converting between CVL types and Solidity
types:
 - The type must be a {ref}`valid CVL type <solidity-types>` (except for
   contract or interface types, which are represented by `address`).

 - Reference types (arrays and structs) can only be passed to Solidity
   functions that expect `calldata` or `memory` arguments; there is no way to
   pass `storage` arrays.

 - Arrays returned from Solidity can only be converted to CVL if their elements
   have [value types][solidity-value-types] that are representable in CVL.

There are additional restrictions on the types for arguments and return values
for internal function summaries; see {ref}`function-summary`.

[solidity-value-types]: https://docs.soliditylang.org/en/v0.8.11/types.html#value-types

