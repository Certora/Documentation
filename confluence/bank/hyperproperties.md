Hyperproperties
===============

It is possible to compare the effects of different transactions starting on the same state. The `additiveTransfer` rule checks that the transfer command is additive.

```java
rule additiveTransfer(uint256 amt1, uint256 amt2, address from, address to) {
  env e1;
  env e2;
  // e1 and e2 transfer from the same address `from`
  require e1.msg.sender == from && e2.msg.sender == from;
  // Record the state before the transaction
  storage init = lastStorage;
  // Transfer amt1 and then amt2 from `from` to `to`
  transfer(e1,to,amt1);	transfer(e2,to,amt2);
  uint256 balanceToCase1 = getFunds(to);
  uint256 balanceFromCase1 = getFunds(from);
  // Start a new transaction from the initial state	
  uint256 sum_amt = amt1 + amt2;
  transfer(e1, to, sum_amt) at init;
  uint256 balanceToCase2 = getFunds(to);
  uint256 balanceFromCase2 = getFunds(from);
  assert balanceToCase1 == balanceToCase2 &&
    balanceFromCase1 == balanceFromCase2,
    "expected transfer to be additive";
}
```
