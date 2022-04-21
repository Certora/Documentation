Invariants
==========

Invariants describe a property of the state of a contract that is always
expected to hold.

```{caution}
Even if an invariant is verified, it may still be possible to violate it.  This
is a potential source of {term}`unsound`ness.  See {ref}`invariant-assumptions`
for details.
```


```{contents}
```


Syntax
------

```
invariant ::= "invariant" id
              [ "(" params ")" ]
              expression
              [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
              [ "{" { preserved_block } "}" ]

preserved_block ::= "preserved"
                    [ method_signature ]
                    [ "with" "(" params ")" ]
                    block

```

Overview
--------

In CVL, an invariant is a property of the contract state that is expected to be
true whenever a contract method is not currently executing.  This kind of
invariant is sometimes called a "representation invariant".

Each invariant has a name, possibly followed by a set of parameters, followed
by a boolean expression.  We say the invariant *holds* if the expression
evaluates to true in every reachable state of the contract, and for all
possible values of the parameters.

While verifying an invariant, the Prover checks two things.  First, it checks
that the invariant is established after the constructor.  Second, it checks
that the invariant holds after the execution of any contract method, assuming
that it held before the method was executed (if it does hold, we say the method
*preserves* the invariant).

If an invariant always holds at the beginning of every method call, it is
always safe to assume that it is true.  The
{ref}`requireInvariant command <requireInvariant>` makes it easy to add this
assumption to another rule, and is a quick way to rule out counterexamples that
start in impossible states.  See also {doc}`/docs/user-guide/patterns/safe-assum`.

(invariant-assumptions)=
Assumptions made while checking invariants
------------------------------------------

In Ethereum, the only way to change the storage state of a smart contract is
using the smart contract's methods.  Therefore, if an invariant depends only on
the storage of the contract, we can prove the invariant by checking it after
calling each of the contract methods.

However, it is possible to write invariants whose value depends on things other
than the contract's storage.  The truth of an expression may depend on the
state of other contracts or on environment variables.  For these invariants,
the expression can change from `true` to `false` without invoking a method on
the main contract.

For example, consider the following contract:

```solidity
contract Timestamp {
    uint256 public immutable timestamp;

    constructor() {
        timestamp = block.timestamp;
    }
}
```

The following invariant will be successfully verified, although it is clearly
false:

```cvl
invariant time_is_now(env e)
    timestamp(e) == e.block.timestamp;
```

The verification is successful because the action that falsifies the invariant
is the passage of time, rather than the invocation of a contract method.

Similarly, an invariant that depends on an external contract can become false
by calling a method on the external contract.

For this reason, invariants that depend on the environment or on the state of
external contracts are a potential source of {term}`unsound`ness, and should be
used with care.


Filters
-------

For performance reasons, you may want to avoid checking an invariant is
preserved by a particular method or set of methods.  Invariant filters provide
a method for skipping verification on a method-by-method basis.

```{caution}
Filtering out methods while checking invariants is {term}`unsound`.
```

To filter out methods from an invariant, add a `filtered` block after the
expression defining the invariant.  The body of the `filtered` block must
contain a single filter of the form `var -> expr`, where `var` is a variable
name, and `expr` is a boolean expression that may depend on `var`.

If the expression evaluates to `false` with `var` replaced by a given method,
the Prover will not check that the method preserves the invariant.  For example,
the following invariant will not be checked on the `deposit(uint)`
method:

```cvl
invariant balance_is_0(address a)
    balanceOf(a) == 0
    filtered {
        f -> f.selector != deposit(uint).selector
    }
```

In this example, when the variable `f` is bound to `deposit(uint)`, the
expression `f.selector != deposit(uint).selector` evaluates to `false`, so the
method will be skipped.

See {ref}`method-type` for a list of the fields available on `method` objects.

Preserved blocks
----------------

```{todo}
This feature is currently undocumented.
```

Writing an invariant as a rule
------------------------------



