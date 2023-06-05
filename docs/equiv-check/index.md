(equivcheck-intro)=

=================================

This chapter describes how one can use the Certora Prover to
  check the equivalence of two pure functions.

```{note}
We are working on extending this to support functions with side effects;
  for the remaining documentation,
  we assume a user is interested in running the equivalence checker
  for two pure functions which may belong to the same contract
  or two different contracts.
```

The equivalence checker front-end automatically generates (1) a
  CVL spec to check if two functions are equivalent, and, (2) a
  configuration file (`.conf`) for running the Certora Prover.

## Installation

The front-end script, `CertoraEqCheck`,
  should be available as part installing `certora-cli`.

## Usage

`CertoraEqCheck` can be run either in default (`def`) mode,
 in which the user must supply all the required information as
 command line arguments (see below),
 or in a `conf` mode where the user supplies a
 Certora Prover `conf` file along with additional arguments.

### Default mode

To run the equivalence checker in default mode,
  use `CertoraEqCheck` like so:

```bash
CertoraEqCheck def "path_to_file:contract:function:solc" "path_to_file:contract:function:solc"
```

For example:

```bash
CertoraEqCheck def Test/EqCheck/BasicMathGood.sol:add:solc8.0 Test/EqCheck/BasicMathBad.sol:add_pass:solc8.0
```

In the above example, `solc` is the name of the executable
  for the Solidity compiler version you are using.
The Solidity compilers do not need to be the same for both arguments to
 `CertoraEqCheck`, it only need to be appropriate for the given contract.
Also note that
  the contract field can be omitted if the contract name is the same
  the file name.


### Configuration mode

To run the equivalence checker in the configuration mode,
  use `CertoraEqCheck` like so:

```bash
CertoraEqCheck conf <path_to_conf>.conf contract:function contract:function
```

For example:

```bash
   CertoraEqCheck conf Test/EqCheck/testGood.conf BasicMathGood:add BasicMathBad:add_mult
```

In the above, `testGood.conf` contains the following:

```{note}
Use `--bitvector` if you are comparing functions with bitwise operations.
This will slow down the tool slightly,
but ensure that the results are sound.
```
