(equivcheck-intro)=
Equivalence Checking
====================

Concord is Certora's equivalence checker for smart contracts. It takes two
contracts and one method that both contracts implement, and it proves that the
two methods behave the same on every input. If they do not, Concord shows an
input that makes them differ.

Typical uses:

- Check that a refactored or gas-optimized method still behaves like the
  original.
- Check that two compilers, or two compiler settings, produce equivalent
  bytecode for the same source.

```{warning}
Concord is experimental. Each run prints a warning that says so.
```

(equivcheck-install)=
## Installation

Concord is part of the `certora-cli` package. See {ref}`installation`. You run
it with the `certoraConcord` command. If your installation does not have that
command, run the module through the Python interpreter of your `certora-cli`
installation:

```bash
python -m certora_cli.certoraConcord <files> --check_method "<signature>"
```

(equivcheck-quickstart)=
## Quick start

Concord takes two inputs and the signature of the method to compare.

From Solidity source, name the two contracts in the usual `file:contract` form:

```bash
certoraConcord Token.sol:TokenV1 Token.sol:TokenV2 --check_method "transfer(address,uint256)"
```

From bytecode, give two files that hold only the runtime bytecode as a hex
string:

```bash
certoraConcord Counter.solc.hex Counter.solar.hex --check_method "increment(uint256)"
```

You can also put the same settings in a `.conf` file:

```json
{
    "files": [
        "Counter.solc.hex",
        "Counter.solar.hex"
    ],
    "check_method": "increment(uint256)"
}
```

```bash
certoraConcord Default.conf
```

(equivcheck-semantics)=
## What Concord compares

Concord runs the method of contract A and the method of contract B on the same
starting state, and then compares what each run did.

### Starting state

Both runs start with:

- the same calldata, which is arbitrary beyond the method selector,
- the same storage and the same transient storage,
- the same `address(this)`, `msg.sender`, `msg.value`, `tx.origin` and block
  values (for example `block.number` and `block.timestamp`),
- the same balance, nonce, code size and code hash for every account.

Immutable variables with the same name are assumed to have the same value.

### Compared behavior

If any of these differ between the two runs, Concord reports a difference:

- The outcome: one run returns and the other reverts.
- The return data, or the revert data.
- The emitted events, in order, with their topics and data.
- The external calls, in order, with the callee address, the value sent and
  the calldata.
- The final storage.

Concord compares events and external calls only on runs where neither method
reverts.

Concord matches external calls by position. The first external call in A and
the first external call in B get the same result, and so on. Concord then
proves that the calls themselves are equal.

### Behavior that is not compared

- Gas use.
- The kind of call (`CALL`, `STATICCALL` or `DELEGATECALL`).
- Final ETH balances.
- Final transient storage.

(equivcheck-inputs)=
## Inputs

### Solidity contracts

Give exactly two contracts. Concord compiles them like the Prover does, so the
usual compiler options apply, for example {ref}`--solc` and
{ref}`--compiler_map`.

### Runtime bytecode files

Give exactly two files. Each file holds the runtime (deployed) bytecode of one
contract as a hex string, with or without a `0x` prefix. Concord recognizes
these files by their content, so any file extension works.

To get the runtime bytecode from `solc`:

```bash
solc --bin-runtime -o out/ Counter.sol
```

To get it from `solar`:

```bash
solar -Zcodegen --emit bin-runtime Counter.sol | jq -r '.contracts["Counter.sol:Counter"]["bin-runtime"]'
```

Concord names each contract after its file, without the last extension. It
replaces characters that are not allowed in a contract name with `_`. For
example, `Counter.solar.hex` becomes `Counter_solar`. If the two names are the
same, Concord adds the position of the file, for example `Counter_0` and
`Counter_1`.

The first file is contract A, and the second file is contract B.

A bytecode file has no ABI. Concord finds the method by the selector of the
`check_method` signature. For the same reason, the counterexample does not
decode the method arguments.

You cannot mix bytecode files with Solidity files in one run.

(equivcheck-options)=
## Options

### `check_method`

The method to compare, as an ABI signature with parameter types and no spaces,
for example `"transfer(address,uint256)"`. Do not add a contract name. This
option is mandatory, and Concord checks one method per run. To compare several
methods, run Concord once for each method.

Contract B must have a method with the same selector as the method in contract
A. As a result, the two methods must have the same name and parameter types.

### Prover options

Concord accepts most Prover options. Some options do not apply to equivalence
checking, and Concord refuses them:

- Rule and method selection: `verify`, `method`, `exclude_method`,
  `exclude_rule`, `parametric_contracts`.
- Sanity, coverage and multiple results: `rule_sanity`, `project_sanity`,
  `coverage_info`, `foundry`, `independent_satisfy`, `multi_assert_check`,
  `multi_example`.
- Linking and dispatch: `link`, `struct_link`, `address`,
  `contract_extensions`, `contract_recursion_limit`,
  `optimistic_contract_recursion`, `dynamic_bound`, `dynamic_dispatch`,
  `prototype`.

Use {ref}`--prover_args` to pass these settings to Concord:

`-equivalenceIncludeDelegates true`
: Inlines delegate calls. By default, Concord treats a delegate call like any
  other external call.

`-equivTraceFile <file>`
: Writes the explanation of a counterexample to `<file>` instead of the
  console.

`-equivalenceUniversalCopyTracking true`
: Tracks all long memory copies precisely. This can fix a false difference,
  but it makes the formulas larger and the run slower.

(equivcheck-results)=
## Reading the results

The result has one rule, named after the two contracts and the method:

```text
Equivalence of Counter_solc and Counter_solar on increment(uint256)
```

If the methods are equivalent, the rule is verified. If they are not, the rule
is violated with the message `traces equal`, or with the message
`storage equal post execution` when only the final storage differs.

Concord checks calls, events and the result in separate steps, and it refines
false counterexamples. Because of this, it can print several intermediate
`Verified` and `Violated` lines for the same rule while it runs. Only the final
results table counts.

For a violation, Concord explains the difference. The explanation shows the
input (the sender, the call value and the method arguments), the events before
the difference, and one of these messages:

- `The methods performed different actions`, followed by the action in each
  method.
- `<method> included an event *missing* in <method>`.
- `The executions left storage in conflicting states`, followed by the value of
  the storage slot in each contract.

(equivcheck-limits)=
## Limitations

- Concord compares one method per run.
- The two methods must have the same selector.
- Concord compares storage slot by slot, so the two contracts must use the same
  storage layout.
- Concord does not run a constructor. It compares the deployed code of the two
  contracts.
- Vyper contracts are not supported.
- With bytecode inputs, counterexamples have no source mapping, and Concord
  cannot use the source to simplify the problem. Large methods can be slower to
  check than the same methods given as source.
