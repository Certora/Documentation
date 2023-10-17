(use)=
Import and Use Statements
=========================

Contents of additional spec files can be imported using the `import` command.
Some parts of the imported spec files are implicitly included in the importing
spec file, while others such as rules and invariants must be explicitly
`use`d. Functions, definitions, filters and preserved blocks of the imported spec can be overriden by the importing 
spec.

```{todo}
This feature is currently undocumented.
```

Examples
--------
- [Example for `import`](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L1)
- [`use rule` with filters](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L3)
- [overriding imported filters](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L3)
- [`use invariant`](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L8)
    - [overriding imported `preserved`](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L10)
    - [adding a `preserved` block](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L14)
- [`use builtin` rule](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/ReadOnlyReentrancy/certora/spec/ReadOnlyReentrancy.spec#L1)


Syntax
------

The syntax for `import` and `use` statements is given by the following [EBNF grammar](syntax):

```
import ::= "import" string

use ::= "use" "rule" id
        [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
      | "use" "builtin" "rule" id
      | "use" "invariant" id [ "{" { preserved_block } "}" ]

```

See [`basics`](https://github.com/Certora/Documentation/blob/master/docs/cvl/basics.md) for the `string` and `id` 
productions, [`expr`](https://github.com/Certora/Documentation/blob/master/docs/cvl/expr.md) for the
`expression` production, and [`invariants`](https://github.com/Certora/Documentation/blob/26ebc45781d4f07258b64083b9a76d5497b56824/docs/cvl/invariants.md?plain=1#L140)
for the `preserved_block` production.

