CVL commands
============

*   `foo@withrevert(args)` or `invoke foo(args)`
    
    \- simulate a function named `foo` with arguments `args` allowing it to revert.
    
*   `foo(args)`or `sinvoke foo(args)`
    
    \- simulate a function named `foo` with arguments `args` and assume that it does not revert. This syntax is equivalent to:

```cvl
foo@withrevert(arg); // same as invoke foo(arg)
require !lastReverted;
```

