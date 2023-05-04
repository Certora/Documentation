(using-stmt)=
Using statements
================

The `using` statement introduces a variable that can be used to call methods on
contracts other than the main contract being verified.

```{todo}
The documentation for this feature is incomplete.  See
[the old documentation](/docs/confluence/advanced/multicontract)
for more information.
```

```{contents}
```

Syntax
------

The syntax for `using` statements is given by the following [EBNF grammar](syntax):
```{versionchanged} 2.0
Using statements now terminate with a {ref}`semicolon <new-semicolons>`.
```
```
using ::= "using" id "as" id
```

See {ref}`identifiers` for the `id` production.

