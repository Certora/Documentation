# Harnessing

Occasionally, CVL lacks a feature that is necessary for a complete verification
of a contract.  We are working to extend the feature set of CVL to cover these
cases, but in the mean time we have developed a set of workarounds that we
refer to as "harnesses".

## Example:

Consider a scenario where we want to write a unit test for an internal functions of a contract. The contract serves as a workaround, allowing us to call original functions rather than relying on summarized implementations. 


```solidity
contract ExampleHarnessing is ExampleHarnessingGetter {
    constructor(Configuration memory config) ExampleHarnessingGetter(config) { }
    
    // External wrapper for accrueInternal
    function call_accrueInternal() external {
        return super.accrueInternal();
    }

    // External wrapper for getNowInternal
    function call_getNowInternal() external view returns (uint40) {
        return super.getNowInternal();
    }

    // Compute the n-th power of 10
    function powerOfTen(uint8 n) public pure returns (uint64){
        return uint64(uint64(10) ** n);
    }
}
```
for more details checkout the [source code](https://github.com/Certora/comet/blob/certora/certora/harness/CometHarnessWrappers.sol)

Here's a brief overview:

### unit test internal functions
`call_accrueInternal` and `call_getNowInternal`: External wrappers facilitating access to internal functions like `accrueInternal` and `getNowInternal`.

### define complex functionally  (view/pure)
`powerOfTen`: A utility function to compute the n-th power of 10.

## Getters for private and unstructured state

Rules often need to observe state the contract does not expose: `private`
variables, or unstructured storage kept at a hash-derived slot (EIP-1967
proxy slots, ERC-7201 namespaced storage) and accessed with inline assembly.
A harness contract that inherits from the verified contract can add `view`
getters for exactly this state:

```solidity
contract ProxyHarness is Proxy {
    // keccak256("eip1967.proxy.implementation") - 1, per EIP-1967
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function getImplementation() external view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}
```

The harness is then named as the verified contract (in the {ref}`--verify`
option of the configuration), so rules can call `getImplementation()` like any other
contract method.  Keep such getters `view` and free of any logic beyond the
raw read, so that the harness cannot change the behavior being verified.

Two alternatives avoid a harness altogether when they apply:
 - for *declared* private variables,
   {ref}`direct storage access <direct-storage-access>` reads the variable
   from CVL by name;
 - for unstructured slots, a slot-based storage hook can mirror the value
   into a ghost; see {doc}`/docs/user-guide/patterns/unstructured-storage`.

## Decomposing complex functions

When a single external function performs a long, multi-step state transition
(pull funds, update an index, mint shares, emit checkpoints, ...), verifying
properties of the whole function may time out, and a counterexample over the
whole function can be hard to attribute to a step.  A harness can expose each
step as a thin external wrapper:

```solidity
contract VaultHarness is Vault {
    // each helper is a thin wrapper around one internal step of deposit()

    function helperPullAssets(address from, uint256 assets) external {
        _pullAssets(from, assets);
    }

    function helperAccrueFees() external {
        _accrueFees();
    }

    function helperMintShares(address to, uint256 assets) external returns (uint256) {
        return _mintShares(to, assets);
    }
}
```

Each step can now be specified in isolation &mdash; for example, that
`_accrueFees` is idempotent, or that `_mintShares` is monotonic in `assets`
&mdash; and these intermediate properties compose into an argument about the
full transition.  The wrappers must contain no logic of their own: a wrapper
that re-implements part of the original function verifies the harness, not
the contract.

```{caution}
Helper wrappers expose intermediate states that are not reachable through the
original external interface, and parametric rules over the harness will
instantiate them like any other external method.  Properties that quantify
over "all reachable states" should either filter the helpers out explicitly
or be checked against the original contract as well.
```

## Harness for unresolved calls

For a specialized harness that intercepts unresolved external calls,
see {ref}`unresolved-harness`.