Statements
==========

The bodies of {doc}`rules <rules>`, {doc}`functions <functions>`, and
{doc}`hooks <hooks>` in CVL are made up of statements.  Statements describe the
steps that are simulated by the Prover when evaluating a rule.

Statements in CVL are similar to statements in Solidity, although there are
some differences; see {ref}`control-flow`.  This document lists the available
CVL commands.

```{contents}
```

Syntax
------

The syntax for statements in CVL is given by the following [EBNF grammar](syntax):

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
Variable declarations
---------------------

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
`assert` and `require`
----------------------

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
this message will be included in the reported violation.  Assertion messages
may use {ref}`string interpolation <string-interpolation>` to add information
about the counterexamples to the message.

```{note}
Unlike Solidity's `assert` and `require`, the CVL syntax for `assert` and
`require` does not require parentheses around the expression and message.
```

(satisfy)=
`satisfy` statements
--------------------

A `satisfy` statement is used to check that the rule can be executed in such a
way that the `satisfy` statement is true.  A rule with a `satisfy` statement is
describing a scenario and may not contain `assert` statements.  We require that
each rule ends with a `satisfy` statement or an `assert` statement.

For each `satisfy` statement, the Certora verifier will produce a witness for a
valid execution of the rule.  It will show an execution trace containing values
for each input variable and each state variable where all `require` and `satisfy`
statements are executed successfully.  In case there is no such execution, for
example if the `require` statements are already inconsistent or if a solidity
function always reverts, an error is reported.

If the rule contains multiple `satisfy` statements, then all executed `satisfy`
statements must hold.   However, a `satisfy` statement on a conditional branch that
is not executed, does not need to hold.  The verifier produces multiple witnesses
such that for every `satisfy` statement there is a witness that executes this
statement.

If for at least one `satisfy` statement there is no execution path on which it
holds, an error is reported.  If all `satisfy` statements can be fulfilled on
at least one path, the rule succeeds.

```{note}
A success does only guarantee that there is some execution starting in some
arbitrary state.  It is not possible to check that there is an execution for
very starting state.
```

(requireInvariant)=
`requireInvariant` statements
-----------------------------

```{todo}
This feature is currently undocumented.
```

```{note}
`requireInvariant` is always safe for invariants that have been proved, even in
`preserved` blocks; see {ref}`invariant-induction` for a detailed explanation.
```

(control-flow)=
Solidity-like statements
------------------------

```{todo}
This feature is currently undocumented.
```

(withrevert)=
Function calls
--------------

```{todo}
This feature is currently undocumented.  See {ref}`call-expr` for partial information.
```

(havoc-stmt)=
`havoc` statements
------------------

```{todo}
This section is currently incomplete.  See
[ghosts](/docs/confluence/anatomy/ghosts) and {ref}`two-state-old`
for the old documentation.
```

```{todo}
Be sure to document `@old` and `@new` (two-state contexts).  They are not documented in {doc}`expr`
because I think `havoc ... assuming ...` is the only place that they are
available.
```

