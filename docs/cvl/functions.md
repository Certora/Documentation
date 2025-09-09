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

Math and rounding summaries
---------------------------

In real protocols, arithmetic often requires precise rounding envelopes. CVL functions are a clean way to centralize these rules as small, composable summaries.

- Round‑aware mulDiv abstraction with explicit direction:

  ```cvl
  // Rounds up or down depending on a Math.Rounding enum
  function mulDivCVL(uint256 x, uint256 y, uint256 denominator, Math.Rounding rounding) returns uint256 {
      if (rounding == Math.Rounding.Floor) {
          return mulDivDownAbstractPlus(x, y, denominator);
      } else {
          return mulDivUpAbstractPlus(x, y, denominator);
      }
  }
  ```

- Tight, solver‑friendly models for up/down mulDiv used across specs:

  ```cvl
  function mulDivDownAbstractPlus(uint256 x, uint256 y, uint256 z) returns uint256 {
      uint256 res;
      require z != 0;
      uint256 xy = require_uint256(x * y);
      uint256 fz = require_uint256(res * z);
      require xy >= fz;
      require fz + z > to_mathint(xy);
      return res;
  }

  function mulDivUpAbstractPlus(uint256 x, uint256 y, uint256 z) returns uint256 {
      uint256 res;
      require z != 0;
      uint256 xy = require_uint256(x * y);
      uint256 fz = require_uint256(res * z);
      require xy >= fz;
      require fz + z > to_mathint(xy);
      if (xy == fz) { return res; }
      return require_uint256(res + 1);
  }
  ```

- Convenience wrappers for fixed‑point WAD arithmetic:

  ```cvl
  definition ONE18() returns uint256 = 1000000000000000000;
  function mulDownWad(uint256 x, uint256 y) returns uint256 { return mulDivDownAbstractPlus(x, y, ONE18()); }
  function mulUpWad(uint256 x, uint256 y)   returns uint256 { return mulDivUpAbstractPlus(x, y, ONE18()); }
  function divDownWad(uint256 x, uint256 y) returns uint256 { return mulDivDownAbstractPlus(x, ONE18(), y); }
  function divUpWad(uint256 x, uint256 y)   returns uint256 { return mulDivUpAbstractPlus(x, ONE18(), y); }
  ```

- Discrete ratio/quotient variants can drastically reduce search space by constraining common cases (e.g., 2x, 5x, 100x), while still allowing exact cases to pass through:

  ```cvl
  function discreteQuotientMulDiv(uint256 x, uint256 y, uint256 z) returns uint256 {
      uint256 res;
      require z != 0 && noOverFlowMul(x, y);
      require(
          ((x == 0 || y == 0) && res == 0) ||
          (x == z && res == y) ||
          (y == z && res == x) ||
          constQuotient(x, y, z, 2, res)   || // 1/2 or 2
          constQuotient(x, y, z, 5, res)   || // 1/5 or 5
          constQuotient(x, y, z, 100, res)    // 1/100 or 100
      );
      return res;
  }
  ```

```{warning}
Ghost‑based math models can be powerful but require care. For example, a ghost power function `_ghostPow` with axioms like `x^0==1`, monotonicity, and bounds is useful for reasoning, but equality‑like axioms may be invalid under fixed‑point rounding. Keep axioms conservative and prefer inequality bounds.
```
