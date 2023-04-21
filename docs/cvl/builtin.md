Built-in Rules
==============

The Prover has some built-in general-purpose rules that can be verified on a
contract out-of-the-box.

## Deep Sanity

Enable with:
```cvl
use builtin rule deepSanity
```

Ensure `--multi_assert_check` is enabled (will throw an error otherwise!).

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

Where `assert false` is replaced with `assert !true1. This is actually equivalent! But with a small tweak, it can become the key to getting much wider coverage from sanity rules.

### The generalization

There is an intractable number of paths in a complex code and ensuring each one can be realized does not scale. But we can consider simple algorithms to pick main interesting paths. The `deepSanity` rule is implementing heuristics for picking points we must reach as part of sanity. For example, we could pick nodes that:
- Dominate a big number of nodes (we can easily sort through the dominators mapping and pick top dominators)
- Percede an external call
- The root (the usual sanity rule)

For example, if we pick N nodes, for each we make a reachability-style variable `Xn`. `Xn` is initialized at the root to false, and setting it to true at the beginning of the node.

At the end of the instrumented program we add an `assert !Xn`, and make sure to enable multi-assert.

## More rules

```{todo}
This feature is currently undocumented.
```

