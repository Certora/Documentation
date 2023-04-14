(partially parametric rules)=
Partially Parametric Rules
==========================

````{todo}

Write a function that applies a method with some arbitrary arguments and others
passed in, and uses method otherwise.

```cvl
function applyToUser(method f, env e, address user) {
    if (f.selector == balanceOf(address).selector) {
        return balanceOf(e, user);
    }
    if (f.selector == transfer(address,address).selector) {
        address other;
        return transfer(e, user, other);
    }
    else {
        calldataarg arg;
        return f(e, arg);
    }
}
```
````
