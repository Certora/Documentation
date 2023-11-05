(ghosts-doc)=
Ghosts
======

Ghosts are a way of defining additional variables for use during verification.
These variables are often used to 
- communicate information between {ref}`rules-main` and {ref}`hooks`.
- define deterministic [function summaries](https://github.com/Certora/Examples/blob/61ac29b1128c68aff7e8d1e77bc80bfcbd3528d6/CVLByExample/summary/with-env/WithEnvGhostSummary/WithEnv.spec#L10).

```{contents}
```

The syntax for ghost declarations is given by the following [EBNF grammar](ebnf-syntax):

Syntax
------

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
A ghost variable declaration includes the keyword `ghost` followed by the type and name
of the ghost variable.

The type of a ghost variable may be either a [CVL type](types.md) or a `mapping` type.
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

- [simple `ghost` variable example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/ERC20/certora/specs/ERC20.spec#L113)

- [`ghost mapping` example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/structs/BankAccounts/certora/specs/Bank.spec#L117)

(ghost-functions)=
Ghost Functions
---------------
CVL also has support for "ghost functions".  These serve a different purpose from ghost variables, although they can be
used in similar ways.
Ghost functions must be declared at the top level of a specification file.
A ghost function declaration includes the keyword `ghost` followed by the name and signature of the ghost function.
Ghost functions should be used either:
- when there are no updates to the ghost as the deterministic behavior and axioms are the only properties of the ghost
- when updating the ghost - more than one entry is updated and then the havoc assuming statement is used.

  
  - [`ghost` function example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/QuantifierExamples/DoublyLinkedList/certora/spec/dll-linkedcorrectly.spec#L24)

Restrictions on ghost definitions
---------------------------------
- A ghost axiom cannot refer to `Solidity` or `CVL` functions or to other ghosts. It can refer to the ghost itself.
- Since the signature of a ghost contains just parameter types without names, it cannot refer to its parameters. 
 `forall` can be used in order to refer the storage referred to by the parameters. [Example](https://github.com/Certora/Examples/blob/61ac29b1128c68aff7e8d1e77bc80bfcbd3528d6/CVLByExample/summary/ghost-summary/ghost-mapping/certora/specs/WithGhostSummary.spec#L12).
- A user-defined type, such as struct, array or interface is not allowed as the key or the output type of a `ghost mapping`.

Using ghost variables
---------------------
While verifying a rule or invariant, the Prover considers every possible
initial value of a ghost variable (subject to its {ref}`ghost-axioms`,
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

(ghost-axioms)=
Ghost axioms
------------
### Initial state axioms

When writing invariants, initial axioms are a way to express the “constructor state” of a ghost function. They are used 
only when checking the base step of invariants.

```cvl
ghost mathint sumBalances{
// assuming value zero at the initial state before constructor
init_state axiom sumBalances == 0;
}
```

- [initial state axiom example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/ConstantProductPool/certora/spec/ConstantProductPool.spec#L207)

(global-axioms)=
### Global axioms

Sometimes we might want to constrain the behavior of a ghost in some particular way. 
In CVL this is achieved by writing axioms. Axioms are simply CVL expressions that the tool will then assume are true 
about the ghost. For example:

```cvl
ghost bar(uint256) returns uint256 {
axiom forall uint256 x. bar(x) > 10;
}
```

In any rule that uses bar, no application of bar could ever evaluate to a number less than or equal to 10. 
While this is not a very interesting axiom, we could imagine expressing more complicated functions, 
such as a reachability relation.

- [`axiom` example](https://github.com/Certora/Examples/blob/14668d39a6ddc67af349bc5b82f73db73349ef18/CVLByExample/structs/BankAccounts/certora/specs/Bank.spec#L119)

