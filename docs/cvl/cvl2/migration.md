Migration guide
===============

This section gives a step-by-step process for migrating your specs from CVL 1 to
CVL 2.

### Method declarations

- for `public` functions, the method can be summarized either externally or internally. Annotate visibility of `external` or `internal`, and if you need both, repeat the declaration in the `methods` block.

### Arithmetic and casts

```{todo}
This is incomplete
```

### `using` statements

Multi-contract declaration using `using` statements are not imported.
If you have a spec `a.spec` importing `b.spec`, with `b.spec` declaring a multicontract contract usage, which you need in `a.spec`, repeat the declaration from `b.spec`.


```{todo}
This is incomplete
```
