import "./mulDivSummary.spec";
using underlying as asset;

methods {
    function asset.balanceOf(address) external returns(uint256) envfree;
    function balanceOf(address) external returns(uint256) envfree;
    function convertToAssets(uint256) external returns(uint256) envfree;
    function totalSupply() external returns(uint256) envfree;
    function totalAssets() external returns(uint256) envfree;
    
    // Math summaries
    //function _.mulDivDown(uint256 x, uint256 y, uint256 z) internal library => discreteQuotientMulDiv(x, y, z) expect uint256;
}

rule depositRedeemNoGain(uint256 assets, address receiver) {
    env e1;
    require e1.msg.sender != currentContract;
    require e1.msg.sender != asset;

    // If not required, pool starts in a "bad" state
    // where the user can gain free tokens
    require totalSupply() != 0 <=> totalAssets() != 0;

    uint256 balanceBefore = asset.balanceOf(receiver);
        uint256 sharesDep = deposit(e1, assets, receiver);
        uint256 assetsRed = redeem(e1, sharesDep, receiver, e1.msg.sender);
    uint256 balanceAfter = asset.balanceOf(receiver);

    assert receiver == currentContract => balanceBefore <= balanceAfter;
    assert receiver != e1.msg.sender && receiver != currentContract => balanceBefore + assetsRed == to_mathint(balanceAfter);
    assert receiver == e1.msg.sender => balanceBefore >= balanceAfter;
    assert assetsRed <= assets;
}

rule depositRedeemUserLoss_wrong(uint256 assets, address receiver, address owner) {
    env e1;
    require e1.msg.sender != currentContract;
    require e1.msg.sender != asset;

    require totalSupply() != 0 <=> totalAssets() != 0;

    uint256 sharesDep = deposit(e1, assets, receiver);
        uint256 oneShareValue = convertToAssets(1);
    uint256 assetsRed = redeem(e1, sharesDep, receiver, owner);

    require assetsRed <= assets; // True
    assert assetsRed >= require_uint256(assets - oneShareValue) ; // False
}

rule depositRedeemUserLoss(uint256 assets, address receiver, address owner) {
    env e1;
    require e1.msg.sender != currentContract;
    require e1.msg.sender != asset;

    require totalSupply() != 0 <=> totalAssets() != 0;

    uint256 sharesDep = deposit(e1, assets, receiver);
        uint256 oneShareValue = convertToAssets(1);
    uint256 assetsRed = redeem(e1, sharesDep, receiver, owner);

    require assetsRed <= assets; // True
    assert assetsRed >= require_uint256(assets - oneShareValue - 1) ; // True
}

rule depositRedeemMonotinicity(address receiver, address owner) {
    /// deposit block
    env e1;
    require e1.msg.sender != currentContract;
    require e1.msg.sender != asset;
    require owner == e1.msg.sender;

    /// redeem block
    env e2;
    require e2.msg.sender != currentContract;
    require e2.msg.sender != asset;
    require owner == e2.msg.sender;

    uint256 assetsA; // assets to deposit (scenario A)
    uint256 assetsB; // assets to deposit (scenario B)

    require totalSupply() != 0 <=> totalAssets() != 0;

    storage initState = lastStorage; 

    uint256 sharesDep_A = deposit(e1, assetsA, receiver);
    uint256 assetsRed_A = redeem(e2, sharesDep_A, receiver, owner);

    /// Reverse to initial state to start new scenario
    uint256 sharesDep_B = deposit(e1, assetsB, receiver) at initState;
    uint256 assetsRed_B = redeem(e2, sharesDep_B, receiver, owner);

    assert assetsA < assetsB => assetsRed_A <= assetsRed_B;
}

rule depositMonotonicity(address receiver, address owner) {
    env e1;
    require e1.msg.sender != currentContract;
    require e1.msg.sender != asset;
    require owner == e1.msg.sender;

    require totalSupply() != 0 <=> totalAssets() != 0;
    uint256 assetsA;
    uint256 assetsB;
    require assetsA < assetsB;

    storage initState = lastStorage; 

    uint256 sharesDep_A = deposit(e1, assetsA, receiver);

    uint256 sharesDep_B = deposit(e1, assetsB, receiver) at initState;

    assert sharesDep_A <= sharesDep_B; // True
}

rule redeemMonotonicity(address receiver, address owner) {
    env e1;
    require e1.msg.sender != currentContract;
    require e1.msg.sender != asset;
    require owner == e1.msg.sender;

    require totalSupply() != 0 <=> totalAssets() != 0;

    uint256 sharesDep_A;
    uint256 sharesDep_B;
    require sharesDep_A <= sharesDep_B; // True

    storage initState = lastStorage; 

    uint256 assetsRed_A = redeem(e1, sharesDep_A, receiver, owner);

    uint256 assetsRed_B = redeem(e1, sharesDep_B, receiver, owner) at initState;

    assert assetsRed_A <= assetsRed_B; // True
}
