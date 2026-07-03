# Hooking on Unstructured Storage

Some contracts keep part of their state outside of declared storage variables,
at storage slots computed from a hash.  Common examples are:

 - [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967) proxy slots, e.g. the
   implementation address at
   `bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)`;
 - [ERC-7201](https://eips.ethereum.org/EIPS/eip-7201) namespaced storage
   layouts, where a struct of state variables lives at
   `keccak256(abi.encode(uint256(keccak256(<namespace>)) - 1)) & ~bytes32(uint256(0xff))`;
 - ad-hoc unstructured storage using `keccak256(<name>)` or
   `keccak256(<name>) - 1` as the slot, read and written with inline assembly.

Because these variables are not part of the Solidity storage layout, they have
no names that can be used in {ref}`hook patterns <access-paths>`, and often no
public getters either.  This does **not** put them beyond the reach of
verification: the hash that determines the slot is a compile-time constant, so
the slot number itself is a constant that can be computed once, offline, and
then used in the specification.

## Computing the slot constant

Compute the slot value with any tool that implements `keccak256` (for example
`cast keccak` from Foundry, or a one-off Solidity snippet), following the
derivation used by the contract.  For the EIP-1967 implementation slot:

```
keccak256("eip1967.proxy.implementation") - 1 =
0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

Bind the constant to a {doc}`definition </docs/cvl/defs>` so that rules and
invariants can refer to it by name, and record the derivation in a comment so
that reviewers can re-check it:

```cvl
// keccak256("eip1967.proxy.implementation") - 1, per EIP-1967
definition IMPLEMENTATION_SLOT() returns uint256 =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
```

## Hooking on the slot

Storage hooks accept a slot number as an access path (see
{ref}`access-paths`).  The hook pattern requires a number literal, so the
constant is repeated in the pattern; the derivation comment should appear
there as well.  The following example mirrors the implementation address into
a {ref}`ghost variable <ghost-variables>`:

```cvl
ghost address ghostImplementation;

// keccak256("eip1967.proxy.implementation") - 1, per EIP-1967
hook Sstore (slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
    address newImplementation {
    ghostImplementation = newImplementation;
}

hook Sload address implementation
    (slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc) {
    require implementation == ghostImplementation;
}
```

With the ghost in place, properties about the unstructured variable are
written exactly as they would be for a declared variable.  For example, a
{doc}`parametric rule </docs/user-guide/parametric>` stating that only the
upgrade function may change the implementation:

```cvl
rule onlyUpgradeChangesImplementation(method f, env e, calldataarg args) {
    address before = ghostImplementation;

    f(e, args);

    address after = ghostImplementation;
    assert after != before => f.selector == sig:upgradeTo(address).selector;
}
```

The same recipe applies to ERC-7201 namespaced structs: the struct's base slot
is a constant, and each member occupies the base slot plus a constant offset
determined by the struct layout, so each member gets its own precomputed slot
constant (and, for packed members, an `.(offset n)` component &mdash; see
{ref}`access-paths`).

```{note}
Inline assembly `sload`/`sstore` instructions can cause the Prover's storage
analysis for *named* variables to fail (see {ref}`storage-and-memory-analysis`).
Slot-based hook patterns like the ones above match the physical slot number
directly, which is exactly how unstructured storage is accessed.  If hooks
still do not apply, check the global problems view of the rule report.
```

## Alternatives

 - A harness getter that reads the slot with inline assembly makes the value
   directly callable from rules, which is often more convenient than a ghost
   when you only need to *read* the value rather than react to writes.  See
   {doc}`/docs/prover/approx/harnessing`.
 - For state that *is* declared as a Solidity variable but merely lacks a
   getter, no slot arithmetic is needed at all: use
   {ref}`direct storage access <direct-storage-access>`.
