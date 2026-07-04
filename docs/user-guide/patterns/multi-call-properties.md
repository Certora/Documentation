# Multi-Call Properties with Storage Snapshots

Some of the most valuable properties compare *different call sequences*
starting from the same state: does splitting a deposit into two smaller
deposits mint the same shares as one big deposit?  Does a deposit followed by
a withdrawal return the caller to where they started?  CVL expresses these
with the {ref}`storage type <storage-type>`: a variable of type `storage`
snapshots the entire EVM state (including {doc}`ghosts </docs/cvl/ghosts>`),
and appending `at <snapshot>` to a call restores that state before the call
executes.

```cvl
storage init = lastStorage;   // snapshot the current state
f(e, args);                   // first scenario
g(e, args) at init;           // second scenario, restarted from the snapshot
```

## Additivity: split vs. batch

An additivity property states that performing an operation in two steps is
equivalent to (or at least no better than) performing it in one.  Violations
of additivity often reveal rounding-direction bugs or incentives to split or
batch operations:

```cvl
rule depositAdditivity(env e, uint256 x, uint256 y) {
    storage init = lastStorage;

    // scenario 1: batched deposit
    deposit(e, require_uint256(x + y));
    // balanceOf is declared envfree in the methods block (omitted here)
    uint256 sharesBatched = balanceOf(e.msg.sender);

    // scenario 2: split deposit, restarted from the same state
    deposit(e, x) at init;
    deposit(e, y);
    uint256 sharesSplit = balanceOf(e.msg.sender);

    // splitting a deposit must never mint more shares than batching it
    assert sharesSplit <= sharesBatched;
}
```

Exact equality (`sharesSplit == sharesBatched`) is usually too strong in the
presence of rounding; the inequality form documents *which direction* the
rounding is allowed to favor.  If exact equality does hold, so much the
better &mdash; assert it.

## Round trips

A round-trip property performs an operation and its inverse and compares the
final state to the initial one.  The comparison can be on a specific value:

```cvl
rule depositWithdrawRoundTrip(env e, uint256 amount) {
    uint256 shares = deposit(e, amount);
    uint256 amountOut = withdraw(e, shares);

    // the round trip must not create value for the caller
    assert amountOut <= amount;
}
```

or on entire storage, using {ref}`storage comparison <storage-comparison>`
against a snapshot:

```cvl
rule redeemRestoresState(env e, uint256 shares) {
    storage init = lastStorage;

    uint256 assets = redeem(e, shares);
    mint(e, shares);

    assert lastStorage[currentContract] == init[currentContract];
}
```

Storage-equality round trips are strict: any stray state change (a fee
accumulator, a timestamp cache) shows up as a counterexample, which makes
them a good way to *discover* what state an operation actually touches.

## Notes

 - Each scenario after an `at` restart replays from the snapshot, but
   environment variables (`env`) are not part of storage; reuse the same
   `env` in both scenarios unless the property is specifically about
   different callers or times.
 - Ghost variables are restored by `at` along with contract storage (declare
   them `persistent` to opt out; see {ref}`persistent-ghosts`).
 - Multi-call rules multiply the number of contract calls the Prover must
   reason about, so they are more prone to timeouts; see
   {doc}`/docs/user-guide/out-of-resources/timeout` for mitigations.
