Invariants
==========

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
