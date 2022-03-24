Expressions
===========

```{todo}
This page is incomplete.  For information on mathematical operations, see
{doc}`mathops`.  For information on some of the built-in keywords and operators,
see {doc}`/docs/confluence/anatomy/keywords` and
{doc}`/docs/confluence/anatomy/commands`.  Some of the special fields are described
in {doc}`types`, and some of the special syntax for calling methods and accessing
ghosts are described in {doc}`/docs/confluence/advanced/index`.
```

```
expr ::= literal
       | unop expr
       | expr binop expr
       | "(" exprs ")"
       | expr "?" expr ":" expr
       | [ "forall" | "exists" ] type id "." expr

       | expr "." id
       | id [ "@" "old" | "@" "new" ] [ "[" expr "]" { "[" expr "]" } ]

       | [ "invoke" | "sinvoke" ] [ id "." ] id [ "(" exprs ")" ] [ "@" id ]
       | [ id "." ] id
         [ "@" ( "old" | "new" | "norevert" | withrevert" | "dontsummarize" ]
         "(" exprs ")"
         [ "@" id ]

       | id "(" types ")" "." signature_field
       | expr "in" id


literal ::= "true" | "false" | number | string

unop  ::= "~" | "!" | "-"

binop ::= "+" | "-" | "*" | "/" | "%" | "^"
        | ">" | "<" | "==" | "!=" | ">=" | "<="
        | "&" | "|" | "xor" | "<<" | ">>" | ">>>"
        | "&&" | "||"
        | "=>" | "<=>"

specials_fields ::=
           | "block" [ ".coinbase" | ".difficulty" | ".gaslimit" | ".number" | ".timestamp" ]
           | "msg"   [ ".data" | ".sender" | ".sig" | ".value" ]
           | "tx"    [ ".gasprice" | ".origin" ]
           | "length"

special_vars ::=
           | "lastReverted" | "lastHasThrown"
           | "lastStorage"
           | "allContracts"
           | "lastMsgSig"
           | "_"
           | "max_uint" | "max_address" | "max_uint8" | ... | "max_uint256"

special_functions ::=
           | "to_uint256" | "to_int256" | "to_mathint"

signature_field ::=
           | "selector" | "isPure" | "isView" | "numberOfArguments" | "isFallback"
```


