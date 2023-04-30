Builtin Rules
=============
CVT has builtin rules targeted at finding known vulnerabilities. 
You can add several builtin rules and all other rule types in the same spec file.


Sytax
------
"use builtin rule" id


Example
-------
use builtin rule msgValueInLoopRule

The names of currently implemented rules:
-----------------------------------------
msgValueInLoopRule – check for occurrences of "msg.value" and delegate calls in loops.
