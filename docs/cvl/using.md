(using-stmt)=
Using Statements
================

The `using` statement introduces a variable that can be used to call methods on
contracts other than the main contract being verified.

Examples
--------
[Accessing  additional contracts from CVL](https://github.com/Certora/Documentation/blob/2a86333702f3986776f4d462380a8098062e6baf/docs/user-guide/multicontract/index.md?plain=1#L228)
[An example for `using`](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/LiquidityPool/certora/specs/pool_link.spec#L14)

Syntax
------

The syntax for `using` statements is given by the following [EBNF grammar](syntax):

```
using ::= "using" id "as" id
```

See {ref}`identifiers` for the `id` production.



