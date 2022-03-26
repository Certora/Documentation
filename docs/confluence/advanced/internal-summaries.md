Internal Function Summaries
===========================

Summaries Always Inserted
-------------------------

Summaries for **external** functions are only inserted when an implementation of that function cannot be found, and so we default to some summary that we, the verifier, sees fit. _However_, internal functions can always be found and so it only makes sense to force-replace the body of the function (as opposed to filling in for one that could not be found).‌

Feature Limitations:
--------------------

*   Function must have primitive parameter types and return types (`bool`, `address`, `uintX`, `bytesX`)
    
*   Functions must be pure
    

Allowed Summaries
-----------------

Not all summaries make sense in the context of an internal function. Only the following summaries are allowed:

*   `ALWAYS(X)` the summary always returns `X` and has no side-effects
    
*   `CONSTANT` the summary always returns the same constant and has no side effects
    
*   `NONDET` the summary returns a havoc'd value
    
*   `Ghost` the summary returns the value return by the given ghost function with the given arguments
    

Example
-------

Consider the following toy contract where accounts earn continuously compounding interest. Balances are stored as "day 0 principal" and current balances are calculated from that principal using the function `continuous_interest` which implements the standard continuous interest formula.

```solidity
contract Interest {
  uint256 days;
  uint256 interest;
  mapping(address => uint256) principals;
  // decimals 18
  public uint256 constant e = 2718300000000000000;
  
  function balance(address account) public view returns (uint256) {
    return continuous_interest(principals[account], interest, days);
  }
  
  function advanceDays(uint256 n) public {
    days = days + n;
  }
  
  function continuous_interest(uint256 p, uint256 r, uint256 t)
      internal pure returns (uint256) {
    return p * e ^ (r * t);
  }
}
```

Now suppose we would like to prove that this balance calculation is monotonic with respect to time (as days go by, balance never decreases). The following spec would demonstrate this property.

```cvl
rule yield_monotonic(address a, uint256 n) {
  uint256 y1 = balance(a);
  require n >= 0;
  advanceDays(n);
  uint256 y2 = balance(a);
  assert y2 >= y1;
}
```

Unfortunately, the function `continuous_interest` includes some arithmetic that is very difficult for the underlying SMT solver to reason about and two things may happen.

1.  The resulting formula may be cause the underlying SMT formula to time out which will result in an `unknown` result
    
2.  The Prover will use "overapproximations" of the arithmetic operations in the resulting formula. Basically this means that we let allows some weird and unexpected behavior which _includes_ the behavior of the function, but _also_ includes more behavior. Basically, this means that a counterexample may not be a _real_ counterexample (i.e. not actually possible program behavior). To understand this better see our section on [overapproximation](approximation).
    

It turns out that in this case, we run into problem (2) where the tool reports a violation which doesn't actually make sense. This is where function summarization becomes useful, since we get to decide how we would like to overapproximate our function! Suppose we would like to prove that, _assuming the equation we use to calculate continuously compounding interest is monotonic_, then it is also the case that the value of our principal is monotonically increasing over time. In this case we do the following:

```cvl
methods {
  // tell the tool to use a ghost function as the summary for the function
  continuous_interest(uint256 p, uint256 r, uint256 t) =>
      ghost_interest(p, r, t)
}

// define the ghost function
ghost ghost_interest(uint256,uint256,uint256) {
  // add an axiom describing monotonicity of ghost_interest
  axiom forall uint256 p. forall uint256 r. forall uint256 t1. forall uint256 t2.
      t2 >= t1 => ghost_interest(p,r,t2) >= ghost_interest(p,r,t1);
}

rule yield_monotonic(address a, uint256 n) {
  // internally, when this call continuous_interest, the function will
  // be summarized as ghost_interest
  uint256 y1 = balance(a);
  require n >= 0;
  
  advanceDays(n);
  
  // internally, when this call continuous_interest, the function will
  // be summarized as ghost_interest
  uint256 y2 = balance(a);
  assert y2 >= y1;
}
```

By summarizing `continuous_interest` as a function who is monotonic with its last argument (time) we are able to prove the property.
