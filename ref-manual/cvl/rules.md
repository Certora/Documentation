```
rule     ::= [ "rule" ]
             id
             [ "(" [ params ] ")" ]
             [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
             [ "description" string ]
             [ "good_description" string ]
             block

params ::= cvl_type [ id ] { "," cvl_type [ id ] }

```

TODO: move params somewhere more general
