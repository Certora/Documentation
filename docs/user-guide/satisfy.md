(producing-examples)=
Producing Positive Examples
===========================

TODO: replace links with CI
TODO: demonstrative screenshots

Sometimes it is useful to produce examples of an expected behavior instead of
counterexamples that demonstrate unexpected behavior.  You can do this by
writing a rule that uses {ref}`satisfy` instead of the `assert` command.  For
each `satisfy` command in a rule, the Prover will produce an example that makes
the condition true, or report an error.

The purpose of the `satisfy` statement is to produce examples that demonstrate
some execution of the code.  Not every example is interesting &mdash; users
should inspect the example to ensure that it demonstrates the expected
behavior.

For [example][constant-product-spec], we may be interested in showing that it is
possible for someone to deposit some assets into a pool and then immediately
withdraw them.  The following rule demonstrates this scenario:

[constant-product-spec]: https://github.com/Certora/ConstantProductExample/blob/master/certora/spec/ConstantProductPool.spec

```cvl
/// Demonstrate that one can fully withdraw deposited assets
rule uninterestingPossibleToFullyWithdraw(address sender, uint256 amount) {
    // record initial balance
    uint256 balanceBefore = _token0.balanceOf(sender);

    // transfer `amount` tokens from `sender` to the pool
    env eTransfer;
    require eTransfer.msg.sender == sender;
    _token0.transfer(eTransfer, currentContract, amount);

    // mint and then immediately withdraw tokens for `sender`
    env eMint;
    require eMint.msg.sender == sender;
    uint256 amountOut0 = mint(eMint,sender);

    // withdraw tokens immediately after minting
    env eBurn;
    require eBurn.msg.sender == sender;
    require eBurn.block.timestamp == eMint.block.timestamp;
    burnSingle(eBurn, _token0, amountOut0, sender);

    // demonstrate that it is possible that `sender`'s balance is unchanged
    satisfy balanceBefore == _token0.balanceOf(sender);
}
```

Although the Prover produces an example ([report][zero-amount]) that satisfies
this rule, the example is uninteresting because the `amount` that is minted and
withdrawn is 0; of course minting and withdrawing 0 tokens leaves the
sender's balance unchanged!

[zero-amount]: https://prover.certora.com/output/40726/7e2ea3f2baf64505a79108f7ee5b6a35?anonymousKey=09ee75d8c35e4b9b33447820ede1016af9c65022

We can add a `require` statement to force the Prover to consider a more
interesting case:

```cvl
/// Demonstrate that one can fully withdraw deposited assets
rule infeasiblePossibleToFullyWithdraw(address sender, uint256 amount) {
    // force `amount` to be nonzero
    require amount > 0;

    // remainder of the rule is the same...
}
```

Again the Prover produces an example ([report][infeasible-example]), but again
it is an uninteresting one: the underlying token is minted for 999 LP tokens,
which should be impossible.  The problem is that the Prover is able to start the
rule in an infeasible state.

[infeasible-example]: https://prover.certora.com/output/40726/ce7c3e49011f4ae7bf06983eff3254b1/?anonymousKey=3a02d99c74c950c5de0886521581c7096948714c

We can remedy this by adding some additional setup assumptions (see the [full
spec][constant-product-spec] for details of the `setup` function):

```cvl
/// Demonstrate that one can fully withdraw deposited assets
rule possibleToFullyWithdraw(address sender, uint256 amount) {
    // beginning of the rule is the same

    setup(envMint);

    // remainder of the rule is the same...
}
```

With this additional requirement, the Prover produces a [satisfactory example][good-example].

[good-example]: https://prover.certora.com/output/40726/db4d12e98718424c86e95937c0945700/?anonymousKey=92ffd0f1210cac228563cd9ad92575f798111e2b


