Definitions
===========

```{todo}
The documentation for this feature is incomplete.  See [the old documentation](/docs/confluence/anatomy/definitions)
```

Syntax
------

The syntax for definitions is given by the following [EBNF grammar](syntax):

```
definition ::= [ "override" ]
               "definition" id [ "(" params ")" ]
               "returns" cvl_type
               "=" expression ";"
```

See {doc}`types`, {doc}`expr` and {ref}`identifiers` for descriptions of
the `cvl_type`, `expression`, and `id` productions respectively.

