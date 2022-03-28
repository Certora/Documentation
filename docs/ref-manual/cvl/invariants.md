Invariants
==========

Invariants describe a property of the state of a contract that is always
expected to hold.

```
invariant ::= "invariant" id
              [ "(" params ")" ]
              expression
              [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
              [ "{" { preserved_block } "}" ]

preserved_block ::= "preserved"
                    [ method_signature ]
                    [ "with" "(" params ")" ]
                    block

```

Overview
--------

```{todo}
This section is incomplete.  See [the user guide](/docs/user-guide/bank/index)
for an overview of invariants.
```

Filters
-------

```{todo}
This feature is currently undocumented.
```

Preserved blocks
----------------

```{todo}
This feature is currently undocumented.
```

How invariants are checked
--------------------------

```{todo}
This section is currently undocumented.
```

