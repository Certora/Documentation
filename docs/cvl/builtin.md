Built-in Rules
==============

The Prover has some built-in general-purpose rules that can be verified on a
contract out-of-the-box.

## Deep Sanity

Enable with:
```cvl
use builtin rule deepSanity;
```

Ensure `--multi_assert_check` is enabled (will throw an error otherwise!).

One can configure the number of branching nodes that will be selected (it will always pick those nodes that dominate more) by setting `--settings -maxNumberOfReachChecksBasedOnDomination=N`, default `N=10`.

### Background and motivation

Sanity rules are one of our main methods to setup a new code base for verification. It serves two needs:

- Checking that the Prover is able to solve through a path of the code, and that there are no obvious vacuities.
- Checking that the Prover is able to find said path in a reasonable amount of time for both pre-processing and SMT phases.

However sanity rules are limited. As they only require to find a single path, it is not guaranteed that a fast running time for the sanity rule means that the checked method is easy. In addition, it may be able to find a path that does not go through a vacuity that does exist deeper down in the code of the program.

For example, consider:
```solidity
function foo() {
  ...
  for (uint i = 0 ; i < array.len; i++) {
    ...
  }
  ...
}
```

One trivial way to pass sanity here is we can find a model where `array.len=0`. In that case, our sanity check didn’t even visit the loop, regardless of our loop configuration. Any branching in the code is potentially hiding important code. 

### The structure of a sanity rule

We usually write a sanity rule as follows:
```cvl
rule sanity(method f) {
	env e;
	calldataarg arg;
	f(e, arg); 
	assert false;
}
```

That is, we call each one of the methods of the contract with arbitrary environment and arguments, and assert false. This assert false must be reached (SAT result, or red cross :x:  in the web report) for sanity to succeed.

It can be alternatively written like this:
```cvl
rule sanity(method f) {
    env e;
    calldataarg arg;
    f(e, arg); 
    assert !true;
}
```

Where `assert false` is replaced with `assert !true`. This is actually equivalent! But with a small tweak, it can become the key to getting much wider coverage from sanity rules.

### The generalization

We would like to assert certain points in the program can be reached. 
Let's suppose that for every such interesting point, we add a variable assignment `X = true;`.
We can now instead of `assert false`, write: `assert !X`. If the assert is violated, it means we went through the point that set `X` to true.
If the assert is verified, it means we could not find a path in the program reaching the end through the point we chose, failing our sanity check.
This is, in essence, the effect of running the `deepSanity` rule.

There is an intractable number of paths in a complex code and ensuring each one can be realized does not scale. 
The `deepSanity` rule uses a heuristic to pick a few interesting points in the program that must be reached:
- Conditions, for example must reach the "if" or "else" case if they are code-heavy
- Before an external call
- The root of the program (this is the same as the usual sanity rule)

The list of such interesting points will be updated from time to time.

## More rules

```{todo}
To appear.
```

