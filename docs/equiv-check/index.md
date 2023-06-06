(equivcheck-intro)=
Equivalence Checking Using the Certora Prover
=================================

This chapter describes how one can use the Certora Prover to
  check the equivalence of two smart contract functions.

```{note}
Currently the equivalence checker only compares two `pure` functions, but we are actively working to develop an equivalence checker for non-`pure` functions as well.
```

The equivalence checker front-end automatically generates (1) a
  CVL spec to check if two functions are equivalent, and, (2) a
  configuration file (`.conf`) for running the Certora Prover.

## Installation

The equivalence checker is part of the `certora-cli` package; see {ref}`installation`.


(example)=
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
    function add_mult(uint256 a, uint256 b) public pure returns(uint256) {
        return a * b;
    }
}
```

We are interested in checking the equivalence of `add` and `add_mult`.
In this simple case, these two functions are clearly not equivalent
  but you can imagine scenarios where
  the functions are more complex.
Equivalence checking can be used to check whether two functions that
  may be implemented differently, are still semantically equivalent.

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

For the functions in {ref}`example`, this would look like so:

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
  use `certoraEqCheck` like so:

```bash
certoraEqCheck conf <path_to_conf>.conf contract:function contract:function
```

For the functions in {ref}`example`, this would look like so:

```bash
   certoraEqCheck conf Test/EqCheck/testGood.conf BasicMathGood:add BasicMathBad:add_mult
```

where `testGood.conf` contains the following configuration:

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
Use `--bitvector` if you are comparing functions with bitwise operations.
This will slow down the tool slightly,
but ensure that the results are sound.
```
