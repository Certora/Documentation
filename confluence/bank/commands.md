CVL commands
============

*   `require exp` - assume that `exp` is true at this point (i.e., the tool will only consider executions in which `exp` holds). For example, `require e.msg.sender == admin` would ignore any cases where the caller is not the admin.
    
*   `assert exp` - check if `exp` is true, and output a counterexample if there is an input for which it is false. For example, `assert newBalance == oldBalance + amount` will check that a balance always equals the correct value after a transfer (or will report an error, such as when an account transfers to itself and this assertion doesn't hold). The optional string argument is displayed when the assertion is violated. 
    
*   `foo@withrevert(args)` or `invoke foo(args)`
    
    \- simulate a function named `foo` with arguments `args` allowing it to revert.
    
*   `foo(args)`or `sinvoke foo(args)`
    
    \- simulate a function named `foo` with arguments `args` and assume that it does not revert. This syntax is equivalent to:
    

```java
foo@withrevert(arg); // same as invoke foo(arg)
require !lastReverted;
```

### Boolean operators that do not exist in Solidity

*   Implication: `=>`   
    `A => B` evaluates to true if either `A` is false or `B` is true. For example, `assert e.sender != admin => lastReverted` could check that if the caller is not the admin, a given function must revert in all cases.
    
*   Bi-directional implication: `<=>`  
     `A <=> B` evaluates to true if and only if `A => B && B => A`. For example,  `assert e.sender != admin <=> lastReverted` checks that if the caller is not the admin, a given function reverts and that if the function reverted, it must be the case that the sender was not the admin (basically saying that this is the only reason it would revert).
    

### If Then Else (ITE) expressions

*   CVL supports _If Then Else (ITE)_ expressions that can be used at any place where an expression is expected (e.g., right-hand side of an assignment statement_)._
    
*   It uses the syntax `cond ? e1 : e2` where `cond` is a boolean expression and `e1` and `e2` are arbitrary expressions of the same type.
    
*   It is a type error if `cond` is _**not**_ of type `bool` (e.g. `5 ? 1 : 0`) or if `e1` and `e2` are of **different** types (e.g. `true ? 1 : false`).
    
*   Here are a few examples showing the use of ITE expressions:
    

```java
methods {
    inc() envfree
    dec() envfree
}
// In definitions
definition ABOVE_TEN(uint256 x) returns bool = x > 10 ? true : false;
definition SIGNED_INT_TO_MATHINT(uint256 x) returns mathint = x >= 2^255 ? x - 2^256 : x;
 
 
rule checkITE(mathint r) {
	// In assignment expressions
	uint x = 4 > 5 ? 24 : 42; 
	uint y = SIGNED_INT_TO_MATHINT(2^255);
	bool f = ABOVE_TEN(10);
	uint z = r > 5 ? inc() : dec();
	
	// In assert
	assert z == 11;
  bool a;
  bool b;
  assert (z > y ? 111 : 222) == ((a && b) ? 333 : 111);
 
 // In forall exp
 assert forall uint256 x. ((a || b) ? 100 : 500) * x == 100 * x;
}
```

**Note**: When `cond` evaluates to **true**, _only_ expression `e1` is executed, i.e., _only the **then branch** is executed_ while `e2` is ignored_._ Similarly, when `cond` evaluates to **false**, _only_ expression `e2` is executed, i.e., _only the **else branch** is executed._
