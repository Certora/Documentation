Rule Sanity Checks (Solana)
==========================

The {ref}`--rule_sanity` option enables an automatic checks that warns the user
about potential problems in the specification. Currently only one sanity check is implemented:
the vacuity check.

```{note}
This is the documentation for the sanity checks for Solana. 
If you look for the Sanity checks for Solidity, please take a look [at this section](https://docs.certora.com/en/latest/docs/prover/checking/sanity.html).
```

The `--rule_sanity` option may be followed by one of `none` or `basic` and controls if the sanity checks should be executed:
 * With `--rule_sanity none` or without passing `--rule_sanity`, no sanity
   check is performed.
 * With `--rule_sanity basic` or just `--rule_sanity` without a mode, the
   sanity check is executed.

Each sanity check adds a new child node to every rule in the rule tree of the rule report. Each check transform the underlying
representation into a deviated subprograms from the original program under verification and attempts to verify this new program.  
If the sanity check fails on a rule, the sanity node in the rule report will be displyed as a yellow icon, 
and this status propagates to the parent rule's node:

![Screenshot of rule report showing a passing rule, a failing rule, and a sanity failure](sanity-icons.png)

If a sanity node is `halted`, then the parent rule will also have the status `halted`.

The remainder of this document describes the vacuity check in detail. 

(sanity-vacuity)=
Vacuity checks
--------------

The **vacuity** sanity check ensures that even when ignoring all the
user-provided assertions, the end of the rule is reachable. This check ensures
that that the combination of `require` statements does not rule out all
possible counterexamples.  Rules that rule out all possible counterexamples
are called {term}`vacuous` rules.  Since they don't actually check any
assertions, they are almost certainly incorrect.

For example, the following rule would be flagged by the vacuity check:
```rs
#[rule]
pub fn rule_vacuity_test_expect_sanity_failure() {
    let amount: u64 = nondet();

    cvt_assume!(amount >= 2);
    cvt_assume!(amount <= 1);
    cvt_assert!(amount == 1); //Expect a sanity failure here as the assumes are conflicting.
}
```

Since the two `assumes` `amountx >= 2` and `amount <= 1` contradict, this rule
will always pass, regardless of the behavior of the contract.  This is an
example of a {term}`vacuous` rule &mdash; one that passes only because the
preconditions are contradictory.

In the rule report, a vacuity check adds a node called `rule_not_vacuous` to each rule.  
For example, see how the rule `rule_vacuity_test_expect_sanity_failure` from above
is reported as failing sanity, as `rule_not_vacuous` fails. 
(Below you see an example of a rule without the contradicting assumes that doesn't fail sanity). 

![Screenshot of vacuity subrule](img/vacuity_check.png)

Note, the vacuity check will only be executed, if the original's rule status is verified. 
In the case the Prover found a violation, the sanity check will be skipped.