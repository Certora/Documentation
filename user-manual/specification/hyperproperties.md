# Hyperproperties

It is possible to compare the effects of different transactions starting on the same state. The `additiveTransfer` rule checks that the transfer command is additive.

```text
rule additiveTransfer(uint256 amt1, uint256 amt2, address from, address to) {
    env e1;
    env e2;

    // e1 and e2 transfer from the same address `from`
    require e1.msg.sender == from && e2.msg.sender == from;
    
    // Record state before the transaction
    storage init = lastStorage;
        
    // Transfer amt1 and then amt2 from `from` to `to`
    sinvoke transfer(e1, to, amt1);
    sinvoke transfer(e2, to, amt2);
    uint256 balanceToCase1 = sinvoke getFunds(to);
    uint256 balanceFromCase1 = sinvoke getFunds(from);
    
    // Start a new transaction from the initial state
    sinvoke transfer(e1, to, amt1 + amt2) at init;
    uint256 balanceToCase2 = sinvoke getFunds(to);
    uint256 balanceFromCase2 = sinvoke getFunds(from);
    assert balanceToCase1 == balanceToCase2 &&
           balanceFromCase1 == balanceFromCase2,
           "expected transfer to be additive" ;
}
```



