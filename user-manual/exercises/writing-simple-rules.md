---
description: Writing simple rules for The Bank example from the previous section
---

# Writing Simple Rules

In this exercise we use as an example a straightforward simple bank implementation \([Bank.sol](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson1/Bank.sol)\). The contract has a mapping from users to their funds and the total funds deposited in the system. The primary operations are `deposit`, `transfer`, and `withdraw`.

## A Basic Rule

Thinking about the function `deposit`, a basic property is:

_**P1: Correct deposit functionality: The balance of the beneficiary is increased appropriately**_

1. Write a rule for checking property P1, "Correct deposit functionality"
2. Is the contract correct with respect to P1?
3. If the contract is incorrect with respect to P1, fix the contract and re-run the Prover.

## Using Precondition checks and Helper Variables

Let’s define another property and verify that after `deposit`, the `totalFunds` in the system is at least the funds of the `msg.sender`:

_**P2: Sanity of deposit: total funds &gt;= funds of the single user**_

```text
rule totalFundsAfterDeposit(uint256 amount) {
	env e; 
	
	deposit(e, amount);
	
	uint256 userFundsAfter = getFunds(e, e.msg.sender);
	uint256 totalAfter = getTotalFunds(e);
	
	// Verify that the total funds of the system is at least the current funds of the msg.sender.
	assert totalAfter >= userFundsAfter, "Total funds are less than a user's funds";
}
```

1. Run the spec on `totalFundsAfterDeposit` only \(hint: `--rule`\).
2. A violation is found. Do you understand why?
3. Adding additional variables to the rule can help understand the counter-example. Try adding the _**helper variables**_ `userFundsBefore` and `totalBefore`.
4. Add a precondition using `require` on the initial state before invoking `deposit`. re-run the tool and make sure that the rule passes. Give your run a distinct name using `--msg`.
5. Is the requirement you added a realistic one? Or can it be violated in concrete executions of the Bank contract?

## Parametric Rules

This property can be generalized to hold for all functions.

_**P3: Sanity of total funds: total funds &gt;= funds of a single user**_

1. Write a rule for checking propert P3.
2. Your new rule should run on all public or external methods in the Bank contract. Make sure that you see all functions results.
3. Are all functions correct with respect to P3?
4. Re-run the tool on the original version of the Bank contract. What are the results of P3 now?

Parametric rules enable expressing reusable and concise correctness conditions. Note that they are not dependent on the implementation. You can integrate them easily into the CI to verify changes to the code, including signature changes, new functions, and implementation changes.

