Rules
=====

Rules (along with {doc}`invariants`) are the main entry points for the Prover.

```{contents}
```

Syntax
------

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

Overview
--------

```{todo}
This documentation is incomplete.  See {doc}`/docs/user-guide/bank/index` for an
overview of rules in CVL.
```

How rules are verified
----------------------

```{todo}
This feature is undocumented.
```

(parametric-rules)=
Parametric rules
----------------

```{todo}
This documentation is incomplete.  See {doc}`/docs/user-guide/bank/index`.
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

