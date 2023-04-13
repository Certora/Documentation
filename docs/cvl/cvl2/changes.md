Syntax changes introduced in CVL 2
==================================

CVL 2.0 is a major overhaul to the type system of CVL.  Many
of the changes are internal, but we also wanted to take this opportunity to
introduce a few improvements to the syntax.  The general goal of these changes
is to make the behavior of CVL more explicit and predictable, and to bring the
syntax more in line with Solidity's syntax.

This document summarizes the changes to CVL syntax introduced by CVL 2.0.

```{contents}
```

Superficial syntax changes
--------------------------

There are several simple changes to the syntax to make specs more uniform and
consistent, and to reduce the superficial differences with Solidity.

### `function` and `;` required for methods block entries

In CVL 2, methods block entries must now start with `function` and end with
`;` (semicolons were optional in CVL 1).  For example:

```cvl
balanceOf(address) returns(uint) envfree
```
will become
```cvl
function balanceOf(address) external returns(uint) envfree;
```
(note also the addition of `external`, {ref}`described below <cvl2-visibility>`).

This is also true for entries with summaries:
```cvl
_setManagedBalance(address,uint256) => NONDET
```
will become
```cvl
function _setManagedBalance(address,uint256) internal => NONDET;
```

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### Required `;` in more places

`using`, `import`, and `use` statements all require a `;` at the end.  For
example,

```cvl
using C as c
```

becomes
```cvl
using C as c;
```

`use` statements do not require (and may not have) a semicolon if they
are followed by a `preserved` or `filtered` block.  For example:

```cvl
use rule poolSolvency filtered {
    f -> !isEmergencyWithdrawal(f)
}
```

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### Method literals require `sig:`

In some places in CVL, you can refer to a contract method by its name and
argument types.  For example, you might write
```cvl
require f.selector == balanceOf(address).selector;
```

In this example, `balanceOf(address)` is a *method literal*.  In CVL 2,
these methods literals must now start with `sig:`.  For example, the above
would become:

```cvl
require f.selector == sig:balanceOf(address).selector;
```

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### Use of contract name instead of `using` variable

In CVL 1, the only way to refer to a contract in the {term}`scene` was to first
introduce a contract instance variable with a `using` statement, and then use
that variable.  For example, to access a struct type `S` defined in
`Example.sol`, you would need to write

```cvl
using Example as c;

rule example {
    c.S x = getAnS();
}
```

In CVL 2, you must now use the name of the contract, rather than the instance
variable, when referring to user-defined types.  The above example would now be
written

```cvl
rule example {
    Example.S x = getAnS();
}
```

There is no need for a `using` statement in this example.

Calling methods on secondary contracts still requires using a contract instance
variable:

```cvl
using Example as c;

rule example {
    ...
    c.balanceOf(a);
    ...
}
```

Entries in the `methods` block may use either the contract name or the instance
variable:

```cvl
using Example as c;

methods {
    //// both are valid:
    function c.balanceOf(address) external returns(uint) envfree;
    function Example.transfer(address,uint) external envfree;
}
```

% ```{todo}
% Error message
% ```

Changes to methods block entries
--------------------------------

In addition to the superficial changes listed above, there are some changes to
the way that methods block entries can be written (there are also a
{ref}`few instances <cvl2-wildcards>` where the meanings of entries has
changed).  In CVL 1, `methods` block entries often had several different
functions and meanings:

 - They were used to indicate targets for summarization
 - They were used to write generic specs that could apply to contracts with
   missing methods
 - They were used to declare targets `envfree`

The changes described in this section make these different uses more explicit:

```{contents}
:local:
:depth: 1
```

### Most Solidity types allowed as arguments

CVL 1 had some restrictions on the types of arguments allowed in `methods` block
entries.  For example, user-defined types (such as enums and structs) were not
fully supported.

CVL 2 `methods` block entries may use any Solidity types for arguments and
return values, except for [function types][sol-fn-types] and contract or
interface types.

[sol-fn-types]: https://docs.soliditylang.org/en/v0.8.17/types.html#function-types

To work around the missing types, CVL 1 allowed users to encode some
user-defined types as primitive types in the `methods` block; these workarounds
are no longer allowed in CVL 2.  For example, consider the following solidity
function:

```solidity
contract Example {
    enum Permission { READ, WRITE };

    function f(Permission p) internal { ... }
}
```

In CVL 1, a methods block entry for `f` would need to declare that it takes a
`uint8` argument:

```cvl
methods {
    f(uint8 permission) => NONDET
}
```

In CVL 2, the methods block entry should use the same type as the Solidity
implementations, except for function types and contract or interface types:

```cvl
methods {
    function f(Example.Permission p) internal => NONDET;
}
```
The method can be called from CVL as follows:
```cvl
rule example {
    f(Example.Permission.READ);
}
```

Contract functions that take or return contract or interface types should
instead use `address` in the `methods` block declaration.  For example, if the
contract contains the following function:

```solidity
function listToken(IERC20 token) internal
```

the `methods` block should use `address` for the `token` argument:

```cvl
methods {
    function listToken(IERC20 address) internal
}
```

Contract functions that take or return function types are not currently
supported.  Users can use {ref}`munging <munging>` to work around this
limitation.

(cvl2-visibility)=
### Required `internal` or `external` annotation

Every methods block entry must be marked either `internal` or `external`.  The
annotation must come after the argument list and before the `returns` clause.

If a function is declared `public` in Solidity, then the Solidity compiler
creates an internal implementation method, and an external wrapper method that
calls the internal implementation.  Therefore, you can summarize a `public`
method by marking the summarization `internal`.

```{warning}
The behavior of `internal` vs. `external` summarization for public methods can
be confusing, especially because functions called directly from CVL are not
summarized.

Consider a public function `f`.  Suppose we provide an `internal` summary for
`f`:

 - Calls from CVL to `f` *will* effectively be summarized, because CVL will call
   the external function, which will then call the internal implementation, and
   the internal implementation will be summarized.

 - Calls from another contract to `f` (or calls to `this.f` from `f`'s contract)
   *will* effectively be summarized, again because the external function
   immediately calls the summarized internal implementation.

 - Internal calls to `f` will be summarized.

On the other hand, suppose we provide an `external` summary for `f`.  In this
case:

 - Calls from CVL to `f` *will not* be summarized, because direct calls from
   CVL to contract functions do not use summaries.

 - Internal calls to `f` *will not* be summarized - they will use the original
   implementation.

 - External calls to `f` (from Solidity code that calls `this.f` or `c.f`) will
   be summarized

In most cases, public functions should use an `internal` summary, since this
effectively summarizes both internal and external calls to the function.
```

If the rare case that you want to summarize the internal implementation and the
external wrapper differently, you can add two separate entries to the `methods`
block.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### `optional` methods block entries

In CVL 1, you could write an entry in the methods block for a method that does
not exist in the contract; rules that would call the non-existent method were
skipped during verification.

This behavior can lead to confusion, because typos or name changes could silently
cause a rule to be skipped.

In CVL 2, this behavior is still available, but the methods entry must contain
the keyword `optional` somewhere after the `returns` clause and before the
summarization (if any).

% ```{todo}
% If a methods block contains a non-optional entry for a method that doesn't exist
% in the contract, you will receive the following error message:
% ```

### `library` annotations

In CVL 2, contract functions declared as library functions must be annotated
with `library` in the `methods` block.

% ```{todo}
% If you forget to declare a method as a `library` method, you will receive the
% following error message:
% ```

### Required `calldata`, `memory`, or `storage` annotations for reference types

In CVL 2, methods block entries for internal functions must contain either `calldata`,
`memory`, or `storage` annotations for all arguments with reference types (such
as arrays).

% ```{todo}
% If you do not change this, you will see the following error:
% ```

(cvl2-wildcards)=
### Summaries only apply to one contract by default

In CVL 1, a summary in the `methods` block applied to all methods with the
given signature.

In CVL 2, summaries only apply to a single contract, unless the old behavior is
explicitly requested by using `_` as the receiver.  If no contract is specified,
the default is `currentContract`.

Entries that use `_` as the receiver are called {term}`wildcard entries <wildcard>`, summaries
that do not are called {term}`exact entries <exact>`.

Consider the following example:
```cvl
using C as c;

methods {
    function f(uint)   internal => NONDET;
    function c.g(uint) internal => ALWAYS(4);
    function h(uint)   internal => ALWAYS(1);
    function _.h(uint) internal => NONDET;
}
```

In this example, the internal function `currentContract.f` has a `NONDET`
summary, `c.g` has an `ALWAYS` summary, a call to `currentContact.h` has an
`ALWAYS` summary and a call to `h(uint)` on any other contract will use a
`NONDET` summary.

Summaries for specific contract methods (including the default
`currentContract`) always override wildcard summaries.

Wildcard entries cannot be declared `optional` or `envfree`, since these
annotations only make sense for specific contract methods.

```{warning}
The meaning of your summarizations will change from CVL 1 to CVL 2.  In CVL 2,
any entry without an `_` will only apply to a single contract!
```

(cvl2-returns)=
### Requirements on `returns`

In CVL 1, the `returns` clause on methods block entries was optional.
CVL 2 has stricter requirements on the declared return types.

Entries that apply to specific contracts (i.e. those that don't use the
`_.f` {ref}`syntax <cvl2-wildcards>`) must include a `returns` clause if the
contract method returns a value.  A specific-contract entry may only omit the
`returns` clause if the contract method does not return a value.

The Prover will report an error if the contract method's return type differs
from the type declared in the `methods` block entry.

% ```{todo}
% Error message
% ```

Wildcard entries must not declare return types, because they may apply to
multiple methods that return different types.

% ```{todo}
% Error message
% ```

If a wildcard entry has a ghost or function summary, the user must explicitly
provide an `expect` clause to the summary.  The `expect` clause tells the
Prover how to interpret the value returned by the summary.  For example:

```cvl
methods {
    function _.foo() external => fooImpl() expect uint256 ALL;
}
```

This entry will replace any call to any external function `foo()` with a call to
the CVL function `fooImpl()` and will interpret the output of `fooImpl` as a
`uint256`.

If a function does not return any value, the summary should be declared with
`expect void`.

% ```{todo}
% Error message
% ```

````{warning}
You must check that your `expect` clauses are correct.

The Prover cannot always check that the return type declared in the `expect`
clause matches the return type that the contract expects.  Continuing the above
example, suppose the contract being verified declared a method `foo()` that
returns a type other than `uint256`:

```solidity
function foo() external returns(address) {
    ...
}

function bar() internal {
    address x = y.foo();
}
```

In this case, the Prover would encode the value returned by `fooImpl()` as a
`uint256`, and the `bar` method would then attempt to decode this value as an
`address`.  This will cause undefined behavior, and in some cases the Prover
will not be able to detect the error.
````

Changes to integer types
------------------------

In CVL 1, the rules for casting between integer types were complex; CVL 2
simplifies them.

The general rule of thumb is that you should use `mathint` whenever possible;
only use `uint` or `int` types for data that will be passed as input to
contract functions.

It is now impossible for CVL math expressions to cause overflow - all integer
operations are exact.
The remainder of this section describes the changes in detail.

(cvl2-mathops-return-mathint)=
### Mathematical operations return `mathint`

In CVL 2, the results of all arithmetic operators have type `mathint`,
regardless of the input types.  Arithmetic operators include `+`,
`*`, `-`, `/`, `^`, and `%`, but not bitwise operators like `<<`, `xor`, and `|`
(changes to bitwise operators are described {ref}`below <cvl2-bitwise>`).

The primary impact of this change is that you may need to declare more of your
variables as `mathint` instead of `uint`.  If you are passing the results of
arithmetic operations to contract functions, you will need to be more explicit
about the overflow behavior by using the {ref}`new casting operators
<cvl2-casting>`.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### Comparisons require identical types

When comparing two integers using `==`, `<=`, `<`, `>`, or `>=`, CVL 2 will
require both sides of the equation to have identical types, and {ref}`implicit
casts <cvl2-casting>` will not be used.  Comparisons with number literals (e.g.
`0` or `1`) are allowed for any integer type.

If you do not have identical types (and cannot change one of your variables to
a `mathint`), the best solution is to use the special
`to_mathint` operator to convert both sides to `mathint`.  For example:

```cvl
assert to_mathint(balanceOf(user)) == initial + deposit;
```

Note that in this example, we do not need to cast the right hand side, since
the result of `+` is always of type `mathint`.

````{note}
When should you not simply cast to `mathint`?  We have one example: consider the
following code:

```cvl
ghost uint256 sum;

hook ... {
    havoc sum assuming sum@new == sum@old + newBalance - oldBalance;
}
```

Simply casting to `mathint` will turn overflows into vacuity.

In this particular example, the right solution is to declare `sum` to be a
`mathint` instead of a `uint`.  Note that with the more recent update syntax,
this problem will correctly be reported as an error.  For example, if you
mistakenly write the following:

```cvl
ghost uint256 sum;

hook ... {
    sum = sum + newBalance - oldBalance;
}
```

then the Prover will again report a type error, but the only available solutions
are to change `sum` to a `mathint` (which would prevent the vacuity) or write
an explicit `assert` or `require` cast (which would make the vacuity explicit).
````

% ```{todo}
% If you do not change this, you will see the following error:
% ```

(cvl2-casting)=
### Implicit and explicit casting

If every number that can be represented by one type can also be represented by
another type, then we say that the first type is a *subtype* of the second type.

For example, a `uint8` variable could have any value between `0` and `2^8-1`,
and all of these values can be stored in a `uint16` variable, so `uint8` is a
subtype of `uint16`.  An `int16` can also store any value between `0` and
`2^8-1`, so `uint8` is also a subtype of `int16`.

All integer types are subtypes of `mathint`, since any integer can be
represented by a `mathint`.

In CVL 1, the rules for converting between supertypes and subtypes were
complicated; they depended not only on the types involved, but on the context
in which the conversion happened.  CVL 2 simplifies these rules and improves the
clarity and predictability of casts.

In CVL 2, with one exception, you can always use a subtype whenever the
supertype is accepted.  For example, you can always use a `uint8` where an
`int16` is expected.  We say that the subtype can be "implicitly cast" to the
supertype.

The one exception is comparison operators; as mentioned {ref}`above <cvl2-mathops-return-mathint>`, you must add an
explicit conversion if you want to compare two numbers with different types.
The `to_mathint` operator exists solely for this purpose; in all other contexts
you can simply use any number when a `mathint` is expected (since all integer
types are subtypes of `mathint`).

In order to convert from a supertype to a subtype, you must use an explicit
cast.  In CVL 1, only a few casting operators (such as `to_uint256`) were
supported.

CVL 2 replaces these casting operators with two new casting operators: *assert casts*
such as `assert_uint8(x)` or `assert_int256(x)`, and *require casts* such as `require_uint8(x)` or `require_int256(x)`.
Each of these casts checks that the value is in range; the `assert` cast will
report a counterexample if the value is out of range, while the `require` cast
will ignore counterexamples where the cast value is out of range.

```{warning}
As with normal `require` statements, require casts can cause vacuity and should
be used with care.
```

CVL 2 supports assert and require casts on all numeric types.

Casts between `address`, `bytes1`...`bytes32`, and integer types are not
supported.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### Modulo operator `%` returns negative values for negative inputs

As in Solidity, if `n < 0` then `n % k == -(-n % k)`.

### Support for `bytes1`...`bytes32`

CVL 2 supports the types `bytes1`, `bytes2`, ..., `bytes32`, as in Solidity.
Number literals must be explicitly cast to these types using `to_bytesN`; for
example:

```cvl
bytes32 x = to_bytes32(0);
```

Unlike Solidity, `bytes1`...`bytes32` literals do not need to be written in hex
or padded to the correct length.

There is no way to convert between these types and integer types (except for
literals as just mentioned).

% ```{todo}
% If you do not change this, you will see the following error:
% ```

(cvl2-bitwise)=
### Changes for bitwise operations

In CVL1, the exact details for bitwise operations (such as `&`, `|`, and `<<`) were not
completely specified, especially for negative integers.

In CVL 2, all bitwise operations (`&`, `|`, `~`, `>>`, `>>>`, `<<`, and `xor`)
on integer types first convert to a 256 bit word, then perform the operations
on the full 256-bit word, then convert back to the expected type.  Signed
integer types use twos-complement encoding.

The two right-shifts differ in how they treat signed integers.  `>>` is an
arithmetic shift; it preserves the sign bit.  `>>>` is a logical shift; it pads
the shifted word with zero.

Bitwise operations cannot be performed on `mathint` values.

```{note}
By default, bitwise operators are {term}`overapproximated <overapproximation>`
(in both CVL 1 and CVL 2), so you may see counterexamples that incorrectly
compute the results of bitwise operations.  The approximations are still
{term}`sound`: the Prover will not report a rule as verified if the original
code does not satisfy the rule.

The {ref}`-useBitVectorTheory` flag makes the Prover's reasoning about bitwise
operations more precise, but this flag is experimental in CVL 2.
```

Removed features
----------------

As part of the transition to CVL 2.0, we have removed several language features
that are no longer used.

We have removed these features because we think they are no longer used and no
longer useful.  If you find that you do need one of these features, contact
Certora support.

### Methods entries for sighashes

In CVL 1, you could write a sighash instead of a method identifier in the
`methods` block.  This feature is no longer supported.  You will need to have
the name and argument types of the called method in order to provide an entry.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### `invoke`, `sinvoke`, and `call`

Older versions of CVL had special syntax for calling contract and CVL functions:
 - `invoke f(args);` should be replaced with `f@withrevert(args);`.
 - `sinvoke f(args);` should be replaced with `f(args);`.
 - `call f(args)` should be replaced with `f(args)`.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### `static_assert` and `static_require`

These deprecated aliases for `assert` and `require` are being removed; replace
them with `assert` and `require` respectively.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### `invoke_fallback`

The `invoke_fallback` syntax is no longer supported; there is no longer a way
to directly invoke the fallback method.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### Havocing local variables

In CVL 1, you could write the following:

```cvl
calldataarg args; env e;
f(e, args);

havoc args;
g(e, args);
```

In CVL 2, you can only `havoc` ghost variables and ghost functions.  Instead of
havocing a local variable, replace the havoced variable with a new variable. For
example, you should replace the above with

```cvl
calldataarg args; env e;
f(e,args);

calldataarg args2;
g(e,args2);
```

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### Destructuring syntax for struct returns

In CVL 1, if a contract function returned a struct, you could use a
destructuring syntax to get the return value in your spec.  For example,
consider the following contract:

```solidity
contract Example {
    struct S {
        uint firstField;
        uint secondField;
        bool thirdField;
    }

    function f() returns(S) { ... }
    function g() returns(uint, uint) { ... }
}
```

To access the return value of `f` in CVL 1, you could write the following:

```cvl
uint x; uint y; bool z;
x, y, z = f();
```

This syntax is no longer supported.  Instead, you should declare a variable with
the struct type:

```cvl
Example.S result = f();
uint x = result.firstField;
```

Destructuring assignments are still allowed for functions that return multiple
values; the following is valid:

```cvl
uint x; uint y;
x, y = g();
```

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### `bytes[]` and `string[]`

In CVL 1, you could declare variables of type `string[]` and `bytes[]`.  You can
no longer use these types in CVL.

You can still declare contract methods that use these types in the `methods`
block.  However, you can only call methods that take one of these types as an
argument by passing a `calldataarg` variable, and you cannot access the return
value of a method that returns one of these types.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

### `pragma`

CVL 1 had a `pragma` command for specifying the CVL version, but this feature
was not used.  It has been removed in CVL 2.

% ```{todo}
% If you do not change this, you will see the following error:
% ```

