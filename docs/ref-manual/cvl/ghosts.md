(ghost-functions)=
Ghosts
======

```{todo}
This documentation is currently incomplete.  See [ghosts](/docs/confluence/anatomy/ghosts)
and [ghost functions](/docs/confluence/anatomy/ghostfunctions) in the old documentation.

```{contents}
```

Syntax
------

```
ghost ::= "ghost" "(" [ cvl_type { "," cvl_type } ] ")"
          ( ";" | "{" axiom { axiom } "}" )

axiom ::= [ "init_state" ] "axiom" expression ";"
```
