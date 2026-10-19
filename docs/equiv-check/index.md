(equivcheck-intro)=
Concord: The Certora Equivalence Checker
========================================

Concord checks whether two implementations of the same external function
  behave identically.
It is useful for validating refactors, gas optimizations, and compiler or
  compiler-setting changes.

```{warning}
Concord is experimental. Treat its results as a strong signal, not as a
  replacement for a full specification.
```

## What "equivalent" means

Concord starts both contracts in the same state, calls the chosen function in
  each with the same calldata, and checks that the two executions cannot be
  told apart.

Both executions start with identical:
- calldata,
- environment (`msg.sender`, `msg.value`, block variables, and so on),
- storage and transient storage, compared slot by slot,
- immutables, balances, and contract address.

Concord then checks that, on every input:
- both functions make the same external calls, in the same order, with the
  same target, value, and calldata,
- both functions emit the same events, in the same order, with the same topics
  and data,
- both functions revert, or neither does, and the returned or revert data is
  identical,
- both functions leave storage in the same state.

Because storage is compared slot by slot, the two contracts must use the same
  storage layout.
Gas usage is not compared.

## Installation

Concord is part of the `certora-cli` package; see {ref}`installation`.
Concord does not have its own command yet.
Run it as a Python module:

```bash
python3 -m certora_cli.certoraConcord <args>
```

## Usage

Concord takes exactly two contracts and one method:

```bash
python3 -m certora_cli.certoraConcord Original.sol Refactored.sol \
    --check_method "deposit(uint256)"
```

- **The two contracts.** Pass each contract as `path/to/File.sol:ContractName`.
  You can drop `:ContractName` when the contract has the same name as its file.
  Both contracts can be in the same file.
- **`--check_method`.** Give the method's full ABI signature, without a
  contract prefix, for example `transfer(address,uint256)`.
  The method must exist in both contracts with the same signature.

As with the Certora Prover, you can put the arguments in a `.conf` file:

```json
{
    "files": [
        "Original.sol",
        "Refactored.sol"
    ],
    "check_method": "deposit(uint256)",
    "solc": "solc8.30",
    "msg": "Concord: Original vs Refactored deposit"
}
```

```bash
python3 -m certora_cli.certoraConcord concord.conf
```

Most standard EVM options work with Concord, for example
  {ref}`--solc`, {ref}`--solc_optimize`, {ref}`--compiler_map`,
  {ref}`--loop_iter`, and {ref}`--optimistic_loop`.
CVL-specific options are rejected, including {ref}`--verify`,
  {ref}`--rule_sanity`, {ref}`--link`, and {ref}`--method`.
Use `--check_method` instead of `--method`.

Only Solidity is supported.
Vyper and Rust contracts are not.

(equivalence-checker-example)=
## Example

`Refactored` rewrites `deposit` with compound assignments:

```solidity
contract Original {
    mapping(address => uint256) public balances;
    uint256 public total;

    event Deposit(address indexed who, uint256 amount);

    function deposit(uint256 amount) external {
        require(amount > 0, "zero");
        balances[msg.sender] = balances[msg.sender] + amount;
        total = total + amount;
        emit Deposit(msg.sender, amount);
    }
}

contract Refactored {
    mapping(address => uint256) public balances;
    uint256 public total;

    event Deposit(address indexed who, uint256 amount);

    function deposit(uint256 amount) external {
        require(amount > 0, "zero");
        balances[msg.sender] += amount;
        total += amount;
        emit Deposit(msg.sender, amount);
    }
}
```

Running Concord on `deposit(uint256)` produces a single rule,
  `Equivalence of Original and Refactored on deposit(uint256)`.
The rule passes if the two functions are equivalent.

Suppose `Refactored` replaced the `require` with a custom error, for example
  `if (amount == 0) revert ZeroAmount();`.
The two functions would no longer be equivalent: both revert on the same
  inputs, but the revert data differs.
Concord would report a counterexample.

## Reading counterexamples

When the rule fails, Concord shows the following:
- the concrete calldata and environment that expose the difference,
- the external calls and events each function produced before they diverged,
- the first difference.

The first difference is one of the following:
- an event or call that appears in one function but not the other,
- two events or calls that differ,
- different return or revert data,
- a storage slot that ends with different values.

## Tips

- **Internal functions.** Concord automatically finds internal functions that
  appear in both contracts with the same signature.
  It proves each pair equivalent separately, then reuses that result.
  Keeping shared helpers under the same name and signature helps Concord
  scale.
- **Loops.** Loops are unrolled up to {ref}`--loop_iter`, as in the Prover.
  Set it to a bound that covers the inputs you care about.
- **Bitwise operations.** If the functions use bitwise operations heavily,
  add {ref}`--precise_bitwise_ops` for sound results.
  This slows the check down.

## Legacy tool: `certoraEqCheck`

Older versions of this page described `certoraEqCheck`.
That tool is still shipped, but it only handles `pure` functions.
It works by generating a CVL spec and running the Prover on it.
Use Concord for new work.
