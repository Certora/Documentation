# Reasoning about Solidity events

The Prover cannot reason natively about Solidity `events` that a contract `emits`. 

Say in the following example, you want to reason about the `Deposit` event emitted by the function `deposit`. 

```
contract Contract {
    event Deposit(address from, uint amount);
    function deposit(uint amount) public {      
        emit Deposit(msg.sender, amount);
    }
}
```

We recommend to rewrite the code and wrap the `emit` in an internal function that
is then summarized within the methods block. 

```
contract Contract {
   event Deposit(address from, uint amount);
   function deposit(uint amount) public {     
        emitDepositEvent(msg.sender, amount);  
   }
   function emitDepositEvent(address from, uint amount) internal{
        emit Deposit(msg.sender, amount);
   }
}
```

and then 
```cvl
methods {
    function emitDepositEvent(address from, uint amount) internal => cvlEmitDepositEvent(from, amount);
}

function cvlEmitDepositEvent(address from, uint amount){
    // Add the logic you want to verify about
}
```

For more information and a full example checkout [this tutorial](https://github.com/Certora/Examples/tree/master/Events).
