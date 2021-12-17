```
methods          ::= "methods" "{" { method_spec } "}"

method_spec      ::= ( hash | [ id "." ] id "(" evm_params ")" )
                     [ "returns" types ]
                     [ "envfree" ]
                     [ "=>" method_summary [ "UNRESOLVED" | "ALL" ] ]
                     [ ";" ]

evm_param ::= evm_type [ id ]

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
                   | [ "with" "(" cvl_params ")" ] block
                   | [ "with" "(" cvl_params ")" ] expression

cvl_param ::= cvl_type [ id ]

```
