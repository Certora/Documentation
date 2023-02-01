Modeling of Hashing in CVT
===========


## Introduction

The Keccak hash function is used heavily by Solidity smart contracts. 
Most prominently, all unbounded data structures in storage (arrays, mappings) receive their storage addresses as values of the Keccak function.

<!---
Solidity makes intensive use of the Keccak hash function in order to create
its storage layout.
For instance consider this contract:
```solidity
contract A {
  mapping(uint => uint) m; // first field of A -- gets slot 0

  function setMTo0(uint i) {
    m[i] = 0
  }
}

```
In order to determine the storage address of `m[i]`, solidity 
computes this hash: `keccak(0, i)` (the first argument is 0 because mapping `m` 
is the first field in contract `A`).

This means that non-collision of hashes is crucial for storage integrity, since 
a collision means that writes to different solidity variables interfere with 
each other.


--->

## Modeling the Keccak Function (bounded case)

The Certora Prover models the Keccak hash function as an arbitrary function that is _injective with large gaps_.
That means that if `x != y` then `hash(x) != hash(y)`, but also that for all additive offsets `o` that actually occur in the program `hash(x) + o != hash(y)`.

These constraints are enough for the solidity storage model to work as expected. However when hashes are compared, they might show different behaviour from the actual Keccak function (e.g. `hash(x) > hash(y)` is always true or false for given `x` and `y`, but in our formulas, the SMT solver is free to choose a function for `hash` that makes the formula satisfiable.). 
We have not observed a practical use case yet where the numeric values of the hash function play a role, thus we chose this modeling for tractability reasons.


### Example

Whichever distinct values we chose for `x` and `y` in the example below, on the real keccak function one rule would be violated and one rule would not. In the modeling of the Certora prover, both rules are always violated, since the prover is allowed to "invent" a hash function for each rule and will choose one that violates the property.

```
// CVL:
methods { hash(uint) returns (uint) envfree; }

definition x() : uint = 12345678
definition y() : uint = 87654321

rule hashXLowerOrEqualToHashY {
	assert hash(x()) <= hash(y());
}

rule hashXLargerThanHashY {
	assert hash(x()) > hash(y());
}

// solidity:
contract C {
	function hash(uint x) public returns (bytes32) {
		return keccak256(x);
	}
}

```


<!---
[comment]: # We should also clearly explain the surprising thing the user might see. A clear example of a rule that should pass and doesn't, or a rule that shouldn't pass and does, and an explanation of why.
--->

## Hashing of Unbounded Data

In the discussion so far we only hashed data whose length is already known before program execution (e.g. a `uint` variable always has 256 bit). Hashing of unbounded data (typically unbounded arrays, like `bytes`, `uint[]`, etc.) is trickier, since their implementation requires loops and the the Certora Prover reduces all loops to other constructs in oder to achieve better tractability and robustness.

The Certora Prover models unbounded hashing similar to how it eliminates loops. The user specifies an upper length bound up to which unbounded hashing should be modeled precisely (using the CLI option {ref}`--hashing_length_bound`) as well as whether this bound is to be assumed or to be verified (using the CLI option {ref}`--optimistic_hashing`).


<!---
[comment]: # [Mike] : I might say "including bytes and string", since the most common case of unbounded arrays is something like int[]
--->


<!---
comment]: # [Mike] : Link to the setting (it should be documented in ref-manual/cli/options.md)
--->