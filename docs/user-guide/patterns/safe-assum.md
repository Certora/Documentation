Listing Safe Assumptions
========================

````{todo}

Write a method that requires all the safe assumptions, just add it in all your
rules and preserved blocks.

```cvl
function safeAssumptions(env e) {
    require e.msg.sender != 0;

    // assumption justified because we assume the token isn't in circulation
    require closed() => balance() == 0;

    requireInvariant foo(e);
    requireInvariant bar();
}

invariant foo(env e)
    ...
    { { preserved with (env e2) { safeAssumptions(e2); } } }

invariant bar()
    ...
    { { preserved with (env e2) { safeAssumptions(e2); } } }

rule baz() {
    env e;
    safeAssumptions(e);

    ...
}

```
````
