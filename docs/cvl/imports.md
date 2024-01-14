(use)=
Import and Use Statements
=========================

Contents of additional spec files can be imported using the `import` command.
Some parts of the imported spec files are implicitly included in the importing
spec file, while others such as rules and invariants must be explicitly
`use`d. Functions, definitions, filters, and preserved blocks of the imported spec can be overridden by the importing 
spec. If a spec defines a function and uses it (e.g. in a rule or function), and another spec imports it and overrides 
it, uses in the imported spec use the new version.

Examples
--------
- [Example for `import`](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L1)
- [`use rule`](https://github.com/Certora/Examples/blob/61ac29b1128c68aff7e8d1e77bc80bfcbd3528d6/CVLByExample/import/certora/specs/sub.spec#L24)
- [`use rule` with filters](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L3)
- [overriding imported filters](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L3)
- [`use invariant`](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L8)
    - [overriding imported `preserved`](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L10)
    - [adding a `preserved` block](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L14)

Syntax
------

The syntax for `import` and `use` statements is given by the following [EBNF grammar](ebnf-syntax):

```
import ::= "import" string

use ::= "use" "rule" id
        [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
      | "use" "builtin" "rule" id
      | "use" "invariant" id [ "filtered" "{" id "->" expression "}" ] [ "{" { preserved_block } "}" ]

```

See {doc}`basics` for the `string` and `id` productions, {doc}`expr` for the `expression` production, and 
{doc}`invariants` for the `filtered` and `preserved_block` production.

