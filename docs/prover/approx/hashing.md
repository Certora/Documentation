Modeling of Hashing in CVT
===========


## Introduction

The Keccak hash function is used heavily by Solidity smart contracts. 
Most prominently, all unbounded data structures in storage (arrays, mappings) receive their storage addresses as values of the Keccak function.

The Certora Prover does not operate with an actual implementation of the Keccak hash function, since this would make most verification intractable and provide no benefits in all practical cases we are aware of so far.
Instead, the Keccak hash function is modeled as an arbitrary function that is _injective with large gaps_. 

The hash function `hash` being injective with large gaps means that on distinct inputs `x` and `y`
  - the hashes `hash(x)` and `hash(y)` are also distinct, and
  - the gap between `hash(x)` and `hash(y)` is large enough that every additive term `hash(x) + o` that occurs in the program is also distinct from `hash(y)`.

## Background: The Solidity Storage Model

For instance consider this contract:
```solidity
contract C {
  uint i;                  // slot 0
  uint[] a;                // slot 1
  mapping(uint => uint) m; // slot 2
  // ...
  function foo() {
	// ...
	i = u;    // sstore(0, u)
    // ... 
    a[j] = w; // sstore(hash(1) + j, w)
    // ... 
    m[k] = v; // sstore(hash(2, k), v)
    // ... 
  }
}
```

Here we can see how storage is laid out by solidity.
The occurrences of `sstore(x, y)` in the line comments above denote a storage update of storage address `x` to value `y`.
The scalar `i` is stored at storage address `0`, which is derived from it's slot number in the contract (slots are numbered in order of appearance in the source code).
The array `a` is stored contiguously, starting from slot `hash(1)`.
The entries of mapping `m` are spread out over storage; their locations are computed as the hash of the mapping's storage slot and the key at which the mapping is being accessed; thus the storage slot used for the entry of `m` under key `k` is computed as `hash(2, k)`.

We can see that non-collision of hashes is essential for storage integrity. E.g., if `hash(1) + j` was equal to `hash(2, k)` then the operations on `a` an `m` would interfere with each other.

Also note that the initial storage slots are reserved, i.e., we make sure that no hash value ends up colliding with slots 0 to 10000.


## Modeling the Keccak Function (bounded case)

The Certora Prover models the Keccak hash function as an arbitrary function that is _injective with large gaps_.
That means that if `x != y` then `hash(x) != hash(y)`, but also that for all additive offsets `o` that actually occur in the program `hash(x) + o != hash(y)`.

These constraints are enough for the solidity storage model to work as expected. However when hashes are compared, they might show different behavior from the actual Keccak function (e.g. `hash(x) > hash(y)` is always true or false for given `x` and `y`, but in our formulas, the SMT solver is free to choose a function for `hash` that makes the formula satisfiable.). 
We have not observed a practical use case yet where the numeric values of the hash function play a role, thus we chose this modeling for tractability reasons.


### Example (Imprecision of Modeling)

Whichever distinct values we chose for `x` and `y` in the example below, on the real Keccak function one rule would be violated and one rule would not. In the modeling of the Certora Prover, both rules are violated, since the prover is allowed to "invent" a hash function for each rule and will choose one that violates the property.

```solidity
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

In the discussion so far we only considered hashes of data whose length is already known before program execution (e.g. a `uint` variable always has 256 bit). Hashing of unbounded data (typically unbounded arrays, like `bytes`, `uint[]`, etc.) requires some extra measures, since their implementation requires loops and the the Certora Prover internally eliminates all loops to other constructs in order to achieve better tractability.

The Certora Prover models unbounded hashing similar to how it eliminates loops. The user specifies an upper length bound up to which unbounded hashing should be modeled precisely (using the CLI option {ref}`--hashing_length_bound`) as well as whether this bound is to be assumed or to be verified (using the CLI option {ref}`--optimistic_hashing`).

We demonstrate how these flags work using the following program snippet.

```solidity
contract C {
	mapping(bytes => uint) m;
	bytes b1, b2, b3;
	uint u, v, w;
	...
		require b1.length < 224;
		m[b1] = u;
	...
		// no constraints on b2.length
		m[b2] = v; 
	...
		m[b3] = v;
	    assert(b3.length > 300, "b3 is less than 300 bytes long, unexpectedly")
	...
}
```

Let us assume that the `--hashing_length_bound` flag is set to 224 (which corresponds to 7 machine words).
Then, the first hash operation, triggered by the mapping access `m[b1]`, behaves like the hash of a bounded data chunk. The `--optimstic_hashing` flag has no impact on this hash operation.
Behavior of the second hash operation, triggered by the mapping access `m[b2]`, depends on whether `--optimistic_hashing` is set. 
If the `--optimistic_hashing` flag is not set, the violation of an internal assertion will be reported by the prover, stating that an chunk of data is being hashed that may exceed the given bound of 224.
If the `--optimistic_hashing` flag is set, the prover will internally impose an assumption (like a `require` statement) on `b2` stating that its length cannot exceed 224 bytes.
The third operation behaves like the second, since also no length constraint on `b3` is made by the program. However, we can see the impact of the `--optimistic_hashing` flag on the `assert` command that follows the hash operation: When the flag is set, the assertion will be shown as not violated even though nothing in the program itself prevents `b3` from being longer than 300 bytes. This is an example of potential unsoundness coming from "optimistic" assumptions.
(When `--optimistic_hashing` is not set, then we get a violation from any or all assertions, depending on the configuration of Certora Prover.)






### Examples for Unbounded Hashing

The following collection snippet illustrates the most common use cases for hashing of data that has unbounded length.


```solidity
contract C {
	mapping(bytes => uint) m; 
	uint x, y, z, start, len;
    // ... 
		m[b] = v
    // ... 
		keccak256(abi.encode(x, y, z))
    // ... 
		keccak256(abi.encodePacked(x, y, z))
	// ...
		assembly {
			keccak(start, len)
		}
	// ...
}

```

Probably the most common use case is the use of mappings whose keys are an unbounded array (`bytes`, `string`, `uint[]`, etc.); any access to such a mapping induces a hash of the corresponding array whose length is often unknown and unbounded.

Further use cases include direct calls of the Keccak function, either directly on solidity or inside an inline assembly snippet.

Note that Certora Prover's static analysis is aware of the ABI encoder. Thus, in many cases, it can figure out that when `x, y, z` are scalars that `keccak256(abi.encode(x, y, z))` is actually a bounded hash of the form `hash(x, y, z)` as opposed to an unbounded hash of the `bytes` array that is the result of the `encode` function.




## Conclusion

To summarize, Certora Prover handles hashing in a way such that for the vast majority of hashes it will behave as expected. 

However, it is good to be aware of limitations of the modelling; i.e. that not all properties of the actual Keccak function are preserved but only the ones that are crucial for practical use cases, which are covered by the "injectivity with large gaps" property.

Furthermore, special attention may be necessary when hashing of unbounded data is required. For this case, Certora Prover relies on user-controlled approximations that are analogous to its handling of loops.





<!---
[comment]: # [Mike] : I might say "including bytes and string", since the most common case of unbounded arrays is something like int[]
--->


<!---
comment]: # [Mike] : Link to the setting (it should be documented in ref-manual/cli/options.md)
--->