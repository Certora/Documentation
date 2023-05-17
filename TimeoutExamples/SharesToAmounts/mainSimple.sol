// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";
import {FixedPointMathLib} from "./FixedPointMathLib.sol";

contract PoolExample is ERC20 {
    using FixedPointMathLib for uint256;

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        asset = _asset;
    }

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = convertToShares(assets)) != 0, "ZERO_SHARES");

        asset.transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        
        uint256 supply = totalSupply();

        assets = supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
        
        asset.transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        uint256 supply = totalSupply();

        shares =  supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());

        _burn(owner, shares);

        asset.transfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        // Check for rounding error since we round down in previewRedeem.
        require((assets = convertToAssets(shares)) != 0, "ZERO_ASSETS");

        _burn(owner, shares);

        asset.transfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }
}
