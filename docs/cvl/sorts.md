Uninterpreted Sorts
===================

The syntax for `sort` declarations is given by the following [EBNF grammar](ebnf-syntax):

```
sort ::= "sort" id ";"
```

See {ref}`identifiers` for the `id` production.


There are then 3 things we can do with these sorts:

1.  Declare variables of said sort: `Node x`.
    
2.  Test equality between two elements of this sort: `Node x; Node y; assert x == y;`;
    
3.  Use these sorts in the signatures of `ghost` function `ghost myGhost(uint256 x, Foo f) returns Foo`.

4. Use these sorts in ghosts: `ghost mapping(uint256 => Node) toNode;`

Putting these pieces together we might write the following useless, but demonstrative example:

```cvl
sort Foo;
ghost bar(Foo, Foo) returns Foo;

rule myRule {
  Foo x;
  Foo y;
  Foo z = bar(x, y);
  assert x == y && y == z;
}
```

The following is an example for using `sort` using ghosts.

``` cvl
ghost mapping(uint256 => Node) toNode;
ghost mapping(Node => mapping(Node => bool)) reach {
  axiom forall Node X. reach[X][X];
  axiom forall Node X. forall Node Y.
      reach[X][Y] && reach[Y][X] => X == Y;
  axiom forall Node X. forall Node Y. forall Node Z.
      reach[X][Y] && reach[Y][Z] => reach[X][Z];
  axiom forall Node X. forall Node Y. forall Node Z.
      reach[X][Y] && reach[X][Z] => (reach[Y][Z] || reach[Z][Y]);
}

definition isSucc(Node a, Node b) returns bool =
    reach[a][b] && a != b &&
        (forall Node X. reach[a][X] && reach[X][b] => (a == X || b == X));
        
rule checkGetSucc {
  uint256 key;
  uint256 afterKey = getSucc(key);
  assert reach[toNode[key]][toNode[afterKey]];
}
```
