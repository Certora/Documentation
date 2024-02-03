CVL2 Migration Guide
====================

This section gives a step-by-step process for migrating your specs from CVL 1 to
CVL 2.  It only addresses the changes that are most likely to arise; for full
details see {doc}`changes`.

Here is an outline of the migration process:

```{contents}
:local:
:depth: 1
```

If you have any questions, please {ref}`ask for help <contact>`!

## Step 0: Install CVL 2

The `certora-cli` python package will use CVL 2 starting with version 4.0.0.

If you aren't ready to migrate your specs yet, Certora will continue supporting
CVL 1 for three months after the official release of CVL 2.  You can keep
using CVL 1 after the release of `certora-cli-4.0.0` by pinning your
`certora-cli` package to version `3.6.5`:

```
pip install 'certora-cli<4.0.0'
```

If you want to switch between the two versions, see the instructions for setting
up a virtual environment in {ref}`beta-install`.

## Step 1: Skim CVL 2 changes

We recommend at least skimming {doc}`changes` to familiarize yourself with the
changes introduced by CVL 2.

## Step 2: Run the migration script

Certora has written a simple script to aid in the conversion from CVL 1 to
CVL 2.  You can download the script [here][script-location].

[script-location]: https://gist.github.com/shellygr/c054a0ad569397ef4e19ec1d1d5afcdb

The script will automatically modify all `.spec` files in a directory.  The
script will modify the files in place, so make sure that you commit your files
before running it.

To run the script, place it in a file called `CVL1_to_CVL2.0_syntax_update.py`
and run it using the following command:

```
python3 CVL1_to_CVL2.0_syntax_update.py -d <path> -r
```

Run `python3 CVL1_to_CVL2.0_syntax_update.py --help` for further instructions.

The migration script only handles simple cases, and is not guaranteed to work.
Some manual work and adjustment may be needed after running the script. The
script may also make odd mistakes.

The script will attempt to make the following changes:
 - replace `sinvoke f(...)` with `f(...)`
 - replace `invoke f(...)` with `f@withrevert(...)`
 - replace `f(...).selector` with `sig:f(...).selector`
 - ensure that rules start with `rule`
 - replace `static_assert` with `assert`
 - replace `static_require` with `require`
 - add `;` to the end of `pragma`, `import`, `using`, and `use` statements
 - add a `;` to the end of a methods block entry if it doesn't seem to continue to the next line
 - add `function` to the beginning of a methods block entry
 - add `external` to unsummarized or `DISPATCHER` methods block entries
 - change `function f(...)` to `function _.f(...)` for summarized external functions

In particular, as the script only consumes spec files, there are decisions that
it cannot make, as they are based on the Solidity code. Some of those are
listed here.

## Step 3: Fix type errors

This is a good time to try running `certoraRun` on your spec.  The command-line
interface to `certoraRun` has not changed in CVL 2, so you should try to verify
your contract the same way you usually would.

If your spec verifies without errors, move on to
{ref}`cvl2-migration-summaries`!  If `certoraRun` reports errors, you will need
to fix them manually.  Here are some of the more common errors that you may
come across:

```{contents}
:local:
:depth: 1
```

This section contains specific advice for these situations; if you come across
problems that are not covered here, consult the {doc}`changes` or ask!

### Syntax errors introduced by the migration script

The migration script is not perfect, and can make syntax mistakes in some
cases, such as adding an extra semicolon or omitting a keyword.  We hope these
will be easy to identify and fix, but if you have syntax errors you can't
understand, consult {ref}`cvl2-superficial-syntax-changes`.

### Type errors in arithmetic and casts

CVL 2 is more careful about converting between different integer types.  See
{ref}`cvl2-integer-types` in the changes guide for complete details and
examples.

If you have errors that indicate problems with number types, try the following:

 - Try to change most of your integers to `mathint`.  The only integers that
   should *not* be `mathint` are those that you are passing as arguments to
   contract functions.

 - If you have a type error in a `havoc ... assuming` statement, consider using
   the {ref}`newer ghost variable syntax <ghost-variables>`.  This can avoid
   potential vacuity pitfalls caused by mixing `to_mathint` and `havoc ...
   assuming`.

 - If you need to compare two different types of integers with with a comparison
   like `==`, `>=`, you probably want to convert them to `mathint` using
   `to_mathint` unless they are part of a `havoc ... assuming` statement or a
   `require` statement.  See {ref}`cvl2-comparisons-identical-types` for an example
   of why you might *not* want to use `to_mathint`.

```{note}
The only place you need `to_mathint` is in comparisons!  It won't hurt in other
places, but it is unnecessary.
```

 - If you need to modify the output of one contract function and pass it to
   another contract function, you will need to think carefully about how you
   want to handle overflow.  If you think the computation won't go out of bounds,
   you can use an `assert_` cast to assert that the value is in bounds.  If you
   want to ignore cases where the value goes out of bounds, you can use a
   `require_` cast (but think twice first: `require_` casts are dangerous!).
   See {ref}`cvl2-integer-types` for more details.

```{warning}
Use `assert_` and `require_` casts sparingly!  `assert_` casts can lead to
unnecessary counterexamples, and `require_` casts can hide bugs in your contracts
(just as any `require` statement can).
```

 - You cannot use `assert_` and `require_` casts inside
   {term}`quantified statements <quantifier>`.
   To solve that issue, you can introduce an additional universally quantified
   variable of type `uint256`, and require it to be equal to the expression using
   an upcast to `mathint`.

   For example, if there is a ghost array access `forall uint x. a[x+1] == 0`,
   rewrite it as follows:

   ```cvl
   forall uint x. forall uint y. to_mathint(y) == x+1 => a[y] == 0
   ```

### `using` statements

Multi-contract declaration using `using` statements are not imported.  If you
have a spec `a.spec` importing `b.spec`, with `b.spec` declaring a
multicontract contract usage, which you need in `a.spec`, repeat the
declaration from `b.spec`, and rename the alias.

_The next minor version of CVL2 will improve this behavior._

### Problems with `certorafallback` or `invoke_fallback`

CVL2 does not allow you to refer to the fallback function explicitly as it was
seldom used and not well-defined. The most common use case for having to refer
to the fallback was to check if a parametric method is the fallback function.
For that, one can use the `.isFallback` field of any variable of type `method`.

See {ref}`cvl2-fallback-changes` for examples.

(cvl2-migration-summaries)=
## Step 4: Review your `methods` blocks

CVL 2 changes the requirements for and meanings of methods block entries; you
should manually review all of your methods block entries to make sure they have
the intended meanings.  Here are the things to consider:

```{contents}
:local:
:depth: 1
```

The remainder of this section describes these considerations.  See
{ref}`cvl2-methods-blocks` for more details.

If you have complex methods blocks, we encourage you to examine the call
resolution tab on the rule report to double-check that your summaries are
applied as you expect them to be.

### `internal` and `external` methods

In CVL 2, you must mark `methods` block entries as either `internal` or
`external`.  Unlike Solidity, you cannot mark entries as `private` or `public`.

The Prover does not distinguish between `private` and `internal` methods; if
you want to summarize a `private` method, use `internal` in the `methods` block.

To understand how to work with public Solidity methods, it is important to
understand how Solidity compiles public functions.  When a contract contains a
public method, the Solidity compiler generates an internal method that executes
the code, and an external method that calls the internal method.

You can add methods block entries for either (or both) of those methods, and
they will have different effects.  See {ref}`cvl2-visibility` for the details.

### Receiver contracts

In CVL 1, method summaries applied to all methods in all contracts that match
the specified signature.  In CVL 2, summaries only apply to one contract by
default.

You specify the receiver contract just before the method name.  For example, to
refer to the `exampleMethod` method of the `ExampleContract` contract, you would
write:

```cvl
methods {
    function ExampleContract.exampleMethod(uint) external returns(uint);
}
```

If no contract is specified, the default contract is `currentContract`.

If you want to write an entry that applies to methods in all contracts with the
given signature, you can use the special `_` receiver:

```cvl
methods {
    function _.exampleMethod(uint) external => NONDET;
}
```

Wildcard entries cannot specify return types.  If you summarize them with a CVL
function or ghost, you will need to supply an `expect` clause.  See
{ref}`cvl2-wildcards` for details.

## Step 5: Profit!

Hopefully this guide has helped you successfully migrate to CVL 2.  Although
the functional changes in CVL 2.0 are relatively small, the internal changes
lay the groundwork for many exciting features.  We promise that the effort
involved in migration will pay off in the next few releases!

