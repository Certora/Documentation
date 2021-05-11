---
description: >-
  In this tutorial, you will practice understanding counter-examples produced by
  Certora Prover.
---

# Understanding Counter-examples

## Warm-up Exercise

Start with [Ball Game](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/BallGame/BallGame.sol), implementing a ball game with four players. Player 1 passes the ball to Player 2; Player 2 passes back to Player 1. Player 3 and 4 pass to each other. The ball starts at Player 1. Let's prove that the ball can never reach player 4.

* Run:

  ```text
  certoraRun BallGame.sol --verify BallGame:BallGame.spec 
  ```

* Understand the counter-example
* Fix the rule to avoid superfluous initial states

We learn here that to prove the required property, we needed to prove a stronger invariant.

## Realistic Exercise

[Manager](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/Manager.sol) implements transferring of a management role of a fund. It is a requirement that an address can manage at most one fund. Let's try to prove this property.

[Manager.spec](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/Manager.spec) contains a typical parametric rule `uniqueManagerAsRule`.

* Run:

  ```text
  certoraRun Manager.sol --verify Manager:Manager.spec 
  ```

* Understand the counter-examples.
* Understand which additional properties are related and need to be proven together.
* Fix the rule.
* Check your rule as sometimes the rule is too strict, it limits the possible initial states or executions too much:
  * Insert bugs to the code that you believe should be uncovered and re-run Certora Prover
  * Run on [ManagerBug1](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/ManagerBug1.sol) and [ManagerBug2](https://github.com/Certora/CertoraProverSupplementary/blob/master/Tutorials/Lesson2/Manager/ManagerBug2.sol)

    To run on those files:

    ```text
    certoraRun ManagerBug1.sol:Manager --verify Manager:Manager.spec --msg "check for bug"
    certoraRun ManagerBug2.sol:Manager --verify Manager:Manager.spec --msg "check for bug"
    ```

    Did your rule find violations?

