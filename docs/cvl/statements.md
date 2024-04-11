# Statements


The bodies of {doc}`rules <rules>`, {doc}`functions <functions>`, and
{doc}`hooks <hooks>` in CVL are made up of statements.  Statements describe the
steps that are simulated by the Prover when evaluating a rule.

Statements in CVL are similar to statements in Solidity, although there are
some differences; see {ref}`control-flow`.  This document lists the available
CVL commands.

```{contents}
```

## Syntax

The syntax for statements in CVL is given by the following [EBNF grammar](ebnf-syntax):

```
block ::= statement { statement }

statement ::= type id [ "=" expr ] ";"

            | "require" expr ";"
            | "static_require" expr ";"
            | "assert" expr [ "," string ] ";"
            | "static_assert" expr [ "," string ] ";"
            | "satisfy" expr [ "," string ] ";"

            | "requireInvariant" id "(" exprs ")" ";"

            | lhs "=" expr ";"
            | "if" expr statement [ "else" statement ]
            | "{" block "}"
            | "return" [ expr ] ";"

            | function_call ";"
            | "call" id "(" exprs ")" ";"
            | "invoke_fallback" "(" exprs ")" ";"
            | "invoke_whole" "(" exprs ")" ";"
            | "reset_storage" expr ";"

            | "havoc" id [ "assuming" expr ] ";"

lhs ::= id [ "[" expr "]" ] [ "," lhs ]
```

See {doc}`basics` for the `id` and `string` productions.  See {doc}`types` for
the `type` production.  See {doc}`expr` for the `expr` and `function_call` productions.

(declarations)=
## Variable declarations


Unlike undefined variables in most programming languages, undefined variables
in CVL are a centrally important language feature.  If a variable is declared
but not defined, the Prover will generate {term}`models <model>` with every
possible value of the undefined variable.

Undefined variables in CVL behave the same way as {ref}`rule parameters
<rule-overview>`.

When the Prover reports a counterexample that violates a rule, the values of the
variables declared in the rule are displayed in the report.  Variables declared
in CVL functions are not currently visible in the report.

(require)=
## `assert` and `require`


The `assert` and `require` commands are similar to the corresponding statements
in Solidity.  The `require` statement is used to specify the preconditions for
a rule, while the `assert` statement is used to specify the expected behavior
of contract functions.

During verification, the Prover will ignore any {term}`model` that causes the
`require` expressions to evaluate to false.  Unlike Solidity, the `require`
statement does not contain a descriptive message, because the Prover will never
consider an example where the `require` statement evaluates to `false`.

The `assert` statements define the expected behavior of contract functions.  If
it is possible to generate a model that causes the `assert` expression to
evaluate to `false`, the Prover will construct one of them and report a
violation.

Assert conditions may be followed by a message string describing the condition;
this message will be included in the reported violation.

```{note}
Unlike Solidity's `assert` and `require`, the CVL syntax for `assert` and
`require` does not require parentheses around the expression and message.
```
### Examples

```cvl
rule withdraw_succeeds {
    env e; // env represents the bytecode environment passed on every call
    // invoke function withdraw and assume that it does not revert
    bool success = withdraw(e);  // e is passed as an additional argument
    assert success, "withdraw must succeed"; // verify that withdraw succeeded
}

rule totalFundsAfterDeposit(uint256 amount) {
	 env e;

	 deposit(e, amount);

	 uint256 userFundsAfter = getFunds(e, e.msg.sender);
	 uint256 totalAfter = getTotalFunds(e);

	 // Verify that the total funds of the system is at least the current funds of the msg.sender.
	 assert totalAfter >= userFundsAfter;
}

```
- [`assert` example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/ConstantProductPool/certora/spec/ConstantProductPool.spec#L75)

- [`require` example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/ConstantProductPool/certora/spec/ConstantProductPool.spec#L44)

(satisfy)=
## `satisfy` statements


A `satisfy` statement is used to check that the rule can be executed in such a
way that the `satisfy` statement is true.  A rule with a `satisfy` statement is
describing a scenario and must not contain `assert` statements.  We require that
each rule ends with either a `satisfy` statement or an `assert` statement.

See {ref}`producing-examples` for an example demonstrating the `satisfy`
command.

For each `satisfy` statement, the Certora verifier will produce a witness for a
valid execution of the rule.  It will show an execution trace containing values
for each input variable and each state variable where all `require` and `satisfy`
statements are executed successfully.  In case there is no such execution, for
example if the `require` statements are already inconsistent or if a solidity
function always reverts, an error is reported.

If the rule contains multiple `satisfy` statements, then all executed `satisfy`
statements must hold.   However, a `satisfy` statement on a conditional branch
that is not executed does not need to hold.

If at least one `satisfy` statement is not satisfiable an error is reported.
If all `satisfy` statements can be fulfilled on at least one path, the rule
succeeds.

```{note}
A success only guarantees that there is some satisfying execution starting in
some arbitrary state.  It is not possible to check that every possible starting
state has an execution that satisfies the condition.
```

- [`satisfy` example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/ConstantProductPool/certora/spec/ConstantProductPool.spec#L243)

(requireInvariant)=
## `requireInvariant` statements


`requireInvariant` is shorthand for `require` of the expression of the invariant where the invariant parameters have to be substituted with the values/ variables for which the invariant should hold.

- [`requireInvariant` example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/ConstantProductPool/certora/spec/ConstantProductPool.spec#L178)

```{note}
`requireInvariant` is always safe for invariants that have been proved, even in
`preserved` blocks; see {ref}`invariant-induction` for a detailed explanation.
```

(havoc-stmt)=
## Havoc Statements

Havoc statements introduce non-determinism into the contract execution, allowing the SMT solver to choose random values for specific variables. Havoc statements are helpful for modeling uncertainty and verifying a wider range of possible scenarios.

### Syntax

The syntax for a `havoc` statement is as follows:

```cvl
havoc identifier [ assuming condition ];
```

- **`identifier`:** The variable or expression for which non-deterministic values will be chosen.
- **`condition`:** An optional condition that restricts the possible values for the havoc variable.

### Usage

#### Basic Havoc

The basic use of a havoc statement involves introducing non-deterministic values for a specific variable. This is useful when the exact value of a variable is unknown or when exploring various scenarios.

##### Example:

```cvl
uint256 x;
havoc x;
```

In this example, the value of variable `x` is chosen randomly by the SMT solver.
**Note:** The havoc statement is not really necessary as unassigned values are havoc by default.

#### Havoc with Condition

Havoc statements can include a condition that restricts the possible values for the havoc variable. This allows for more fine-grained control over the non-deterministic choices made by the SMT solver.

##### Example:

```cvl
uint256 y;
havoc y assuming y > 10;
```

In this example, the havoc statement introduces non-deterministic values for variable `y`, but only values greater than 10 are considered valid.

**Note:** The above is equivalent to:
```cvl
uint256 y;
require y > 0;
```

### Two-State Contexts: `@old` and `@new`

Two-state contexts, denoted by `@old` and `@new`, are essential when dealing with havoc statements. They provide a mechanism to reference the old and new states of a variable within the havoc statement, allowing for more nuanced control over the non-deterministic choices.

#### Example:
```cvl
havoc sumAllBalance assuming sumAllBalance@new() == sumAllBalance@old() + balance - old_balance;
```

In the given example, the havoc statement introduces non-deterministic values for the variable `sumAllBalance`. The assuming clause adds a condition: the new state of `sumAllBalance` should be the old state plus the change in the balance variable.

`sumAllBalance@new()`: Value in the updated state.
`sumAllBalance@old()`: Value in the previous state.
`balance - old_balance`: Change in the balance variable.

```{note} 
{doc}`hooks` will not be triggered for havoc statements. That is, if there is a hook defined on load, or store, of the `sumAllBalance` variable,
it will not be triggered from the havoc statement. 
```

### Advanced Usage: `havoc assuming`

The `havoc assuming` construct allows introducing non-deterministic choices for variables while imposing specific conditions. This can be particularly useful for modeling complex scenarios where certain constraints must be satisfied.

#### Example:

```cvl
ghost uint256 a;
ghost uint256 b;
rule example(){
havoc a assuming a@new < b;
havoc b assuming a + b@new == 100;
assert a < b && a + b == 100;
}
```

In this example, havoc statements are used to introduce non-deterministic values for ghosts `a` and `b` while ensuring that `a` is less than `b` and their sum is equal to 100.

### Conclusion

Havoc statements play a critical role in making CVL specifications more expressive and capable of handling uncertainty. They widen the coverage of possible contract behaviors making verification more robust and comprehensive. Understanding two-state contexts (`@old` and `@new`) and the `havoc assuming` construct is useful for harnessing the full power of CVL, in particular when combined with ghosts.

(control-flow)=
## Solidity-like Statements

Solidity-like statements provide a familiar syntax for expressing conditions and behaviors similar to Solidity, These statements enhance the readability and ease of writing specifications by adopting a syntax that resembles Solidity.

### 1. Assert Statement

#### Syntax:

```cvl
assert condition;
```

#### Usage:

The `assert` statement is used to assert a condition that must be true during the execution of the contract. If the condition evaluates to false, it will trigger a verification failure.

##### Example:

```cvl
uint256 balance;
assert balance > 0;
```

In this example, the `assert` statement ensures that the balance variable is positive.

### 2. Require Statement

#### Syntax:

```cvl
require condition;
```

#### Usage:

The `require` statement is similar to the `assert` statement but is used for expressing preconditions that must be satisfied for the execution to continue. Values that make the condition evaluate to false will not be considered as violations of a later `assert` statement or witnesses to a later `satisfy` statement.

##### Example:

```cvl
uint256 amount;
require amount > 0;
satisfy amount >= 0;
```

Here, the `require` statement ensures that the `amount` must be greater than zero. This means there cannot be a witness of the `satisfy` command with `amount` equal to zero.

### 3. Modeling Reverts in Solidity Calls

The default method of calling Solidity functions within CVL is to assume they do not revert.
This behavior can be adjusted with the `@withrevert` modifier.
After every Solidity call, even if it is not marked with `@withrevert`, a builtin variable called `lastReverted` is updated according to whether the Solidity call reverted or not.

Note: For calls without `@withrevert`, `lastReverted` is automatically set to to false.

#### Syntax:

```cvl
f@withrevert(args);
assert !lastReverted;
```
In this example, we call to `f` without pruning the reverting paths, and then we assert that the call to `f` did not revert on any given input.

##### Example:

```cvl
uint256 limit = 100;
uint256 value;
require value > limit;
Deposit@withrevert(value);
assert lastReverted, "Expected revert when value exceeds limit";
```

In this example, the `@withrevert` modifier is applied to the `Deposit` function call, which is expected to revert if the `value` exceeds the specified `limit`. The `assert` statement checks whether `lastReverted` is true, ensuring that the contract execution does revert as anticipated when the condition is violated. The error message in the `assert` provides additional context about the expectation.

### 4. Return Statement

#### Syntax:

```cvl
return expression;
```

#### Usage:

The `return` statement is used to terminate the execution of a function and return a value. It can only be used in functions to specify the value to be returned.

##### Example:

```cvl
function calculateSum(uint256 a, uint256 b) returns (uint256) {
    return a + b;
}
```

This example defines a function `calculateSum` that takes two parameters and returns their sum.

### Conclusion

Solidity-like statements in CVL simplify the process of writing specifications by using a syntax that closely resembles Solidity. These statements align with the familiar patterns and structures used in Solidity smart contracts, making it easier for developers and auditors to express and verify the desired behaviors and conditions in a contract. Understanding and using these statements contributes to more readable and expressive CVL specifications.
