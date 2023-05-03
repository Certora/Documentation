Built-in Rules
==============
`Certora` Prover has built-in general-purpose rules targeted at finding known vulnerabilities.
These rules can be verified on a contract out-of-the-box.

You can add several builtin rules and all other rule types in the same spec file.


Syntax
------
The syntax for using the built-in rule identifier

built-in-rule-usage ::= 'use builtin rule' identifier


Example
-------
In order to run the built-in rule `msgValueInLoopRule` add to the spec file the line

use builtin rule msgValueInLoopRule

The Names of Currently Implemented Rules:
-----------------------------------------
- `msgValueInLoopRule` – check for occurrences of `msg.value` and delegate calls in loops.
- `hasDelegateCalls` - check for delegate calls anywhere in the contract.


