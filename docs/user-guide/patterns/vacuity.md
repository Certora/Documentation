# Repairing Vacuous Rules

A rule is {term}`vacuous` when its assumptions rule out every possible
execution, so its assertions are never actually checked.  The
{doc}`sanity checks </docs/prover/checking/sanity>` detect this situation, but
they do not explain *why* it happened or how to fix it.  This page
describes the most common root cause &mdash; an over-approximating summary
that makes the contract revert on every path &mdash; and a repair sequence
that restores coverage instead of hiding the problem.

## Reading the sanity results as a setup signal

When the {ref}`vacuity check <sanity-vacuity>` flags a single rule, the
problem is usually in that rule: contradictory `require` statements or an
unsatisfiable combination of `requireInvariant`s.

When the *same contract method* fails the vacuity check across many rules
(for example, in every instantiation of a parametric rule), the problem is
almost never in the rules.  It is a setup problem: something in the methods
block or the scene makes every call to that method revert.  Fixing the rules
one by one &mdash; or worse, filtering the method out &mdash; treats the
symptom and silently removes the method from verification coverage.

## Root cause: `NONDET` on a state-changing callee

The `NONDET` summary (see {ref}`view-summary`) replaces a call with an
arbitrary return value and *no state changes*.  This is sound and appropriate
for `view` functions.  Applied to a `payable` or otherwise state-changing
callee, it frequently makes the *caller* revert on every path:

```solidity
function stake() external payable {
    uint256 sharesBefore = pool.sharesOf(address(this));
    pool.deposit{value: msg.value}();   // summarized as NONDET
    uint256 sharesAfter = pool.sharesOf(address(this));
    require(sharesAfter - sharesBefore >= minShares(msg.value), "slippage");
    ...
}
```

Suppose `pool` is linked to a real contract in the scene, but `deposit` was
summarized as `NONDET` (a typical shortcut for taming a complex callee).  The
pool's state then never changes, so `sharesAfter == sharesBefore` and the
slippage check fails whenever `minShares(msg.value) > 0`.  Every rule that
calls `stake` becomes vacuous.
The same effect occurs with unresolved low-level calls: for
`.call{value: ...}` and `send`, the default havoc approximation lets the call
return `false` on every path when the caller requires success; `transfer`
reverts on failure instead of returning `false`, so there the havoc manifests
as a call that reverts on every path.

## The repair sequence

Work through these steps in order; each step preserves more behavior than the
next.  Only fall through to the next step when the current one is
impractical.

1. **Fix the summary.**  Replace `NONDET` with a summary that preserves the
   semantics the caller relies on.  Often a small {ref}`expression summary
   <expression-summary>` over a ghost is enough &mdash; here, one that
   credits the deposited value:

   ```cvl
   methods {
       function _.deposit() external with(env e)
           => cvlDeposit(calledContract, e.msg.value) expect void;
       function _.sharesOf(address account) external
           => cvlSharesOf(calledContract, account) expect uint256;
   }

   ghost mapping(address => mapping(address => uint256)) ghostShares;

   function cvlDeposit(address pool, uint256 value) {
       ghostShares[pool][currentContract] =
           require_uint256(ghostShares[pool][currentContract] + value);
   }

   function cvlSharesOf(address pool, address account) returns uint256 {
       return ghostShares[pool][account];
   }
   ```

2. **Write a mock contract.**  When the required behavior is too rich for a
   CVL summary (for example, it must interact with real ETH balances), write
   a minimal Solidity mock implementing just the behavior the caller depends
   on, add it to the scene, and link it (see
   {doc}`/docs/user-guide/multicontract/index`).

3. **Use `--optimistic_fallback` for unresolved low-level calls.**  If the
   vacuity comes from an unresolved external call with an empty input buffer
   (`.call{value: ...}("")`, `send`, or `transfer`) rather than a summarized
   method, {ref}`--optimistic_fallback` replaces the whole-scene havoc with
   a dispatcher over the non-trivial `fallback` implementations in the
   scene, plus a plain ETH transfer when the callee is an externally owned
   account.  Reverting paths are still verified.  Like all optimistic
   options this narrows the modeled behaviors, so record why it is
   acceptable.

4. **Filter as a last resort.**  Only after the steps above have been tried
   should the method be excluded from parametric rules with a `filtered`
   block.  A filter does not fix anything &mdash; it removes the method from
   coverage entirely &mdash; so leave a comment stating which of the repairs
   above were attempted and why they were not applicable.

```{warning}
A `filtered` block that hides a vacuous method makes every remaining result
look green while an entire entry point goes unverified.  If a method is
vacuous in every rule, the specification setup is broken; prefer repairing
the setup over filtering the method.
```
