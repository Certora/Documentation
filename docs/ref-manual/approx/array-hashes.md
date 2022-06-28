Array hashes
============

### Background: Non-Collision of Hashes is Essential for Storage Integrity

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

This means that non-collision of hashes is crucial for memory integrity, since 
a collision means that writes to different solidity variables interfere with 
each other.

### Modelling of Hashing in CVT -- Adequate, Except for Unbounded Arrays

CVT generally uses a modelling of the Keccak function that prohibits these 
unwanted collisions.
An exception to this statement is the case when we hash arrays of unbounded 
length, like `bytes`, or `string`.
If such a `bytes` array is longer than the bound chosen via the 
`--settings -byteMapHashingPrecision=X` CVT setting, CVT will be allowed to 
choose an arbitrary hash value as a result.
Note also that CVT may be allowed to choose the length of the array.

This can easily lead to unexpected collisions.
A workaround for avoiding these collisions is to introduce `requires` statements
that bound the mapping to not exceed the bound for precise hashing.

The dev team is looking into more user-friendly solutions to this problem.


