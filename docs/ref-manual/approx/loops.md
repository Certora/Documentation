Loop unrolling
==============

One of the approximations applied by the Certora Prover is loop unrolling.
Loops in the contract are replaced by multiple copies of their bodies.  The
default number of copies is 1, but it can be configured using
the {ref}`--loop_iter` flag.

For example, consider the following solidity function:

```solidity
/// @notice: `f(n)` always returns `n`
function f(uint n) returns uint {
    uint j = 0;
    for (uint i = 0; i < n; i++)
        j++;
    return j;
}
```

With `--loop_iter 2`, the loop in `f` will be approximated by two copies of its
body:

```solidity
function f_unrolled(uint n) returns uint {
    uint i = 0;
    if (i < n) {
        j++;
        i++;
        if (i < n) {
            j++;
            i++;
        }
    }
    return j;
}
```

If a particular example would cause the loop to run more than twice, then the
loop guard (`i < n` in the example) would still be true at the end of the loop.

The Prover has two options for handling examples that would execute the loop
too many times:

 * In **pessimistic mode** (the default), the prover will report an example
   that executes the loop too many times as a violation of the "loop unwinding
   condition" rule.  In pessimistic mode, any rule run on `f(n)` would report a
   violation with `n = 3`.

   Pessimistic mode is {term}`sound`, because there may be rule
   violations in the original code that only occur when the loop runs more than
   3 times, and loop unrolling would cause those violations to be missed.  For
   example, the original function `f` should not satisfy the following rule:

   ```cvl
   rule bogus_rule(uint n) {
       assert f(n) < 5, "f returns something less than 5";
   }
   ```

   but any violation would require 5 or more iterations of the loop.  The loop
   unwinding violation notifies the user that this rule might not hold.

 * In **optimistic mode** (enabled by passing the {ref}`--optimistic_loop` option),
   the prover _ignores_ any examples that would cause the loop to execute
   too many times.  In optimistic mode, the rule `f_lt_5` above would be
   reported as passing.

   ```{caution}
   Optimistic mode is {term}`unsound` since it may miss counterexamples like
   these.  It should be used with care since it may hide bugs.
   ```

   Despite the unsoundness, optimistic mode is quite useful in practice.  For
   example, it allows us to document that `f` satisfies the specification given
   in its documentation:

   ```cvl
   rule f_correct(uint n) {
       assert f(n) == n, "f(n) always returns n";
   }
   ```

   In optimistic mode, this rule will pass (as it should), but in pessimistic
   mode it will fail if `n > 2`.

