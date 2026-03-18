(linking)=
`Links` Block
===========

The `links` block allows you to declare contract linking directly in your CVL
specification, replacing the {ref}`--link` and {ref}`--struct_link` conf file
attributes. Each entry in the `links` block tells the Prover that a particular
storage location holding an address should be resolved to a specific contract
instance in the {term}`scene`.

The `links` block supports linking simple scalar fields, struct fields, array
elements, mapping entries, immutable variables, and arbitrary nesting of these.
Entries can target a single contract or a list of possible contracts, and can
use wildcard indices to cover all keys of a mapping or all elements of an array.

```{contents}
```

Syntax
------

The syntax for the `links` block is given by the following [EBNF grammar](ebnf-syntax):

```
links_block   ::= "links" "{" { link_entry } "}"

link_entry    ::= link_path "=>" id ";"
               | link_path "=>" "[" id { "," id } "]" ";"

link_path     ::= id "." id { link_segment }

link_segment  ::= "." id
               | "[" index_expr "]"

index_expr    ::= number
               | "to_bytes" number "(" number ")"
               | id
               | "_"
```

See {ref}`identifiers` for the `id` production, and {doc}`expr` for the
`number` production.

The first `id` in a `link_path` is the contract alias (introduced via a
{ref}`using statement <using-stmt>`), and the second `id` is the name of a
storage variable in that contract.


(basic-linking)=
Basic Linking
-------------

The simplest form of linking maps a storage variable that holds an address to a
contract instance in the scene.  This is equivalent to using the {ref}`--link`
conf file attribute.

Given a contract with a storage variable `token` of type `address` (or a
contract type like `IERC20`):

```solidity
contract Pool {
    IERC20 public token;
}
```

You can link it in your spec:

```cvl
using Pool as pool;
using TokenImpl as tokenImpl;

links {
    pool.token => tokenImpl;
}
```

This is equivalent to passing `--link Pool:token=TokenImpl` on the command line
or in the conf file.


(multi-target-linking)=
Multi-Target Dispatch
---------------------

When a storage location could resolve to one of several contracts, you can
specify a list of possible targets using square brackets:

```cvl
links {
    pool.token => [tokenA, tokenB];
}
```

This tells the Prover that `pool.token` could be the address of either
`tokenA` or `tokenB`, and it will consider both possibilities when resolving
calls through that field.

Multi-target entries are particularly useful when combined with array or mapping
linking.  For example, to verify a contract that holds two tokens which may or
may not be the same:

```cvl
links {
    main.tokens[0] => tokenA;
    main.tokens[1] => [tokenA, tokenB];
}
```

This allows the Prover to explore both the case where both elements point to
the same contract and the case where they point to different contracts.


(struct-linking)=
Struct Field Linking
--------------------

To link an address field inside a struct, use dot notation to navigate into the
struct.  This replaces the {ref}`--struct_link` CLI flag.

```solidity
contract Main {
    struct TokenHolder {
        IERC20 token;
    }
    TokenHolder public holder;
}
```

```cvl
links {
    main.holder.token => tokenImpl;
}
```

This works with arbitrarily nested structs:

```cvl
links {
    main.wrapper.inner.token => tokenImpl;
}
```

Unlike `--struct_link`, the `links` block targets a specific storage variable
and struct path, so there is no risk of accidentally linking the same field name
across unrelated struct types.

```{note}
The `--struct_link` flag matches a field name across all structs in the contract,
including struct values inside mappings and arrays.  For example, if a contract
has `mapping(uint => MyStruct) myMapping` where `MyStruct` has an `address`
field called `token`, then `--struct_link C:token=TokenA` would link the `token`
field in every `MyStruct` value in the mapping.  The equivalent in the `links`
block would be `c.myMapping[_].token => tokenA;`.
```


(array-linking)=
Array Linking
-------------

You can link elements of both static and dynamic arrays using index notation.

### Static arrays

```solidity
contract Main {
    IERC20[3] public fixedTokens;
}
```

```cvl
links {
    main.fixedTokens[0] => tokenA;
    main.fixedTokens[1] => tokenB;
    main.fixedTokens[2] => tokenC;
}
```

### Dynamic arrays

```solidity
contract Main {
    IERC20[] public tokens;
}
```

```cvl
links {
    main.tokens[0] => tokenA;
    main.tokens[1] => tokenB;
}
```

```{note}
For dynamic arrays with concrete index links, the linking is conditional on the
array being long enough.  For example, linking `main.tokens[1] => tokenA`
causes the Prover to assume `tokens.length > 1 => main.tokens[1] == tokenA`.
If the array is shorter than the linked index, no assumption is made about that
element.
```


(mapping-linking)=
Mapping Linking
---------------

You can link entries of mappings by specifying the key in square brackets.

### Numeric keys

```cvl
links {
    main.tokenMap[0] => tokenA;
    main.tokenMap[1] => tokenB;
}
```

### Byte cast keys

For mappings with `bytesN` keys, use the `to_bytesN(...)` cast:

```cvl
links {
    main.bytes4Map[to_bytes4(0x12345678)] => tokenA;
}
```

### Contract alias keys

For mappings with `address` keys, you can use a contract alias as the key:

```cvl
links {
    main.addrMap[tokenA] => tokenC;
}
```

Here, the address of the `tokenA` contract instance is used as the mapping key.


(wildcard-linking)=
Wildcard Indices
----------------

Use `_` as a wildcard index to link all elements of an array or all entries of a
mapping to the same target(s):

```cvl
links {
    main.tokenMap[_] => tokenA;
}
```

This means that for any key, the value of `tokenMap` is linked to `tokenA`.

### Wildcard precedence

When both concrete and wildcard entries exist for the same path, concrete
entries take precedence.  For example:

```cvl
links {
    main.tokens[0] => tokenB;
    main.tokens[_] => tokenA;
}
```

Here, `main.tokens[0]` resolves to `tokenB`, while all other indices resolve to
`tokenA`.

```{caution}
You cannot mix concrete and wildcard indices in the same entry when there are
multiple levels of indexing.  For example, `main.nested[0][_]` is not allowed.
Each entry must use either all concrete indices or all wildcard indices.
```


(nested-linking)=
Nested Structures
-----------------

The `links` block supports arbitrary nesting of structs, arrays, and mappings:

```cvl
links {
    // Array element within a struct
    main.arrayHolder.tokens[0] => tokenC;

    // Struct within an array
    main.structItems[0].token => tokenA;

    // Struct value within a mapping
    main.structMap[0].token => tokenC;
}
```


(immutable-linking)=
Immutable Linking
-----------------

Immutable variables can also be linked:

```cvl
links {
    main.immutableToken => tokenB;
    main.immutableTokenMulti => [tokenA, tokenC];
}
```


(linking-requirements)=
Requirements and Limitations
----------------------------

```{important}
The `links` block requires storage layout information from the Solidity
compiler.  This information is only available for contracts compiled with
**Solidity version 0.5.13 or later**.
```

- Library contracts cannot be linked.
- The `links` block and the {ref}`--link` / {ref}`--struct_link` CLI flags are
  **mutually exclusive** for the same contract.  You cannot use both in the
  same verification run.


(linking-migration)=
Migrating from CLI Flags
-------------------------

If you are currently using `--link` or `--struct_link`, you can migrate to the
`links` block as follows:

| CLI Flag | `links` Block Equivalent |
| --- | --- |
| `--link Pool:token=TokenImpl` | `pool.token => tokenImpl;` |
| `--struct_link Pool:field=TokenImpl` | One entry per storage variable containing a struct with that field, using the full path. For example, `pool.holder.field => tokenImpl;` for a direct struct, or `pool.myMapping[_].field => tokenImpl;` for struct values inside a mapping or array. |

The `links` block provides several advantages over the CLI flags:

- **Type-checked:** The Prover validates that the paths and targets in the
  `links` block are well-typed.
- **Precise struct linking:** Unlike `--struct_link`, which applies to all
  structs with a matching field name, the `links` block targets a specific
  storage path.
- **Richer linking:** Support for arrays, mappings, wildcards, and multi-target
  dispatch that are not available through CLI flags.
