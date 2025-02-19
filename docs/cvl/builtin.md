(built-in)=
Built-in Rules
==============

The Certora Prover has built-in general-purpose rules targeted at finding common
vulnerabilities.  These rules can be verified on a contract without writing any
contract-specific rules.

Built-in rules can be included in any spec file by writing `use builtin rule
<rule-name>;`.  This document describes the available built-in rules.

```{contents}
```

Syntax
------

The syntax for rules is given by the following [EBNF grammar](ebnf-syntax):

```
built_in_rule ::= "use" "builtin" "rule" built_in_rule_name ";"

built_in_rule_name ::=
    | "msgValueInLoopRule"
    | "hasDelegateCalls"
    | "trustedMethods"
    | "sanity"
    | "deepSanity"
    | "viewReentrancy"
```

(built-in-msg-value-in-loop)=
Bad loop detection &mdash; `msgValueInLoopRule`
-----------------------------------------------

Loops that [use `msg.value` or make delegate
calls][msg-value-vulnerability] are a well-known source of security
vulnerabilities.

[msg-value-vulnerability]: https://trustchain.medium.com/ethereum-msg-value-reuse-vulnerability-5afd0aa2bcef


The `msgValueInLoopRule` detects these anti-patterns.  It can be enabled by
including
```cvl
use builtin rule msgValueInLoopRule;
```
in a spec file.  The rule will fail on any functions that can make delegate
calls or access `msg.value` inside a loop. This includes any functions that recursively call any functions that has
this vulnerability.

(built-in-has-delegate-calls)=
Delegate call detection &mdash; `hasDelegateCalls`
--------------------------------------------------

The `hasDelegateCalls` built-in rule is a handy way to find delegate calls in
a contract. [Contracts that use delegate calls][delegatecall-vulnerability] require proper security checking.

[delegatecall-vulnerability]: https://blog.solidityscan.com/security-issues-with-delegate-calls-4ae64d775b76

The `hasDelegateCalls` can be enabled by including
```cvl
use builtin rule hasDelegateCalls;
```
in a spec file.  Any functions that can make delegate calls will fail the
`hasDelegateCalls` rule.

(built-in-trusted-methods)=
Trusted methods call detection &mdash; `trustedMethods`
--------------------------------------------------

The `trustedMethods` built-in rule allows to find calls within a contract that are potentially untrusted.
The analysis takes as input a list of trusted methods (defined via their contract address and their method sighashes, 
further details see below) and iterates over the contract to mark all calls that are _not_ on the list and are therefore
potentially untrusted. 

I.e. a method call is trusted iff at the call site:
1. the target contract address is resolvable and is known to be a fixed address (along all possible execution paths) _and_
2. the method sighash is resolvable and is known to be fixed (also along all possible execution paths) _and_
3. the resolved target contract address and the method sighash are on the list of trusted methods.

Vice versa, a method call is untrusted iff:
1. the contract address is not statically computable (cannot be proven to be a fixed address), or
2. the sighash is not statically computable (cannot be proven to be a fixed sighash), or
3. the contract address and the sighash are known but are untrusted according to the list of trusted methods. 


The `trustedMethods` can be enabled by the following steps:

1. Add to your spec file
```cvl
use builtin rule trustedMethods;
```

2. Add to your `.conf` file 

```
 "prover_resource_files": ["trustedMethods:ExampleTrustedMethod.json"],
```

3. Create a file called `ExampleTrustedMethod.json` in the folder from which you are executing the `certoraRun` command. Within the file
specify the contract address and a list of method sighashes you consider trusted. For instance,
```JSON
{
    "0xe0f5206bbd039e7b0592d8918820024e2a7437b9": ["0xfebb0f7e"],
    "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed": ["0xfebb0f7e","0xa7916fac"]
}
```
Here `["0xfebb0f7e","0xa7916fac"]` is the list of methods with signatures `["bar()","baz()"]`. 

Please note, for both the contract addresses and the sighashes it's also possible to use a wildcard `_`. I.e. a line
`"_": ["0xfebb0f7e"]` indicates that any method call to `bar()` - no matter to which target contract address a call resolves to is trusted.
A line `"0xe0f5206bbd039e7b0592d8918820024e2a7437b9": ["_"]` indicates that all methods on contract with address `0xe0f5206bbd039e7b0592d8918820024e2a7437b9` are considered trusted calls by the analysis.

(built-in-sanity)=
Basic setup checks &mdash; `sanity`
-----------------------------------

The `sanity` rule checks that there is at least one non-reverting path through
each contract function.  It can be enabled by including
```cvl
use builtin rule sanity;
```
in a spec file.

The sanity rule is useful for two reasons:

 - It is an easy way to determine which contract functions take a long time to
   analyze.  If a method takes a long time to verify the `sanity` rule (or
   times out), it will almost certainly time out while verifying interesting
   properties.  This can help you quickly discover which methods may need
   {term}`summarization <summary>`.

 - A method the fails the `sanity` rule will revert on every input; every rule
   that calls the method will therefore be {term}`vacuous <vacuity>`.  This
   probably indicates a problem with the Prover configuration; the most likely
   cause is {ref}`loop unrolling <unrolling>`.

We recommend running the sanity rule at the beginning of a project to
ensure that the Prover's configuration is reasonable.

```{note}
The `sanity` built-in rule is unrelated to the {ref}`--rule_sanity` option;
the built-in rule is used to check the basic setup, while `--rule_sanity` checks
individual rules.
```

### How `sanity` is checked

The `sanity` rule is translated into the following {term}`parametric rule`:

```cvl
rule sanity {
    method f; env e;
    calldataarg arg;
    f(e, arg); 
    assert true;
    satisfy true;
}
```

This will create two sub-rules, which will be visible in the report. One
sub-rule checks the `satisfy true` statement, which is fulfilled if there is an
input such that `f(e, arg)` runs to completion without reverting. The other
sub-rule checks the `assert true` statement. Of course, this assertion itself is
never violated, but the sub-rule contains the {term}`pessimistic assertions` that 
we insert when at least one of the "optimistic" flags (e.g.
{ref}`--optimistic_loop`, {ref}`--optimistic_hashing`, etc.) is not active. Note
that rules with only {ref}`satisfy` do not check these assertions.

(built-in-deep-sanity)=
Thorough complexity checks &mdash; `deepSanity`
-----------------------------------------------

The basic sanity rule only tries to find a _single_ input that causes each
function to execute without reverting.  While this check can quickly identify
problems with the Prover setup, a successful `sanity` run does not guarantee
that the contract methods won't cause Prover timeouts, or that all of the
contract code is reachable.

For example, consider the following method:
```solidity
function veryComplexFunction() returns(uint) {
    uint x = 0;
    for (uint i = 0 ; i < array.len; i++) {
        x = x + complexComputation(i);
    }
    return x;
}
```

There is clearly a simple non-reverting path through the code: it will
immediately return if `array.len` is `0`; the basic `sanity` can quickly find a
{term}`model` like this without even considering the implementation of
`complexComputation`, so the `sanity` rule will succeed.  However, verifying
any property that depends on the return value of `veryComplexFunction` will
require the Prover to reason about `complexComputation()`, which may cause
timeouts.  Moreover, portions of `complexComputation` may be unreachable, and
this will not be caught by the basic `sanity` rule.

The `deepSanity` rule generalizes the basic `sanity` rule by heuristically
choosing interesting statements in the contract code and ensuring that there
are non-reverting {term}`models <model>` that execute those statements.  In the above
example, one of the paths chosen by `deepSanity` would go through the body of
the `for` loop, forcing the Prover to find a non-reverting path through the
`complexComputation` method.

The `deepSanity` rule heuristic favors the following program points:
1. The "if" and "else" branches of a code-heavy `if` statement
2. The beginning of an external call
3. The beginning of the program (this is the same as the usual sanity rule)

The `deepSanity` rule can be enabled by including
```cvl
use builtin rule deepSanity;
```
in a spec file.  You must also pass the {ref}`--multi_assert_check` flag to
the Prover.

The number of code points that are chosen can be configured with the
{ref}`-maxNumberOfReachChecksBasedOnDomination` flag; the default value is
`10`.

### How `deepSanity` is checked

The `deepSanity` rule works similarly to the `sanity` rule; it adds an
additional variable `x_p` for each interesting program point `p`, and
instruments the contract code at `p` to set `x_p` to `true`.  The Prover then
tries to prove that `x_p` is false after executing the function.  To find a
counterexample; the Prover must construct a model that passes through `p`.

(built-in-view-reentrancy)=
Read-only reentrancy detection &mdash; `viewReentrancy`
-----------------------------------------------------------

The `viewReentrancy`  built-in rule detects 
[read-only reentrancy vulnerabilities in a contract][view-reentrancy-vulnerability].

[view-reentrancy-vulnerability]: https://blog.pessimistic.io/read-only-reentrancy-in-depth-6ea7e9d78e85

The `viewReentrancy` rule can be enabled by including
```cvl
use builtin rule viewReentrancy;
```
in a spec file.  Any functions that have read-only reentrancy will fail the
`viewReentrancy` rule.

### How `viewReentrancy` is checked

Reentrancy vulnerabilities can arise when a contract makes an external call with an inconsistent internal 
state. This behavior allows the receiver contract to make reentrant calls that exploit the inconsistency.

The `viewReentrancy` rule ensures that whenever a method `f` of {ref}`currentContract <currentContract>` makes an external call, 
the internal state of `currentContract` is equivalent to either (1) the state of `currentContract` at the beginning of the calling function,
or (2) the state of `currentContract` at the end of the calling function (by "equivalent", 
we mean that all view functions return the same values). 
This ensures that the external call cannot observe `currentContract` in any state that it couldn't have without being 
called from `currentContract`. 


