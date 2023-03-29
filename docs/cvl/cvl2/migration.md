Migration guide
===============

This section gives a step-by-step process for migrating your specs from CVL 1 to
CVL 2.

### Migration script
You can find the migration script at TODO.
You can run it on a directory containing spec files as follows:
```
python3 CVL1_to_CVL2.0_syntax_update.py -d . -r
```

Run `python3 CVL1_to_CVL2.0_syntax_update.py --help` for further instructions.

Note that the migration script only helps deal with common use-cases where the migration is straight-forward. Some manual work and adjustment may be needed after running the script. The script may also make odd mistakes. 

In particular, as the script only consumes spec files, there are decisions that it cannot do, as they are based on the Solidity code. Some of those are listed here.

### Method declarations

- for `public` functions, the method can be summarized either externally or internally. Annotate visibility of `external` or `internal`, and if you need both, repeat the declaration in the `methods` block.

### Arithmetic and casts

See <changes> section.

```{todo}
This is incomplete
```

### `using` statements

Multi-contract declaration using `using` statements are not imported.
If you have a spec `a.spec` importing `b.spec`, with `b.spec` declaring a multicontract contract usage, which you need in `a.spec`, repeat the declaration from `b.spec`, and rename the alias.

_The next minor version of CVL2 will improve this behavior._


### Checked-cast operations within quantifiers

If you downcast a `mathint` to a `uint256` within a quantifier context, you cannot use the usual `require_uint256` and `assert_uint256` that you can use outside of the quantifier context.

To solve that issue, you can introduce an additional universally quantified variable of type `uint256`, and require it to be equal to the expression using an upcast to mathint.

For example, if there is a ghost array access `forall uint x. a[x+1] == 0`, rewrite it as follows:

```cvl
forall uint x. forall uint y. to_mathint(y) == x+1 => a[y] == 0
```

### Use f.isFallback instead of comparing to `certorafallback().selector`

CVL2 does not allow you to refer to the fallback function explicitly as it was seldom used and not well-defined. The most common use case for having to refer to the fallback was to check if a parametric method is the fallback function.
For that, one can use `.isFallback` field of any variable of type `method`.

### External summaries require wildcard receivers

A new requirement is for external methods that are summarized to be denoted with a wildcard receiver, i.e. `_`.

Instead of:
```cvl
using OtherContract as other;
methods {
    myFunc(uint) external returns (uint256) => NONDET
    other.otherFunc() external returns (uint256) => CONST
}
```

One should write:
```cvl
methods {
    _.myFunc(uint) external returns (uint256) => NONDET
    _.otherFunc() external returns (uint256) => CONST
}
```

As it does not make sense to specify a summary for a known call to the current contract (e.g. to `myFunc`) or a known call to `other` (e.g. to `otherFunc`)

(TODO: SG: I'm not sure this makes 100% sense, but maybe I miss something: what if we want to summarize forcibly `myFunc` for external calls to the current contract, but not to other contracts?)

```{todo}
This is incomplete
```

