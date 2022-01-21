The IterableMap contract
------------------------

‌The `IterableMap` will maintain an internal array of the keys inserted to the map. In the next section, we will add an iteration function.

(function(){ var data = { "addon\_key":"confluence-prism", "uniqueKey":"confluence-prism\_\_confluence-prism-macro5473350555781008600", "key":"confluence-prism-macro", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"100%", "h":"360px", "url":"https://confluence-prism.weweave.net/macro?pageId=41124276&pageVersion=5&macroId=39e1c435-33c9-43e7-a865-e26a138a9806&outputType=html\_export&language=Solidity+%28Ethereum%29&height=&limitHeight=&lineNumbers=true&lineNumbersStart=&lineHighlight=&downloadFilename=&dialogTitle=&xdm\_e=https%3A%2F%2Fcertora.atlassian.net&xdm\_c=channel-confluence-prism\_\_confluence-prism-macro5473350555781008600&cp=%2Fwiki&xdm\_deprecated\_addon\_key\_do\_not\_use=confluence-prism&lic=active&cv=1.1192.0&jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2MGZjMjVkNzhiMWE5YjAwNmYxNmFiZDAiLCJxc2giOiJmNDRlN2VmODE1ZWM4MDEyYjdmOTY1MTQxOWM3MjU3NThhMjE3MTgxNzExMTQ0YjVlYTc3MTVkZjRhNDg0MGMwIiwiaXNzIjoiZjA3Y2YyNDYtOTk1OS0zNzJlLWFlMzQtM2Y1ZmE5Njc3OTdhIiwiY29udGV4dCI6e30sImV4cCI6MTY0Mjc3NzQyMCwiaWF0IjoxNjQyNzc3MjQwfQ.6SgACNGieVpZacAM4-eLjGFpxhYnwuInGNVoH-s5-u8", "contextJwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2MGZjMjVkNzhiMWE5YjAwNmYxNmFiZDAiLCJxc2giOiJjb250ZXh0LXFzaCIsImlzcyI6ImYwN2NmMjQ2LTk5NTktMzcyZS1hZTM0LTNmNWZhOTY3Nzk3YSIsImNvbnRleHQiOnsibGljZW5zZSI6eyJhY3RpdmUiOnRydWV9LCJjb25mbHVlbmNlIjp7ImVkaXRvciI6eyJ2ZXJzaW9uIjoiXCJ2MlwiIn0sIm1hY3JvIjp7Im91dHB1dFR5cGUiOiJodG1sX2V4cG9ydCIsImhhc2giOiIzOWUxYzQzNS0zM2M5LTQzZTctYTg2NS1lMjZhMTM4YTk4MDYiLCJpZCI6IjM5ZTFjNDM1LTMzYzktNDNlNy1hODY1LWUyNmExMzhhOTgwNiJ9LCJjb250ZW50Ijp7InR5cGUiOiJwYWdlIiwidmVyc2lvbiI6IjUiLCJpZCI6IjQxMTI0Mjc2In0sInNwYWNlIjp7ImtleSI6IkNQRCIsImlkIjoiMjkxNjUyNSJ9fX0sImV4cCI6MTY0Mjc3ODE0MCwiaWF0IjoxNjQyNzc3MjQwfQ.HimtzxRm9qVNd93Dff\_8pbOxm4Fwih3hkFoPd6Vwdkw", "structuredContext": "{\\"license\\":{\\"active\\":true},\\"confluence\\":{\\"editor\\":{\\"version\\":\\"\\\\\\"v2\\\\\\"\\"},\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"39e1c435-33c9-43e7-a865-e26a138a9806\\",\\"id\\":\\"39e1c435-33c9-43e7-a865-e26a138a9806\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"5\\",\\"id\\":\\"41124276\\"},\\"space\\":{\\"key\\":\\"CPD\\",\\"id\\":\\"2916525\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"41124276\\",\\"macro.hash\\":\\"39e1c435-33c9-43e7-a865-e26a138a9806\\",\\"lineNumbers\\":\\"true\\",\\"space.key\\":\\"CPD\\",\\"user.id\\":\\"60fc25d78b1a9b006f16abd0\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"5\\",\\"page.title\\":\\"An Iterable Map\\",\\"macro.localId\\":\\"52a140c4-b8a5-469f-9c2b-81b4c4823824\\",\\"language\\":\\"Solidity (Ethereum)\\",\\"macro.body\\":\\"pragma solidity ^0.7.0;\\\\n\\\\ncontract IterableMap {\\\\n mapping(uint =\\u003e uint) internal map;\\\\n function get(uint key) public view r\\",\\": = | RAW | = :\\":\\"lineNumbers=true|language=Solidity (Ethereum)\\",\\"space.id\\":\\"2916525\\",\\"macro.truncated\\":\\"true\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"5\\",\\"user.key\\":\\"8a7f808a7ad469f9017ad8f4037a0390\\",\\"content.id\\":\\"41124276\\",\\"macro.id\\":\\"39e1c435-33c9-43e7-a865-e26a138a9806\\",\\"editor.version\\":\\"\\\\\\"v2\\\\\\"\\"}", "timeZone":"US/Eastern", "origin":"https://confluence-prism.weweave.net", "hostOrigin":"https://certora.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } }());

‌We can now run the original spec file on the new contract. Unfortunately, not all rules are passing. The `inverses` rule is failing. The assertion message tells us `Unwinding condition in a loop`. It is the output whenever we encounter a loop that cannot be finitely unrolled. To avoid misdetections of bugs, the Prover outputs an assertion error in the loop's stop condition. We can control how many times the loops are unrolled, and in the future, the Prover will also support specification of inductive invariants for full loop coverage. In our example, we can start by simply assuming loops can be fully unrolled even if only unrolled once by specifying `--optimistic_loop` in the command line for running the Prover.‌

Even then `inverses` still fails. Let's consider the call trace for this rule:

![](attachments/41124276/41157020)

‌We see that we were able to nullify the entry in the map, but the last operation that we see in the call trace under `remove` is that we load from `keys` a value of 0. It is known that the Solidity compiler associates the storage slot that of an array to its length. Here we see that the read length is 0. This means the `key` array is empty. However, it shouldn't have been empty after invoking `insert`. This is exactly the bug that we have in the code - we need to add the inserted key into the `keys` array:

```java
function insert(uint key, uint value) external {
    require(value != 0, "0 is not a valid value");
    require (!contains(key), "key already exists");
    map[key] = value;
    keys.push(key);
}
```

‌Oddly enough, the rule still fails:

![](attachments/41124276/41157027)

‌It is still reported that the length of `keys` is 0, but this is unexpected. We examine the operations performed by `insert`, and we see that it loaded a length of `ff....ff`, and then stored a length of 0. That is, our array filled-up and reached the length of max `uint256`. This may look absurd or unrealistic, but that's where the power of the Prover lies - it doesn't miss any edge case. If we believe it is unrealistic for the length of `keys` to reach the maximum value, we should:

*   assume that the length of the array is less than max `uint256`.
    
*   assert that it is indeed infeasible to directly overwrite the length slot, or to increment the length by more than `1` in each operation.
    

We start by adding a simple assumption in the rule. (We will later replace it with an assumption of an invariant, that will also assert that reaching max `uint256` is infeasible.)

```java
rule inverses(uint key, uint value) {
    uint max_uint = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    require numOfKeys() < max_uint;
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

‌(don't forget to add `numOfKeys` to our `envfree` declarations!)

### Adding iteration

‌Our goal in adding the `keys` variable was to allow iteration over the keys. We start with an extremely simple example, that sets all keys' values to 100:

```java
function iterate() external {
    for (uint i = 0 ; i < keys.length ; i++) {
        uint key = keys[i];
        doSomething(key, get(key));
    }
}

function doSomething(uint key, uint value) virtual internal {
    map[key] = 100;
}
```

‌We also want to add a basic check rule:

```java
rule checkIterate() {
    env e;
    iterate(e);
    uint someKey;    
    require contains(someKey);
    assert get(someKey) == 100;
}
```

‌The rule fails with the following call trace:

![](attachments/41124276/41157033)

‌Let's unpack what can be seen here. First, the length of the `keys` array is 1, and we read a key `22f2`. We then write `100` to it in the map and then `iterate` function is done. We then note that `someKey`, the key we want to check for, is not `22f2`, but rather `20c9`. While we assumed that it is contained in the map by using the `contains` function, it is not contained in the `keys` array. This is expected since the Prover's starting state can be completely arbitrary, subject to constraints that we specify on it. We wish to leave the `contains` function to be an `O(1)` complexity function, and rather provide the tool with the invariants that will allow it to see only states that "make sense", or in more precise terms, we only want to see states where the `keys` array contains exactly the same elements as the non-zero valued keys in the map.

‌In mathematical terms, the invariant that our `IterableMap` contract should satisfy is:

(function(){ var data = { "addon\_key":"orah-latex", "uniqueKey":"orah-latex\_\_orah-latex3088990633481316037", "key":"orah-latex", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://content-formatting.connect.apps.adaptavist.com/macro/latex/latex.html", "contextJwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2MGZjMjVkNzhiMWE5YjAwNmYxNmFiZDAiLCJxc2giOiJjb250ZXh0LXFzaCIsImlzcyI6ImYwN2NmMjQ2LTk5NTktMzcyZS1hZTM0LTNmNWZhOTY3Nzk3YSIsImNvbnRleHQiOnsibGljZW5zZSI6eyJhY3RpdmUiOnRydWV9LCJjb25mbHVlbmNlIjp7ImVkaXRvciI6eyJ2ZXJzaW9uIjoiXCJ2MlwiIn0sIm1hY3JvIjp7Im91dHB1dFR5cGUiOiJodG1sX2V4cG9ydCIsImhhc2giOiJhMTNhMzViNS03OTlmLTQ4MTgtOWRjNi1mOWU2NjgwNjQ3OWQiLCJpZCI6ImExM2EzNWI1LTc5OWYtNDgxOC05ZGM2LWY5ZTY2ODA2NDc5ZCJ9LCJjb250ZW50Ijp7InR5cGUiOiJwYWdlIiwidmVyc2lvbiI6IjUiLCJpZCI6IjQxMTI0Mjc2In0sInNwYWNlIjp7ImtleSI6IkNQRCIsImlkIjoiMjkxNjUyNSJ9fX0sImV4cCI6MTY0Mjc3ODE0MCwiaWF0IjoxNjQyNzc3MjQwfQ.Ea4Vw8Ndairc4V02l8xBgbC8KsLpc8U73TfzbY4pmz4", "structuredContext": "{\\"license\\":{\\"active\\":true},\\"confluence\\":{\\"editor\\":{\\"version\\":\\"\\\\\\"v2\\\\\\"\\"},\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"a13a35b5-799f-4818-9dc6-f9e66806479d\\",\\"id\\":\\"a13a35b5-799f-4818-9dc6-f9e66806479d\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"5\\",\\"id\\":\\"41124276\\"},\\"space\\":{\\"key\\":\\"CPD\\",\\"id\\":\\"2916525\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"41124276\\",\\"macro.hash\\":\\"a13a35b5-799f-4818-9dc6-f9e66806479d\\",\\"space.key\\":\\"CPD\\",\\"user.id\\":\\"60fc25d78b1a9b006f16abd0\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"5\\",\\"page.title\\":\\"An Iterable Map\\",\\"macro.localId\\":\\"0f60db0a-af05-406a-924b-e3c56b49dbae\\",\\"macro.body\\":\\"$$\\\\n\\\\\\\\forall x. (map(x) \\\\\\\\neq 0 \\\\\\\\iff \\\\\\\\exists i. 0\\\\\\\\leq i \\\\\\\\leq keys.length \\\\\\\\land keys\[i\] =x)\\\\n$$\\",\\": = | RAW | = :\\":null,\\"space.id\\":\\"2916525\\",\\"macro.truncated\\":\\"false\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"5\\",\\"user.key\\":\\"8a7f808a7ad469f9017ad8f4037a0390\\",\\"content.id\\":\\"41124276\\",\\"macro.id\\":\\"a13a35b5-799f-4818-9dc6-f9e66806479d\\",\\"editor.version\\":\\"\\\\\\"v2\\\\\\"\\"}", "timeZone":"US/Eastern", "origin":"https://content-formatting.connect.apps.adaptavist.com", "hostOrigin":"https://certora.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } }());

∀x.(map(x)≠0⟺∃i.0≤i≤keys.length∧keys\[i\]=x)\\forall x. (map(x) \\neq 0 \\iff \\exists i. 0\\leq i \\leq keys.length \\land keys\[i\] =x)∀x.(map(x)≠0⟺∃i.0≤i≤keys.length∧keys\[i\]=x)

‌

This invariant can be encoded directly in the spec file, as follows (for convenience we assume `keys` is public and has a getter):

```java
invariant inMapIffInArray(uint x) 
    get(x) != 0 <=> 
        (exists uint i. 0 <= i && i < getNumOfKeys() && keys(i) == x)
```

‌It is not recommended to invoke the underlying contract directly within quantified expressions (such as `exists uint i. ...`). The complexity of the underlying bytecode might lead to timeouts, and thus it is recommended to move to _ghost variables_. Ghost variables, once properly instrumented, allow us to write specs that are separated from the many technicalities of low-level bytecode and are thus a powerful abstraction tool.

A soft introduction to ghosts
-----------------------------

‌We will write the above invariant using ghost variables exclusively. First, we will declare ghost variables for the underlying map structure as a function mapping keys to values:

```java
ghost _map(uint) returns uint;
```

‌The above declaration declares a _ghost function_. The ghost function takes a `uint` argument (representing a key in the map) and returns a `uint` value. We want `_map` to return for each given key the same value as the `map` in the code. We can state this property as an invariant:

```java
invariant checkMapGhost(uint someKey) get(someKey) == _map(someKey)
```

Currently, the rule fails for all state-mutating functions, and even in the contract's initial state after constructor (rule `checkMapGhost_instate`):

![](attachments/41124276/41157039)

This is, in fact, unsurprising. There is nothing in the spec that links the value of the ghost to its Solidity counterpart. To make that link, we write _hooks_. Hooks allow us to instrument the verified code, that is, to wrap a bytecode operation with our own code, defined in the spec file.

For example, we can hook on `SSTORE` operations that write to the underlying map as follows:

```java
hook Sstore map[KEY uint k] uint v STORAGE {
    havoc _map assuming _map@new(k) == v &&
        (forall uint k2. k2 != k => _map@new(k2) == _map@old(k2));
}
```

This hook will match every storage write to `map[k]`, denoting the written value by `v`. Optionally, and not shown in the syntax above, we can also specify the overwritten value of `map[k]`. The body of the hook is the injected code. It will apply `havoc` on the `_map` ghost, meaning that every key-value association it stored is "forgotten" by the prover and results in a completely new instance of `_map`. However, we restrict the new instance of `_map` using the old `_map` definition, with the `assuming ...` syntax. Under `assuming` we get a two-state context: we can see both old and new instances of `_map`, accessible with `_map@old` and `_map@new`. We require that `_map@old` and `_map@new` are the same for all keys except for `k`, the one we write to, and for `k` we require that `_map@new(k) == v`.

‌If we run `checkMapGhost` with only the `SSTORE` hook, the rule will pass for all functions but fail in the initial state, where no values were written. It is possible to specify initial state axioms on ghosts.

‌Similarly, one could define `SLOAD` hooks:

```java
hook Sload uint v map[KEY uint k] STORAGE {
    require _map(k) == v;
}
```

‌This hook says that every time the Prover encounters an `SLOAD` operation that reads the value `v` from `map[k]`, it will inject the code within the hook body after the `SLOAD`. This will make our `checkMapGhost` rule pass, but it's also become a tautology, because it's always true: by calling `get` we're already calling instrumented code that requires `_map(k) == v` whenever we load an arbitrary value `v` from the key `k`.