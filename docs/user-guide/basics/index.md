Specification By Example
========================

```{todo}
This chapter is incomplete.  The following resources are available for learning
the basics of the Certora Prover:

 - {doc}`../tutorials` lists workshops and tutorials that cover basic Prover usage
 - The [old documentation](/docs/confluence/examples.md) introduces Prover features by walking through some examples.
```

[videos]: https://www.youtube.com/playlist?list=PLKtu7wuOMP9Wp_O8kylKbtFYgM8HVTGIA "Certora workshop playlist"

The entire running example for this chapter can be found [here][erc20example].

```{contents}
```

The ERC20 Example
=================

Rules in the Certora Verification Language
------------------------------------------------

The Certora Prover verifies that a smart contract satisfies a set of rules written in a language called _Certora Verification Language (CVL)_. Each rule is checked on all possible inputs. Of course, this is not done by explicitly enumerating the inputs, but rather through symbolic techniques. Rules can check that a public contract method has the correct effects on the contract state or returns the correct value, etc... The syntax for expressing rules somewhat resembles Solidity, but also supports more features that are important for verification. 

Basic Rules for ERC20 Contracts
-------------------------------

Most people reading this will be familiar with the basics of an [ERC20 contract][eip-20]. For an ERC20 contract to be implemented correctly, a number of properties must be true of that contract. If clear documentation is available for a contract or protocol, that documentation can be a good place to start when designing a specification. In our case, the first properties we would like to test with the Certora Prover are described in the IERC20 interface.

Consider the following excerpt from the contract interface to implement a simple ERC20:

```solidity
/**
 * Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}
```

As described, a correctly working transfer function should move a certain amount of tokens from the caller's account to the account of the recipient. Let's write our first rule to specify that property: 

```cvl
///Transfer must move `amount` tokens from the caller's account to `recipient`
rule transferSpec {
    address sender; address recip; uint amount;
    env e;
    require e.msg.sender == sender;
    mathint balance_sender_before = balanceOf(sender);
    mathint balance_recip_before = balanceOf(recip);
    transfer(e, recip, amount);
    mathint balance_sender_after = balanceOf(sender);
    mathint balance_recip_after = balanceOf(recip);
    require sender != recip;
    assert balance_sender_after == balance_sender_before - amount,
        "transfer must decrease sender's balance by amount";
    assert balance_recip_after == balance_recip_before + amount,
        "transfer must increase recipient's balance by amount";
}
```

The rule calls withdraw with an arbitrary EVM environment (`e`) in an arbitrary initial state. It assumes that the function does not revert. The assert command checks that success is true on all potential executions. Notice that each Solidity function has an extra argument, which is the EVM environment.

Certora Conference Day 1 Introduction
-------------------------------------
6:30 What does Certora do?

7:05 Notional Incident

9:15 Machines making mistakes is worse than people, some level of paranoia is okay with FV

9:45 Why now? FV has rich and interesting history

11:10 Before if you want funding say no FV, now if you want to get funding say FV

11:30 Good work by others SMT solvers Static Analysis

12:20 Code is law, smart contracts perfect place for FV

12:50 FV is expensive in terms of people and machines, but with $billions, you want to do everything possible including auditing and FV

13:00 How is Certora doing

14:15 Motivation - property that is most interesting for DeFi is solvency

15:45 How is the `prover` performing compared to other techniques

17:15 `truefi` chart who found what

17:55 MakerDAO example, using our technology not our people, finding bug

19:15 State of the art in code tools, automation vs security

21:20 Certora we want the benefit of both

22:20 We want people to write in their own language

23:00 Myths and Reality about FV

26:00 Questions



Certora Conference Day 1 Setup and Rules
----------------------------------------

1:00 Intro and overview
--Installation
--Basic Rules
--Invariants
--Ghosts
Day 2
--How the `prover` works
--Intro to AAVE governance token
--systematic specification design

18:20 Unit test style rules

19:10 ERC20 Example start

19:50 `transferSpec` rule

22:10 introducing notion of environment

23:45 envfree

26:30 Showing web interface

30:10 Modifying rule to exclude same address

31:00 There is no `calltrace` when a rule passes because `calltrace` is for a particular counterexample

31:10 Difference from fuzzer

32:25 default of ignoring reverting paths, `@withrevert` `lastReverted`

35:15 warning about `lastReverted`

35:50 `liveness` property

41:15 Summary
--writing rules is like writing unit tests...
--use `mathint` to avoid overflow
--...

42:40 exercise intro writing `transferFromSpec`

44:15 work time / break

44:45 --rule `ruleName`

47:30 how to generalize rules parametric rules intro

54:00 Starting parametric example

54:40 `calldataarg`

59:05 method selector

1:01:35 Summary

1:02:31 Generalized rule patterns
--stakeholder rule
--variable change rule


Certora Conference Day 1 Ghosts
-------------------------------

0:00 ghost definition

0:20 two kinds of ghosts, ghost variable (covered) and ghost function (not covered)

0:55 ghost syntax

1:35 combining ghost and hook



Certora Conference Day 1 Invariants
-----------------------------------



Certora Conference Day 2 Introduction
-------------------------------------



Certora Conference Day 2 Pipeline
---------------------------------



Certora Conference Day 2 Satisfiability
---------------------------------------



Certora Conference Day 2 AAVE Token
-----------------------------------



Certora Conference Day 2 Properties
-----------------------------------



Example Section Header
----------------------

This is equivalent to starting a markdown line with `##`

For smaller subheadings, add additional hashes `###`

```{todo}
Things to do here
```



[erc20example]: https://github.com/Certora/ERC20Example
[eip-20]: https://eips.ethereum.org/EIPS/eip-20