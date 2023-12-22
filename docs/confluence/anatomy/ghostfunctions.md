Ghost Functions
===============

Uninterpreted Sorts
-------------------

CVL specifications support normal solidity primitives (`uint256`, `address` etc.) in addition to some of it's own (for example `mathint`). These types are _interpreted_ meaning that their values are ascribed some sort of semantics (for example a bit vector of width 256 can be used inside arithmetic operations or comparison operations and has specific semantics associated i.e. `2 + 2 = 4` or `x = y => z + x = z + y` etc.).

While it can be useful to use interpreted sorts within uninterpreted functions, for reasons we won't get into here, sometimes it is easier to use an _uninterpreted sort_ that doesn't carry around all the "baggage," so to speak, associated with its interpretation. This is where uninterpreted sorts come in. In CVL an uninterpreted sort is simply declared at the top level of a specification. For example

```cvl
sort MyUninterpSort;
sort Foo;

rule myRule {    ...
```

‌There are then 3 things we can do with these sorts:

1.  Declare variables of said sort: `Foo x`.
    
2.  Test equality between two elements of this sort: `Foo x; Foo y; assert x == y;`;
    
3.  Use these sorts in the signatures of uninterpreted functions: `ghost myGhost(uint256 x, Foo f) returns Foo`.
    

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

This will generate an assertion violation. Behind the scenes the solver gets to generate any number of members of the sort `Foo`. So it can easily generate a counterexample by assigning `x` to one member and `y` to the other.

(uninterp-functions)=
Uninterpreted Functions
-----------------------

Uninterpreted functions are called _uninterpreted_ because they have _no interpretation_ associated with them. In the example above, it is impossible to say what `bar(x, y)` _means_. Uninterpreted functions really only give us a single guarantee:

```{note}
Any two applications of the same uninterpreted function with the same arguments will return the same value.
```

So for example:

```cvl
ghost bar(Foo) returns Foo;

rule shouldSucceed(Foo x, Foo y, Foo z) {
  require bar(x) == y;
  require x == z;    // the solver must choose y for bar(z)
  assert bar(z) == y;
}

rule shouldFail(Foo x, Foo y, Foo z) {
  require bar(x) == y;    // the solver can choose whatever it wants for bar(z)
  assert bar(z) == y;
}
```

Axioms for Uninterpreted Functions‌
-----------------------------------

Sometimes we might want to constrain the behavior of an uninterpreted function in some particular way. In CVL this is achieved by writing _axioms_. Axioms are simply CVL expressions that the tool will then _assume_ are true about the uninterpreted functions. For example:

```cvl
ghost bar(uint256) returns uint256 {
    axiom forall uint256 x. bar(x) > 10;
}
```

In any rule that uses `bar`, no application of `bar` could ever evaluate to a number less than or equal to 10. While this is not a very interesting axiom, we could imagine expressing more complicated functions, such as a reachability relation.

```{caution}
Axioms are **dangerous** and should be used **carefully** as they are a potential source of **vacuity bugs**. This can happen in two situations:

1.  The axiom implies `false`
    
2.  Somewhere in the program, we assume something about a ghost function that, when conjoined with a ghost axiom, implies `false`
```
    

Initial Axioms for Uninterpreted Functions
------------------------------------------

Initial axioms look a lot like axioms but are used for a completely different reason. When writing _invariants_ initial axioms are a way to express the "initial state" of a ghost function. For example:

```cvl
ghost sum() returns uint256 {
  init_state axiom sum() == 0;
}
```

This simply states that our sum should start out at zero.
