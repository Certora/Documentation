Built-in Rules
==============

The Prover has some built-in general-purpose rules that can be verified on a
contract out-of-the-box.

## Sanity

Enable with:
```cvl
use builtin rule sanity;
```

The sanity rule acts as one of our main methods to set up a new code base for verification. It serves two needs:

- Checking that the Prover can solve through a non-reverting path of the code, and that no obvious vacuous statements exist. For example, calling a method that always reverts will fail the sanity check, meaning it must be invoked with the `@withrevert` annotation.
- Checking that the Prover can find the said path in a reasonable amount of time for both pre-processing and SMT phases.

It is recommended to include the sanity rule in initial runs of the Prover to ensure the Prover's configuration is a reasonable one.

## Deep Sanity

Enable with:
```cvl
use builtin rule deepSanity;
```

Ensure --multi_assert_check is enabled (otherwise, it will throw an error).

One can configure the number of branching nodes that will be selected. (the nodes that dominate more than the others will always be picked.) Set `--settings -maxNumberOfReachChecksBasedOnDomination=N`, where the default is `N=10`.

### Background and motivation

The basic sanity rule is limited. This is because it only requires finding a _single_ path, and therefore it is not guaranteed that a fast running time for the sanity rule means that the checked method is easy. In addition, it may be able to find a path that does not go through a vacuity that exists deeper down in the code of the program.

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

One trivial way to pass sanity here is to find a model where `array.len=0`. In that case, our sanity check does not visit the loop, regardless of our loop configuration. Any branching in the code is potentially hiding important code.

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

We call each one of the methods of the contract with arbitrary environment and arguments, and assert false. This assert false must be reached (SAT result, or red cross ❌ in the web report) for sanity to succeed.

It can be alternatively written as:
```cvl
rule sanity(method f) {
    env e;
    calldataarg arg;
    f(e, arg); 
    assert !true;
}
```

Where `assert false` is replaced with `assert !true`. This is actually equivalent! However, with a small tweak, it can become the key to getting much wider coverage from sanity rules.

### The generalization

We would like to assert that certain points in the program can be reached.
Let's suppose that for every such interesting point, we add a variable assignment `X = true;`.
We can now instead of `assert false`, write: `assert !X`. If the assert is violated, it means we went through the point that set `X` to true.
If the assert is verified, it means we could not find a path in the program reaching the end through the point we chose, failing our sanity check.
This is, in essence, the effect of running the `deepSanity` rule.

There are an intractable number of paths in complex code, and ensuring that each one can be realized does not scale.
Therefore, the `deepSanity` rule uses a heuristic to pick a few interesting points in the program that must be reached:
1. Conditions, for example, must reach the "if" or "else" case if they are code-heavy 
2. Before an external call
3. The root of the program (this is the same as the usual sanity rule)

The list of such interesting points will be updated from time to time.
