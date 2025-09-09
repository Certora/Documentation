(rules-main)=
Rules
=====

Rules (along with {doc}`invariants`) are the main entry points for the Prover.
A rule defines a sequence of [commands](statements) that should be simulated
during verification.

When the Prover is invoked with the {ref}`--verify` option, it generates a
report for each rule and invariant present in the spec file (as well as any
{ref}`imported rules <use>`).

You can find examples for rules in the
[Certora Prover and CVL Examples Repository](https://github.com/Certora/Examples/).
For example, the specs in {clink}`/CVLByExample/Teams/` demonstrate some of
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

Examples and edge cases
-----------------------

This section distills patterns from larger production specs. Each example is self‑contained and designed to be adapted to your scene.

- Preview equals actual (ERC‑4626). EIP‑4626 requires preview functions to not exceed the actual action in the same tx. In some implementations they are equal; this stronger property is easy to assert:

  ```cvl
  /// previewDeposit returns the exact deposit shares
  rule previewDepositAmountCheck(){
      env e1; env e2;
      uint256 assets; address receiver;
      uint256 previewShares = previewDeposit(e1, assets);
      uint256 shares       = deposit(e2, assets, receiver);
      assert previewShares == shares, "preview equals actual";
  }
  ```

- Preview independence from allowance. Previews should ignore allowance and max limits. Keep the environment controlled and assert equality across different allowance states:

  ```cvl
  rule previewDepositIndependentOfAllowanceApprove(){
      env e1; env e2; env e3; env e4; env e5;
      address user; uint256 assets;

      uint256 before1 = _AToken.allowance(currentContract, user);
      require assets < before1;
      uint256 p1 = previewDeposit(e1, assets);

      _AToken.approve(e2, currentContract, before1 - assets); // adjust to equality
      require _AToken.allowance(currentContract, user) == assets;
      uint256 p2 = previewDeposit(e3, assets);

      _AToken.approve(e4, currentContract, 0);
      require _AToken.allowance(currentContract, user) < assets;
      uint256 p3 = previewDeposit(e5, assets);

      assert p1 == p2 && p2 == p3, "preview ignores allowance";
  }
  ```

- Joining and splitting near‑additivity. When conversions round, splitting/merging accounts yields off‑by‑one envelopes. Use mathints to avoid silent overflow:

  ```cvl
  /// Convert sum of assets is within [parts, parts+1]
  rule convertSumOfAssetsPreserved(uint256 a1, uint256 a2) {
      env e;
      uint256 s1 = convertToShares(e, a1);
      uint256 s2 = convertToShares(e, a2);
      uint256 as = require_uint256(a1 + a2);
      mathint js = convertToShares(e, as);
      assert js >= s1 + s2;
      assert js <  s1 + s2 + 2;
  }
  ```

- Deposit envelopes by index (Aave‑style index RAY). Bound deposited aTokens relative to requested `assets` and index. For `index > RAY` the bound is `+1 aToken`; for `index == RAY` it tightens to `+0.5 aToken`:

  ```cvl
  rule depositUpperBound(env e){
      uint256 assets; address receiver;
      uint256 before = _AToken.balanceOf(currentContract);
      uint256 idx = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
      require e.msg.sender != currentContract;
      uint256 shares = deposit(e, assets, receiver);
      uint256 after  = _AToken.balanceOf(currentContract);
      assert (idx > RAY()  => after - before <= assets + idx / RAY());
      assert (idx == RAY() => after - before <= assets + idx / (2 * RAY()));
  }
  ```

- Non‑zero mint condition. Ensure users receive at least one share when depositing at least one unit in index terms:

  ```cvl
  rule depositMintsAtLeastOne(env e){
      uint256 assets; address receiver;
      uint256 idx = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
      require e.msg.sender != currentContract;
      uint256 shares = deposit(e, assets, receiver);
      assert assets * RAY() >= to_mathint(idx) => shares != 0;
  }
  ```

- Mint envelopes. When minting shares directly, the receiver’s balance increases by the requested amount, up to an extra unit due to rounding:

  ```cvl
  rule mintBounds(env e){
      uint256 shares; address receiver;
      require e.msg.sender != currentContract;
      uint256 idx  = _SymbolicLendingPool.getReserveNormalizedIncome(asset());
      uint256 pre  = balanceOf(e, receiver);
      require pre + shares <= max_uint256; // avoid overflow in spec
      uint256 assets = mint(e, shares, receiver);
      uint256 post = balanceOf(e, receiver);
      assert (idx >= RAY());
      assert to_mathint(post) >= pre + shares;
      assert to_mathint(post) <= pre + shares + 1;
  }
  ```

- Duplicate reward claims do not amplify payout. Whether the contract has sufficient funds or not, listing the same reward twice must not increase net rewards to a user beyond the computed claimable amount:

  ```cvl
  rule prevent_duplicate_reward_claiming_single_reward() {
      single_RewardToken_setup();
      rewardsController_arbitrary_single_reward_setup();
      env e; require e.msg.sender != currentContract;

      uint256 bal0 = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
      mathint claimable = getClaimableRewards(e, e.msg.sender, _DummyERC20_rewardToken);

      // Attempt to claim the same reward twice
      claimDoubleRewardOnBehalfSame(e, e.msg.sender, e.msg.sender, _DummyERC20_rewardToken);

      uint256 bal1 = _DummyERC20_rewardToken.balanceOf(e.msg.sender);
      mathint diff = bal1 - bal0;
      uint256 unclaimed = getUnclaimedRewards(e.msg.sender, _DummyERC20_rewardToken);

      assert diff + unclaimed <= claimable, "duplicate claim changes rewards";
  }
  ```

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
