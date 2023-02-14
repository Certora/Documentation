Syntax changes introduced in CVL 4
==================================

This document summarizes the changes to CVL syntax introduced by CVL 4.0.

```{contents}
```

Superficial syntax changes
--------------------------

There are several changes to make the syntax rhyme better with Solidity, they are

### `function` and `;` required for methods block entries
Methods block entries must now start with `function` and end with `;`.  For
example:

```cvl
balanceOf(address) returns(uint) envfree
```
will become
```cvl
function balanceOf(address) returns(uint) envfree;
```

This is also true for entries with summaries:
```cvl
_setManagedBalance(address,uint256) => NONDET
```
will become
```cvl
function _setManagedBalance(address,uint256) => NONDET;
```

```{todo}
If you do not change this, you will see the following error:
```

### Required `;` in more places

`using`, `pragma`, and `import` statements all require a `;` at the end.  For
example,

```cvl
using C as c
```

becomes
```cvl
using C as c;
```

```{todo}
If you do not change this, you will see the following error:
```

### Method literals require `sig:`

In some places in CVL, you can refer to a contract method by its name and
argument types.  For example, you might write
```cvl
require f.selector == balanceOf(address).selector;
```

In this example, `balanceOf(address)` is a *method literal*.  In CVL 4.0,
these methods literals must now start with `sig:`.  For example, the above
would become:

```cvl
require f.selector == sig:balanceOf(address).selector;
```

```{todo}
If you do not change this, you will see the following error:
```


Changes to methods block entries
--------------------------------

In addition to the superficial changes listed above, there are some changes that
change the way that methods block entries can be written.

### Multiple entries with the same signature

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```


### `internal` and `external`

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### `optional` methods entries

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Location modifiers

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Explicit receivers and wildcards

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Requirements on `returns`

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

Changes to integer types
------------------------

```{todo}
overview
```

### Mathematical operations return `mathint`

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Comparisons require identical types

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Implicit and explicit casting

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Support for `bytes<K>`

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Changes for bitwise operations

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

Removed features
----------------

As part of the transition to CVL 4.0, we have removed several language features
that are no longer used.

We have removed these features because we think they are no longer used and no
longer useful.  If you find that you do need one of these features, contact
Certora support.

### Methods entries for sighashes

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### `invoke`, `sinvoke`, and `call`

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### `static_assert` and `static_require`

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

### Havocing `calldataarg` variables

```{todo}
finish
```

```{todo}
If you do not change this, you will see the following error:
```

