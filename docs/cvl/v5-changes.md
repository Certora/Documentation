Certora CLI 5.0 Changes
=======================

The release of `certora-cli` version 5.0 introduces a few small breaking
changes for CVL.  These changes improve the coverage for parametric rules and
invariants, disallow Solidity function calls in quantified expressions,
and simplify some rarely-used features.  This document explains those changes
and how to work with them.

```{note}
`certora-cli` 5.0 also includes several new features, bug fixes, and
performance improvements that are not discussed here; see {ref}`prover-release-notes`
for more details.
```

```{contents}
```

Exhaustive parametric rules
---------------------------

Starting with `certora-cli` version 5.0, {term}`parametric rule`s and
{term}`invariant`s will now be checked on the methods of all contracts by
default, instead of just the primary contract.

This change improves the coverage of rules and can catch important errors.  For
example, an invariant that relates a contract's total supply to its balance in
an underlying token contract could be invalidated by calling methods directly on
the underlying token; before this change those violations would not have been
detected.

This change can break existing specifications in a few ways:

 - A property that should hold cannot be verified.

 - A parametric rule that was never intended to apply to secondary contracts
   may be violated by methods of those contracts.

 - Verification may time out on methods of secondary contracts.

The remainder of this section describes how to address these three failure
modes.

```{contents}
:local:
```

### Fixing properties that should hold

Most parametric rules and all invariants encode general properties of a system
that should be impossible for any contract to violate.  For example, consider a
"solvency" invariant that shows that a vault contract holds enough underlying
tokens to cover any withdrawals:

```cvl
invariant solvency()
    underlying.balanceOf(currentContract) >= currentContract.totalSupply();
```

Any violation of this property would be an important security vulnerability,
regardless of whether it is violated by a method of the vault or a method of
the underlying token.  Therefore, it is important to check that no method of
any contract can violate these kinds of properties.  However, sometimes
verifying these kinds of properties on methods of secondary contracts will
require additional work.

Continuing the solvency example, the Prover is likely to find a violation of
the solvency rule in `underlying.transferFrom` where the vault contract has
given an allowance to a third party.  If a third party has an allowance, it
will be able to reduce the vault's balance by transferring the vault's tokens
to itself.

This violation represents an important vulnerability: if the vault mismanages
its allowances, then it may become insolvent.  This violation shows that the
solvency of the vault depends on the correct management of its underlying
allowances.

Therefore, to get the rule to pass, we will need to add another invariant
stating that the vault manages its allowances correctly:

```cvl
invariant no_vault_allowance()
    underlying.allowance(currentContract) == 0;
```

We can then use this invariant in the `preserved` block for the original
solvency rule.  We are also likely to get violations from the case that the
vault contract itself calls methods on the underlying contract, so we rule that
out as well[^call-note]:

[^call-note]: Adding this restriction does not ignore any actual contract
  behaviors. If the vault does call methods on the underlying contract, it will
  only do so from its code, and that call will be analyzed while the Prover is
  verifying the calling method.  The additional requirement only rules out
  spurious counterexamples where the vault makes calls to the underlying token
  without having code that does so.

```cvl
invariant solvency()
    underlying.balanceOf(currentContract) >= currentContract.totalSupply()
    {
        preserved with (env e) {
            require e.msg.sender != currentContract;
            requireInvariant no_vault_allowance();
        }
    }
```

There is nothing new about this process of identifying violations and adding
new invariants as necessary; it is the same process you would use for analyzing
any violation.  This example just shows that some work may be required when
verifying old specifications with `certora-cli` 5.0.

The benefit is that by checking methods on secondary contracts, the Prover
forces us to consider a previously unstated assumptions about the contract and
write invariants that could detect important security vulnerabilities.  For
this reason, you are encouraged to identify and prove additional invariants
to address counterexamples instead of using the filtering techniques described
in the following sections.

### Filtering properties that should not be checked

Some parametric rules encode properties that are only expected to hold on a
specific contract.  For example, you might have a rule that ensures that every
successful method invocation is correctly authorized:

```cvl
rule authorization_check(method f)
filtered { f -> f.isView }
{
    env e; calldataarg args;

    f(e,args);

    assert is_authorized(e.msg.sender, f.selector);
}
```

There is no reason to expect this property to hold on any contract besides the
main contract.

To handle cases like these, `certora-cli` 5.0 introduces two new ways to filter
methods to a specific contract.

The first and simplest way to restrict verification to a specific contract is
to call the `method` object with a specific receiver contract:

```{code-block} cvl
:emphasize-lines: 6

rule authorization_check(method f)
filtered { f -> f.isView }
{
    env e; calldataarg args;

    currentContract.f(e,args);

    assert is_authorized(e.msg.sender, f.selector);
}
```

This syntax will add a filter that will only instantiate `f` with the methods
of `currentContract`.  The receiver may be either `currentContract` or a
variable introduced by a `using` clause.

The second and more flexible way is to use the new `contract` property of the
`method` variable:
```{code-block} cvl
:emphasize-lines: 2

rule authorization_check(method f)
filtered { f -> f.isView && f.contract == currentContract }
{
    env e; calldataarg args;

    f(e,args);

    assert is_authorized(e.msg.sender, f.selector);
}
```

If `f` is a `method` variable, `f.contract` refers to the contract that contains
the method `f`.

(v5-contract-option)=
### Focusing on specific contracts

If you want to focus verification on a specific contract, you can do so using
the {ref}`--parametric_contracts` option.  This option takes a list of contracts and only
instantiates parametric rules and invariants on methods of those contracts.

You can use this option to help transition specs to `certora-cli` 5.0; if `C`
is the main contract being verified, then passing `--parametric_contracts C` will cause
method variables to be instantiated in the same way the would have in older
versions.

Disallow calls to contract functions in quantified expressions
--------------------------------------------------------------

Starting with `certora-cli` version 5.0, the Prover no longer supports
making contract method calls in quantified expression bodies by
default.

For example, given the simple contract below, you can no longer
use the `method` `getI()` in a quantified expression body.

```{code-block} solidity
contract example {

   uint i; 
    
   function getI() public view returns (uint256) {
       return i;
   }
}
```

```{code-block} cvl
:emphasize-lines: 4

rule there_exists {
    // Using getI() in the quantified body will now cause the Prover to
    // generate a type-checking error.
    require (exists uint256 i . i == getI());
    assert false, "Prover will generate an error before this line";
}
```

In the example rule `there_exists`, the Prover will now generate an error similar
to the following:

```text
Error in spec file (test2.spec:8:36): Contract function calls such as getI()
are disallowed inside quantified formulas.
```

In most simple cases, you can replace contract method calls with either a
{ref}direct storage access <...> or a {ref}ghost <ghosts>. For example the
above function `getI` simply returns the storage variable `i` and you can
change the `require` statement in the `there_exists` rule to use storage access:
`require (exists uint i . i == currentContract.i)`. To use a ghost, declare
the ghost and the hook that populates the ghost with the current value of
the contract variable `i`.

```{code-block} cvl
ghost uint gI;

hook Sstore i uint256 v {
    gI = v;
}
```

Finally, replace `getI` in the `require` statement in rule `there_exists` with the
ghost variable `gI`: `require (exists uint i . i == gI)`.

If you must use contract method calls in quantified expressions,
you can still access the old behavior by specifying the
{ref}`--allow_solidity_calls_in_quantifiers` argument to `certoraRun` on the 
command line.


Method variable restrictions
----------------------------

Starting with `certora-cli` version 5.0, you cannot declare new {ref}`method
variables <method-type>` anywhere except the top-level body of a rule.
Declaring new `method` variables inside of `if` statements, hook bodies, CVL
function bodies, preserved blocks, and all other contexts are all disallowed.

You can still pass `method`-type variables as arguments to CVL functions and
definitions.  You can use this feature to rewrite CVL functions that formerly
declared new `method` variables.

For example, before `certora-cli` 5.0, the following CVL function was valid:

```cvl
function call_arbitrary() {
    method f; env e; calldataarg args;
    f(e, args);
}

rule r {
    call_arbitrary();
    assert true;
}
```

The declaration of `f` inside of `call_arbitrary` is now disallowed, so `f` must
be passed into `call_arbitrary` instead of declared within it:

```cvl
function call_arbitrary(method f) {
    env e; calldataarg args;
    f(e,args);
}

rule r {
    method f;
    call_arbitrary(f);
    assert true;
}
```
New `DELETE` summary syntax
---------------------------

The syntax of the {ref}``new `DELETE` keyword <delete-summary>`` in summaries
has changed.  Prior to `certora-cli` 5.0, it was possible to call methods
summarized with `DELETE` summaries from spec, and the user had to annotate the
`DELETE` modifier to indicate how those calls should be treated.

Starting with `certora-cli` 5.0, calling methods that have been summarized with
a `DELETE` summary is disallowed, and the `DELETE` annotation requires no
additional annotation.

CLI changes: New Parametric Contracts Attribute
-----------------------------------------------

As mentioned above the attribute `parametric_contracts` was added to `certora-cli` 5.0. 
The attribute accepts the parametric contracts as a list of strings. 
The attribute can be set as the CLI flag `--parametric_contracts` or in a `.conf` file.

**Example**
CLI:

`certoraRun C1.sol C2.sol C3.sol --parametric_contracts C1 C3 ...`

Configuration file:

`"files": [ "C1", "C2", "C3"],
"parametric_contracts": [ "C1", "C3"],
...`

CLI changes: End of CVL1 Deprecation period
-------------------------------------------

With the release of `certora-cli` version 5.0, we stop supporting
the CVL1 attributes that were deprecated during the transition to CVL2. 
You can find the list of the deprecated attributes [here](https://docs.certora.com/en/latest/docs/cvl/cvl2/changes.html?highlight=cvl2#changes-to-the-command-line-interface-cli).
