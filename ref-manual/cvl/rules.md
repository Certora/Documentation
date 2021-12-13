```
rule     ::= [ "rule" ]
             id
             [ "(" params ")" ]
             [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
             [ "description" string ]
             [ "good_description" string ]
             block
```
