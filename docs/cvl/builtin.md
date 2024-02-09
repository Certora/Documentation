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
    satisfy true;
}
```

To find a satisfying trace, the Prover must construct an input
for which `f` doesn't revert.

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


