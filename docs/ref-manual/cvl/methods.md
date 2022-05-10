The Methods Block
=================

The `methods` block contains declarations for contract methods.

There are two kinds of declarations:

* **Non-summary declarations** document the interface between the specification
  and the contracts used during verification.  Non-summary declarations support
  spec reuse by allowing specs written against a complete interface to be
  checked against a contract that only implements part of the interface.

* **Summary declarations** are used to replace _all_ calls to methods having the
  given signature with something that is simpler for the Prover to reason about.
  Summaries allow the Prover to reason about external contracts whose code is
  unavailable.  They can also be useful to simplify the code being verified to
  circumvent timeouts.

```{contents}
```

Syntax
------

The syntax for the `methods` block is given by the following [EBNF grammar](syntax):

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
                   | "DISPATCHER" [ "(" ( "true" | "false" ) ")" ]
                   | "AUTO"
                   | [ "with" "(" cvl_params ")" ] block
                   | [ "with" "(" cvl_params ")" ] expression

cvl_param ::= cvl_type [ id ]

```

See {doc}`types` for the `evm_type` and `cvl_type` productions.  See {doc}`basics`
for the `id` production.  See {doc}`statements` for the `block` production, and
{doc}`expr` for the `expression` production.

```{todo}
This document is incomplete.  See {doc}`/docs/confluence/advanced/methods-overview`,
{doc}`/docs/confluence/advanced/summaries`, {doc}`/docs/confluence/advanced/internal-summaries`,
and {doc}`/docs/confluence/advanced/expressive-summaries` for the old documentation
about the methods block.
```

## Non-summary declarations

(envfree)=
### The envfree modifier

(summaries)=
## Summary declarations

### Application policies (UNRESOLVED or ALL)

### `ALWAYS`, `CONSTANT`, `PER_CALLEE_CONSTANT`

(havoc-summary)=
### `HAVOC_ALL`, `HAVOC_ECF`

### `DISPATCHER`

### `AUTO`

### expression and block summaries



