(hooks)=
Hooks
=====

Hooks are used to attach CVL code to certain low-level operations, such as
loads and stores to specific storage variables.

Each hook contains a pattern that describes what operations cause the hook to
be invoked, and a block of code that is executed when the contract performs
those operations.

The remainder of this document describes the operation of hooks in detail.  For
examples of idiomatic hook usage, see {ref}`tracking-changes` and
{ref}`using-opcodes`.

```{contents}
```

Syntax
------

```
hook ::= "hook" pattern block

pattern ::= "Sstore" access_path param [ "(" param ")" ] "STORAGE"
          | "Sload"  param access_path "STORAGE"
          | opcode   [ "(" params ")" ] [ param ]

access_path ::= id
              | "(" "slot" number ")"
              | access_path "." id
              | access_path "[" "KEY"   basic_type id "]"
              | access_path "[" "INDEX" basic_type id "]"
              | access_path "." "(" "offset" number ")"

opcode ::= "ALL_SLOAD" | "ALL_SSTORE" | ... TODO

param  ::= evm_type id
```

See {doc}`statements` for information about the `statement` production; see
{doc}`types` for the `evm_type` production; see {doc}`basics` for the `number`
production.

(load-hooks)=
(store-hooks)=
Load and store hooks
--------------------

```{todo}
Syntax for load and store hooks
```

Load hooks are executed before a read from a specific location in storage, while
store hooks are executed before a write to a specific location in storage.

The locations to be matched are given by an access path, such as a contract
variable, array index, or a slot number.  See {ref}`access-paths` below for
information on the available access paths.

A load pattern contains the keyword `Sload`, followed by the type and name of a
variable that will hold the loaded value, followed by an access path indicating
the location that is read.  Load patterns must end with the keyword `STORAGE`.

For example, here is a load hook that will execute whenever a contract reads the
value of `C.owner`:
```cvl
hook Sload address o C.owner STORAGE { ... }
```
Inside the body of this hook, the variable `o` will be bound to the value that
was read.

A store pattern contains the keyword `Sstore`, followed by an access path
indicating the location that is being written to, followed by the type and name
of a variable to hold the value that is being stored.  Optionally, the pattern
may also include the type and name of a variable to store the previous value
that is being overwritten.  Store patterns must end with the keyword `STORAGE`.

For example, here is a store hook that will execute whenever a contract writes
the value of `C.totalSupply`:
```cvl
hook Sstore C.totalSupply uint ts (uint old_ts) STORAGE { ... }
```
Inside the body of this hook, the variable `ts` will be bound to the value that
is being written to the `totalSupply` variable, while `old_ts` is bound to the
value that was stored there previously.

If you do not need to refer to the old value, you can omit the variable
declaration for it.  For example, the following hook only binds the new value
of `C.totalSupply`:
```cvl
hook Sstore C.totalSupply uint ts STORAGE { ... }
```

```{todo}
Is this correct?

If there is a store hook that binds the old value of the variable, then the
Prover will add a load instruction that reads the value immediately before the
store instruction.  Therefore, if a path has both a load hook and a store hook,
they will both be executed when the contract performs a store.
```

(access-paths)=
### Access paths

The patterns for load and store hooks are fine-grained; they allow you to hook
on accesses to specific contract variables or specific array, struct, or
mapping accesses.

Storage locations are designated by "access paths".  An access path
starts with either the name of a contract field, or a [slot number][storage-layout].

```{todo}
is this correct?

Contract fields must be qualified by the contract that defines them (e.g.
`Contract.field`).  If the contract name is omitted, it defaults to
`currentContract`.
```

```{todo}
Does the contract need to be the contract that defines the field, or can it be
an inheriting contract?  What happens if there are multiple variables with the
same name (because of inheritance)?
```

[storage-layout]: https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html

If the indicated location holds a struct, you can refer to a specific field of
the struct by appending `.<field-name>` to the path.  For example, the following
hook will execute on every store to the `balance` field of the struct `C.owner`:
```cvl
hook Sstore C.owner.balance uint b STORAGE { ... }
```

If the indicated location holds an array, you can refer to an arbitrary element
of the array by appending `[INDEX uint <variable>]`.  This pattern will match
any store to an element of the array, and will bind the named variable to the
index of the access.  For example, the following hook will execute on any write
to the array `C.entries` and will update the corresponding entry of the ghost
mapping `_entries` to match:
```cvl
hook Sstore C.entries[INDEX i] uint e STORAGE {
    _entries[i] = e;
}
```

Similarly, if the indicated location holds a mapping, you can refer to an
arbitrary entry by appending `[KEY <type> <variable>]`.  This pattern will
match any write to the mapping, and will bind the named variable to the key.
For example, the following hook will execute on any write to the mapping
`C.balances`, and will update the `_balances` ghost accordingly:

```cvl
hook Sstore C.balances[KEY address user] uint balance STORAGE {
    _balances[user] = balance;
}
```

Finally, there is the low-level access pattern `<base>.(offset <n>)` for matching
loads and stores that are a specific number of bytes from the
base.  For example, the following hook will match writes to the third or fourth
byte of slot 1 (these two bytes are matched because the type of the variable is
`uint16`:

```cvl
hook Sstore (slot 1).(offset 2) uint16 b STORAGE { ... }
```

These different kinds of paths can be combined.  For example, the following
hook will execute whenever the contract writes to the `balance` field of a
struct in the `users` mapping of contract `C`:
```cvl
hook C.users[KEY address user].balance uint v (uint old_value) STORAGE { ... }
```
Inside the body of the hook, the variable `user` will refer to the address that
was used as the key into the mapping `C.users`; the variable `v` will contain
the value that is written, and the variable `old_value` will contain the value
that was previously stored there.

```{note}
The only available access paths for `solc` versions 5.17 and older are `slot`
and `offset` paths.
```

### Access path caveats

```{todo}
information on what kind of funny business happens if people do their own memory
management, and about the disjointness of arrays and so forth

How can you tell if an analysis failed and your hooks didn't apply?
```

(rawhooks)=
### Hooking on all loads or stores

Load and store hooks apply to reads and writes to specific storage locations.
In some cases, it is useful to instrument every load or store, regardless of
the location.

The `ALL_SLOAD` and `ALL_SSTORE` opcode hooks are used for this purpose; they
will be executed on every load and store instruction (in all contracts)
respectively.  See {ref}`opcode-hooks` below for the general syntax of opcode
hooks.

The `ALL_SLOAD` opcode hook takes one input `uint` argument containing the slot
number of the load instruction, and has one `uint` output containing the value
that is loaded from the slot.  For example:
```cvl
hook ALL_SLOAD(uint slot) uint val { ... }
```

The `ALL_SSTORE` opcode hook takes two input `uint` arguments; the first is the
slot number of the store instruction, and the second is the value being stored.
For example:
```cvl
hook ALL_SSTORE(uint slot, uint val) { ... }
```

```{note}
The storage splitting optimization must be disabled using the
{ref}`-enableStorageSplitting` option in order to use the `ALL_SLOAD` or
`ALL_SSTORE` hooks.
```

If a load instruction matches an `Sload` hook pattern and there is also an
`ALL_SLOAD` hook, then both hooks will be executed; the `Sload` hook will apply
first, and then the `ALL_SLOAD` hook.

Similarly, if a store would trigger both an `Sstore` pattern and an `ALL_SSTORE`
pattern, the `Sstore` hook would be executed, followed by the `ALL_SSTORE` hook.

```{note}
Just like the usual opcode hooks, the raw storage hooks are applied on all
contracts.  This means that a storage access on _any_ contract will trigger the
hook.  Therefore, in a rule that models calls to multiple contracts, if two
contracts are accessing the same slot the same hook code will be called with
the same slot number.
```

(opcode-hooks)=
EVM opcode hooks
----------------

Opcode hooks are executed just after[^before-hooks] a contract executes a
specific [EVM opcode][evm-opcodes].  An opcode hook pattern consists of the
name of the opcode, followed by the inputs to the opcode (if any), followed by
the type and variable name for the output (if any).

[^before-hooks]: For halting instructions such as `REVERT` and `SELFDESTRUCT`,
  the hook is executed before the instruction instead of after.

[evm-opcodes]: https://ethereum.org/en/developers/docs/evm/opcodes/

For example, the following hook will execute immediately after any contract
executes the `EXTCODESIZE` instruction:
```cvl
hook EXTCODESIZE(address addr) uint v { ... }
```
Within the body of the hook, the `addr` variable will be bound to the address
argument to the opcode, and the variable `v` will be bound to the returned value
of the opcode.

```{note}
Opcode hooks are applied to _all_ contracts, not just the main contract under
verification.
```

Opcode hooks have the same names, arguments, and return values as the
corresponding [EVM opcodes][evm-opcodes], with the exception of the `CREATE1`
hook, which corresponds to the `CREATE` opcode.

Below is the set of supported opcode hook patterns:
```cvl
hook ADDRESS address v

hook BALANCE(address addr) uint v

hook ORIGIN address v

hook CALLER address v

hook CALLVALUE uint v

hook CODESIZE uint v

hook CODECOPY(uint destOffset, uint offset, uint length)

hook GASPRICE uint v

hook EXTCODESIZE(address addr) uint v

hook EXTCODECOPY(address b, uint destOffset, uint offset, uint length)

hook EXTCODEHASH(address a) bytes32 hash

hook BLOCKHASH(uint n) bytes32 hash

hook COINBASE address v

hook TIMESTAMP uint v

hook NUMBER uint v

hook DIFFICULTY uint v

hook GASLIMIT uint v

hook CHAINID uint v

hook SELFBALANCE uint v

hook BASEFEE uint v

hook MSIZE uint v

hook GAS uint v

hook LOG0(uint offset, uint length)

hook LOG1(uint offset, uint length, bytes32 t1)

hook LOG2(uint offset, uint length, bytes32 t1, bytes32 t2)

hook LOG3(uint offset, uint length, bytes32 t1, bytes32 t2, bytes32 t3)

hook LOG4(uint offset, uint length, bytes32 t1, bytes32 t2, bytes32 t3, bytes32 t4)

hook CREATE1(uint value, uint offset, uint length) address v

hook CREATE2(uint value, uint offset, uint length, bytes32 salt) address v 

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc

hook CALLCODE(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc

hook DELEGATECALL(uint g, address addr, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc

hook STATICCALL(uint g, address addr, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc

hook REVERT(uint offset, uint size)

hook SELFDESTRUCT(address a)
```

% Note: I'm removing the following section and just replacing it by saying that
% the above list are the only supported codes, since there seem to be many other
% unsupported codes (e.g. `ADD` and friends)
% ### Unsupported opcodes
% 
% The standard stack-manipulating instructions `DUP*`, `SWAP*`, `PUSH*` and `POP`
% are not modeled.  `MLOAD` and `MSTORE` are also not modeled.

### Known inter-dependencies and common pitfalls

Hooks are instrumented for every appearance of the matching instruction in the
bytecode, as generated by a high-level source compiler such as the Solidity
compiler.  The behavior of the bytecode may sometimes be surprising.  For
example, every Solidity method call to a non-payable function will contain an
early call to `CALLVALUE` to check that it is 0. This means that every time a
non-payable Solidity function is invoked, the `CALLVALUE` hook will be
triggered.

Hook bodies
-----------

The body of a hook may contain almost any CVL code, including calls to other
Solidity functions.  The only exception is that hooks may not contain
parametric method calls.  Expressions in hook bodies may reference variables
bound by the hook pattern.

````{todo}
Questions about the following:
 - does this have to do with the fact that the call is from a hook, or from a
   summary?
 - for example, if a hook calls a contract function that performs a store that
   has a hook on it, would the inner hook get called?  Similarly, if a contract
   calls a summarized function and the summary calls a contract function that
   then performs a store with a hook, does the hook execute?


Hooks are not recursively applied.
That is, if a hook calls a Solidity function `foo`, and the Solidity function
call triggers a summarization that also calls another Solidity function `bar`,
then any hooks that would have applied to `bar` would not be instrumented from
this context.

For example, given the following contract and specification, the rule `check` will fail.

```solidity
contract C {
  uint public x;
  function main() external {
    x = 3;
  }

  function foo() external {
    myInternalFoo();
  }

  function myInternalFoo() internal {
    // ...
  }

  function bar() external {
    x = 5;
  }

}
```

```cvl
methods {
  function myInternalFoo() internal => callBar();
  function x() external returns (uint256) envfree;
}

function callBar() {
  env e;
  bar(e);
}

ghost uint xGhost;
hook Sstore x uint v STORAGE {
  xGhost = v;
  env e;
  foo(e);
}

rule check() {
  env e;
  main(e);
  assert xGhost == x(); // will fail - bar()'s hooks are not instrumented. xGhost == 3 while x == 5
}
```

````

