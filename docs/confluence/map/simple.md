A Simple Map
============

## The code

The below code contains the implementation of a simple map data structure, holding `uint` keys, `uint` values, and assuming that the value `0` indicates a non-existent key. It is possible to get, insert, or remove a key from the map.

```solidity
pragma solidity ^0.7.0;

contract SimpleMap {
    mapping(uint => uint) internal map;
    function get(uint key) public view returns(uint) { return map[key]; }

    function insert(uint key, uint value) external {
        require(value != uint(0), "0 is not a valid value");
        require (!contains(key), "key already exists");
        map[key] = value;
    }

    function remove(uint key) external {
        require (map[key] != uint(0), "Key does not exist");
        map[key] = uint(0);
    }

    function contains(uint key) public view returns (bool) {
        if (map[key] == uint(0)) {
            return false;
        }

        return true;
    }
}
```

In the next sections of the tutorial, we will generalize this trivial contract to support enumeration of the keys in the map.

## Writing specs

Writing rules requires us to consider what are the high-level properties our contract should satisfy. We show some simple and useful patterns for rules.

### Generalized unit tests

Rules that generalize unit tests focus on a single state-mutating function of the contract and ensure that the state is mutated as expected. The main benefits of these rules are that they are easy to develop due to their similarity to unit tests. The added advantage compared to unit tests is that they only use symbolic values, meaning that we check not a single set of concrete values in the unit test but _all_ possible values.

Here is a simple rule for the `insert` function:

```cvl
rule checkInsert(uint key, uint value) {
    env e;
    insert(e, key, value);
    assert get(key) == value, "value of key is not equal to the inserted value";
    assert contains(key), "key is not contained after successful insertion";
}
```

This rule checks that once a key is successfully inserted with `insert`, getting the key with `get` returns the value inserted. The `key` and `value` parameters declared in the rule's header are completely arbitrarily chosen. The `env` (environment) variable `e` is capturing the (symbolic) values of the blockchain variables, such as `msg.sender` and `block.number`. The invocation of insert expects to get as a first argument the environment variable, followed by the arguments according to the function's declaration.

```{note}
Note that by default, the invocation of a function is assumed to succeed. That is, reverting paths of the function are ignored.
```

After calling `insert`, we wish to examine if the mutated state is as expected. Therefore, we assert that calling `get(key)` is returning the value `value` inserted. It is possible to add an explanation string to the assertion, which may help in finding out which assertion was violated if a rule contains more than one assertion.

We are now ready to run the tool: suppose the contract is saved in a file called `SimpleMap.sol`, and the spec is saved in a file `simpleMap.spec`, we can run the tool as follows:

```bash
certoraRun SimpleMap.sol --verify SimpleMap:simpleMap.spec
```

Which tells the tool to include the `SimpleMap` contract in its verification context, and to verify it using the provided spec file.

Unfortunately, the tool outputs the following error:

```
[main] ERROR log.Logger - Syntax error in spec file (9:5): could not type expression "get(key)", message: Could not find an overloading of method get that matches the given arguments: uint. Method is not envfree; did you forget to provide the environment as the first function argument?
```

The cause of the failure is that we did not pass an environment variable to the invocation of `get`. While it is possible to reuse `e` or even declare another environment variable, we note that `get` does not depend on any of the blockchain-related variables. Thus, we can tell the Prover to relieve us from specifying the environment by adding the following declaration to the top of the spec file:

```cvl
methods {
    get(uint) returns uint envfree
}
```

Add an `envfree` declaration for the method `contains` too.

### Revert conditions

As noted before, by default, invocations are assuming only the non-reverting paths of the function. It is useful to precisely characterize all conditions that guarantee that the function would not revert. We can write such a rule for `insert`:

```cvl
rule insertRevertConditions(uint key, uint value) {
    env e;
    insert@withrevert(e, key, value);
    bool succeeded = !lastReverted;

    assert value != 0  => succeeded;
}
```

Here, we invoke `insert` but append to the function name the modifier `@withrevert` that tells the Prover to skip the pruning of reverting paths. (One could also stress that a function should prune the reverting paths using `@norevert`, although this is equivalent to not writing any modifier at all.) We then save into a boolean variable the negation of `lastReverted`, which is a special keyword set to `true` if the last invocation reverted. We then assert that if the value inserted is non-zero (recall that we consider 0 to be an illegal value in our map implementation), then the value of `succeeded` must be true.

```{note}
`lastReverted` will _always_ be `false` following an invocation that is not permitting reverting paths.
```

Running the Prover on the new rule, it returns a failure. The failure is happening because `value` is non-zero yet the `insert` function reverted anyway.

![call trace example](insert_revert.png)

A hint towards what happened can be found in the `Variables` section. The value of `e.msg.value` is indicating the `msg.value` used in `insert`. Since `insert` is not a payable function, it is expected to revert when `msg.value` is non-zero, which is indeed our case here.

We refine the rule as follows, and require that `e.msg.value` is 0:

```cvl
rule insertRevertConditions(uint key, uint value) {
    env e;
    insert@withrevert(e, key, value);
    bool succeeded = !lastReverted;

    assert (e.msg.value == 0 
        && value != 0)
        => succeeded;
}
```

We run the rule again, but it still fails:

![call trace example - second failure](iter_fail_2.png)

We get a call trace that tells us the most important operations performed by the bytecode of the contract, on which the Prover operates. The call trace tells us that we were reading from a storage slot the value 1. To assist us in identifying the issue, in parenthesis we get a reference to the matching source code, which is the load of `map[key]` in line 19, which is where the `contains` function is defined. We understand that we forgot to include the condition that the key does not already exist in the map. So we refine the code again:

```cvl
rule insertRevertConditions(uint key, uint value) {
    env e;
    bool containsKey = contains(key);
    insert@withrevert(e, key, value);
    bool succeeded = !lastReverted;

    assert (e.msg.value == 0 
        && value != 0
        && !containsKey)
        => succeeded;
}
```

And finally our rule is successfully verified.

### Inverses

In some cases, we can reach wider coverage if we write rules that check the interaction of multiple functions with each other. In the map implementation, it is natural to check that insert and remove are inverses of one another. Specifically, we'd like to check that:

*   Invoking `remove` after a successful `insert` must succeed too.
    
*   The value of a key that was inserted and immediately removed is not the value that we inserted.
    

The below rule shows how we can check these two assertions:

```cvl
rule inverses(uint key, uint value) {
    env e;
    insert(e, key, value);
    env e2;
    require e2.msg.value == 0;
    remove@withrevert(e2, key);
    bool removeSucceeded = !lastReverted;
    assert removeSucceeded, "remove after insert must succeed";
    assert get(key) != value, "value of removed key must not be the inserted value";
}
```

Note that we use two separate environments for `insert` and `remove` for better coverage.

```{note}
Reuse of environment variables could lead to vacuity, which is expanded upon in other sections of this manual.
```

```{note}
It is recommended to keep `lastReverted` in separate variables to clearly indicate which invocation we refer to, and to avoid confusion if invocations are reordered.
```

This rule is verified by the Prover.
