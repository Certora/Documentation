Method declarations
===================

(summaries-sec)=
Summarizing Solidity Functions
==============================

Calls inside the code
---------------------

The below table shows the differences between these summaries. Asterisks (\*)
indicate havocing.

<table data-layout="default" class="confluenceTable"><colgroup><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"><col style="width: 113.33px;"></colgroup><tbody><tr><td class="confluenceTd"><p><strong>Summary</strong></p></td><td class="confluenceTd"><p><strong>Return value</strong></p></td><td class="confluenceTd"><p><strong>Return code</strong></p></td><td class="confluenceTd"><p><strong>Current contract state</strong></p></td><td class="confluenceTd"><p><strong>Other contracts states</strong></p></td><td class="confluenceTd"><p><strong>Balances</strong></p></td></tr><tr><td class="confluenceTd"><p><code>HAVOC_ALL</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td></tr><tr><td class="confluenceTd"><p><code>HAVOC_ECF</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Havoc'd except for current contract's balance that may increase</p></td></tr><tr><td class="confluenceTd"><p><code>ALWAYS(n)</code></p></td><td class="confluenceTd"><p>n</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>CONSTANT</code></p></td><td class="confluenceTd"><p>Some constant <code>x</code> for all calls to the same method signature in any target contract</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>PER_CALLEE_CONSTANT</code></p></td><td class="confluenceTd"><p>Every target contract <code>c</code> will return the same constant <code>x_c</code> for all calls to the same method signature</p></td><td class="confluenceTd"><p>success (1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td></tr><tr><td class="confluenceTd"><p><code>DISPATCHER[(bool)]</code></p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td><td class="confluenceTd"><p>See below</p></td></tr><tr><td class="confluenceTd"><p><code>NONDET</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>success(1)</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged</p></td><td class="confluenceTd"><p>Unchanged (up to current transfer)</p></td></tr><tr><td class="confluenceTd"><p><code>AUTO</code></p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td><td class="confluenceTd"><p>Depends on call type*</p></td></tr></tbody></table>

Internal Function Summaries
===========================

Allowed Summaries
-----------------

Not all summaries make sense in the context of an internal function. Only the
following summaries are allowed:

*   `ALWAYS(X)` the summary always returns `X` and has no side-effects
    
*   `CONSTANT` the summary always returns the same constant and has no side
    effects
    
*   `NONDET` the summary returns a havoced value
    
*   `Ghost` the summary returns the value return by the given ghost function
    with the given arguments
    

(old-summary-example)=
Example
-------

Consider the following toy contract where accounts earn continuously
compounding interest. Balances are stored as "day 0 principal" and current
balances are calculated from that principal using the
function `continuous_interest` which implements the standard continuous
interest formula.

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
    return p * e ** (r * t);
  }
}
```

Now suppose we would like to prove that this balance calculation is monotonic
with respect to time (as days go by, balance never decreases). The following
spec would demonstrate this property.

```cvl
rule yield_monotonic(address a, uint256 n) {
  uint256 y1 = balance(a);
  require n >= 0;
  advanceDays(n);
  uint256 y2 = balance(a);
  assert y2 >= y1;
}
```

Unfortunately, the function `continuous_interest` includes some arithmetic that
is very difficult for the underlying SMT solver to reason about and two things
may happen.

1.  The resulting formula may be cause the underlying SMT formula to time out
    which will result in an `unknown` result
    
2.  The Prover will use "overapproximations" of the arithmetic operations in
    the resulting formula. Basically this means that we let allows some weird
    and unexpected behavior which _includes_ the behavior of the function,
    but _also_ includes more behavior. Basically, this means that a
    counterexample may not be a _real_ counterexample (i.e. not actually
    possible program behavior). To understand this better see our section
    on [overapproximation](approximation).
    

It turns out that in this case, we run into problem (2) where the tool reports
a violation which doesn't actually make sense. This is where function
summarization becomes useful, since we get to decide how we would like to
overapproximate our function! Suppose we would like to prove that, _assuming
the equation we use to calculate continuously compounding interest is
monotonic_, then it is also the case that the value of our principal is
monotonically increasing over time. In this case we do the following:

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

By summarizing `continuous_interest` as a function who is monotonic with its
last argument (time) we are able to prove the property.


More Expressive Summaries
=========================

Ghost Summaries
---------------

What we refer to as [ghost functions](../anatomy/ghostfunctions.md) are simply
{ref}`uninterpreted functions <uninterp-functions>`.
Because these can be axiomatized, they can be used to express any number of
[approximating](approximation.md) semantics (rather than summarizing a function
as simply a constant). For example, say we wanted to give some approximation
for a multiplication function--this is an example of an operation that is very
difficult for an SMT solver. Perhaps we only care about the monotonicity of
this multiplication function. We may do something like the following:

```cvl
ghost ghost_multiplication(uint256,uint256) returns uint256 {
  axiom forall uint256 x1. forall uint256 x2. forall uint256 y. 
      x1 > x2 => ghost_multiplication(x1, y) > ghost_multiplication(x2, y);
  axiom forall uint256 x. forall uint256 y1. forall uint256 y2.
      y1 > y2 => ghost_multiplication(x, y1) > ghost_multiplication(x, y2);
}
```

Then we can summarize our multiplication function:

```cvl
methods {
  mul(uint256 x, uint256 y) => ghost_multiplication(x, y);
}
```

You may pass whichever parameters from the summarized function as arguments to
the summary in whichever order you want. However you may not put an expression
as an argument to the summary.

CVL Function Summaries
----------------------

[CVL Functions](../anatomy/functions.md) provide standard encapsulation of code
within a spec file and allow for control flow, local variables etc. (but not
loops). A subset of these are allowed as summaries, namely:

1.  They do not contain methods as parameters
    
2.  They do not contain calls to contract functions
    

For example, say we want to summarize a multiplication function again, but this
time we want to cut down the search space for the solver a bit. We might try
something like the following:

```cvl
function easier_multiplication(uint256 x, uint256 y) returns uint256 {
  require(x < 1000 || y < 1000);
  return to_uint256(x * y);
}
```

and just as above we summarize the multiplication function in the methods block:

```cvl
methods {
  mul(uint256 x, uint256 y) => easier_multiplication(x, y);
}
```

Note this specific summarization is very dangerous and may cause vacuity bugs.

In simple cases, these summaries may be used to replace harnesses, though the
fact that they cannot call contract functions limits the types of harnesses
that may be written.
