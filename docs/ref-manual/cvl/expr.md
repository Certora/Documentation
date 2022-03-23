Expressions
===========

```{todo}
organization
```

CVL Expressions
---------------

```{todo}
List and descriptions of different CVL expressions
```

Built-in variables
------------------

```{todo}
Other magic variables `lastStorage`, etc
```

Sometimes it is useful to bound a `mathint` variable to the ranges allowed by a Solidity type. The following keywords describe the maximal values of their respectively named Solidity types:

*   `max_uint` and `max_uint256`
    
*   `max_uint160` and `max_address`
    
*   `max_uint128`
    
*   `max_uint96`
    
*   `max_uint64`
    
*   `max_uint32`
    
*   `max_uint16`
    
*   `max_uint8`
    


Mathematical operations
-----------------------

In CVL, arithmetic operators (+, -, \* and /) are overloaded: they could mean a
machine-arithmetic operation that can overflow, or a mathematical operation
that does not overflow. The default interpretation used in almost all cases is
the mathematical one. Therefore, the assertion below holds:

```cvl
uint x;
assert x + 1 > x;
```

The syntax supports Solidity’s integer types (`uintXX` and `intXX`) as well as
the CVL-only type `mathint` representing the domain of mathematical integers
(ℤ). Using these types allows controlling how arithmetic operators such as +,
-, and \* are interpreted. Therefore, in the following variant on the above
example, if we wish the + operation to be the overflowing variant, we can write
the following:

```cvl
uint x;
uint y = x + 1;
assert y > x;
```

The assertion here will fail with `x = MAX_INT`, since then y is equal to 0. If
we write instead:

```cvl
uint x;
mathint y = x + 1;
assert y > x;
```

The meaning is the same as in the first snippet since an assignment to a `mathint` variable allows non-overflowing interpretations of the arithmetic operators.

The only case in which arithmetic operators in expressions are allowed to overflow is within arguments passed to functions, or generally, whenever we interact with the code being checked. Solidity functions cannot take values that do not fit within 256 bits. Therefore the tool will report an overflow error if `mathint` variable is passed directly as a function argument.

```cvl
uint256 MAX_INT = 2^256 - 1;
foo(MAX_INT + 1); // equivalent to invoking foo(0)
assert MAX_INT + 1 == 0; // always false, because ‘+’ here is mathematical
mathint x = MAX_INT + 1;
foo(x); // error
```


Casting
-------

