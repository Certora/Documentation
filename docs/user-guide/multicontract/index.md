```{eval-rst}
.. role:: cvl(code)
   :language: cvl
```

Working with Multiple Contracts
===============================

In the previous chapter, we focused on rules describing the behavior of a
single contract.  In practice, most protocols consist of multiple interacting
contracts.  In this chapter, we discuss techniques for verifying protocols
involving multiple contracts.

We begin by walking through a running example protocol and explaining the
Prover's default behavior when it encounters calls from one contract to
another.  We then show how to handle a protocol consisting of multiple
contracts whose implementation is known.  After that, we discuss dispatcher
summaries, an important technique for handling contracts whose implementation
is not known at verification time.  Finally, we give a concrete and reusable
setup for a very common case: a contract that can work with many different ERC20
implementations.

The entire running example for this chapter can be found {clink}`here</DEFI/LiquidityPool/>`.

```{contents}
```

Example protocol
----------------

To demonstrate these concepts, we work with a simplified liquidity pool contract called
{clink}`Pool</DEFI/LiquidityPool/contracts/Pool.sol>`.
The {clink}`full specification</DEFI/LiquidityPool/certora/specs/Full.spec>` is in
`certora/specs/Full.spec` (although this chapter only discusses the
`integrityOfDeposit` and `flashLoanIncreasesBalance` properties) and the
{clink}`final run conf</DEFI/LiquidityPool/runFullPool.conf>` is in `runFullPool.conf`.

The liquidity pool allows users to deposit and withdraw a single fixed type of
ERC20 token (the `asset`). The liquidity pool itself is an ERC20 token and
balance in the liquidity pool token denotes the _shares_ in the pool.
We'll reserve the words _amount_ and _assets_ to denote balance in the `asset`.
So, in return for depositing _assets_ the user receives _shares_ in the pool.
Withdrawing decreases the user's shares and increases the user' assets.

Here is the interface for the pool, followed by the Pool's code.

```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/contracts/IPool.sol
   :language: solidity
   :caption: :clink:`IPool interface</DEFI/LiquidityPool/contracts/IPool.sol>`
```

```{eval-rst}
.. dropdown:: :clink:`Pool.sol </DEFI/LiquidityPool/contracts/Pool.sol>`

   .. literalinclude:: ../../../Examples/DEFI/LiquidityPool/contracts/Pool.sol
      :language: solidity
```

For demonstration purposes, we have also added function `assetBalance`, which
returns the pool's balance of the underlying asset (we'll see
{ref}`later <using-example>` that this is not necessary):

```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/contracts/Pool.sol
   :language: solidity
   :caption: :clink:`assetBalance</DEFI/LiquidityPool/contracts/IPool.sol>`
   :lines: 82-84
```

Users can also take out _flash loans_ - loans that must be repaid within the same
transaction.  To do so, the user calls `flashLoan`, passing in a
`FlashLoanReceiver` contract and the desired number of tokens.  The `flashLoan`
method transfers the tokens to the receiver, calls the `executeOperation`
method on the receiver, and finally transfers the tokens (plus a fee) from the
receiver back to the pool:


```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/contracts/Pool.sol
   :language: solidity
   :caption: :clink:`flashLoan</DEFI/LiquidityPool/contracts/IPool.sol>`
   :lines: 67-76
```

Our goal is to prove properties about the `Pool` contract, but we will need to
interact with the entire combined protocol consisting of the `Pool` contract,
the `Asset` contract, and the `FlashLoanReceiver` contracts.  We will begin by
explaining the default behavior of the Prover when making external calls to
unknown contracts.  We will then show how to link the specific `Asset` contract
implementation to the `Pool` contract. Finally, we will show some techniques
for reasoning about the open-ended set of possible `FlashLoanReceiver`
implementations.


Handling unresolved method calls
--------------------------------

To start, let's write a basic property of the pool and run the Prover on the
`Pool` contract to see how it handles calls to unknown code.

Here is a simple property:

```{eval-rst}
.. cvlinclude:: ../../../Examples/DEFI/LiquidityPool/certora/specs/pool_havoc.spec
   :cvlobject: integrityOfDeposit
   :caption: :clink:`integrityOfDeposit</DEFI/LiquidityPool/certora/specs/pool_havoc.spec>`
```

This rule makes a call to `Pool.deposit(...)`, which in turn makes a call to
`asset.transferFrom(...)`; to understand the behavior of `deposit` the Prover
must also reason about the `Asset` contract.  If we verify the rule without
giving the Prover access to the `Asset` code, the call to `transferFrom(...)`
will be unresolved.

By default, the Prover will handle calls to unresolved functions by assuming
they can do almost anything &mdash; we say that the Prover "{term}`havocs <havoc>`"
some part of the state.  The part of the state that is havoced depends on the
type of call: calls to view functions are allowed to return any value but can
not affect storage (a `NONDET` summary), while calls to non-view functions are
allowed to change the storage of all contracts in the system *besides the
calling contract*[^reentrancy] (a `HAVOC_ECF` summary).  See
{ref}`auto-summary` in the reference manual for complete details.

[^reentrancy]: The Prover assumes that the external calls do not modify the
  storage of the calling contract.  This assumption comes from an assumption
  that the called code is non-reentrant.  If you are concerned about violations
  caused by reentrancy, you can override this assumption using a `HAVOC_ALL`
  summary; see {ref}`havoc-summary` for details.

We can see this behavior by verifying the `integrityOfDeposit` rule against the
`Pool` contract without giving the Prover access to the `Asset` contract.
The {clink}`JustPool.conf</DEFI/LiquidityPool/JustPool.conf>` config file does
just that, run it using:

```sh
$ certoraRun JustPool.conf
```

In this case, the `integrityOfDeposit` rule fails.  To understand why, we can
unfold the call trace for the call to `deposit`:

![Call trace for `integrityOfDeposit` with `deposit` method unfolded to show DEFAULT HAVOCs for calls to `balanceOf` and `transferFrom`](no-link-call-trace.png)

Here we see that the calls to `transferFrom` and `balanceOf` are marked with
"DEFAULT HAVOC".  This means that the Prover lets the call to
`transferFrom` to change the balances any way it likes.  In fact, calls to
`asset.balanceOf(...)` are also unresolved, so the Prover can choose any return
value that causes a counterexample.  In this case, we can see that the Prover
chose `3` for the first return value of `balanceOf` and `9`
for the last return value of `balanceOf`:

![Call trace for `integrityOfDeposit` on `Pool` showing call to `assetBalance` with internal havoced call to `balanceOf`, returning 3 in once place and 9 in another](no-link-variables.png)

The "Call Resolution" tab on the report provides more information about all of
the unlinked external method calls within the contract and how they are
resolved by the Prover[^resolutionWarnings]:

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
[command line argument](/docs/prover/cli/options.md)
to `certoraRun`.  The Prover creates a contract instance (with a corresponding
address[^addressOption]) in the scene for each source contract provided on the command
line (or the config file).

```sh
$ certoraRun contracts/Pool.sol contracts/Asset.sol --verify Pool:certora/specs/pool_havoc.spec ...
```

[^addressOption]: You can control the address chosen for the contract instance
using the {ref}`--address` option.

Adding `Asset.sol` to the scene makes the Prover aware of it, but it does not
connect the `asset` field of the pool to the `Asset` contract.  Although
`Pool.asset` is declared to have type `Asset` in the solidity source, the
solidity compiler erases that information from the bytecode; in the compiled
bytecode the field is just treated as an `address`, and at run time the field
could point to any contract.

To connect the `Asset` code to the `Pool.asset` field, we can use the
{ref}`--link` option:

```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/WithLinking.conf
   :language: json
   :caption: :clink:`WithLinking.conf</DEFI/LiquidityPool/WithLinking.conf>`
   :emphasize-lines: 8-10
```

The `--link Pool:asset=Asset` option tells the Prover to assume that the `asset`
field of the `Pool` contract instance in the scene is a pointer to the `Asset`
contract instance in the scene.  With this information, the Prover is able to
resolve the calls to the methods on `Pool.asset` using the code in `Asset.sol`.

With this option, the Prover is no longer able to construct a counterexample to
the `integrityOfDeposit` rule, so the rule passes. Note that the external calls
to the `Asset` contract no longer appear in the "Call Resolution" tab, because
the Prover does not report linked calls here.

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
using Asset as underlying;
using Pool as pool;
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
    require e.msg.sender != pool;
   
    deposit(e, amount);

    env e2;
    mathint balance_after = underlying.balanceOf(e2, pool);

    assert balance_after == balance_before + amount,
        "deposit must increase the underlying balance of the pool";
}
```

We can simplify this rule in two ways. First, we can declare the
`underlying.balanceOf` method `envfree` to avoid explicitly passing in `env`
variables. This works the same way as `envfree` {ref}`declarations for the
main contract <envfree>`, except that you must indicate that the method is for
the `underlying` contract instance [^wildcards]:


```{eval-rst}
.. cvlinclude:: ../../../Examples/DEFI/LiquidityPool/certora/specs/pool_link.spec
   :cvlobject: methods
   :lines: 12-14
```

[^wildcards]: instead of `underlying.balanceOf` in the methods block, you could
  also use the contract name: `Asset.balanceOf`.  You could also write a single
  entry for all `balanceOf` methods using `_` for the contract: `_.balanceOf`.
  See {ref}`methods-entries` for full details.

The second simplification is that we can use the special variable
`currentContract` to refer to the main contract being verified (the one passed
to {ref}`--verify`), so we don't need to add the `using` statement for `Pool`.
With these changes, the rule looks as follows:

```{eval-rst}
.. cvlinclude:: ../../../Examples/DEFI/LiquidityPool/certora/specs/pool_link.spec
   :cvlobject: integrityOfDeposit
   :caption: :clink:`integrityOfDeposit from pool_link.spec</DEFI/LiquidityPool/certora/specs/pool_link.spec>`
```

You can run this rule using the
{clink}`WithLinking.conf</DEFI/LiquidityPool/WithLinking.conf>` config file.

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
Prover.  Although there are many available types of summaries, the ones most
commonly used for unknown code are {ref}`dispatcher`.

The `DISPATCHER` summary resolves calls by assuming that the receiver address
is one of the contracts in the scene that implements the called method.  It
will try every option, and if any of them can cause a violation, it will
report a counterexample.

```{warning}
The `DISPATCHER` summary is {term}`unsound`, meaning that using it can cause you
to hide bugs in your contracts.  Therefore, you should make sure you understand
the risks before using them.  See {ref}`dispatcher-danger` below.
```

To demonstrate the `DISPATCHER` summary, let us prove a basic property about
flash loans.  For example, we might like to show that flash loans can only
increase the underlying balance of the pool.  We can write the property as
follows:

```{eval-rst}
.. cvlinclude:: ../../../Examples/DEFI/LiquidityPool/certora/specs/flashLoan_dispatcher.spec
   :cvlobject: flashLoanIncreasesBalance
   :caption: :clink:`flashLoanIncreasesBalance</DEFI/LiquidityPool/certora/specs/flashLoan_dispatcher.spec>`
```

Verifying this rule without any summarization will fail, for the same reasons
that the first run of `integrityOfDeposit` above failed:  the `flashLoan`
method calls `executeOperation` on an unknown contract, and the Prover
constructs a counterexample where `executeOperation` changes the underlying
balance.  This is possible because the default `HAVOC_ECF` summary allows
`executeOperation` to do anything to the `underlying` contract.

To use a `DISPATCHER` summary for the `executeOperation` method, we add it to
the `methods` block[^optimistic-dispatcher]:

```{eval-rst}
.. cvlinclude:: ../../../Examples/DEFI/LiquidityPool/certora/specs/flashLoan_dispatcher.spec
   :cvlobject: methods
   :lines: 1, 4-5
```

[^optimistic-dispatcher]: The `true` in `DISPATCHER(true)` tells the Prover to
  use "optimistic dispatch mode".  Optimistic mode is almost always the right
  choice; see {ref}`dispatcher` in the reference manual for full details.

This summary means that when the Prover encounters an external call to
`receiver.executeOperation(...)`, it will try to construct counterexamples
where the `receiver` contract is any of the contracts in the scene that
implement the `executeOperation` method.  We use the wildcard `_` as the
receiver contract so that the summary will apply regardless of the receiver
contract.

So far, there are no contracts in the scene that implement the
`executeOperation` method, so the Prover will conservatively use a havoc
summary for the call, and the rule will still fail.  To make use of the
dispatcher summary, we need to add a contract to the scene that implements the
method.

Let's start by adding a trivial receiver
(in {clink}`TrivialReceiver.sol</DEFI/LiquidityPool/certora/harness/TrivialReceiver.sol>`)
that implements `executeOperation` but does nothing:

```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/certora/harness/TrivialReceiver.sol
   :language: solidity
   :caption: :clink:`TrivialReceiver.sol</DEFI/LiquidityPool/certora/harness/TrivialReceiver.sol>`
   :lines: 5-
```

Adding `TrivialReceiver.sol` to the scene allows the Prover to dispatch to it.
To run, use the {clink}`FlashLoanTrivial.conf</DEFI/LiquidityPool/FlashLoanTrivial.conf>`
config file.

With this dispatcher in place, the rule passes. Examining the call resolution
tab shows that the Prover used the dispatcher summary for `executeOperation`
and considered only `TrivialReceiver.executeOperation` as a possible
implementation:

![Call resolution tab showing `Pool.flashLoan` summarized with a Dispatcher.
The "alternatives" list contains `[TrivialReceiver.executeOperation]`](trivial-resolution.png)

Although the rule passes, it is important to pause and think about what we have
proved; the next section shows that we shouldn't rest easy yet.

(dispatcher-danger)=
### The dangers of `DISPATCHER`

What we have proved so far is that *if* the only possible `FlashLoanReceiver`
is `TrivialReceiver`, *then* the pool's underlying balance doesn't decrease.
However, we have not proved that the underlying balance *never* decreases after
a flash loan.

Since the `DISPATCHER` summary only considers the contracts you provide as
possible implementations, it forces you to think about a threat model: the set
of behaviors that you want to protect against.  If there is a clever way to
construct a receiver contract that violates the rule, but you don't think of
it, the Prover won't be able to find it.  So far, we were able to prove the
rule, but only with a very weak threat model: we assume that the flash loan
receiver does nothing.

In fact, we can easily construct a flash loan receiver that decreases the
pool's underlying balance.  For example, if the receiver somehow got an
approval to transfer underlying tokens away from the pool, it could just
transfer them, thereby decreasing the underlying balance of the pool.
We can write such a receiver:

```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/certora/harness/TransferReceiver.sol
   :language: solidity
   :caption: :clink:`TransferReceiver.sol</DEFI/LiquidityPool/certora/harness/TransferReceiver.sol>`
   :lines: 6-
```

Note that this isn't a complete working example; we haven't provided a
constructor, or linked the `pool` address to the actual pool, or any way to
ensure that the pool has given the receiver an allowance.  Nevertheless, if we
add it to the scene, the Prover is able to use it to construct a
counterexample. Since the Prover explores every possible value of the `pool`
variable, and every possible value for the underlying's allowances, it is able
to set up the details of the counterexample automatically.

We do need to do one more piece of setup to get this receiver to work the way
we'd like. If we just add `TransferReceiver` to the scene, the Prover will not
be able to resolve its call to `transferFrom`.  This will cause the same kind
of havoc we saw above. We could remedy this using a `DISPATCHER` summary for
`transferFrom` (see {ref}`erc20-dispatcher`), but for now, we'll simply
link the `underlying` variable to the `Asset` contract instance:

```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/FlashLoanTransfer.conf
   :language: json
   :caption: :clink:`FlashLoanTransfer.conf</DEFI/LiquidityPool/FlashLoanTransfer.conf>`
   :emphasize-lines: 10-13
```

With the additional receiver implementation on the scene, we see that the Prover
considers both alternatives for the `executeOperation` call:

![Call resolution tab showing unresolved call from `Pool.flashLoan` to
  `executeOperation`, with the "alternatives" set containing both
  `TransferReceiver.executeOperation` and `TrivialReceiver.executeOperation`](transfer-resolution.png)

And we also see that it was able to use the `TransferReceiver` to construct a
counterexample:

![Partial call trace showing `executeOperation` dispatched to
  `TransferReceiver.executeOperation`, which calls
  `transferFrom(Pool,TransferReceiver,2)`](transfer-trace.png)

As we expected, the dispatcher for `executeOperation` chooses
`TransferReceiver.executeOperation` as the receiver, which in turn calls
`underlying.transferFrom(Pool, ..., 2)`.  If we look in the initial storage of the contract,
we see that the Prover chose the pool's allowance for the recipient to be
`10`:

![Call trace entry showing `_allowance[Pool][TransferReceiver]` returning `10`](transfer-allowance.png)

It turns out that this particular violation can't actually happen, because the
pool contract never approves any other contract to transfer its funds.  We
could prove an invariant to this effect and add it to our rule using
{ref}`requireInvariant`.

For more examples of `requireInvariant` usage, check out the [user guide](../patterns/require-invariants.md).

Nevertheless, this example shows that having too few dispatchees can cause a
rule to pass, even though the property it describes is not necessarily true in
all situations.

### Designing flexible dispatchees

The `TransferReceiver` described in the previous section is fairly targeted: we
thought of a way to violate the rule, and then designed a receiver contract to
cause the violation.  However, one of the main benefits of the Prover is that
you don't have to know in advance the attacks you're trying to prevent, and
this approach to creating dispatchees loses that benefit.

There is a clever trick you can use to write flexible dispatchees that can
cover a broad range of potential attacks.  The trick relies on the fact that the
Prover will consider all possible values for contract fields when trying to
produce a counterexample.

Suppose we wanted to reason about the possibility that a flash loan receiver
could make non-view calls back to the pool from `executeOperation`.  We could
write a separate receiver contract for each method which just calls that method,
and add them all to the scene as potential dispatchees.  However, this can
become cumbersome, especially if there are multiple methods that need to be
implemented.

Instead, we can write a single receiver that simulates all of these potential
method calls.  Let's start by getting a list of the external methods of the
contract.  The Prover helpfully provides such a list whenever we verify a rule[^noview]:

!["Contract list" tab (next to the "Results" tab) showing the `Pool` contract
  and all of its methods](pool-methods.png)

[^noview]: The Prover doesn't identify the view functions, so we have to look at
  the source code to determine which ones are non-view functions.

Now, we can write an `executeOperation` method that could call any of the
non-view functions.  We can do this with a big `if`-`then`-`else` statement (
:clink:`full contract</DEFI/LiquidityPool/certora/harness/FlexibleReceiver.sol>`)[^no-recursion]:

```solidity
contract FlexibleReceiver is IFlashLoanReceiver {
    IPool token;

    function executeOperation(...) ... {
        uint  callbackChoice = ...;

        if (callbackChoice == 0)
            token.deposit(...);
        else if (callbackChoice == 1)
            token.transferFrom(...);
        else if (callbackChoice == 2)
            token.withdraw(...);
        ...
        else
            assert(false, "invalid callbackChoice value");

        return ...;
    }
}
```

[^no-recursion]: We don't include a call to `token.flashLoan` since this will
  cause potentially infinite recursion, which will cause the Prover to fail.

The value of the `callbackChoice` variable determines which `Pool` method
`executeOperation` will call. We would like the Prover to consider every
possible value of the `callbackChoice` field, so that it can choose to call any
of the pool's methods. We would also like the Prover to consider every choice
of arguments to these method calls.

For this to be valid solidity code, we need to actually give values to the
`callbackChoice` and the arguments to the called methods. To do this, we use a
clever trick. Since the Prover considers every possible value for storage
variables, we can simply use a storage variable for `callbackChoice` and for
the arguments. For example, we could write

```solidity
contract FlexibleReceiver is IFlashLoanReceiver {
    ...

    uint arbitraryCallback;
    function executeOperation(...) ... {
        uint callbackChoice = arbitraryCallback;

        ...
    }
}
```

The Prover will consider cases where `arbitraryCallback` can have any possible
value at the beginning of the rule, and we can use this arbitrary value to fill
in `callbackChoice`[^arbitrary-constructor].

[^arbitrary-constructor]: This trick doesn't work during the initial state
  checks for invariants, since storage is always initialized to zero at the
  start of a constructor.

One potential drawback of this choice is that the receiver contract will make
the same callback every time `executeOperation` is called within a rule.  We can
relax this restriction by using a mapping of arbitrary values instead of a
single callback:

```solidity
contract FlexibleReceiver is IFlashLoanReceiver {
    ...

    uint counter;
    mapping(uint => uint) arbitraryCallbacks;

    function executeOperation(...) ... {
        uint  callbackChoice = arbitraryCallbacks[counter++];

        ...
    }
}
```

With this version, the Prover is able to choose a new value of
`arbitraryCallbacks[i]` for each `i`; since the `counter` variable is updated
on each call, this means that it can choose a different value of
`callbackChoice` for each call.

The abstract contract {clink}`ArbitraryValues</DEFI/LiquidityPool/certora/helpers/ArbitraryValues.sol>`
makes this simple. For each value type, it provides an `arbitraryType()` method that
returns an undefined value that the Prover can fill in arbitrarily as it is
constructing counterexamples.  For example, the `arbitraryInt192()` method
returns a newly selected `int192` each time it called.  In this case, we can
use the `arbitraryUint` and `arbitraryAddress` methods to choose the callback
and the arguments (conf file {clink}`WithFlexibleLinked.conf</DEFI/LiquidityPool/WithFlexibleLinked.conf>`).

```{eval-rst}
.. literalinclude:: ../../../Examples/DEFI/LiquidityPool/certora/harness/FlexibleReceiver.sol
   :language: solidity
   :caption: :clink:`FlexibleReceiver.sol</DEFI/LiquidityPool/certora/harness/FlexibleReceiver.sol>`
   :lines: 7-
```

With this implementation, the Prover will consider every possible value for
`callbackChoice` as well as for the arguments to the methods, which has the
effect of calling an arbitrary non-view method on `pool` with arbitrary
arguments.

This approach still doesn't give perfect coverage.  If the `token` field is
linked to the pool, it will only call methods on the pool.  In fact, this
receiver will miss the violation that the `TransferReceiver` uncovered, because
that requires calling `transferFrom` on the `Asset` rather than the `Pool`,
although this particular shortcoming can be
addressed by {ref}`using a dispatcher for the ERC20 methods <erc20-dispatcher>`
instead of linking to the pool.

Another important caveat is that this technique does not work for initial state
checks for invariants.  In this case, the Prover does not choose arbitrary
values for storage variables, since it knows that storage variables are all
initialized to 0 before the constructor call.  Therefore, the `arbitraryType()`
methods will always return 0.

A third shortcoming with this implementation is that it only makes one
reentrant call to the `token` contract.  Vulnerabilities that require two or
more callbacks from the `FlashLoanReceiver` to exploit will not be detected.

Nevertheless, this technique is a useful way to build dispatchers that get
pretty good coverage without requiring too much prediction of the bugs they
will find.  The `ArbitraryValues` helper contract makes this pattern easy to
implement.

(erc20-dispatcher)=
### Using `DISPATCHER` for ERC20 contracts

One very common use case for the material discussed in this chapter is when a
contract is designed to work with arbitrary ERC20 tokens.  In this case, it is
common to summarize all of the ERC20 methods using `DISPATCHER` summaries, and
to provide several ERC20 implementations to the Prover.

To facilitate this, the {clink}`helpers</DEFI/LiquidityPool/certora/helpers/>`
directory of the example code contains a
{clink}`spec file called erc20.spec</DEFI/LiquidityPool/certora/helpers/erc20.spec>`
as well as a variety of ERC20 token implementations
(inside {clink}`tokens</DEFI/LiquidityPool/certora/helpers/tokens>` folder).
The `erc20.spec` file simply contains a methods block that summarizes all of the
ERC20 methods as `DISPATCHER`.  You can use an
{doc}`import statement </docs/cvl/imports>` to include this in your spec:

```cvl
import "../helpers/erc20.spec";
```

This gives a concise way to handle this situation.  Be sure to include the
tokens in the scene!

Conclusion
----------

In this chapter, we've seen several techniques for handling inter-contract
calls.  Linking allows us to give the source code for a contract referenced by
a particular field.  `DISPATCHER` summaries instruct the Prover to consider
several possible implementations of a contract, and can be used when we don't
know exactly which contract an address will refer to.

We've seen that `DISPATCHER` summaries are not completely safe &mdash; they
constrain the possible implementations of external contracts, so they may miss
bugs that those implementations don't trigger.  However, we have seen a useful
technique that can explore a wide range of behaviors with little effort.
