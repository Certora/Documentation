# Harnessing

Occasionally, CVL lacks a feature that is necessary for a complete verification
of a contract.  We are working to extend the feature set of CVL to cover these
cases, but in the mean time we have developed a set of workarounds that we
refer to as "harnesses".

## Example: CometHarnessWrappers

Consider a scenario where we want to write a unit test for an internal functions of a contract. The CometHarnessWrappers contract serves as a workaround, allowing us to call original functions rather than relying on summarized implementations. 


```solidity
// SPDX-License-Identifier: XXX ADD VALID LICENSE
pragma solidity ^0.8.11;

import "./CometHarnessGetters.sol";
import "../munged/ERC20.sol";
import "../munged/vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Certora's comet harness wrappers contract
 * @notice wrappers for internal function checks
 * @author Certora
 */
contract CometHarnessWrappers is CometHarnessGetters {
    constructor(Configuration memory config) CometHarnessGetters(config) { }
    
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

Here's a brief overview:

### unit test internal functions
`call_accrueInternal` and `call_getNowInternal`: External wrappers facilitating access to internal functions like `accrueInternal` and `getNowInternal`.

### define complex functionally  (view/pure)
`powerOfTen`: A utility function to compute the n-th power of 10.

In essence, these wrappers allow us to extend CVL's functionality for a more comprehensive verification until CVL itself incorporates these needed features.