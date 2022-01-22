CVL Functions
=============

A CVL Function provides basic encapsulation for code reuse in a specification. If there is a common set of assumptions or assertions used in several rules, a CVL Function would be an apt place to group those together. Additionally they can be used for basic calculations.

## Syntax

Function with no return:

```cvl
function my_function(address a, uint256 n) {
  require isValidAddress(a);
  require balance(a) >= n;
}
```

Function with a return:

```cvl
function abs_value_difference(uint256 x, uint256 y) returns uint256 {
  if (x < y) {
    return y - x;
  } else {
    return x - y;
  }
}
```

## Using a CVL Function

CVL Function may be called from within a **rule**, or from within another **CVL Function**.
