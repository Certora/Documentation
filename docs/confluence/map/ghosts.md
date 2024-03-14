Verification With Ghosts
========================

(WIP)

In the last section, we presented the idea of ghosts for proving the invariant:

$$∀x.(map(x)≠0⟺∃i.0≤i≤keys.length∧keys[i]=x)$$

And we have already defined a ghost for the underlying map:

```cvl
ghost mapping(uint => uint) _map;
```

with the hooks:

```cvl
hook Sload uint v map[KEY uint k] {
    require _map[k] == v;
}

hook Sstore map[KEY uint k] uint v {
    _map[k] = v;
}
```

We continue with defining two additional ghosts: one capturing the length of
the array, and the second for remembering the elements of the array:

```cvl
ghost mapping(uint => uint) array; ghost uint arrayLen;
```

We also define the hooks. For `array`:

```cvl
hook Sload uint n keys[INDEX uint index] {
    require array[index] == n;
}

hook Sstore keys[INDEX uint index] uint n {
    array[index] = n;
}
```

For `arrayLen`:

```cvl
hook Sstore keys uint lenNew {
    // the length of a solidity storage array is at the variable's slot
    arrayLen = lenNew;
}
```
