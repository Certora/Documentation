Rule Sanity Checks
==================
The {ref}`--rule_sanity` option enables some automatic checks that can warn users
about certain classes of mistakes in specifications.

There are several kinds of sanity checks:

 * {ref}`sanity-reachability` determine whether there are any {term}`model`s that are not
   ignored.
 * {ref}`sanity-trivial-invariant` determine whether invariants hold in all states, rather than reachable states.
 * {ref}`sanity-assert-vacuity` determine whether individual `assert` statements are {term}`vacuous`.
 * {ref}`sanity-assert-tautology` determine whether individual `assert` statements are {term}`tautologies <tautology>`.
 * {ref}`sanity-redundant-require` determine whether individual `require` statements rule out any models.

The `--rule_sanity` option may be followed by one of `none`, `basic`, or
`advanced` options to control which sanity checks should be executed:
 * With `--rule_sanity none` or without passing `--rule_sanity`, no sanity
   checks are performed.
 * With `--rule_sanity basic` or just `--rule_sanity` without a mode, the
   reachability check is performed for all rules and invariants, and the
   assert-vacuity check is performed for invariants.
 * With `--rule_sanity advanced`, all the sanity checks will be performed for
   all invariants and rules.

We recommend starting with the `basic` mode, since not all rules flagged by the
`advanced` mode are incorrect.

When the Prover is run with any of these options, it first checks that the rule
passes; if it does pass then the sanity checks are performed.  If the sanity
checks also pass, the rule is marked as verified with a green checkmark; if the
sanity check fails, the rule is marked with a yellow symbol:

![Screenshot of rule report showing a passing rule, a failing rule, and a sanity failure](sanity-icons.png)

If a sanity check fails, you can expand the assertion message to see the details
of the failure:

![Screenshot of rule report showing the expanded details of a sanity failure](sanity-details.png)

The remainder of this document describes these checks in detail.

(sanity-reachability)=
Reachability checks
-------------------

**Reachability** checks that even when ignoring all the user-provided
assertions, the end of the rule is reachable. This check ensures that that
the combination of `require` statements does not rule out all possible
counterexamples.

For example, the following rule would be flagged by the reachability check:
```cvl
rule vacuous {
    uint x;
    require x > 2;
    require x < 1;
    assert f(x) == 2, "f must return 2";
}
```

Since there are no models satisfying both `x > 2` and `x < 1`, this rule
will always pass, regardless of the behavior of the contract.  This is an
example of a {term}`vacuous` rule &mdash; one that passes only because the
preconditions are contradictory.

(sanity-assert-vacuity)=
Assert vacuity checks
---------------------

**Assert-Vacuity** checks that individual `assert` statements are not
tautologies.  A tautology is a statement that is true on all examples, even
if all the `require` and `if` conditions are removed.

For example, the following rule would be flagged by the assert-vacuity check:

```cvl
rule tautology {
  uint x; uint y;
  require x != y;
  ...
  assert x < 2 || x >= 2,
   "x must be smaller than 2 or greater than or equal to 2";
}
```

Since every `uint` satisfies the assertion, the assertion is tautological, which
may indicate an error in the specification.

(sanity-trivial-invariant)=
Checking for trivial invariants
-------------------------------

A trivial invariant is one that holds in all possible states, not just in
reachable states.  For example, the following invariant is trivial:

```cvl
invariant squaresNonNeg(int x)
    x * x >= 0
```

While it does hold in every reachable state, it also holds in every
non-reachable state.  Therefore it could be more efficiently checked as a rule:

```cvl
rule squaresNonNeg(int x) {
    assert x * x >= 0;
}
```

The rule version is more efficient because it can do a single check in an
arbitrary state rather than separately checking states after arbitrary method
invocations.

(sanity-assert-tautology)=
Assert tautology checks
-----------------------

### Vacuity checking for rules
    
For rules, checking for tautology requires checking each assertion to see if 
it’s meaningful. In order to do this, we employ a few different checks depending
on the syntax of the assertion expression.

#### Tautology checking for implications

Given a rule with an `assert p => q`, we perform two checks:

1. Implication hypothesis: `assert(!p)`
 
   If the hypothesis part is always false then the implication must always be
   true, so the assertion is a tautology.
   
   ```cvl
   rule testSanity{
       uint a;
       uint b;
       assert a<0 => b<10;
   }
   ```

   If this check fails then the Prover will report a message like the following:

   ```
   assert-vacuity check FAILED: sanity.spec:11:5
   assert-tautology check FAILED: sanity.spec:11:5'a < 0 => b < 10' is a vacuous 
   implication. It could be rewritten to !a < 0 because a < 0 is always false
   ```

2. Implication conclusion: `assert(q)`
   
   If the conclusion is true regardless of the hypothesis then the implication
   is always true, and therefore the assertion is a tautology.
   
   ```cvl
   rule testSanity{
       uint a;
       uint b;
       assert a>10 => b>=0;
   }
   ```
    
   Error Message
    
   ```
   assert-tautology check FAILED: sanity.spec:21:5conclusion `b >= 0` is always true 
   regardless of the hypothesis
   ```
        
#### Tautology checks for double implication

Given a rule with an `assert p <=> q` we perform two checks:
     
1. Double implication, both false: `assert(!p && !q)`
   If both `p` and `q` are always false then the assertion condition `p <=> q`
   is always true and is therefore a tautology.

   ```cvl
   rule sanityDoubleImplication1{
       uint a;
       uint b;
       assert a<0 <=> b<0;
   }
   ```
     
   If this check fails then the Prover will report a message like the following:
      
   ```
   assert-tautology check FAILED: sanity.spec:26:5'a < 0 <=> b < 0' could be rewritten 
   to !a < 0 && !b < 0 because both a < 0 and b < 0 are always false
   ```
           
2. Double implication, both true: `assert(p && q)`

   If this passes then the original assertion is a tautology since both
   conditions are always true.

   ```cvl
   rule sanityDoubleImplication2{
       uint a;
       uint b;
       assert a>=0 <=> b>=0;
   }
   ```
           
   If this check fails then the Prover will report a message like the following:

   ```
   assert-tautology check FAILED: sanity.spec:33:5'a >= 0 <=> b >= 0' could be rewritten
   to a >= 0 && b >= 0 because both a >= 0 and b >= 0 are always true
   ```
            
#### Tautology checking for disjunctions

Given a rule with an `assert p || q`, we perform two checks:
      
1. Disjunction always true: `assert(p)`
   If this passes then the assertion is a tautology since the first expression
   of the disjunction is always true.

   ```cvl
   rule sanityDisjunction1{
       uint a;
       uint b;
       assert a>=0 || b>10;
   }
   ```

   If this check fails then the Prover will report a message like the following:

   ```
   assert-tautology check FAILED: sanity.spec:41:5the expression `a >= 0` is always true
   ```

2. Disjunction always true: `assert(q)`

   If this passes then the assertion is a tautology since the second expression of the disjunction is always true.

   ```cvl
   rule sanityDisjunction2{
       uint a;
       uint b;
       assert a>10 || b>=0;
   }
   ```
            
   If this check fails then the Prover will report a message like the following:
            
   ```
   assert-tautology check FAILED: sanity.spec:47:5the expression `b >= 0` is always true
   ```


(sanity-redundant-require)=
Redundant require checks
------------------------

**Require-Redundancy** checks for redundant `require` statements.
A `require` is considered to be redundant if it can be removed without
affecting the satisfiability of the rule.

For example, the require-redundancy check would flag the following rule:
```cvl
rule require_redundant {
  uint x;
  require x > 3;
  require x > 2;
  assert f(x) == 2, "f must return 2";
}
```
In this example, the second requirement is redundant, since any `x` greater
than 3 will also be greater than 2.
       
```{todo}
Add details of specific Require-Redundancy checks if helpful
```


