Migration guide
===============

This section gives a step-by-step process for migrating your specs from CVL 1 to
CVL 2.

### Migration script
You can find the migration script at TODO.
You can run it on a directory containing spec files as follows:
```
todo
```

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



```{todo}
This is incomplete
```
