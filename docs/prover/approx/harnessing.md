# Harnessing

Occasionally, CVL lacks a feature that is necessary for a complete verification
of a contract.  We are working to extend the feature set of CVL to cover these
cases, but in the mean time we have developed a set of workarounds that we
refer to as "harnesses".

Harnesses involve systematically altering the behavior of the code being
verified.  They are therefore {term}`unsound`.

## Harnessing by extension

### Example: CometHarnessWrappers

Consider a scenario where we need to verify internal functions of a contract. The CometHarnessWrappers contract serves as a workaround, allowing us to call original functions rather than relying on summarized implementations. 


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

    // External wrapper for isInAsset. Calls the original function not the summarized implementation
    function call_isInAsset(uint16 assetsIn, uint8 assetOffset) external view returns (bool) {
        return super.isInAsset(assetsIn, assetOffset);
    }

    // External wrapper for updateAssetsIn. Calls the original function not the summarized implementation
    function call_updateAssetsIn(address account, address asset, uint128 initialUserBalance, uint128 finalUserBalance) external {
        AssetInfo memory assetInfo = getAssetInfoByAddress(asset);
        super.updateAssetsIn(account, assetInfo, initialUserBalance, finalUserBalance);
    }

    // External wrapper for _getPackedAsset. Takes as args all fields of assetConfig since structs aren't stable at the moment. Calls the original function not the summarized implementation.
    function call_getPackedAsset(uint8 i, address assetArg, address priceFeedArg, uint8 decimalsArg, uint64 borrowCollateralFactorArg, uint64 liquidateCollateralFactorArg, uint64 liquidationFactorArg, uint128 supplyCapArg) public view returns (uint256, uint256) {
        AssetConfig memory assetConfigInst = AssetConfig({        
        asset: assetArg,
        priceFeed: priceFeedArg,
        decimals: decimalsArg,
        borrowCollateralFactor: borrowCollateralFactorArg,
        liquidateCollateralFactor: liquidateCollateralFactorArg,
        liquidationFactor: liquidationFactorArg,
        supplyCap: supplyCapArg
        });
        AssetConfig[] memory assetConfigs = new AssetConfig[](1);
        assetConfigs[0] = assetConfigInst;
        return super.getPackedAssetInternal(assetConfigs, i);
    }

    // External wrapper for principalValue from CometCore
    function call_principalValue(int104 presentValue_) external view returns (int104) {
        return super.principalValue(presentValue_);
    }

    // External wrapper for presentValue from CometCore
    function call_presentValue(int104 principalValue_) external view returns (int256) {
        return super.presentValue(principalValue_);
    }

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

call_isInAsset: An external wrapper for isInAsset providing access to the original function.

call_updateAssetsIn: An external wrapper for updateAssetsIn ensuring calls to the genuine function.

call_getPackedAsset: An external wrapper for _getPackedAsset to obtain results from the authentic function, not the summarized one.

call_principalValue and call_presentValue: External wrappers for functions from CometCore providing access to the underlying logic.

call_accrueInternal and call_getNowInternal: External wrappers facilitating access to internal functions like accrueInternal and getNowInternal.

powerOfTen: A utility function to compute the n-th power of 10.

In essence, these wrappers allow us to extend CVL's functionality for a more comprehensive verification until CVL itself incorporates these needed features.