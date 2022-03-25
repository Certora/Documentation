(ghost-functions)=
Ghosts
======

```
ghost ::= "ghost" "(" [ cvl_type { "," cvl_type } ] ")"
          ( ";" | "{" axiom { axiom } "}" )

axiom ::= [ "init_state" ] "axiom" expression ";"
```
