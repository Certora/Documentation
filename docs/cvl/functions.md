Functions
=========

A CVL function provides basic encapsulation for code reuse in a specification.

Syntax
------

The syntax for CVL functions is given by the following [EBNF grammar](syntax):

```
function ::= [ "override" ]
             "function" id
             [ "(" params ")" ]
             [ "returns" type ]
             block
```

See {doc}`basics` for the `id` production, {doc}`types` for the `type` production,
and {doc}`statements` for the `block` production.

```{todo}
This documentation is incomplete.  See [the old documentation](/docs/confluence/anatomy/functions).
```

