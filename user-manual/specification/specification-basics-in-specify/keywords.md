---
description: >-
  Learn about a few of Specify's special keywords, and how they are used in a
  rule that checks revert conditions in the Bank.
---

# Keywords

## Standard identifiers

The Specify language includes the following standard identifiers: 

* `bool lastReverted` - true when the last function call reverted, for example “did the transfer revert?”. Note that it can only return true if the last function was marked with `@withrevert`.
* `address currentContract` - the address of the current contract that is checked, e.g. the address of `Bank`.
* `storage lastStorage` - The current state of the contract. Useful for enforcing hyperproperties of smart contracts.

{% code title="bank.spec" %}
```javascript
rule transfer_reverts() {
	// A rule with two free variables: 
	//     - to - the address the transfer is passed to 
	//     - amount - the amount of money to pass
	address to; 
	uint256 amount;
	
	env e;
	// Get the caller's balance before the invocation of transfer
	uint256 balance = getFunds(e.msg.sender);

	// invoke function transfer and assume the caller is w.msg.from
	transfer@withrevert(e, to, amount);
	// check that transfer reverts if the sender does not have enough funds 
	assert balance < amount => lastReverted , "insufficient funds"; 
}
```
{% endcode %}

