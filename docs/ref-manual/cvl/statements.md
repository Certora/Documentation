Statements
==========

```{todo}
This document is incomplete.  See {doc}`/docs/confluence/anatomy/commands` for
partial information
```

```{contents}
```

Syntax
------

```
statement ::= type id [ "=" expr ] ";"

            | "require" expr ";"
            | "static_require" expr ";"
            | "assert" expr [ "," string ] ";"
            | "static_assert" expr [ "," string ] ";"

            | "requireInvariant" id "(" exprs ")" ";"

            | lhs "=" expr ";"
            | "if" expr statement [ "else" statement ]
            | "{" statements "}"
            | "return" [ expr ] ";"

            | function_call ";"
            | "call" id "(" exprs ")" ";"
            | "invoke_fallback" "(" exprs ")" ";"
            | "invoke_whole" "(" exprs ")" ";"
            | "reset_storage" expr ";"

            | "havoc" id [ "assuming" expr ] ";"

lhs ::= id [ "[" expr "]" ] [ "," lhs ]
```

Variable declarations
---------------------

Unlike undefined variables in most programming languages, undefined variables
in CVL are a centrally important language feature.

```{todo}
This feature is currently undocumented.
```

(require)=
`assert` and `require`
----------------------

```{todo}
This section is incomplete.  See [the old documentation](/docs/confluence/anatomy/commands).
```


Solidity-like statements
------------------------

```{todo}
This feature is currently undocumented.
```

Function calls
--------------

```{todo}
This feature is currently undocumented.  See {ref}`call-expr` for partial information.
```

(havoc-stmt)=
`havoc` statements
------------------

```{todo}
This section is currently incomplete.  See
[ghosts](/docs/confluence/anatomy/ghosts) and {ref}`two-state-old`
for the old documentation.
```

```{todo}
Be sure to document `@old` and `@new` (two-state contexts).  They are not documented in {doc}`expr`
because I think `havoc ... assuming ...` is the only place that they are
available.
```

