The Methods Block
=================

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

# Overview

The `methods` block contains declarations for contract methods.

There are two kinds of declarations:

* **Non-summary declarations** document the interface between the specification
  and the contracts used during verification.  Non-summary declarations support
  spec reuse by allowing specs written against a complete interface to be
  checked against a contract that only implements part of the interface.

* **Summary declarations** are used to replace _all_ calls to methods with the
  given signature with something that is simpler for the prover to reason about.
  Summaries allow the prover to reason about external contracts whose code is
  unavailable.  They can also be useful to simplify the code being verified to
  circumvent timeouts.

# Non-summary declarations



(envfree)=
## The envfree modifier

# Summary declarations

## Application policies (UNRESOLVED or ALL)

## `ALWAYS`, `CONSTANT`, `PER_CALLEE_CONSTANT`

(havoc-summary)=
## `HAVOC_ALL`, `HAVOC_ECF`

## `DISPATCHER`

## `AUTO`

## expression and block summaries




