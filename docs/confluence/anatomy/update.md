Syntax Update: Ghost Variables and Ghost Mappings
=================================================

## Variable-style declarations

CVL now allows for top-level declarations of ghosts that follow the common scheme for variable declarations. Ghost variables can be scalars (`uint` etc.) or mappings.

```cvl
ghost uint myGhost;
ghost mapping(uint => uint) myGhostMapping;
```

Nested (multi-dimensional) ghost mappings are supported, too.

```cvl
ghost mapping(uint => mapping(uint => uint)) myTwoDimensionalGhostMapping
```

Background: Semantically there is no difference between the new variable-style and the old function-style declarations. I.e., the declaration `ghost uint myGhost` creates the same semantic object as the declaration `ghost myGhost() returns uint` .

## Variable-style access

Ghosts that have been declared as scalar variables are accessed like normal variables, e.g. :

```cvl
y = myGhost;
myGhost = x;
```

Ghosts that have been declared as mapping variables are accessed like normal mappings:

```cvl
y = myGhostMapping[i];
myGhostMapping[j] = x;
```

## Mapping-style updates

The update syntax `myGhostMapping[j] = x` can replace many uses of the `havoc .. assuming ..` syntax.

In particular, the old syntax

```cvl
havoc myGhostMapping assuming forall k. k = j ? 
      myGhostMapping@new[k] = x : 
      myGhostMapping@new[k] = myGhostMapping@old[k];
```

can be replaced by

```cvl
myGhostMapping[j] = x;
```

Note that this syntax avoids the quantifiers also internally, so it is strongly recommended to use it if possible.
