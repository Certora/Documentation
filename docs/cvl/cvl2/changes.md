Syntax changes introduced in CVL 2
==================================

CVL 2.0 (the CVL rewrite) is a major overhaul to the type system of CVL.  Many
of the changes are internal, but we also wanted to take this opportunity to
introduce a few improvements to the syntax.  The general goal of these changes
is to make the behavior of CVL more explicit and predictable, and to bring the
syntax more in line with solidity's syntax.

This document summarizes the changes to CVL syntax introduced by CVL 2.0.

```{contents}
```

Superficial syntax changes
--------------------------

There are several simple changes to the syntax to make specs more uniform and
consistent, and to reduce the superficial differences with Solidity.

### `function` and `;` required for methods block entries
Methods block entries must now start with `function` and end with `;`.  For
example:

```cvl
balanceOf(address) returns(uint) envfree
```
will become
```cvl
function balanceOf(address) external returns(uint) envfree;
```
(note also the addition of `external`, see {ref}`described below <cvl2-visibility>`).

This is also true for entries with summaries:
```cvl
_setManagedBalance(address,uint256) => NONDET
```
will become
```cvl
function _setManagedBalance(address,uint256) internal => NONDET;
```

```{todo}
If you do not change this, you will see the following error:
```

### Required `;` in more places

`using`, `pragma`, and `import` statements all require a `;` at the end.  For
example,

```cvl
using C as c
```

becomes
```cvl
using C as c;
```

```{todo}
If you do not change this, you will see the following error:
```

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

```{todo}
If you do not change this, you will see the following error:
```


Changes to methods block entries
--------------------------------

In addition to the superficial changes listed above, there are some changes that
change the way that methods block entries can be written.  In CVL 1, `methods`
block entries often had several different functions and meanings:

 - They are used to indicate targets for summarization
 - They are used to write generic specs that could apply to contracts with
   missing methods
 - They are used to declare targets `envfree`

With these changes, these different uses are more explicit.

(cvl2-visibility)=
### `internal` and `external`

Every methods block entry must be marked either `internal` or `external`.  The
annotation must come after the argument list and before the `returns` clause.

If a function is declared `public` in solidity, then the solidity compiler
creates an internal implementation method, and an external wrapper method that
calls the internal implementation.  Therefore, you can summarize a `public`
method by marking the summarization `internal`.

If you want to summarize both the internal implementation and the external
wrapper, you need to add two separate entries to the `methods` block.

```{todo}
If you do not change this, you will see the following error:
```

### `optional` methods entries

In CVL 1, you could write an entry in the methods block for a method that does
not exist in the contract; rules that would call the non-existent method are
skipped during verification.

This behavior can lead to confusion, because typos or name changes could silently
cause a rule to be skipped.

In CVL 2, this behavior is still available, but the methods entry must contain
the keyword `optional` somewhere after the `returns` clause and before the
summarization (if any).

```{todo}
If a methods block contains a non-optional entry for a method that doesn't exist
in the contract, you will receive the following error message:
```

### Location modifiers

In CVL 2, methods entries for internal functions must contain either `calldata`,
`memory`, or `storage` annotations for all arguments with reference types (such
as arrays).

```{todo}
is `calldata` actually one of the options?
```

```{todo}
If you do not change this, you will see the following error:
```

### Summaries only apply to one contract by default

In CVL 1, a summary in the `methods` block applied to all methods with the
given signature.  Entries that had both an explicit receiver and a summary,
such as the following, were disallowed:

```cvl
using C as c

methods {
    c.f(uint) => NONDET
}
```

In CVL 2, summaries only apply to a single contract, unless the old behavior is
explicitly requested by using `_` as the receiver.  If no contract is specified,
the default is `currentContract`.

Consider the following example:
```cvl
using C as c;

methods {
    function f(uint)   => NONDET;
    function c.g(uint) => ALWAYS(4);
    function _.h(uint) => NONDET;
}
```

In this example, `currentContract.f` has a `NONDET` summary, `c.g` has an `ALWAYS`
summary, and a call to `h(uint)` on any contract will use a `NONDET` summary.


```{warning}
The meaning of your summarizations will change from CVL 1 to CVL 2.  In CVL 2,
any entry without a `_` will only apply to a single contract!
```

### Requirements on `returns`

In CVL 2, methods block entries require a `returns` clause in the following
situations:

 - The method is not a wildcard entry and the contract function returns a value.
   In this case, the methods block entry must match the contract function's
   return type.

   ```{todo}
   Error message
   ```

 - The method is a wildcard entry that is summarized with a ghost or CVL
   function summary.  In this case, the return type from the CVL function must
   be compatible with the declared return type for the method.

   ```{todo}
   Error message
   ```

In all other situations, a `returns` clause is forbidden.

```{todo}
If you do not change this, you will see the following error:
```

Changes to integer types
------------------------

In CVL 1, the rules for casting between integer types were complex; CVL 2
simplifies them somewhat.

The general rule of thumb is that you should use `mathint` for all function
outputs, and the appropriate `int` or `uint` type for all function inputs.

It is now impossible for CVL math expressions to cause overflow - all integer
operations are exact.

### Mathematical operations return `mathint`

In CVL 2, the result of all arithmetic operators have type `mathint`,
regardless of the input types.  Arithmetic operators include `+`,
`*`, `-`, `/`, `^`, and `%`, but not bitwise operators like `<<`, `xor`, and `|`
(changes to bitwise operators are described {ref}`below <cvl2-bitwise>`).

The primary impact of this change is that you may need to declare more of your
variables as `mathint` instead of `uint`.  If you are performing arithmetic
operations and integers that you are passing to specs, you will need to be more
explicit about the overflow behavior by using the {ref}`new casting operators
<cvl2-casting>`.

```{todo}
If you do not change this, you will see the following error:
```

### Comparisons require identical types

When comparing two integers using `==`, `<=`, `<`, `>`, or `>=`, CVL 2 will
require both sides of the equation to have identical types, and {ref}`implicit
casts <cvl2-casting>` will not be used.

If you do not have identical types, the best solution is to use the special
`to_mathint` operator to convert both sides to `mathint`.  For example:

```cvl
assert to_mathint(balanceOf(user)) == initial + deposit;
```

Note that in this example, we do not need to cast the right hand side, since
the result of `+` is always of type `mathint`.

````{todo}
When should you not simply cast to `mathint`?  We have one example: consider the
following code:

```cvl
ghost uint256 sum;

hook ... {
    havoc sum assuming sum@new == sum@old + newBalance - oldBalance;
}
```

Simply casting to `mathint` will turn overflows into vacuity.  It's not clear
how to generalize from this example.

In this particular example, the right solution is to declare `sum` to be a
`mathint` instead of a `uint`.  Note that with the more "modern" update syntax,
this isn't a problem:

```cvl
ghost uint256 sum;

hook ... {
    sum = sum + newBalance - oldBalance;
}
```
will say that the right-hand side is a `mathint` which can't be assigned to a
`uint`.

````

```{todo}
If you do not change this, you will see the following error:
```

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

In CVL 2, with one exception, you can always use a subtype whenever the
supertype is accepted.  For example, you can always use a `uint8` where an
`int16` is expected.

The one exception is comparison operators; as mentioned above, you must add ans
explicit conversion if you want to compare two numbers with different types.
The `to_mathint` operator exists solely for this purpose; in all other contexts
you can simply use any number when a `mathint` is expected (since all integer
types are subtypes of `mathint`).

In order to convert from a supertype to a subtype, you must use an explicit
cast.  In CVL 1, the syntax for casting to a subtype was `to_<subtype>(value)`,
for example `to_uint256(x)`.

In CVL 2, there are now two casting operators: `assert_<type>(value)` and
`require_<type>(value)` (for example: `assert_uint8(x)` or `require_uint8(x)`).
Each of these cases checks that the value is in range; the `assert` cast will
report a counterexample if the value is out of range, while the `require` cast
will ignore counterexamples where the cast value is out of range.

```{todo}
is it an error to use an explicit cast for an upcast?
```

```{todo}
If you do not change this, you will see the following error:
```

### Support for `bytes<K>`

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

(cvl2-bitwise)=
### Changes for bitwise operations

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Conversion between `bytes<k>`, `address`, and integer types

```{todo}
finish
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

```{todo}
If you do not change this, you will see the following error:
```

### `invoke`, `sinvoke`, and `call`

Older versions of CVL had special syntax for calling contract functions:
 - `invoke f(args);` should be replaced with `f(args);`.
 - `sinvoke f(args);` should be replaced with `f@withrevert(args);`
 - `call f(args)` should be replaced with `f(args)`.

```{todo}
If you do not change this, you will see the following error:
```

### `static_assert` and `static_require`

These deprecated aliases for `assert` and `require` are being removed; replace
them with `assert` and `require`.

```{todo}
If you do not change this, you will see the following error:
```

### Havocing `calldataarg` variables

In CVL 1, you could write the following:

```cvl
calldataarg args; env e;
f(e, args);

havoc args;
g(e, args);
```

You can no longer write `havoc x` where `x` is any variable of type `calldataarg`.

Instead, replace the havoced variable with a new variable.

```{todo}
If you do not change this, you will see the following error:
```

### Destructuring syntax for struct returns

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```
