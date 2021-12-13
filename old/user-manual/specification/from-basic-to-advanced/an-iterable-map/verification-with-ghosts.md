---
description: WIP
---

# Verification with ghosts

In the last section, we presented the idea of ghosts for proving the invariant:

$$
\forall x. (map(x) \neq 0 \iff \exists i. 0\leq i \leq keys.length \land keys[i] =x)
$$

And we have already defined a ghost for the underlying map:

```javascript
ghost _map(uint) returns uint;
```

with the hooks:

```javascript
hook Sload uint v map[KEY uint k] STORAGE {
    require _map(k) == v;
}

hook Sstore map[KEY uint k] uint v STORAGE {
    havoc _map assuming _map@new(k) == v &&
        (forall uint k2. k2 != k => _map@new(k2) == _map@old(k2));
}
```

We continue with defining two additional ghosts: one capturing the length of the array, and the second for remembering the elements of the array:

```javascript
ghost array(uint) returns uint;
ghost arrayLen() returns uint;
```

We also define the hooks. For `array`:

```javascript
hook Sload uint n keys[INDEX uint index] STORAGE {
    require array(index) == n;
}

hook Sstore keys[INDEX uint index] uint n STORAGE {
    havoc array assuming array@new(index) == n &&
        (forall uint i. i != index => array@new(i) == array@old(i));
}
```

For `arrayLen`:

```javascript
hook Sstore keys uint lenNew STORAGE {
    // the length of a solidity storage array is at the variable's slot
    havoc arrayLen assuming arrayLen@new() == lenNew;
}
```

