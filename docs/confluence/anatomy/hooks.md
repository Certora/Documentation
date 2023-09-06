Storage Hooks
=============

Motivation
----------

The previous section described uninterpreted functions as they exist in the Prover. But by themselves, these uninterpreted functions are pretty useless. They don't even seem to keep track of any "ghost" state, as there is no way to relate the uninterpreted functions to the state of the contract being analyzed. _Hooks_ are the glue that pieces together program behavior and the uninterpreted functions by providing a way to _hook_ into certain program behavior and _update_ ghost relations to reflect that program behavior.

### Program State

Ghosts are used to represent some state of a smart contract that the contract itself doesn't necessarily explicitly express. Nonetheless, there is often a relationship between what we want to express as a ghost state and the actual state of the program. For this reason, the hooks that can be expressed in CVL are linked to changes in contract `storage`, the only place where persistent contract state lives.

The Anatomy of a Hook
---------------------

A hook is made up of two separate pieces.

1.  The _pattern_: describes what read or write pattern the Prover looks for
    
2.  The _body_: a block of code for the Prover to insert
    

Inside each rule, the Prover takes these hooks and looks for any reads or writes to storage that match the _pattern_. At each match, it will insert the _body_ of the hook where the match was found.

Hook Patterns
-------------

### `Sload` and `Sstore`

`Sload` and `Sstore` are two `TAC` primitives representing a _read_ from storage and a _write_ to storage, respectively. A pattern for an `Sload` will bind a variable to provide access to "the value loaded", and a pattern for an `Sstore` will bind a variable both for "the value stored" and (optionally) "the old value that was overwritten." For example:

```cvl
hook Sload uint256 v <pattern> STORAGE {
  // inside this block, "v" provides access to the value that was loaded
  // by this command (i.e. the lhs of the Sload command). Another variable
  // name other than "v" could have been used
}

hook Sstore <pattern> uint256 v STORAGE {
  // inside this block, "v" provides access to the value that was written
  // to storage by this command (i.e. the rhs of the Sload command) Another
  // variable name other than "v" could have been used
}

hook Sstore <pattern> uint256 v (uint256 v_old) STORAGE {
  // inside this block:
  //  - "v" provides access to the value that was written to storage by
  //    this command
  //  - "v_old" provides access to the value that was overwritten by this
  //    command
}
```

In the last hook, the Prover will generate an extra `Sload v_old <pattern>` before every matched `Sstore`

### Slot Patterns

Slot patterns represent any access path that could represent a storage access to any of Solidity's data structures (struct, array, mapping). However, because the EVM view of storage is just of a flat array of 256 bit words, an inline assembly block can produce a storage access that is not expressible by our slot pattern (in which case the storage analysis will be unable to reason about it anyway). A slot pattern conforms to the following grammar:

```
ap := id            // some storage variable declared in contract
   |  (slot n)      // n words into storage array
   |  ap.(offset n) // struct access n bytes from ap, where n is a multiple of 32
   |  ap[KEY t k]   // mapping access into the mapping at ap with key k of type t
   |  ap[INDEX t i] // array access into the array at ap with index i of type t
   ;
```

```{note}
Nested struct offsets (`ap.(offset n)`) will be flattened before matching with the storage analysis (which will also flatten struct accesses). So, for example, both `ap.(offset 5).(offset 3)`and `ap.(offset 4).(offset 4)` will compile to `ap.(offset 8)` and would match any struct access where `ap` matches the base and some sequence of struct dereferences adds up to `8` bytes.
```

These slot patterns provide a simple syntax to specify what storage slot to hook on directly based on the Solidity-level declarations of storage variables. The following are a few examples of Solidity-level declarations of storage variables and slot patterns that will match accesses to these

```solidity
mapping(address => uint256) balances;
balances[KEY address addr]

MyStruct {
  uint256 el_1;
  address el_2;
}
MyStruct[] arr;
arr[INDEX uint256 i].(offset 32) // an access to el_2 of some element of arr

mapping(uint256 => MyStruct[]) map;
map[KEY uint256 k][INDEX uint256 i].(offset 0) // an access to el_1 of some
                                               // element of some value
                                               // map‌
```

```{note}
The access pattern `(slot n)` requires an understanding of the storage layout of a contract. If you know where a top-level variable sits in the top-level storage array you can use this access pattern. Additionally, with `solc5.X` and older, you must use this pattern instead of storage variable identifiers since the storage layout is unavailable in versions older than `solc5.X`
```

Struct Patterns
---------------

The storage analysis has a less than perfect view of structs which makes them relatively complicated. There are several important things to note:‌

1.  The storage analysis **only** reasons about 1 word/256 bit/32 byte slots,
    
2.  **except** for in static slots (i.e., not inside of a mapping or array)
    
3.  It is possible to extract packed struct values, but it requires knowledge of how solidity packs structs
    

We will examine these three cases in the following running example:

```solidity
contract Test {
  struct MyStruct {
    uint256 first;
    uint256 second;
    uint256 third;
  }
  
  struct MyPackedStruct {
    uint128 first;
    uint64 second;
    uint64 third;
  }

  MyStruct s_1;
  MyPackedStruct s_2;
  mapping(uint256 => MyStruct) m_1;
  mapping(uint256 => MyPackedStruct) m_2;
  ...
}
```

### Structs in Static Slots

In static slots we can reason about packing from the hook pattern. For example, if we wanted to hook on a write to `s_1.second` we would write the following hook (remember offsets are in bytes):

```cvl
hook Sstore s_1.(offset 16) uint64 second (uint64 old_second) STORAGE {
  // hook body
}
```

### Structs inside Mappings or Arrays

When a struct is inside a mapping or an array, it becomes a bit trickier to reason about. However, 1 word/32 byte offsets are fine. So if we wanted to hook on a write to `m_1[k].third` we would write:

```cvl
hook Sstore m_1[KEY uint256 k].(offset 64) uint256 third STORAGE {
  // hook body
}
```

This is allowed only because the offset is **32-byte aligned**. Any non- 32-byte aligned offset will not type-check. However, using a clever definition, we can still get values from within packed structs.

### Manually Unpacking Structs

Solidity packs structs in the order they're declared, starting from the least significant bit. So a word holding a `MyPackedStruct` would look like:

```
//T=third         S=second        F=first
0xTTTTTTTTTTTTTTTTSSSSSSSSSSSSSSSSFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
```

So we can write a definition that will unpack these bits:

```cvl
definition MyPackedStruct_first(uint256 s) returns uint256 =
    s & 0xffffffffffffffffffffffffffffffff;
definition MyPackedStruct_second(uint256 s) returns uint256 =
    (s & 0xffffffffffffffff00000000000000000000000000000000) >>> 128;
definition MyPackedStruct_third(uint256 s) returns uint256 =
    (s & 0xffffffffffffffff000000000000000000000000000000000000000000000000) >>> 192;
```

And so to write a hook to `m_2[k].{first, second, third}` we can write the following:

```cvl
hook Sstore m_2[KEY uint256 k].(offset 0) uint256 s STORAGE {
  uint256 first   = MyPackedStruct_first(s);
  uint256 second  = MyPackedStruct_second(s);
  uint256 third   = MyPackedStruct_third(s);    
  // body
}
```

```{caution}
This hook will be triggered on writes to all fields of the struct packed into the same slot‌.
```

Putting it Together
-------------------

The combination of `Sload`/`Sstore` and the slot pattern combine to create a complete specification of a **hook pattern**. For example:

```cvl
hook Sstore balances[KEY address account] uint256 v (uint256 v_old) STORAGE {
  // inside this block:
  //  - "account" provides access to the key into the mapping that was
  //    was used in this storage access
  //  - "v" provides access to the value that was written to storage by
  //    this command
  //  - "v_old" provides access to the value that was overwritten by this
  //    command
}
```

(hook-body)=
The Body of a Hook
------------------

The body of a hook may contain almost any CVL code, including calls to other Solidity functions (not including parametric method calls).
Expressions in these commands may reference variables bound by the hook. For example:

```cvl
ghost ghostBalances(address) returns uint256;
hook Sload uint256 v balances[KEY address account] STORAGE {
  require ghostBalances(account) == v;
}‌
```

This would make sure that on every read, we make sure that `ghostBalances` matches `balances`. Often hook bodies only include a one-line update to a ghost function, but this doesn't necessarily need to be the case. A similar update to `ghostBalances` would be possible on an `Sstore` but requires understanding a _two-state context_.

(two-state-old)=
Two State Context
-----------------

A two-state context is a scope in which two versions of a variable or ghost function are available, representing _two different_ states of that variable/ghost function. If we are talking about the variable `my_var` then the _old_ version would be accessed using `my_var@old`, and the new version would be accessed using `my_var@new`. For ghost functions, we annotate the ghost application. For example, an application of the _old_ version might look like `my_ghost@old(x, y)`, and an application of the _new_ version might look like `my_ghost@new(x, y)` .

But how is it that we would have _two_ versions of a variable or ghost function? Currently, the _only_ place that will _create_these two versions is a havoc-assuming statement.

### Havoc Assuming

Sometimes we want to forget everything we know about a variable and allow it to take any value from a certain program point onward. This is when we _havoc_ a variable. For example:

```cvl
rule my_rule(uint256 x) {
  require x == 2;
  assert x == 2; // passes
  havoc x;
  assert x == 2; // fails
}
```

Other times, we'd only like to forget certain things about a variable or ghost function, and sometimes we'd like to learn _new_ things or constrain a variable based on its own value. This is where the `havoc assuming` statement becomes very useful. The following example should illustrate the idea:

```cvl
rule my_rule(uint256 x) {
  require x >= 2;
  havoc x assuming x@new > x@old;
  assert x > 2; // passes
}
```

and a `havoc assuming` statement with a ghost function might look like the following:

```cvl
ghost contains(uint256 x) returns bool;

rule my_rule(uint256 x, uint256 y, uint256 z) {
  require contains(x);
  // "every input that used to return true should still return true
  //  AND y should now return true as well"
  havoc contains assuming contains@new(y) &&
      forall uint256 a. contains@old(a) => contains@new(a);
      
  assert contains(x) && contains(y); // passes
  assert contains(z);                // fails
}
```

Finally, as shown in the section on definitions, a definition with ghosts in two-state form may be used inside the two-state context of a `havoc assuming` statement.

A Hook that Modifies Ghost State
--------------------------------

{ref}`Above <hook-body>` we saw an example where we made sure that the ghost state matched a read of its corresponding concrete state. This did not modify the ghost state but rather _further constrained_ it according to new information. But when the concrete state is changed, we need some way to modify the ghost state. Suppose we have an update to a balance. We can use a `havoc assuming` statement to assume that all balances not concerned by the update stay the same and that the balance of the account that was changed gets updated:

```cvl
ghost ghostBalances(address) returns uint256;

hook Sstore balances[KEY address account] uint256 v STORAGE {
  havoc ghostBalances assuming ghostBalances@new(account) == v &&
    forall address a. a != account =>
        ghostBalances@new(a) == ghostBalances@old(a);
}
```

```{caution}
In `Sstore` hooks, the old value is read by means of generating an `Sload`. However, any hook that can be matched to the generated `Sload` _does not_ apply within the `Sstore` hook.
```

Notes on Hooks Calling Solidity Functions
-----------------------------------------

Hooks are not recursively applied.
That is, if a hook calls a Solidity function `foo`, and the Solidity function call triggers a summarization that also calls another Solidity function `bar`, then any hooks that would have applied to `bar` would not be instrumented from this context.
For example, given the following contract and specification, the rule `check` will fail.

```solidity
contract C {
  uint public x;
  function main() external {
    x = 3;
  }

  function foo() external {
    myInternalFoo();
  }

  function myInternalFoo() internal {
    // ...
  }

  function bar() external {
    x = 5;
  }

}
```

```cvl
methods {
  function myInternalFoo() internal => callBar();
  function x() external returns (uint256) envfree;
}

function callBar() {
  env e;
  bar(e);
}

ghost uint xGhost;
hook Sstore x uint v STORAGE {
  xGhost = v;
  env e;
  foo(e);
}

rule check() {
  env e;
  main(e);
  assert xGhost == x(); // will fail - bar()'s hooks are not instrumented. xGhost == 3 while x == 5
}
```
