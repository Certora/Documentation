(using-stmt)=
Using Statements
================

The `using` statement introduces a variable that can be used to call methods on
contracts other than the main contract being verified.

```{contents}

```

Examples
--------
- {ref}`using-example`
- [An example for `using`](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/LiquidityPool/certora/specs/pool_link.spec#L14)

Syntax
------

The syntax for `using` statements is given by the following [EBNF grammar](ebnf-syntax):

```
using ::= "using" id "as" id
```

See {ref}`identifiers` for the `id` production.



