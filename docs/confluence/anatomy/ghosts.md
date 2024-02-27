Ghosts
======

What are ghosts?
----------------

At their core, ghosts are just {ref}`uninterpreted functions <uninterp-functions>`. These uninterpreted functions by themselves wouldn't really be "ghosts" per se. However, along with **axioms** and **hooks**, these uninterpreted functions can be used to model some contract state that isn't explicitly in the contract (hence it is a “ghost” state). In our canonical example, we use ghosts to keep track of the sum of balances in a bank contract.

A Simple Bank Example
---------------------

Consider the following `Bank` contract:

```solidity
contract Bank {
  mapping (address => uint256) balances;
  uint256 public totalSupply;
  
  function deposit(address a, uint256 amount) public {
    // also prevents overflow on account[a].balance, since that's <= totalSupply
    require(totalSupply + amount >= amount);
    balances[a] += amount;
    totalSupply += amount;
  }
  
  function withdraw(address a, uint256 amount) public {
    require(balances[a] >= amount);
    balances[a] -= amount;
    totalSupply -= amount;
  }
  
  function payday(address[] memory payees) public {
    for (uint i = 0; i < payees.length; i++) {
      deposit(payees[i], 1);
    }
  }
}
```

The state of the contract consists of `totalSupply` and `balances` where `balances` keeps track of the balance in each account and `totalSupply` keeps track of the sum of all balances. Now let's suppose that we don't trust that `totalSupply`gets updated correctly. We can introduce a ghost function to keep track of the sum and then compare that ghost function with `totalSupply` to see if they both got updated as expected. Here's what that looks like:

```cvl
// declare the ghost function
ghost ghostSupply() returns uint256;
// the hook that updates the ghost function as follows
// "At every write to the value at key 'a' in 'balances'
// increase ghostTotalSupply by the difference between
// tho old value and the new value"
//                              the new value ↓ written:
hook Sstore balances[KEY address a] uint256 balance
// the old value ↓ already there
    (uint256 old_balance) {
  havoc ghostSupply assuming ghostSupply@new() == ghostSupply@old() +
      (balance - old_balance);
}

rule totalSupplyInvariant(method f) {
  require totalSupply() == ghostSupply();
  calldataarg arg;
  env e;
  sinvoke f(e, arg);
  assert totalSupply() == ghostSupply();
}
```

There are a few things going on here.

1.  We declared `ghost ghostSupply() returns uint256`. This creates an uninterpreted function called `ghostSupply`that takes 0 arguments and returns a `uint256`. Notice that this is in a global scope. Each rule will get its own version of this uninterpreted function, but this way, it doesn't have to be written several times.
    
2.  We declared a `hook`. This hook tells the tool to analyze the rule and find every `Sstore` (write) to an entry in `balances`. It binds the _stored value_ to the name `balance` and the _old value_ to the name `old_balance`.
    
3.  We defined a _ghost update_ inside the _body_ of the hook. We used a `havoc
    assuming` statement to mutate the ghost function. The `havoc
    assuming` statement --- in this case `havoc ghostSupply
    assuming` binds `ghostSupply@new()`, the havoced version,
    and `ghostSupply@old()` the previous version. `ghostSupply` does not exist
    to the right of `assuming`. We then constrain the new version in terms of
    the old.
    

When all of these work in conjunction, the Prover successfully proves the rule `totalSupplyInvariant`.
