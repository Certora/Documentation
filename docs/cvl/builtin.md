Built-in Rules
==============
Certora Prover has built-in general-purpose rules targeted at finding known vulnerabilities.
These rules can be verified on a contract out-of-the-box.

You can add several builtin rules and all other rule types in the same spec file.


Syntax
------
"use builtin rule" id


Example
-------
use builtin rule msgValueInLoopRule

The Names of Currently Implemented Rules:
-----------------------------------------
msgValueInLoopRule – check for occurrences of "msg.value" and delegate calls in loops.
hasDelegateCalls - check for delegatecall anywhere in the contract.


