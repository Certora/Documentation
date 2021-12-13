```
cvl_type ::= "mathint" | "calldataarg" | "storage" | "env" | "method"
           | id
           | basic_type { "[" [ number ] "]" }

evm_type ::= ( basic_type
             | "(" evm_type { "," evm_type } ")"
             )
             { "[" [ number ] "]" }
```
