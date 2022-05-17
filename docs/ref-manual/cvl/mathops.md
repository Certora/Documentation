Mathematical Operations
=======================

This page describes the details of how different integer types are handled in
CVL.  The exact rules for casting between `uint` and `mathint` types are
described in detail.

```{warning}
The details of implicit and explicit casting between `uint*`, `int*`, and
`mathint` in CVL are complicated, and depend not only on the expressions being
cast but also on the context in which the resulting expressions are used.
For example, assignment statements work differently than return statements.

This document contains the best existing documentation for the current
implementation, although it is missing some detail.  However, this portion of
CVL is also in the process of being redefined and simplified.

In the mean time, we recommend the following rules of thumb:
 - where possible, use `mathint`
 - use `uint` or `int` types only when you need to pass values to solidity
   functions
 - defer casting from `mathint` to `uint` until as late as possible.
```

```{contents}
```

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


## Maximum values

The maximum values of Solidity integer types are available as the following
variables in CVL:

*   `max_uint` and `max_uint256`
*   `max_uint160` and `max_address`
*   `max_uint128`
*   `max_uint96`
*   `max_uint64`
*   `max_uint32`
*   `max_uint16`
*   `max_uint8`

## Implicit casting

Only the following _implicit_ cast operations are supported in CVL:

*   `numberLiteral` can implicitly cast to `int*` `uint*` `mathint` `address` and `bytesK` .
    
    *   Note, however, that before casting a `numberLiteral` to target type `int*` `uint*` `address` or `bytesK`, it is (statically) checked that the value of the `numberLiteral` is within the bounds for a safe cast to the target type (e.g. `numberLiteral >= 0 && numberLiteral <= 2^256 - 1` for `uint256`). In case the value is out of bounds, an _explicit_ cast is required. There is no bounds checking when target type is `mathint`.
        
    *   Sometimes, even when the `numberLiteral` expression is within bounds, it is not possible to implicitly cast the expression to the target type when the value of expression cannot be determined statically (e.g. `uint256 uu = true ? 42 : 24`). In this case, an explicit cast is required.
        
*   For `uint*` we have the following cases for implicit casts:
    
    *   `uint_k1` can implicitly cast to `uint_k2` when `k1 <= k2`
        
    *   `uint_k1` can implicitly cast to `address` when `k1 <= 160`. Moreover, `address` can implicitly cast to `uint256`, but _not_ the other way around. (Note : This is different from earlier behavior because before, `uint256` and `address` were aliases).
        
    *   `uint*` can implicitly cast to `mathint`. (Note that there is a **difference** in implicit and explicit casts from `uint256` to `mathint` when the expression value is outside the range of a `uint256` variable. While in the implicit cast the `uint256` value remains unchanged when converted to `mathint`, the explicit cast takes a _mod_ of the value with `2^256`. Again, this difference will be “visible” only when casting unsafely from a `uint` to `mathint`, i.e. when the `uint` value is greater than `2^256`)
        
*   NOTE: When performing an _implicit_ cast, the type of the expression being cast _changes_ to the `targetType` except in the case when the expression is either a _variable_ or a _ghostVariable_. In these two cases, it is only checked that the expression type is a _subtype_ of the `targetType`. If the expression type is a subtype of the `targetType` the expression is successfully type checked. Consider the following example:
    

```cvl
uint256 x;                         // x has type uint256     
mathint m1;                        // m1 has type mathint
mathint y = x + m1;                // check that x's type (uint256) is a subtype of targetType (mathint) -- true
assert x < max_uint                // x STILL has type uint256 
```

## Explicit casting

*   An explicit cast operator tries to convert the type of an operand from its original type to the target type. The _conversion_ below specifies how the original expression is modified to a value in the target type. Furthermore, _safe\_cast\_bounds_ specify the range of values for the original expression under which the conversion to the target type is safe to perform (i.e. does not result in an _overflow_). When the value is out of safe bounds (say in case of `to_uint256(-1)`), it results in an _overflow_. Here are the rules for performing different cast operations:
    
*   **To Unsigned Int**
    
    *   **Syntax**: `to_uint256(exp)`
        
    *   **Rules:**
        
        *   `mathint` to `uint`
            
            *   conversion: `exp mod 2^256`
                
            *   safe\_cast\_bounds for warning: `exp >= 0 && exp <= 2^256 - 1`
                
        *   Signed `int` To unsigned `uint`
            
            *   conversion: `exp`
                
            *   safe\_cast\_bounds: `None`
                
        *   NumberLiteral to UnsignedInt
            
            *   conversion: `exp mod 2^256`
                
            *   safe\_cast\_bounds for warning: `exp >= 0 && exp <= 2^256 - 1`
                
        *   `bytesK` to UnsignedInt
            
            *   conversion: `exp`
                
            *   safe\_cast\_bounds for warning: `None`
                

*   **To Signed Int**
    
    *   **Syntax**: `to_int256(exp)`
        
    *   **Rules:**
        
        *   `mathint` to SignedInt
            
            *   conversion: `exp mod 2^256`
                
            *   safe\_cast\_bounds for warning: `exp >= -2^255 && exp <= 2^255 - 1`
                
        *   UnsignedInt to SignedInt
            
            *   conversion: `exp`
                
            *   safe\_cast\_bounds for warning: `exp <= 2^255 - 1`
                
        *   NumberLiteral to SignedInt
            
            *   conversion: `exp`
                
            *   safe\_cast\_bounds for warning: `exp <= 2^255 - 1`
                

*   **To `mathint`**
    
    *   **Syntax:** `to_mathint(exp)`
        
    *   **Rules:**
        
        *   UnsignedInt to `mathint`
            
            *   conversion: `exp`
                
            *   safe\_cast\_bounds: `None`
                
        *   SignedInt to `mathint`
            
            *   conversion: `exp <= 2^255 - 1 ? exp : exp - 2^256`
                
            *   safe\_cast\_bounds: `None`
                
        *   NumberLiteral to `mathint`
            
            *   conversion: `exp`
                
            *   safe\_cast\_bounds: `None`
                

*   When an overflow occurs (i.e. when the inner expression is out of safe cast bounds for a cast operator), a warning is displayed in the call trace:  
    
    ![overflow example](overflow.png)

**Important Note**: This warning is displayed _only_ when

*   The rule does not pass and a counterexample is generated &&
    
*   The tool is able to statically determine the value of the inner expression (e.g. `m3` above) &&
    
*   The inner expression value is out of bounds for a safe cast
    

Thus, a rule such as

```cvl
mathint x1 = -3;
uint256 x2 = uint256(x1);
assert x2 > 0;
```

is **not** going to display the warning because the _rule passes (as per the conversion above_ `x2` is `-3 mod 2^256` which is **positive**_)_ and no counterexample is generated.
