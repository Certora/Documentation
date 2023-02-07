# Generating Mutations

This is a mutation generator for Solidity.
It takes as input a solidity source file (or a configuration file as you can see below)
  and produces a set of uniquely mutated solidity source files which are, by default, dumped in
  the `out/` directory.
The source is [publicly available](https://github.com/Certora/gambit).

## Installing Gambit
- Gambit is implemented in Rust which you can download [here](https://www.rust-lang.org/tools/install).
- To run Gambit, do the following:
   - `git clone git@github.com:Certora/gambit.git`
   - Install by running `cargo install --path .` from the `gambit/` directory after you clone the repository. This will add the Gambit binary to your `.cargo` directory.
   - Alternatively, you can also build Gambit by running `cargo build --release` from the `gambit/` directory.
- You will need OS specific binaries for various versions of Solidity. You can download them [here](https://github.com/ethereum/solc-bin). Make sure you add them to your `PATH`.

## Users
- If you installed Gambit using `cargo install --path .` described above,
  you can learn how to use Gambit by running `gambit mutate -h`.
- If you went for a local build, you can run `cargo gambit-help` for help.
- You can print log messages by setting the environment variable
  `RUST_LOG` (e.g., `RUST_LOG=info cargo gambit ...`).

`cargo gambit-help` will show you the following message
  that lists all the command line arguments that Gambit accepts.
Some of the simple arguments are `num-mutants (default 5)`
  which lets you control the number of mutants you want to generate,
  the `seed (default 0)` that controls
  the randomization of the generated mutants,
  and `outdir (default out)` that lets you choose
  where you want to dump the mutant files.

```
Command line arguments for running Gambit. Following are the main ways to run it.

1. cargo gambit path/to/file.sol: this will apply all mutations to file.sol.

2. cargo run --release -- mutate -f path/to/file1.sol -f path/to/file2.sol: this will apply all mutations to file1.sol and file2.sol.

3. cargo gambit-cfg path/to/config.json: this gives the user finer control on what functions in which files, contracts to mutate using which types of mutations.

Usage: gambit mutate [OPTIONS]

Options:
  -j, --json <JSON>
          Json file with config

  -f, --filename <FILENAME>
          File to mutate

  -n, --num-mutants <NUM_MUTANTS>
          Number of mutants
          [default: 5]

  -o, --outdir <OUTDIR>
          Directory to store all mutants
          [default: out]

  -s, --seed <SEED>
          Seed for random number generator
          [default: 0]

      --solc <SOLC>
          Solidity binary name, e.g., --solc solc8.10, --solc 7.5, etc
          [default: solc]

      --solc-basepath <SOLC_BASEPATH>
          Basepath argument to solc

      --solc-allowpaths <SOLC_ALLOWPATHS>
          Allowpath argument to solc

      --solc-remapping <SOLC_REMAPPING>
          Solidity remappings

  -h, --help
          Print help (see a summary with '-h')
```

These flags are explained in the following section.

### Examples of How to Run Gambit
You can run Gambit on a single file with various additional arguments.
Gambit also accepts a configuration file as input where you can
  specify which files you want to mutate and using which mutations.
You can also control which functions and contracts you want to mutate.
**Configuration files are the recommended way for using Gambit.**

#### Running Gambit on a Single Solidity File.
We recommend this approach only when you have a simple project with few files
  and no complex dependencies or mutation requirements.

- `cargo gambit benchmarks/RequireMutation/RequireExample.sol` is an example
  of how to run with a single Solidity file.
- For projects that have complex dependencies and imports, you will likely need to:
   * pass the `--base-path` argument for `solc` like so: `cargo gambit path/to/file.sol --solc-basepath base/path/dir/.`
   * or remappings like so: `cargo gambit path/to/file.sol --solc-remapping @openzepplin=... --solc-remapping ...`
   * or the `--allow-paths` argument like so: `cargo gambit path/to/file.sol --solc-allowpaths @openzepplin=... --solc-allowpaths ...`


#### Running Gambit Through a Configuration File.
This is the recommended way to run Gambit.
This approach allows you to control and localize
  mutation generation and is much easier
  to use than passing too many command line flags.

- `cargo gambit-cfg benchmarks/config-jsons/test1.json`  -
  this is how you run the tool if you want to use Gambit's
  configuration file option that lets you control how the mutants are generated.
  Examples of some configuration files can be
  found under `benchmarks/config-jsons`.

- If you are using a configuration file, you can also pass various Solidity arguments as fields, e.g.,
```
{
  "filename": "path/to/file.sol",
  "solc-basepath": "base/path/dir/."
}
```
or
```
{
    "filename": "path/to/file.sol",
    "remappings": [
        "@openzeppelin=PATH/TO/node_modules/@openzeppelin"
    ]
}
```
or
```
{
    "filename": "path/to/file.sol",
    "solc-allowpaths": [
        "path1",
        "path2"
    ]
}
```

#### Configuring the Set of Mutations, Functions, and Contracts
If you are using Gambit through a configuration file,
  you can localize the mutations to some
  functions and contracts.
You can also choose which mutations you want.
Here is an example that shows how to configure these options.
```
[
    {
        "filename": "Foo.sol",
        "contract": "C",
        "functions": ["bar", "baz"],
        "solc": "solc5.12"
    },
    {
        "filename": "Blip.sol",
        "contract": "D",
        "functions": ["bang"],
        "solc": "solc5.12"
        "mutations": [
          "binary-op-mutation",
          "swap-arguments-operator-mutation"
        ]
    }
]
```

This configuration file will perform all mutations on `Foo.sol`'s
  functions `bar` and `baz` in the contract, `C` and
  only `binary-op-mutation` and `swap-arguments-operator-mutation` mutations
  on the function `bang` in the contract, `D`.
Both will compile using the Solidity compiler version `solc5.12`.

### Output of Gambit
Gambit produces a set of uniquely mutated solidity source
  files which are, by default, dumped in
  the `out/` directory.
Each mutant file has a comment that describes the exact mutation that was done.
For example, one of the mutant files for
  `benchmarks/10Power/TenPower.sol` that Gambit generated contains:
```
/// SwapArgumentsOperatorMutation of: uint256 res = a ** decimals;
uint256 res = decimals ** a;
```

## Mutation Types
At the moment, Gambit implements the following mutations:
- Binary Operator Mutation: change a binary operator `bop` to `bop'`
- Unary Operator Mutation: change a unary operator, `uop` to `uop'`
- Require Condition Mutation: negate the condition
- Assignment Mutation: change the RHS
- Delete Expression Mutation: comment out some expression
- Function Call Mutation: randomly replace a function call with one of its operands
- If Statement Mutation:  negate the condition
- Swap Function Arguments Mutation: swap the arguments to a function
- Swap Operator Arguments Mutation: swap the operands of a binary operator
- Swap Lines Mutation: swap two lines
- Eliminate Delegate Mutation: replace a delegate call by `call`

You can see simple examples of them [here](https://github.com/Certora/gambit/tree/master/benchmarks).
As you can imagine, many of these mutations may lead to invalid mutants
  that do not compile.
At the moment, Gambit simply compiles the mutants and only keeps valid ones --
  we are working on using additional type information to reduce the generation of
  invalid mutants by constructions.
You can see the implementation details
  in [mutation.rs](https://github.com/Certora/gambit/blob/master/src/mutation.rs).
