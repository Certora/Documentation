(rules-main)=
Rules
=====

Rules (along with {doc}`invariants`) are the main entry points for the Prover.
A rule defines a sequence of [commands](statements) that should be simulated
during verification.

When the Prover is invoked with the {ref}`--verify` option, it generates a
report for each rule and invariant present in the spec file (as well as any
{ref}`imported rules <use>`).

See {doc}`/docs/confluence/bank/index` for an example demonstrating some of
these features.

```{contents}
```

Syntax
------

The syntax for rules is given by the following [EBNF grammar](ebnf-syntax):

```
rule ::= [ "rule" ]
         id
         [ "(" [ params ] ")" ]
         [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
         [ "description" string ]
         [ "good_description" string ]
         block

params ::= cvl_type [ id ] { "," cvl_type [ id ] }

```

See {doc}`basics` for the `id` and `string` productions; see {doc}`expr` for the `expression`
production; see {doc}`types` for the `cvl_type` production.


(rule-overview)=
Overview
--------

A rule defines a sequence of commands that should be simulated during
verification.  These commands may be non-deterministic: they may contain
{ref}`unassigned variables <declarations>` whose value is not specified.  The
state of storage at the beginning of a rule is also unspecified.  Rules may also
be declared with a set of parameters; these parameters are treated the same way
as undeclared variables.

In principal, the Prover will generate every possible combination of values for
the undefined variables, and simulate the commands in the rule using those
values.  A particular combination of values is referred to as an {term}`example` or a
{term}`model`.  There are often an infinite number of models for a given rule; see
{ref}`verification` for a brief explanation of how the Prover considers all of
them.

If a rule contains a `require` statement that fails on a particular example,
the example is ignored.  Of the remaining examples, the Prover checks that all
of the `assert` statements evaluate to true.  If all of the `assert` statements
evaluate to true on every example, the rule passes.  Otherwise, the Prover will
output a specific counterexample that causes the assertions to fail.

- [simple rule example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/LiquidityPool/certora/specs/pool.spec#L54)

    ```cvl
    /// `deposit` must increase the pool's underlying asset balance
    rule integrityOfDeposit {

        mathint balance_before = underlyingBalance();


        env e; uint256 amount;
        safeAssumptions(_, e);

        deposit(e, amount);

        mathint balance_after = underlyingBalance();

        assert balance_after == balance_before + amount,
            "deposit must increase the underlying balance of the pool";
    }
    ```
```{caution}
`assert` statements in contract code are handled differently from `assert`
statements in rules.

An `assert` statement in Solidity causes the transaction to revert, in the same
way that a `require` statement in Solidity would.  By default, examples that
cause contract functions to revert are {ref}`ignored by the prover
<with-revert>`, and these examples will *not* be reported as counterexamples.

The {ref}`--multi_assert_check` option causes assertions in the contract code
to be reported as counterexamples.
```


(parametric-rules)=
Parametric rules
----------------

Rules that contain undefined `method` variables are sometimes called
{term}`parametric rule`s.  See {ref}`method-type` for more details about
how to use method variables.

Undefined variables of the `method` type are treated slightly differently from
undefined variables of other types.  If a rule uses one or more undefined
`method` variables, the Prover will generate a separate report for each method
(or combination of methods).

In particular, the Prover will generate a separate counterexample for each
method that violates the rule, and will indicate if some contract methods
always satisfy the rule.

You can request that the Prover only run with specific methods using the
{ref}`--method` and {ref}`--parametric_contracts` command line arguments.  The set of
methods can also be restricted using {ref}`rule filters <rule-filters>`.
The Prover will automatically skip any methods that have
{ref}`` `DELETE` summaries <delete-summary>``.

If you wish to only invoke methods on a certain contract, you can call the
`method` variable with an explicit receiver contract.  The receiver must be a
contract variable (either {ref}`currentContract <currentContract>` or a variable introduced with a
`using` statement).  For example, the following will only verify the rule `r`
on methods of the contract `example`:

```cvl
using Example as example;

rule r {
    method f; env e; calldataarg args;
    example.f(e,args);
    ...
}
```

It is an error to call the same `method` variable on two different contracts.

```cvl
  rule sanity(method f) {
    env e;
    calldataarg args;
    f(e,args);
    assert false;
    }
  ```
- [parameteric rule example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/structs/BankAccounts/certora/specs/Bank.spec#L94)


(rule-filters)=
Filters
-------

A rule declaration may have a `filtered` block after the rule parameters.
Rule filters allow you to prevent verification of parametric rules on certain
methods.  This can be less computationally expensive than using a `require`
statement to ignore counterexamples for a method.

The `filtered` block consists of zero or more filters of the form `var -> expr`.
`var` must match one of the `method` parameters to the rule, and `expr` must be
a boolean expression that may refer to the variable `var`.  The filter
expression may not refer to other method parameters or any variables defined in
the rule.

Before verifying that a method `m` satisfies a parametric rule, the `expr` is
evaluated with `var` bound to a `method` object.  This allows `expr` to refer
to the fields of `var`, such as `var.selector` and `var.isView`.  See
{ref}`method-type` for a list of the fields available on `method` objects.

For example, the following rule has two filters.  The rule will only be
verified with `f` instantiated by a view method, and `g` instantiated by a
method other than `exampleMethod(uint,uint)` or `otherExample(address)`:


- [filters example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/Reentrancy/certora/spec/Reentrancy.spec#L29C9-L29C9)

```cvl
rule r(method f, method g) filtered {
    f -> f.isView,
    g -> g.selector != exampleMethod(uint,uint).selector
      && g.selector != otherExample(address).selector
} {
    // rule body
    ...
}
```

See {ref}`method-type` for a list of the fields of the `method` type.

Multiple assertions
-------------------

Rules may contain multiple assertions.  By default, if any assertion fails, the
Prover will report that the entire rule failed and give a counterexample that
causes one of the assertions to fail.

Occasionally it is useful to consider different assert statements in a rule
separately.  With the {ref}`--multi_assert_check` option, the Prover will try
to generate separate counterexamples for each `assert` statement.   The
counterexamples generated for a particular `assert` statement will pass all
earlier `assert` statements.

Rule descriptions
-----------------

Rules may be annotated by writing `description` and/or `good_description` before
the method body, followed by a string.  These strings are displayed in the
verification report.

(verification)=
How rules are verified
----------------------

While verifying a rule, the Prover does not actually enumerate every possible
example and run the rule on the example.  Instead, the Prover translates the
contract code and the rule into a logical formula with logical variables
representing the unspecified variables from the rule.

The logical formula is designed so that if a particular example satisfies the
requirements and also causes an assertion to fail, then the formula will
evaluate to `true` on that example; otherwise the formula will evaluate
to false.

The Prover then uses off-the-shelf software called an SMT solver to determine
whether there are any examples that cause the formula to evaluate to true.  If
there are, the SMT solver provides an example to the Prover, which then
translates it into an example for the user.  If the SMT solver reports that the
formula is unsatisfiable, then we are guaranteed that whenever the `require`
statements are true, the `assert` statements are also true.

