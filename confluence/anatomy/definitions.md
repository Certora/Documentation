Definitions
===========

Syntax
------

Definitions are declared at the top-level of a specification and are in scope inside every rule, function and inside other definitions.

### Basic Definitions

The following shows the basic usage of definitions. The definitions bind parameters for use in an arbitrary expression on the right-hand side, which should evaluate to the declared return type. In the example below, `is_even` binds the variable `x` as a `uint256`. Definitions are applied just as any function would be.

```cvl
methods {
  foo(uint256) returns bool envfree
}

definition MAX_UINT256() returns uint256 = 0xffffffffffffffffffffffffffffffff;
definition is_even(uint256 x) returns bool = exists y. 2 * y == x;​

rule my_rule(uint256 x) {
  require is_even(x) && x <= MAX_UINT256();
  foo@withrevert(x);    assert !lastReverted;
}
```

### Advanced Definitions

Beyond this basic functionality, definitions can do two things:

#### Include an Application of Another Definition.

There can be arbitrarily deep nesting, however there must not be a circular dependency. The type checker will report an error if it detects a circular dependency. In the following example, `is_odd` and `is_odd_no_overflow` both reference other definitions:

```cvl
definition MAX_UINT256() returns uint256 = 0xffffffffffffffffffffffffffffffff;
definition is_even(uint256 x) returns bool = exists y. 2 * y == x;
definition is_odd(uint256 x) returns bool = !is_even(x);
definition is_odd_no_overflow(uint256 x) returns bool =
    is_odd(x) && x <= MAX_UINT256();
```

The following examples would result in a type error due to a circular dependency:

```cvl
// example 1
// cycle: is_even -> is_odd -> is_even
definition is_even(uint256 x) returns bool = !is_odd(x);
definition is_odd(uint256 x) returns bool = !is_even(x);​

// example 2
// cycle: circular1->circular2->circular3->circular1
definition circular1(uint x) returns uint = circular2(x) + 5;
definition circular2(uint x) returns uint = circular3(x - 2) + 7;
definition circular3(uint x) returns uint = circular1(x) + circular1(x);
```

#### Reference Ghost Functions

Definitions may reference ghost functions normally _or_ in a two state context.

```{caution}
This means that definitions are not always "pure" but can affect ghosts which are a "global" construct.
```

The following is an example of a ghost used in a definition:

```cvl
ghost foo(uint256 x) returns uint256;​

definition is_even(uint256 x) returns bool = exists y. 2 * y == x;
definition foo_is_even_at(uint256 x) = is_even(foo(x));​

rule rule_assuming_foo_is_even_at(uint256 x) {
  require foo_is_even_at(x);
  ...
}
```

More interestingly, we can use the two-context version of ghosts in a definition (adding the `@new` or `@old` annotations. If we use the two-context version of a ghost, we _may not_ use the ghost _without_ an `@new` or `@old` annotation. Additionally, that definition _must_ be used in a two state context for that ghost function (i.e., at the right side of a `havoc assuming` statement for that ghost).

```cvl
ghost foo(uint256 x) returns uint256;​

definition is_even(uint256 x) returns bool = exists y. 2 * y == x;
definition foo_add_even(uint256 x) returns bool = is_even(foo@new(x)) &&
    forall uint256 a. is_even(foo@old(x)) => is_even(foo@new(x));
    
rule rule_assuming_old_evens(uint256 x) {
  // havoc foo, assuming all old even entries are still even, and that
  // the entry at x is also even
  havoc foo assuming foo_add_even(x);
  ...
}
```

```{note}
The type checker will tell you if you have used a two-state version of a variable when you should not have
```
