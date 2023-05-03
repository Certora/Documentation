(use)=
Import and Use Statements
=========================

Contents of additional spec files can be imported using the `import` command.
Some parts of the imported spec files are implicitly included in the importing
spec file, while others such as rules and invariants must be explicitly
`use`d.

```{todo}
This feature is currently undocumented.
```

Syntax
------

```{versionadded} 2.0
These statements now require a semicolon after them. See {ref}`new-semicolons`.
```
The syntax for `import` and `use` statements is given by the following [EBNF grammar](syntax):

```
import ::= "import" string

use ::= "use" "rule" id
        [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
      | "use" "builtin" "rule" id
      | "use" "invariant" id [ "{" { preserved_block } "}" ]

```

See {doc}`basics` for the `string` and `id` productions, {doc}`expr` for the
`expression` production, and {doc}`invariants` for the `preserved_block` production.

