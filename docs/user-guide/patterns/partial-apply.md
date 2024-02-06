(partially parametric rules)=
# Partially Parametric Rules

The provided code snippet illustrates a partially parametric rule in CVL that defines specific behavior based on the method invoked (`f`) and its arguments (`calldataarg`). Let's break down the example for better understanding:

```cvl
rule partially_parametric_rule(env e, method f, calldataarg args)
{
    if (f.selector == sig:withdraw(uint256, address).selector) {
        uint256 shares;
        address to;
		require e.msg.sender != currentContract;
		require shares == totalSupply();
		withdraw(e, shares, to);
		assert balanceOf(to) >= balanceOf(currentContract); 
	}
	else if (f.selector == sig:deposit(uint256, address).selector) {
        uint256 depositedAmount = balanceOf(e.msg.sender);
        address to;
		require e.msg.sender != currentContract;
		deposit(e, depositedAmount, to);
        assert balanceOf(to) >= balanceOf(e.msg.sender);
	}
	else {
        uint256 currentContract_balance_before = balanceOf(currentContract);
		f(e, args);
        assert balanceOf(currentContract) == currentContract_balance_before;
	}
}
```

1. **Withdrawal Case:**
   - If the invoked method (`f`) corresponds to the `withdraw` function with arguments of type `uint256` and `address`, the rule checks certain conditions:
     - Ensures that the sender is not the current contract (`currentContract`).
     - Requires that the variable `shares` is equal to the total supply.
     - Invokes the `withdraw` function with specified parameters (`e`, `shares`, `to`).
     - Asserts that the balance of the recipient (`to`) is greater than or equal to the balance of the current contract.

2. **Deposit Case:**
   - If the invoked method (`f`) corresponds to the `deposit` function with arguments of type `uint256` and `address`, the rule checks similar conditions:
     - Ensures that the sender is not the current contract (`currentContract`).
     - Computes the `depositedAmount` as the balance of the sender (`e.msg.sender`).
     - Invokes the `deposit` function with specified parameters (`e`, `depositedAmount`, `to`).
     - Asserts that the balance of the recipient (`to`) is greater than or equal to the balance of the sender.

3. **Default Case:**
   - For any other method, the rule captures the state of the current contract's balance before the method (`f`) execution in the variable `currentContract_balance_before`.
   - Invokes the method (`f`) with its corresponding arguments (`args`).
   - Asserts that the balance of the current contract after the method execution is equal to the recorded `currentContract_balance_before`.

This partially parametric rule demonstrates conditional logic based on the type of method invoked, allowing for specific actions and assertions tailored to different scenarios within the smart contract.