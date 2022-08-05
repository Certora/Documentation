Working with Multiple Contracts
===============================

In the previous chapter, we focused on rules describing the behavior of a
single contract.  In practice, most protocols consist of multiple interacting
contracts.  In this chapter, we discuss techniques for verifying protocols
involving multiple contracts.

```{contents}
```

Example protocol
----------------

To demonstrate these concepts, we work with a simplified liquidity pool called
`Pool`.  You can download the solidity files and specifications for this
example [here][example-repo].  The [completed specification][pool-spec].
is in `certora/specs/pool.spec` and the
[final run script][pool-script] is in `certora/scripts/verifyPool.spec`.

The liquidity pool allows users to deposit and withdraw a single fixed type of
ERC20 token (the `asset`).  The liquidity pool itself also acts as an ERC20
token; depositing assets into the pool increases the user's balance, while
withdrawing decreases their balance.

```solidity
contract LiquidityPool
      is ERC20
{
    IERC20 public immutable asset;

    /// transfers `amount` of `asset` from `msg.sender` to `this`;
    /// mints `amount` of `this` for `msg.sender`
    function deposit(uint256 amount)  external returns(uint256 shares) { ... }

    /// transfers `sharesToAmount(shares)` of `asset` from `this` to `msg.sender`;
    /// burns `shares` of `this` from `msg.sender`
    function withdraw(uint256 shares) external returns(uint256 amount) { ... }

    ...
}
```

For demonstration purposes, we have also added function `assetBalance`, which
returns the pool's balance of the underlying asset (we'll see
{ref}`later <using-example>` that this is not necessary):

```solidity
function assetBalance() public returns (uint256) {
  return asset.balanceOf(this);
}
```


Users can also take out flash loans - loans that must be repaid within the same
transaction.  To do so, the user calls `flashLoan`, passing in a
`FlashLoanReceiver` contract and the desired number of tokens.  The `flashLoan`
method transfers the tokens to the receiver, calls the `executeOperation`
method on the receiver, and finally transfers the tokens (plus a fee) from the
receiver back to the pool:

```solidity
function flashLoan(IFlashLoanReceiver receiver, uint256 amount) external {
    uint fee = ...;

    asset.transferFrom(address(this), msg.sender, amount);

    receiver.executeOperation(amount, fee, msg.sender);

    asset.transferFrom(msg.sender, address(this), amount + fee);
}
```

Our goal is to prove properties about the `Pool` contract, but we will need to
interact with the entire combined protocol consisting of the `Pool` contract,
the `Asset` contract, and the `FlashLoanReceiver` contracts.  We will begin by
explaining the default behavior of the Prover when making external calls to
unknown contracts.  We will then show how to link the specific `Asset` contract
implementation to the `Pool` contract.  Finally, we will show some techniques
for reasoning about the open-ended set of possible `FlashLoanReceiver`
implementations.


Handling unresolved method calls
--------------------------------

To start, let's write a basic property of the pool and run the Prover on the
`Pool` contract to see how it handles calls to unknown code.

Here is a simple property from [`certora/specs/pool_havoc.spec`]:

```cvl
/// `deposit` must increase the pool's underlying asset balance
rule integrityOfDeposit {

    mathint balance_before = assetBalance();

    env e; uint256 amount;
    deposit(e, amount);

    mathint balance_after = assetBalance();

    assert balance_after == balance_before + amount,
        "deposit must increase the underlying balance of the pool";
}
```

This rule makes a call to `Pool.deposit(...)`, which in turn makes a call to
`asset.transferFrom(...)`; to understand the behavior of `deposit` the Prover
must also reason about the `Asset` contract.  If we verify the rule without
giving the Prover access to the `Asset` code, the call to `transferFrom(...)`
will be unresolved.

By default, the Prover will handle calls to unresolved functions by assuming
they can do almost anything -- we say that the Prover "{term}`havocs <havoc>`"
some part of the state.  The part of the state that is havoced depends on the
type of call: calls to view functions are allowed to return any value but can
not affect storage, while calls to non-view functions are allowed to change the
storage of all contracts in the system *besides the calling
contract*[^reentrancy].  See {ref}`auto-summary` in the reference manual for
complete details.

[^reentrancy]: The Prover assumes that the external calls do not modify the
  storage of the calling contract.  This assumption comes from an assumption
  that the called code is non-reentrant.  If you are concerned about violations
  caused by reentrancy, you can override this assumption using a `HAVOC_ALL`
  summary; see {ref}`havoc-summary` for details.

We can see this behavior by verifying the `integrityOfDeposit` rule against the
`Pool` contract without giving the Prover access to the `Asset` contract ([see script](https://github.com/Certora/LiquidityPoolExample/blob/main/certora/scripts/verifyJustPool.sh)):

```bash
$ sh certora/scripts/verifyJustPool.sh
```

In this case, the `integrityOfDeposit` rule fails.  To understand why, we can
unfold the call trace for the call to `deposit`:

![Call trace for `integrityOfDeposit` with `deposit` method unfolded to show DEFAULT HAVOCs for calls to `balanceOf` and `transferFrom`](no-link-call-trace.png)

Here we see that the calls to `transferFrom` and `balanceOf` are marked with
"DEFAULT HAVOC".  This means that the Prover lets the call to
`transferFrom` to change the balances any way it likes.  In fact, calls to
`asset.balanceOf(...)` are also unresolved, so the Prover can choose any return
value that causes a counterexample.  In this case, we can see that the Prover
chose `0` for the first return value of `balanceOf` and `1` for the last return
value of `balanceOf`:

![Variables for `integrityOfDeposit` on `Pool` showing `balance_before = 0` and `balance_after = 1`](no-link-variables.png)

The "Call Resolution" tab on the report provides more information about all of
the unresolved method calls within the contract and how they are resolved by
the Prover[^resolutionWarnings]:

![Call resolution for `integrityOfDeposit` showing havocs of return values for `balanceOf` and all variables of external contracts for `transferFrom`](no-link-call-resolution.png)

[^resolutionWarnings]: Unresolved calls that are not explicitly handled are
  considered warnings; in this case there are three unresolved calls, which is
  why there is a red 3 on the call resolution tab.  In general, it is good
  practice to explicitly resolve all calls.

Here we see that the call from `Pool.deposit` to `balanceOf` is summarized by
havocing only the return value (since `balanceOf` is a view method), while the
call from `Pool.deposit` to `transferFrom` havocs all contracts except `Pool`.

Working with known contracts
----------------------------

In the case of the `Pool` verification, we don't want the Prover to choose
arbitrary behavior for the `Asset`, because we have the `Asset` code.  Instead,
we would like the Prover to model the `asset` contract using the `Asset` code.

To do so, we must first add the `Asset` contract to the set of contracts that
the Prover knows about.  This set of contracts is called the {term}`scene`.  You
can add a contract to the scene by passing the solidity source as a
[command line argument](/docs/ref-manual/cli/options.md)
to `certoraRun`.  The Prover creates a contract instance (with a corresponding
address) in the scene for each source contract provided on the command line:

```bash
$ certoraRun contracts/Pool.sol contracts/Asset.sol --verify Pool:certora/specs/pool_havoc.spec
```

Adding `Asset.sol` to the scene makes the Prover aware of it, but it does not
connect the `asset` field of the pool to the `Asset` contract.  Although
`Pool.asset` is declared to have type `Asset` in the solidity source, the
solidity compiler erases that information from the bytecode; in the compiled
bytecode the field is just treated as an `address`.

To reconnect the `Asset` code to the `Pool.asset` field, we can use the
{ref}`--link` option:

```bash
$ certoraRun contracts/Pool.sol contracts/Asset.sol \
    --verify Pool:certora/specs/pool_havoc.spec \
    --link   Pool:asset=Asset
```

The `--link Pool:asset=Asset` option tells the Prover to assume that the `asset`
field of the `Pool` contract instance in the scene is a pointer to the `Asset`
contract instance in the scene.  With this information, the Prover is able to
resolve the calls to the methods on `Pool.asset` using the code in `Asset.sol`.

With this option, the Prover is no longer able to construct a counterexample to
the `integrityOfDeposit` rule ([see script][pool-link-script]).
Running

```bash
$ sh certora/scripts/verifyWithLink.sh
```

shows that the `integrityOfDeposit` rule now passes.

(using-example)=
### Accessing additional contracts from CVL

When a contract instance is added to the scene, it is also possible to call
methods on that contract directly from CVL.  To do so, you need to introduce
a variable name for the contract instance using
{ref}`the using statement <using-stmt>`.  In our running example, we can create
a variable `underlying` to refer to the `Asset` contract instance[^using-position].

[^using-position]: `using` statements must appear after the `import` statements
  (if any) and before the `methods` block (if any).

```cvl
using Asset for underlying
using Pool  for pool
```

We can then call methods on the contract `underlying`.  For example, instead of
adding a special method `assetBalance` to the `Pool` contract to call
`asset.balanceOf` for us, we can call it directly from the spec:

```cvl
/// `deposit` must increase the pool's underlying asset balance
rule integrityOfDeposit {

    env e1;
    mathint balance_before = underlying.balanceOf(e1, pool);

    env e; uint256 amount;
    deposit(e, amount);

    env e2;
    mathint balance_after = underlying.balanceOf(e2, pool);

    assert balance_after == balance_before + amount,
        "deposit must increase the underlying balance of the pool";
}
```

We can simplify this rule in two ways.  First, we can declare the
`underlying.balanceOf` method `envfree` to avoid explicitly passing in `env`
variables.  This works the same way as `envfree` {ref}`declarations for the
main contract <envfree>`, except that you must indicate that the method is for
the `underlying` contract instance:

```cvl
methods {
    ...

    underlying.balanceOf(address) returns(uint256) envfree
}
```

The second simplification is that we can use the special variable
`currentContract` to refer to the main contract being verified (the one passed
to {ref}`--verify`), so we don't need to add the `using` statement for `Pool`.
With these changes, the rule looks as follows ([spec file][pool-link], [run script][pool-link-script]):

```cvl
/// `deposit` must increase the pool's underlying asset balance
rule integrityOfDeposit {

    mathint balance_before = underlying.balanceOf(currentContract);

    env e; uint256 amount;
    deposit(e, amount);

    mathint balance_after = underlying.balanceOf(currentContract);

    assert balance_after == balance_before + amount,
        "deposit must increase the underlying balance of the pool";
}
```

(unknown-contracts)=
Working with unknown contracts
------------------------------

Linking is appropriate for situations when we know the specific contracts that
a field points to.  In many cases, however, we *don't* know what contract an
address refers to.  For example:

 - A contract may call a method on a contract address passed in by the user.  In
   our running example, the user may provide any `FlashLoanReceiver`
   implementation they want to.

 - A contract may be designed to work with many instances of the same interface.
   For example, a pool might be designed to work with arbitrary ERC20
   implementations.

In this case, the only option is to {term}`summarize` the unknown code for the
Prover.  There are a few commonly used summary types for this situation:

 - The safest option is to use a {ref}`HAVOC_ALL summary <multicontract-havoc>`
   (or a `NONDET` summary for a view method).

 - The most flexible and most commonly used option is to use a
   {ref}`DISPATCHER summary <multicontract-dispatcher>`.

The remainder of this section describes the pros and cons of these options,
using the `FlashLoanReceiver.executeOperation` method as an example.

(multicontract-havoc)=
### Havoc summaries

As described above, a havoc summary instructs the Prover to make no assumptions
about the missing code.

The `HAVOC_ALL` summary means that the provided code is allowed to change any
state in an arbitrary way, including the state of the calling contract.  This
is {term}`sound`, but it makes it difficult to prove anything.

For example, we might like to show that flash loans can only increase the
underlying balance of the pool.  We actually need to be a bit careful because a
user with a balance could withdraw their own tokens during a flash loan
operation without causing a problem.  For simplicity, we'll assume the user has
no balance at the beginning of the transaction (we'll see later that even this
assumption is not strong enough).

We can write the property as follows:

```cvl
rule flashLoanIncreasesBalance {
    address receiver; uint256 amount; env e;

    require balanceOf(receiver) == 0;

    mathint balance_before = underlying.balanceOf(currentContract);

    flashLoan(e, receiver, amount);

    mathint balance_after = underlying.balanceOf(currentContract);

    assert balance_after >= balance_before,
        "flash loans must not decrease the contract's underlying balance";
}
```

To use a `HAVOC_ALL` summary for the `executeOperation` method, we add it to
the `methods` block:

```cvl
methods {
    executeOperation(uint256,uint256,address) returns (bool) => HAVOC_ALL
}
```

We can run this [spec][flash-loan-havoc] (see [script][flash-loan-havoc-script]),
and we see that the rule fails.  The reason is similar to the first version of
the `integrityOfDeposit` rule above failed: the Prover allows the call from
`flashLoan` to `executeOperation` to have arbitrary side effects.

In this case, the Prover chose a somewhat silly counterexample.  We see that
the first time the Prover reads the `asset` field, it gets the address of the
`Asset` contract (as it should, since we linked it).  However, after the return
from the summarized `executeOperation`, loading from `asset` gives a different
address:

![Call trace showing execution of `flashLoan`.  Inside `Pool.flashLoan`, the trace shows two reads from `asset` with different values.](havoc-all.png)

The Prover assumed that the unknown `executeOperation` could change the `asset`
field within the `Pool` contract.  This is clearly an overapproximation, since
the only way for the `asset` field to change is if the `Pool` contract changes
it, and the `Pool` contract has no methods that change it.  Nevertheless, with
a `HAVOC_ALL` summary, the Prover conservatively assumes that anything can
happen.

For this reason, the `HAVOC_ALL` summary, although safe, is rarely used.

(multicontract-dispatcher)=
### Dispatcher summaries



```{todo}
Dispatcher
```

### Other options

TODO: Footnotes:

[example-repo]:     https://github.com/Certora/LiquidityPoolExample
[pool-spec]:        https://github.com/Certora/LiquidityPoolExample/certora/specs/pool.spec
[pool-script]:      https://github.com/Certora/LiquidityPoolExample/blob/main/certora/scripts/verifyPool.sh
[pool-havoc]:       https://github.com/Certora/LiquidityPoolExample/blob/main/certora/specs/pool_havoc.spec
[pool-link]:        https://github.com/Certora/LiquidityPoolExample/blob/main/certora/specs/pool_link.spec
[pool-link-script]: https://github.com/Certora/LiquidityPoolExample/blob/main/certora/scripts/verifyWithLinking.sh
[flash-loan-havoc]:        https://github.com/Certora/LiquidityPoolExample/blob/main/certora/specs/flashLoan_havoc.spec
[flash-loan-havoc-script]: https://github.com/Certora/LiquidityPoolExample/blob/main/certora/scripts/verifyFlashLoanHavoc.sh

