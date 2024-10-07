(equivcheck-intro)=
The Certora Equivalence Checker
===============================

This chapter describes how one can use the Certora Prover to
  check the equivalence of two smart contract functions.

```{note}
Currently the equivalence checker only compares two `pure` functions,
  but we are actively working to develop an
  equivalence checker for non-`pure` functions as well.
```

The equivalence checker front-end automatically generates (1) a
  CVL spec to check if two functions are equivalent, and, (2) a
  configuration file (`.conf`) for running the Certora Prover.

## Installation

The equivalence checker is part of the `certora-cli` package; see {ref}`installation`.


(equivalence-checker-example)=
## Example

Consider two contracts, `BasicMathGood.sol` and `BasicMathBad.sol` shown
  below with two functions, `add` and `add_mult`.

```solidity
contract BasicMathGood {
    function add(uint256 a, uint256 b) public pure returns(uint256) {
        return a + b;
    }
}

contract BasicMathBad {
    function add_uncheck(uint256 a, uint256 b) public pure returns(uint256) {
        unchecked {
            return a * b;
        }
    }
}
```

We are interested in checking the equivalence of `add` and `add_uncheck`.
While this is a simple case,
  you can imagine scenarios where
  the functions are more complex.
Equivalence checking can be used to check whether two functions that
  may be implemented differently, are still semantically equivalent.
The following sections describe how to use the tool.

## Usage

`certoraEqCheck` can be run either in default (`def`) mode,
 in which the user must supply all the required information as
 command line arguments (see below),
 or in a `conf` mode where the user supplies a
 Certora Prover `conf` file along with additional arguments.

### Default mode

To run the equivalence checker in default mode,
  use `certoraEqCheck`:

```bash
certoraEqCheck def "path_to_file:contract:function:solc" "path_to_file:contract:function:solc"
```

For the functions in {ref}`equivalence-checker-example`, this would look as follows:

```bash
certoraEqCheck def Test/EqCheck/BasicMathGood.sol:add:solc8.0 Test/EqCheck/BasicMathBad.sol:add_pass:solc8.0
```

In the above example, `solc` is the name of the executable
  for the Solidity compiler version you are using.
The Solidity compilers do not need to be the same for both arguments to
 `certoraEqCheck`, it only need to be appropriate for the given contract.
Also note how
  the contract field can be omitted if the contract name is the same
  the file name.


### Configuration mode

To run the equivalence checker in the configuration mode,
  use `certoraEqCheck` as follows:

```bash
certoraEqCheck conf <path_to_conf>.conf contract:function contract:function
```

For the functions in {ref}`equivalence-checker-example`, this would be:

```bash
   certoraEqCheck conf Test/EqCheck/testGood.conf BasicMathGood:add BasicMathBad:add_mult
```

where `testGood.conf` is the standard Certora configuration file
  and contains:

```json
{
    "disable_local_typechecking": true,
    "files": ["BasicMathGood.sol", "BasicMathBad.sol"],
    "msg": "Equivalence Check",
    "optimistic_loop": true,
    "loop_iter": "4",
    "process": "emv",
    "send_only": true,
    "short_output": true,
    "rule_sanity": "basic",
    "solc": "solc8.0",
    "solc_optimize": "200",
    "server": "staging",
    "prover_version": "master"
}
```

```{note}
Use {ref}`--precise_bitwise_ops` if you are comparing functions with bitwise operations.
This will slow down the tool slightly,
but ensure that the results are sound.
```

`certoraEqCheck` produces two files that are then used to run the
  Certora Prover automatically.
The first one is a CVL specification file, whose content
  in the case of the example shown here is:

```
  using BasicMathBad as B;

// sets everything but the callee the same in two environments
function e_equivalence(env e1, env e2) {
    require e1.msg.sender == e2.msg.sender;
    require e1.block.timestamp == e2.block.timestamp;
    require e1.msg.value == e2.msg.value;
    // require e1.msg.data == e2.msg.data;
}

rule equivalence_of_revert_conditions()
{
    bool add_revert;
    bool add_mult_revert;
    // using this as opposed to generating input parameters is experimental
    env e_add; calldataarg args;
    env e_add_mult;
    e_equivalence(e_add, e_add_mult);

    add@withrevert(e_add, args);
    add_revert = lastReverted;

    B.add_mult@withrevert(e_add_mult, args);
    add_mult_revert = lastReverted;

    assert(add_revert == add_mult_revert);
}

rule equivalence_of_return_value()
{
    uint256 add_uint256_out0;
    uint256 add_mult_uint256_out0;

    env e_add; calldataarg args;
    env e_add_mult;

    e_equivalence(e_add, e_add_mult);

    add_uint256_out0 = add(e_add, args);
    add_mult_uint256_out0 = B.add_mult(e_add_mult, args);

    assert(add_uint256_out0 == add_mult_uint256_out0);
}
```

The second one is a standard Certora `conf` file:

```
{
    "disable_local_typechecking": true,
    "files": [
        "Test/EqCheck/BasicMathGood.sol",
        "Test/EqCheck/BasicMathBad.sol"
    ],
    "msg": "EquivalenceCheck of add and add_mult",
    "optimistic_loop": true,
    "loop_iter": "4",
    "process": "emv",
    "send_only": true,
    "short_output": true,
    "rule_sanity": "basic",
    "server": "staging",
    "prover_version": "master",
    "solc_optimize": "200",
    "verify": "BasicMathGood:Test/EqCheck/add_to_add_mult_equivalence.spec",
    "solc": "solc8.0"
}
```

The script then invokes the Certora Prover using this `conf` file.
