(functions-doc)=
Functions
=========

CVL functions allow you to reuse parts of a specification, such as common assumptions, assertions, 
or basic calculations. Additionally they can be used for basic calculations and  for [function summaries](https://github.com/Certora/Examples/blob/bf3255766c28068eea2d0513edb8daca7bcaa206/CVLByExample/function-summary/multi-contract/certora/specs/spec_with_summary.spec#L6).

Syntax
------

The syntax for CVL functions is given by the following [EBNF grammar](ebnf-syntax):

```
function ::= [ "override" ]
             "function" id
             [ "(" params ")" ]
             [ "returns" type ]
             block
```

See {doc}`basics` for the `id` production, {doc}`types` for the `type` production,
and {doc}`statements` for the `block` production.

Examples
--------

- Function with a return:
    ```cvl
    function abs_value_difference(uint256 x, uint256 y) returns uint256 {
        if (x < y) {
          return y - x;
        } else {
          return x - y;
        }
    }
    ```
  
- [CVL function with no return](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/LiquidityPool/certora/specs/pool.spec#L24)

- [Overriding a function from imported spec](https://github.com/Certora/Examples/blob/be09cf32c55e39f5f5aa8cba1431f9e519b52365/CVLByExample/import/certora/specs/sub.spec#L38)
  
Using CVL functions
-------------------
  CVL Function may be called from within a rule, or from within another CVL function.

