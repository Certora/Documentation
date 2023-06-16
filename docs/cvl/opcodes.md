EVM Opcode hooks
================

### Background
The EVM's instruction set is tightly integrated with the specifics of the EVM environment.
CVL, which was designed to be as general-purpose as possible, with strong decoupling between the environment of the source programs and the spec language, does not allow controlling all aspects of the EVM environment.
In particular, CVL allows direct access to an environment `env` object for accessing the `msg.value`, `msg.sender`, `block.number`, and `block.timestamp` fields, which map to EVM instructions `CALLVALUE`, `CALLER`, `NUMBER` and `TIMESTAMP`, respectively.
As other fields, such as `CHAINID` are not directly accessible from the `env` object, the expressivity of specs may be limited.
It is however undesirable to expand the CVL `env` type with too many fields. For instance, usually, the `CHAINID` instruction would not return a different value between two Solidity calls to the same contract, even if they take two different environment variables.
Additionally, the scope of an `env` variable is a single function call, but it captures variables that are not necessarily scoped to a function call. `CHAINID` is not expected to change between two function calls.
In particular, the EVM instruction set is dynamic, and new instructions (opcodes) are added from time to time, and some may be removed.

To that end, hooks help us define speciailized behavior for every EVM instruction that accesses the VM internals in some non-trivial way.


### Hooking on opcodes
Currently, we support the following hook opcodes, named the same as their EVM instruction counterparts (with the exception of `CREATE1`, see below):
`ADDRESS`, `CALLER`,`CALLVALUE`,`ORIGIN`,`BALANCE`,`SELFBALANCE`,`NUMBER`,`TIMESTAMP`,`GASPRICE`,`GASLIMIT`,`GAS`, `COINBASE`, `DIFFICULTY`, `BASEFEE`, `MSIZE`,
`CHAINID`, `CODESIZE`, `CODECOPY`, `EXTCODESIZE`, `EXTCODECOPY`, `EXTCODEHASH`, `BLOCKHASH`
`CALL`,`CALLCODE`,`DELEGATECALL`,`STATICCALL`,`LOG0`,`LOG1`,`LOG2`,`LOG3`,`LOG4`, `CREATE1` (for the `CREATE` opcode), `CREATE2`, `REVERT`, `SELFDESTRUCT`

The pattern for each hook follows the arguments that are accepted by the instructions they model. 
Each hook is followed by a command block `{ ... }` where the instrumentation spec code is provided.
Some hooks have output values and some do not. Those that do have an output value, specify the type and name of a variable to bind to the output value after listing the arguments.
Most hooks are applied _after_ the appearance and execution of the instruction they model.
The only hooks that are applied _before_ are those for halting instructions such as `REVERT` and `SELFDESTRUCT`.

Below is the syntax for all opcode hook types, sans command block braces:
```{cvl}
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

### Missing instructions.
The standard stack-manipulating instructions `DUP*`, `SWAP*`, `PUSH*` and `POP` are not modeled.
`MLOAD`, `MSTORE`, `SLOAD`, and `SSTORE` will be available in a future version of the Prover.
Note that you can already hook on storage fields using storage patterns.