Invariants
==========

Invariants describe a property of the state of a contract that is always
expected to hold.

```{caution}
Even if an invariant is verified, it may still be possible to violate it.  This
is a potential source of {term}`unsoundness <unsound>`.  See {ref}`invariant-assumptions`
for details.
```


```{contents}
```


Syntax
------

The syntax for invariants is given by the following [EBNF grammar](syntax):

```
invariant ::= "invariant" id
              [ "(" params ")" ]
              expression
              [ "filtered" "{" id "->" expression "}" ]
              [ "{" { preserved_block } "}" ]

preserved_block ::= "preserved"
                    [ method_signature ]
                    [ "with" "(" params ")" ]
                    block

method_signature ::= id "(" [ evm_type [ id ] { "," evm_type [ id ] } ] ")"
                     | "fallback" "(" ")"
```

See {doc}`basics` for the `id` production, {doc}`expr` for the `expression`
production, and {doc}`statements` for the `block` production.

Overview
--------

In CVL, an invariant is a property of the contract state that is expected to be
true whenever a contract method is not currently executing.  This kind of
invariant is sometimes called a "representation invariant".

Each invariant has a name, possibly followed by a set of parameters, followed
by a boolean expression.  We say the invariant *holds* if the expression
evaluates to true in every reachable state of the contract, and for all
possible values of the parameters.

While verifying an invariant, the Prover checks two things.  First, it checks
that the invariant is established after the constructor.  Second, it checks
that the invariant holds after the execution of any contract method, assuming
that it held before the method was executed (if it does hold, we say the method
*preserves* the invariant).

If an invariant always holds at the beginning of every method call, it is
always safe to assume that it is true.  The
{ref}`requireInvariant command <requireInvariant>` makes it easy to add this
assumption to another rule, and is a quick way to rule out counterexamples that
start in impossible states.  See also {doc}`/docs/user-guide/patterns/safe-assum`.

```{note}
Invariants are intended to describe the state of a contract at a particular
point in time.  Therefore, you should only use view functions inside of an
invariant.  Non-view functions are allowed, but the behavior is undefined.
```

(invariant-assumptions)=
Assumptions made while checking invariants
------------------------------------------

In Ethereum, the only way to change the storage state of a smart contract is
using the smart contract's methods.  Therefore, if an invariant depends only on
the storage of the contract, we can prove the invariant by checking it after
calling each of the contract methods.

However, it is possible to write invariants whose value depends on things other
than the contract's storage.  The truth of an expression may depend on the
state of other contracts or on the {term}`environment`.  For these invariants,
the expression can change from `true` to `false` without invoking a method on
the main contract.

For example, consider the following contract:

```solidity
contract Timestamp {
    uint256 public immutable timestamp;

    constructor() {
        timestamp = block.timestamp;
    }
}
```

The following invariant will be successfully verified, although it is clearly
false:

```cvl
invariant time_is_now(env e)
    timestamp() == e.block.timestamp;
```

The verification is successful because the action that falsifies the invariant
is the passage of time, rather than the invocation of a contract method.

Similarly, an invariant that depends on an external contract can become false
by calling a method on the external contract.  For example:

```solidity
contract SupplyTracker {
    address token;
    uint256 public supply;

    constructor(address _token) {
        token  = _token;
        supply = token.totalSupply();
    }
}
```

As above, an invariant stating that `supply() == token.totalSupply()` would be
verified, but a method on `token` might change the total supply without updating
the `SupplyTracker` contract.  Since the Prover only checks the main contract's
methods for preservation, it will not report that the invariant can be
falsified.

For this reason, invariants that depend on the environment or on the state of
external contracts are a potential source of {term}`unsoundness <unsound>`, and should be
used with care.

```{todo}
There is an additional source of unsoundness that occurs if the invariant
expression reverts in the before state but not in the after state.
```

(preserved)=
Preserved blocks
----------------

Often, the preservation of an invariant depends on another invariant, or on an
external assumption about the system.  These assumptions can be written in
`preserved` blocks.

```{caution}
Adding `require` statements to preserved blocks can be a source of
{term}`unsoundness <unsound>`, since the invariants are only guaranteed to hold if the
requirements are true for every method invocation.
```

Recall that the Prover checks that a method preserves an invariant by first
requiring the invariant (the prestate check), then executing the method, and
then asserting the invariant (the poststate check).  Preserved blocks are
executed after the prestate check but before executing the method.  They
usually consist of `require` or `requireInvariant` statements, although other
commands are also possible.

Preserved blocks are listed after the invariant expression (and after the filter
block, if any), inside a set of curly braces (`{ ... }`).  Each preserved block
consists of the keyword `preserved` followed by an optional method signature, 
an optional `with` declaration, and finally the block of commands to execute.

If a preserved block specifies a method signature, the signature must either be `fallback()` or
match one of the contract methods, and the preserved block only applies when
checking preservation of that contract method.  The `fallback()` preserved block
applies only to the `fallback()` function that should be defined in the contract.
The arguments of the method are in scope within the preserved block.  
If there is no method signature, the preserved is a default block that applies to 
all methods that don't have a specific preserved block, including the `fallback()` method.

The `with` declaration is used to give a name to the {term}`environment` used
while invoking the method.  It can be used to restrict the transactions that are
considered.  For example, the following preserved block rules out
counterexamples where the `msg.sender` is the 0 address:

```cvl
invariant zero_address_has_no_balance()
    balanceOf(0) == 0
    { preserved with (env e) { require e.msg.sender != 0; } }
```

The variables defined as parameters to the invariant are also available in
preserved blocks, which allows restricting the arguments that are considered
when checking that a method preserves an invariant.

````{caution}

A common source of confusion is the difference between `env` parameters
to an invariant and the `env` variables defined by the `with` declaration.
Compare the following to the previous example:

```cvl
invariant zero_address_has_no_balance_v2(env e)
    balanceOf(e, 0) == 0
    { preserved { require e.msg.sender != 0; } }
```

In this example, we require the `msg.sender` argument to `balanceOf` to be
nonzero, but makes no restrictions on the environment for the call to the method
we are checking for preservation.

To see why this is not the desired behavior, consider a `deposit` method that
increases the message sender's balance.  When the
`zero_address_has_no_balance_v2` invariant is checked on `deposit`, the Prover
will report a violation with the `msg.sender` set to 0 in the call to `deposit`
and set to a nonzero value in the calls to `balanceOf`.  This counterexample is
not ruled out by the `preserved` block because the `preserved` block only
places restrictions on the environment passed to `balanceOf`.

````

Filters
-------

For performance reasons, you may want to avoid checking that an invariant is
preserved by a particular method or set of methods.  Invariant filters provide
a method for skipping verification on a method-by-method basis.

```{caution}
Filtering out methods while checking invariants is {term}`unsound`.  If you are
filtering out a method because the invariant doesn't pass, consider using a
`preserved` block instead; this allows you to add assumptions in a fine-grained
way.
```

To filter out methods from an invariant, add a `filtered` block after the
expression defining the invariant.  The body of the `filtered` block must
contain a single filter of the form `var -> expr`, where `var` is a variable
name, and `expr` is a boolean expression that may depend on `var`.

Before verifying that a method `m` preserves an invariant, the `expr` is
evaluated with `var` bound to a `method` object.  This allows `expr` to refer
to the fields of `var`, such as `var.selector` and `var.isView`.  See
{ref}`method-type` for a list of the fields available on `method` objects.

If the expression evaluates to `false` with `var` replaced by a given method,
the Prover will not check that the method preserves the invariant.  For example,
the following invariant will not be checked on the `deposit(uint)`
method:

```cvl
invariant balance_is_0(address a)
    balanceOf(a) == 0
    filtered {
        f -> f.selector != deposit(uint).selector
    }
```

In this example, when the variable `f` is bound to `deposit(uint)`, the
expression `f.selector != deposit(uint).selector` evaluates to `false`, so the
method will be skipped.

```{note}
If there is a {ref}`preserved block <preserved>` for a method it will be
verified even if it should be filtered out.
```


Writing an invariant as a rule
------------------------------

Above we explained that verifying an invariant requires two checks: an initial-state check
that the constructor establishes the invariant, and a preservation check that
each method preserves the invariant.

Invariants are the only mechanism in CVL for specifying properties of
constructors, but {term}`parametric rule`s can be used to write the
preservation check in a different way.  This is useful for two reasons: First,
it can help you understand what the preservation check is doing. Second, it
can help break down a complicated invariant by defining new intermediate
variables.

The following example demonstrates all of the features of invariants:

```cvl
invariant complex_example(env e1, uint arg)
    property_of(e1, arg)
    filtered {
        m -> m.selector != ignored(uint, address).selector
    }
    {
        preserved with (env e2) {
            require e2.msg.sender != 0;
        }
        preserved special_method(address a) with (env e3) {
            require a != 0;
            require e3.block.timestamp > 0;
        }
    }
```

The preservation check for this invariant could be written as a
{term}`parametric rule` as follows:

```cvl
rule complex_example_as_rule(env e1, uint arg, method f)
filtered {
    f -> f.selector != ignored(uint, address).selector
}
{
    // pre-state check
    require property_of(e1, arg);

    if (f.selector == special_method(address).selector) {
        // special_method preserved block
        address a;
        env e3;
        require a != 0;
        require e3.block.timestamp > 0;

        // method execution
        special_method(e3, a);
    } else {
        // general preserved block
        calldataarg args;
        env e2;
        require e2.msg.sender != 0;

        // method execution
        f(e2, args);
    }

    // post-state check
    assert property_of(e1, arg);
}
```

(invariant-induction)=
Invariants and induction
------------------------

This section describes the logical justification for invariant checks.  You do
not need to understand this section to use the Prover correctly, but it helps
explain the connection between the invariant checks and mathematical proofs for
those who are familiar with writing proofs.  This section also justifies the
safety of arbitrary `requireInvariant` statements in `preserved` blocks.

This section assumes familiarity with basic proofs by induction.  We use the
symbols {math}`∀`, {math}`⇒`, and {math}`∧` to stand for "for all", "implies",
and "and" respectively.

Consider an invariant `i(x)` that is verified by the Prover.  For the moment,
let's assume that `i(x)` has no `preserved` blocks. We will prove that for all
reachable states of the contract, `i(x)` is `true`.

A state `s` is reachable if we can start with an uninitialized state (that is,
where all storage variables are 0), apply any constructor, and then call any
number of contract methods to produce `s`.

Let {math}`P_i(x,n)` be the statement "if we start from the uninitialized
state, apply any constructor, and then call {math}`n` contract methods, then
the resulting state satisfies `i(x)`."  Our goal is then to prove
{math}`∀ n, ∀ x, P_i(x,n)`.  We will prove this by induction on {math}`n`.

In the base case we want to show that for any {math}`x`, if we apply any
constructor to the uninitialized contract, that the resulting state satisfies
`i(x)`.  This is exactly what the Prover verifies in the initial state check.
In other words, the initial state check proves that {math}`∀ x, P_i(x,0)`.

For the inductive step, we assume that any {math}`n` contract calls produce a
state that satisfies `i(x)`, and we want to show that a state produced after
{math}`n+1` calls also satisfies `i(x)`.  This is exactly what the Prover
verifies in the preservation check: that if the state before the last method
call satisfies `i(x)` then after the last method call it still satisfies
`i(x)`.  In other words, the preservation check proves that
{math}`∀ n, ∀ x, P_i(x,n) ⇒ P_i(x, n+1)`.

This completes the proof that together, the initial state check and the
preservation check ensure that the invariant `i` holds on all reachable states.

Now, let us consider preserved blocks.  Adding `require` statements to a
`preserved` block for invariant `i` adds an additional assumption `Q` to the
preservation check.  Now, instead of

```{math}
∀ n, ∀ x, P_i(x,n) ⇒ P_i(x, n+1),
```

the preservation check only proves

```{math}
∀ n, ∀ x, P_i(x,n) {\bf ∧ Q} ⇒ P_i(x, n+1).
```

The addition of the assumption {math}`Q` invalidates the above proof if we don't
have reason to believe that {math}`Q` actually holds, which is why we caution
against adding `require` statements to `preserved` blocks.

However, it is important to note that adding `requireInvariant j(y)` to a
`preserved` block is safe (assuming that `j` is verified), even if the
`preserved` block for `j` requires the invariant `i`.  To demonstrate this, we
consider three examples.

For the first example, consider the spec

```cvl
invariant i(uint x) ... { preserved { requireInvariant i(x); } }
```

Although this may seem like circular logic (we require `i` in the proof of
`i`), it is not.  The verification of the preservation check for `i` proves the
statement

```{math}
∀ n, ∀ x, P_i(x, n) ∧ P_i(x, n) ⇒ P_i(x, n+1),
```
which is logically equivalent
to the preservation check without the `preserved` block (since {math}`P_i(x,n) ∧ P_i(x,n)`
is equivalent to just {math}`P_i(x,n)`).

For the second example, consider the following spec:

```cvl
invariant i(uint x) ...  { preserved { requireInvariant j(x); } }

invariant j(uint x) ...  { preserved { requireInvariant i(x); } }
```

Verifying these invariants gives us the preservation check for `i`:

```{math}
∀ n, ∀ x, P_i(x, n) ∧ P_j(x, n) ⇒ P_i(x, n + 1)
```
and for `j`:
```{math}
∀ n, ∀ x, P_j(x, n) ∧ P_i(x, n) ⇒ P_j(x, n + 1)
```

Putting these together allows us to conclude
```{math}
∀ n, ∀ x, P_i(x,n) ∧ P_j(x,n) ⇒ P_i(x,n+1) ∧ P_j(x,n+1)
```
which is exactly what we need for an inductive proof of the statement
{math}`∀ n, ∀ x, P_i(x,n) ∧ P_j(x,n)`.  This statement then shows that both
`i(x)` and `j(x)` are true in all reachable states.

For the third example, consider the following spec:
```cvl
invariant i(uint x) ... { preserved { requireInvariant i(f(x)); } }
```

The preservation check now proves
```{math}
∀ n, ∀ x, P_i(x,n) ∧ P_i(f(x), n) ⇒ P_i(x, n+1).
```

Seeing that this gives us enough to write an inductive proof that
{math}`∀ n, ∀ x, P_i(x,n)` takes a little more effort, but it only requires a
simple trick.  Let {math}`Q(n)` be the statement {math}`∀ x, P_i(x,n)`.  We
prove {math}`∀ n, Q(n)` by induction.

The base case comes directly from the initial state check for `i`.

For the inductive step, choose an arbitrary {math}`n` and assume {math}`Q(n)`.
We want to show {math}`Q(n+1)`, i.e. that {math}`∀ x, P_i(x, n+1)`.  Fix an
arbitrary {math}`x`.  We can apply {math}`Q(n)` to {math}`x` to conclude
{math}`P_i(x,n)`.  We can also apply {math}`Q(n)` to {math}`f(x)` to conclude
{math}`P_i(f(x), n)`.  These facts together with the preservation check show
{math}`P_i(x, n+1)`.  Since {math}`x` was arbitrary, we can conclude
{math}`∀ x, P(x, n+1)`, which is {math}`Q(n+1)`.  This completes the inductive
step, and thus the proof.

The techniques used in these three examples can be used to demonstrate that it
is always logically sound to add a `requireInvariant` to a `preserved` block,
even for complicated interdependent invariants (as long as the required
invariants have been verified).

