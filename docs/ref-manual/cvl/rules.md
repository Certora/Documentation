Rules
=====

Rules (along with {doc}`invariants`) are the main entry points for the Prover.

```{contents}
```

Syntax
------

The syntax for rules is given by the following [EBNF grammar](syntax):

```
rule ::= [ "rule" ]
         id
         [ "(" [ params ] ")" ]
         [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
         [ "description" string ]
         [ "good_description" string ]
         block

params ::= cvl_type [ id ] { "," cvl_type [ id ] }

```

See {doc}`basics` for the `id` and `string` productions; see {doc}`expr` for the `expression`
production; see {doc}`types` for the `cvl_type` production.


Overview
--------

```{todo}
This documentation is incomplete.  See {doc}`/docs/user-guide/bank/index` for an
overview of rules in CVL.
```


Filters
-------

```{todo}
This feature is currently undocumented.
```

Rule descriptions
-----------------

```{todo}
This feature is currently undocumented.
```

