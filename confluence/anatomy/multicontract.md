Multicontract Hooks
===================

By default, a hook will operate on the "current contract" of the spec file. However, as it is possible to invoke functions from multiple contracts, it is also possible to write hooks for storage slots from different contracts. Suppose some contract `MyContract` has an inner contract `InnerContract`:

```solidity
contract MyContract {
  InnerContract c;
  ...
}
```

In our specification, we import this contract with a `using` statement, for example `using InnerContract as inner`. Because, in the specification language, contract instances are singleton, `inner == c`. Thus when we write hooks on `inner`, they will "trigger" any time the corresponding storage slot in `c` is modified. Such a hook might look like the following:

```cvl
hook Sload uint256 x inner.someStorageVariable[KEY uint256 k] STORAGE {
  ...
}
```
