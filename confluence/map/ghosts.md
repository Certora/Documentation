Verification With Ghosts
========================

(WIP)

In the last section, we presented the idea of ghosts for proving the invariant:

$$∀x.(map(x)≠0⟺∃i.0≤i≤keys.length∧keys[i]=x)$$

And we have already defined a ghost for the underlying map:

```java
ghost _map(uint) returns uint;
```

with the hooks:

```java
hook Sload uint v map[KEY uint k] STORAGE {
    require _map(k) == v;
}

hook Sstore map[KEY uint k] uint v STORAGE {
    havoc _map assuming _map@new(k) == v &&
        (forall uint k2. k2 != k => _map@new(k2) == _map@old(k2));
}
```

We continue with defining two additional ghosts: one capturing the length of the array, and the second for remembering the elements of the array:

```java
ghost array(uint) returns uint;ghost arrayLen() returns uint;
```

We also define the hooks. For `array`:

```java
hook Sload uint n keys[INDEX uint index] STORAGE {
    require array(index) == n;
}

hook Sstore keys[INDEX uint index] uint n STORAGE {
    havoc array assuming array@new(index) == n &&
        (forall uint i. i != index => array@new(i) == array@old(i));
}
```

For `arrayLen`:

```java
hook Sstore keys uint lenNew STORAGE {
    // the length of a solidity storage array is at the variable's slot
    havoc arrayLen assuming arrayLen@new() == lenNew;
}
```
