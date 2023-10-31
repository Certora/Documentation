Definitions
===========

Definitions are declared at the top-level of a specification and are in scope inside every rule, function and inside other definitions.

A definition binds parameters for use in an arbitrary expression on the right-hand side, which should evaluate to a value of the declared return type.

Examples
--------

The following [example](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/base.spec#L22) 
introduces a definition called `filterDef` which takes a method argument `m` and produces a `bool`:

```cvl
definition filterDef(method f) returns bool = f.selector == sig:someUInt().selector;
```

This definition can then be used as shorthand for `f.selector == sig:someUInt().selector`. 
For example, in this spec it is [used in the filter](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/base.spec#L28)
for `parametricRule`:

```cvl
rule parametricRuleInBase(method f) filtered { f -> filterDef(f)  }
{
...
}
```
This is equivalent to

```cvl
rule parametricRuleInBase(method f) filtered { f -> f.selector == sig:someUInt().selector  } {
...
}
```

Syntax
------

The syntax for definitions is given by the following [EBNF grammar](syntax):

```
definition ::= [ "override" ]
               "definition" id [ "(" params ")" ]
               "returns" cvl_type
               "=" expression ";"
```

See {doc}`types`, {doc}`expr` and {ref}`identifiers` for descriptions of
the `cvl_type`, `expression`, and `id` productions respectively.

