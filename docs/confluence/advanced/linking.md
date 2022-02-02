Linking Contracts
=================

Suppose we have a contract `BankStorage`:

```solidity
contract BankStorage {
  uint public total;
  mapping(address => uint) public balances;
  
  address owner;
  
  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
  }
  
  function setTotal(uint x) external onlyOwner {
      total = x;
  }
  
  function setBalances(address who, uint x) external onlyOwner {
      balances[who] = x;
  }
  
  constructor() public {
      owner = msg.sender;
  }
}
```

`BankStorage` is used in a contract `Bank`:

```solidity
contract Bank {
  BankStorage s;
  
  function balanceOf(address who) public returns (uint) {
      return s.balanceOf(who);
  }
  
  function mint(uint amount) external {
      s.setTotal(total() + amount); // ignoring overflows
      s.setBalances(msg.sender, amount);
  }
}
```

If we check `Bank` on its own without knowing the code of `BankStorage`, the Certora Prover cannot guarantee that the code of `Bank` is correct. This is because the implementation of `BankStorage` may not behave as intended.

One way to overcome this problem is by _linking_ the `Bank` contract to `BankStorage`. This is done as follows:

```bash
certoraRun Bank.sol BankStorage.sol --link Bank:s=BankStorage --verify Bank:bank.spec
```
