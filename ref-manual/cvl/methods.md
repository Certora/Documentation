```
methods          ::= "methods" "{" { method_spec } "}"

method_spec      ::= ( hash | [ id "." ] id "(" params ")" )
                     [ "returns" types ]
                     [ "envfree" ]
                     [ "=>" method_summary [ "UNRESOLVED" | "ALL" ] ]
                     [ ";" ]

types ::= cvl_type { "," cvl_type }
        | "(" [ evm_type [ id ] { "," evm_type [ id ] } ] ")"

method_summary   ::= "ALWAYS" "(" value ")"
                   | "CONSTANT"
                   | "PER_CALLEE_CONSTANT"
                   | "NONDET"
                   | "HAVOC_ECF"
                   | "HAVOC_ALL"
                   | "DISPATCHER" [ "(" bool ")" ]
                   | "AUTO"
                   | [ "with" "(" params ")" ] block
                   | [ "with" "(" params ")" ] expression
```
