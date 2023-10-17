Functions
=========

A CVL function provides basic encapsulation for code reuse in a specification. If there is a common set of assumptions 
or assertions used in several rules, a CVL Function would be an apt place to group those together. 
Additionally they can be used for basic calculations. CVL function can be used for function summarization as well.

Syntax
------

The syntax for CVL functions is given by the following EBNF grammar:

```
function ::= [ "override" ]
             "function" id
             [ "(" params ")" ]
             [ "returns" type ]
             block
```

See {doc}`basics` for the `id` production, {doc}`types` for the `type` production,
and {doc}`statements` for the `block` production.

```{todo}
This documentation is incomplete.  See [the old documentation](/docs/confluence/anatomy/functions).
```

Examples
--------
- [CVL function with no return](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/LiquidityPool/certora/specs/pool.spec#L24)

- Function with a return:
    `function` abs_value_difference(uint256 x, uint256 y) returns uint256 {
        if (x < y) {
          return y - x;
        } else {
          return x - y;
        }
    }
- [overriding a function from imported spec](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L38)
  
Using a CVL Function
--------------------
  CVL Function may be called from within a rule, or from within another CVL Function.

