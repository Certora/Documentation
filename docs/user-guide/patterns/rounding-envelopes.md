# Rounding Envelopes

Practical, solver‑friendly bounds for protocols with fixed‑point arithmetic and rounding, distilled from ERC‑4626 wrappers and Aave‑style indices (RAY), and applicable to many designs.

## Preview vs. Actual

Enforce preview equals actual (a stronger property than the EIP requires) and independence from allowance policies.

```cvl
rule previewDepositAmountCheck(){
    env e1; env e2; uint256 assets; address receiver;
    assert previewDeposit(e1, assets) == deposit(e2, assets, receiver);
}

rule previewDepositIndependentOfAllowanceApprove(){
    env e1; env e2; env e3; env e4; env e5; address user; uint256 assets;

    uint256 a1 = _AToken.allowance(currentContract, user);
    require assets < a1; uint256 p1 = previewDeposit(e1, assets);

    _AToken.approve(e2, currentContract, a1 - assets);
    require _AToken.allowance(currentContract, user) == assets;
    uint256 p2 = previewDeposit(e3, assets);

    _AToken.approve(e4, currentContract, 0);
    require _AToken.allowance(currentContract, user) < assets;
    uint256 p3 = previewDeposit(e5, assets);

    assert p1 == p2 && p2 == p3;
}
```

## Deposit Upper Bounds by Index

Cap aToken deposits relative to the requested `assets` and the income index.

```cvl
rule depositUpperBound(env e){
    uint256 assets; address receiver;
    uint256 before = _AToken.balanceOf(currentContract);
    uint256 idx = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
    require e.msg.sender != currentContract;
    deposit(e, assets, receiver);
    uint256 after = _AToken.balanceOf(currentContract);
    assert (idx > RAY()  => after - before <= assets + idx / RAY());
    assert (idx == RAY() => after - before <= assets + idx / (2 * RAY()));
}
```

## Non‑Zero Mint Condition

Ensure at least one share is minted when assets cover one aToken at current index.

```cvl
rule depositMintsAtLeastOne(env e){
    uint256 assets; address receiver;
    uint256 idx = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
    require e.msg.sender != currentContract;
    uint256 shares = deposit(e, assets, receiver);
    assert assets * RAY() >= to_mathint(idx) => shares != 0;
}
```

## Mint Envelope

Receiver balance increases by the requested shares, up to one extra due to rounding.

```cvl
rule mintBounds(env e){
    uint256 shares; address receiver;
    require e.msg.sender != currentContract;
    uint256 idx = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
    uint256 pre = balanceOf(e, receiver);
    require pre + shares <= max_uint256;
    mint(e, shares, receiver);
    uint256 post = balanceOf(e, receiver);
    assert (idx >= RAY());
    assert to_mathint(post) >= pre + shares;
    assert to_mathint(post) <= pre + shares + 1;
}
```

## Joining/Splitting Near‑Additivity

Sum of conversions is within ±1 of converting the sum when rounding to integer shares.

```cvl
rule convertSumOfAssetsPreserved(uint256 a1, uint256 a2) {
    env e;
    uint256 s1 = convertToShares(e, a1);
    uint256 s2 = convertToShares(e, a2);
    uint256 as = require_uint256(a1 + a2);
    mathint js = convertToShares(e, as);
    assert js >= s1 + s2;
    assert js <  s1 + s2 + 2;
}
```

## Tips
- Keep envelopes tight but conservative; ±1 bounds often suffice and stabilize solvers.
- Use `mathint` to avoid silent overflow in intermediate arithmetic.
- Prefer coarse summaries for heavy dependencies (pools/controllers) and assert observable effects (balances/indices) instead.
