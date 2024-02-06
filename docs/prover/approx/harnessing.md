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