# Uninterpreted Sorts

CVL specifications support both Solidity primitives (`uint256`, `address`, etc.) and custom types (e.g., `mathint`). Solidity types are _interpreted_, meaning they have specific semantics, such as arithmetic or comparison operations. However, in some cases, it is beneficial to use _uninterpreted sorts_, which do not carry the semantics associated with interpretation.

## Syntax for Uninterpreted Sorts

To declare an uninterpreted sort in CVL, use the following syntax:

```text
Sort MyUninterpSort;
Sort Foo;
```

These uninterpreted sorts can be utilized in various ways within a CVL specification:

1. **Declare Variables:** 
   ```text
   Foo x;
   ```

2. **Test Equality:**
   ```text
   Foo x; 
   Foo y; 
   assert x == y;
   ```

3. **Use in Signatures:**
   ```text
   ghost myGhost(uint256 x, Foo f) returns Foo;
   ```

## Example Usage

Consider the following illustrative example:

```text
Sort Foo;

ghost bar(Foo, Foo) returns Foo;

rule myRule {
   Foo x;
   Foo y;
   Foo z = bar(x, y);
   assert x == y && y == z;
}
```

This example demonstrates the use of an uninterpreted sort `Foo`. The `bar` ghost function takes two arguments of type `Foo` and returns a value of the same type. The `myRule` rule declares variables `x`, `y`, and `z`, and asserts that they are all equal. While this example may seem useless, it serves to highlight the flexibility of uninterpreted sorts.

## Using Uninterpreted Sorts with Ghosts

Uninterpreted sorts can also be employed in ghosts, as shown in the following example:

```text
ghost mapping(uint256 => Node) toNode;
ghost mapping(Node => mapping(Node => bool)) reach {
  // Axioms for reachability relation
  
}

definition isSucc(Node a, Node b) returns bool =
    // Definition for successor relationship
    
rule checkGetSucc {
  uint256 key;
  uint256 afterKey = getSucc(key);
  assert reach[toNode[key]][toNode[afterKey]];
}
```

This example demonstrates the use of uninterpreted sorts (`Node`) in ghost mappings and functions, emphasizing their application in specifying relationships and properties without being bound by specific interpretations.

In summary, uninterpreted sorts in CVL provide a versatile tool for declaring abstract types and relationships, allowing for greater expressiveness in specification design.