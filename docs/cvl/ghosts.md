(ghosts)=
Ghosts
======

Ghosts are a way of defining additional variables for use during verification.
These variables are often used to communicate information between
[rules](rules.md) and [hooks](hooks.md).

```{contents}
```

Syntax
------

The syntax for ghost declarations is given by the following [EBNF grammar](syntax):

```
ghost ::= "ghost" type id                             (";" | "{" axioms "}")
        | "ghost" id "(" cvl_types ")" "returns" type (";" | "{" axioms "}")

type ::= basic_type
       | "mapping" "(" cvl_type "=>" type ")"

axiom ::= [ "init_state" ] "axiom" expression ";"
```

See {doc}`types` for the `type` and `cvl_type` productions, and {doc}`expr` for
the `expression` syntax.

(ghost-variables)=
Declaring ghost variables
-------------------------

Ghost variables must be declared at the top level of a specification file.
A ghost declaration includes the keyword `ghost` followed by the type and name
of the ghost variable.

The type of a ghost may be either a [CVL type](types.md) or a `mapping` type.
Mapping types are similar to solidity mapping types.  They must have CVL types
as keys, but may contain either CVL types or mapping types as values.

For example, the following are valid ghost declarations:

```cvl
ghost uint x;
ghost mapping(address => mathint) balances;
ghost mapping(uint => mapping(uint => mathint)) delegations;
```

while the following are invalid:

```cvl
ghost (uint, uint) x;                              // tuples are not CVL types
ghost mapping(mapping(uint => uint) => address) y; // mappings cannot be keys
```


Using ghost variables
---------------------

While verifying a rule or invariant, the Prover considers every possible
initial value of a ghost variable (subject to its {ref}`axioms <ghost-axioms>`,
see below).

Within CVL, you can read or write ghosts using the normal variable syntax.  For
example:

```cvl
ghost mapping(address => mathint) balances;

function example(address user) {
    balances[user] = x;
}
```

The most common reason to use a ghost is to communicate information from a hook
back to the rule that triggered it.  For example, the following CVL checks
that a call to the contract method `do_update(user)` changes the contract
variable `userInfo[user]` and does not change `userInfo[other]` for any other
user:

```cvl
ghost mapping(address => bool) updated;

hook Sstore userInfo[KEY address u] uint i STORAGE {
    updated[u] = true;
}

rule update_changes_user(address user) {
    updated[user] = false;

    do_update(user);

    assert updated[user] == true, "do_update(user) should affect user";
}

rule update_changes_no_other(address user, address other) {
    require user != other;
    require updated[other] == false;

    do_update(user);

    assert updated[other] == false;
}
```

Here the `updated` ghost is used to communicate information from the `userInfo`
hook back to the `updated_changes_user` and `updated_changes_no_other` rules.

Initial state axioms
--------------------

```{todo}
This documentation is incomplete.  See [the old documentation](/docs/confluence/anatomy/ghostfunctions)
for information about initial state axioms.
```

(ghost-axioms)=
(ghost-functions)=
Ghost functions
---------------

CVL also has support for "ghost functions".  These serve a different purpose
from ghost variables, although they can be used in similar ways.

```{todo}
This documentation is currently incomplete.  See [ghosts](/docs/confluence/anatomy/ghosts)
and [ghost functions](/docs/confluence/anatomy/ghostfunctions) in the old documentation.
```



