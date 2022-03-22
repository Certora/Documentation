More Expressive Summaries
=========================

Ghost Summaries
---------------

What we refer to as [ghost functions](../anatomy/ghostfunctions.md) are simply {ref}`uninterpreted functions <uninterp-functions>` uninterpreted functions. Because these can be axiomatized, they can be used to express any number of [approximating](approximation.md) semantics (rather than summarizing a function as simply a constant). For example, say we wanted to give some approximation for a multiplication function--this is an example of an operation that is very difficult for an SMT solver. Perhaps we only care about the monotonicity of this multiplication function. We may do something like the following:

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

You may pass whichever parameters from the summarized function as arguments to the summary in whichever order you want. However you may not put an expression as an argument to the summary.

CVL Function Summaries
----------------------

[CVL Functions](../anatomy/functions.md) provide standard encapsulation of code within a spec file and allow for control flow, local variables etc. (but not loops). A subset of these are allowed as summaries, namely:

1.  They do not contain methods as parameters
    
2.  They do not contain calls to contract functions
    

For example, say we want to summarize a multiplication function again, but this time we want to cut down the search space for the solver a bit. We might try something like the following:

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

In simple cases, these summaries may be used to replace harnesses, though the fact that they cannot call contract functions limits the types of harnesses that may be written.
