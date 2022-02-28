Certora Prover Tutorial
=======================

```{todo}
This tutorial is under development.
```

Secureum Bootcamp Notes
-----------------------

The best existing tutorial for the Certora Prover is the
[lecture notes](https://github.com/Certora/Tutorials)
for our 2022 Secureum Bootcamp.  To follow the tutorial, see the `README` files
in each directory.

Exercises for Writing Rules
---------------------------

In this exercise we use as an example a straightforward simple bank implementation ([Bank.sol](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson1/Bank.sol)). The contract has a mapping from users to their funds and the total funds deposited in the system. The primary operations are `deposit`, `transfer`, and `withdraw`.

### A Basic Rule

Thinking about the function `deposit`, a basic property is:

_**P1: Correct deposit functionality: The balance of the beneficiary is increased appropriately**_

1.  Write a rule for checking property P1, "Correct deposit functionality"
    
2.  Is the contract correct with respect to P1?
    
3.  If the contract is incorrect with respect to P1, fix the contract and re-run the Prover.
    
4.  What about the balances of other users? How should it be affected by a deposit? Think about the property, then repeat steps 1-3 for it.
    

### Using Precondition checks and Helper Variables

Let’s define another property and verify that after `deposit`, the `totalFunds` in the system is at least the funds of the `msg.sender`:

_**P2: Sanity of deposit: total funds >= funds of the single user**_

```cvl
rule totalFundsAfterDeposit(uint256 amount) {
    env e; 
    
    deposit(e, amount);
    
    uint256 userFundsAfter = getFunds(e, e.msg.sender);
    uint256 totalAfter = getTotalFunds(e);
    
    // Verify that the total funds of the system is at least the current funds of the msg.sender.
    assert totalAfter >= userFundsAfter, "Total funds are less than a user's funds";
}
```

1.  Run the spec on `totalFundsAfterDeposit` only (hint: use `--rule`).
    
2.  A violation is found. Do you understand why?
    
3.  Adding additional variables to the rule can help understand the counter-example. Try adding the _**helper variables**_ `userFundsBefore` and `totalBefore`.
    
4.  Add a precondition using `require` on the initial state before invoking `deposit`. re-run the tool and make sure that the rule passes. Give your run a distinct name using `--msg`.
    
5.  Is the requirement you added a realistic one? Or can it be violated in concrete executions of the Bank contract?
    

### Parametric Rules

This property can be generalized to hold for all functions.

_**P3: Sanity of total funds: total funds >= funds of a single user**_

1.  Write a rule for checking property P3.
    
2.  Your new rule should run on all public or external methods in the Bank contract. Make sure that you see all function results.
    
3.  Are all functions correct with respect to P3?
    
4.  Re-run the tool on the original version of the Bank contract. What are the results of P3 now?
    

Parametric rules enable expressing reusable and concise correctness conditions. Note that they are not dependent on the implementation. You can integrate them easily into the CI to verify changes to the code, including signature changes, new functions, and implementation changes.


Exercises for Understanding Counterexamples
-------------------------------------------

### Warm-up Exercise

Start with [Ball Game](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/BallGame/BallGame.sol), implementing a ball game with four players. Player 1 passes the ball to Player 2; Player 2 passes back to Player 1. Player 3 and 4 pass to each other. The ball starts at Player 1. Let's prove that the ball can never reach player 4.

*   Run:
    
    ```bash
    certoraRun BallGame.sol --verify BallGame:BallGame.spec 
    ```
    
*   Understand the counter-example
    
*   Fix the rule to avoid superfluous initial states
    

We learn here that to prove the required property, we needed to prove a stronger invariant.

### Realistic Exercise

[Manager](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/Manager.sol) implements transferring of a management role of a fund. It is a requirement that an address can manage at most one fund. Let's try to prove this property.

[Manager.spec](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/Manager.spec) contains a typical parametric rule `uniqueManagerAsRule`.

*   Run:
    
    ```bash
    certoraRun Manager.sol --verify Manager:Manager.spec 
    ```
    
*   Understand the counter-examples.
    
*   Understand which additional properties are related and need to be proven together.
    
*   Fix the rule.
    
*   Check your rule as sometimes the rule is too strict, it limits the possible initial states or executions too much:
    
    *   Insert bugs to the code that you believe should be uncovered and re-run Certora Prover
        
    *   Run on [ManagerBug1](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/ManagerBug1.sol) and [ManagerBug2](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/ManagerBug2.sol)
        
        To run on those files:
        
        ```bash
        certoraRun ManagerBug1.sol:Manager --verify Manager:Manager.spec --msg "check for bug"
        certoraRun ManagerBug2.sol:Manager --verify Manager:Manager.spec --msg "check for bug"
        ```
        
        Did your rule find violations?
