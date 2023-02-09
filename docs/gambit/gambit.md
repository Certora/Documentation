# Generating Mutations

This is a mutation generator for Solidity.
It takes as input a solidity source file (or a configuration file as you can see below)
  and produces a set of uniquely mutated solidity source files which are output in the `out/` directory by default.
The source is [publicly available](https://github.com/Certora/gambit).

## Installing Gambit
- Gambit is implemented in Rust, which you can download [here](https://www.rust-lang.org/tools/install).
- To run Gambit, do the following:
   - `git clone git@github.com:Certora/gambit.git`
   - Install by running `cargo install --path .` from the `gambit/` directory after you clone the repository. This will add the Gambit binary to your `.cargo` directory.
   - If you prefer to run Gambit without installing, you can also build it by running `cargo build --release` from the `gambit/` directory.
- You will need OS specific binaries for various versions of Solidity.
    The version of the binary will depend on your Solidity project.
    You can download them
    [here](https://github.com/ethereum/solc-bin). Make sure you add them to your `PATH`.

## Usage
- If you installed Gambit using `cargo install --path .` described above,
  you can learn how to use Gambit by running `gambit mutate -h`.
- If you went for a local build, you can run `cargo gambit-help` for help.
- You can print log messages by setting the environment variable
  `RUST_LOG` (e.g., `RUST_LOG=info cargo gambit ...`).
  This will show colored diffs of the mutants on your standard output.

`cargo gambit-help` will show you the following message
  that lists all the command line arguments that Gambit accepts.
Some of the simple arguments are `num-mutants (default 5)`
  which lets you control the number of mutants you want to generate,
  the `seed (default 0)` that controls
  the randomization of the generated mutants,
  and `outdir (default out)` that lets you choose
  where you want to output the mutant files.

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
You can run Gambit on a single solidity file with various additional arguments.
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
   * To specify the solidity [base path][basepath], pass the `--base-path` argument.  For example
   ```bash
   cargo gambit path/to/file.sol --solc-basepath base/path/dir/.
   ```
[basepath]: https://docs.soliditylang.org/en/v0.8.17/path-resolution.html#base-path-and-include-paths
   * To indicate where solidity should find libraries, you provide an [import remapping][remapping] to `solc` using the `--solc-remapping` argument.  For example:
```bash
cargo gambit path/to/file.sol --solc-remapping @openzepplin=node_modules/@openzeppelin --solc-remapping ...`
```
[remapping]: https://docs.soliditylang.org/en/v0.8.17/path-resolution.html#import-remapping
   * To include additional allowed paths,
   you provide solidity's [allowed paths][allowed] to `solc` using the `--allow-paths` argument.
   For example:
   ```bash
   cargo gambit path/to/file.sol --solc-allowpaths @openzepplin=... --solc-allowpaths ...
   ```
[allowed]: ttps://docs.soliditylang.org/en/v0.8.17/path-resolution.html#allowed-paths

(gambit-config)=
#### Running Gambit Through a Configuration File.
This is the recommended way to run Gambit.
This approach allows you to control and localize
  mutation generation and is easier
  to use than passing many command line flags.

To run gambit with a configuration file, simply pass the name of the `json` file:
```bash
cargo gambit-cfg benchmarks/config-jsons/test1.json`
```

The configuration file is a [json][json-spec] file containing the command line
arguments for `gambit` and additional configuration options.
For example, the following configuration is equivalent
to `gambit benchmarks/10Power/TenPower.sol --solc-remapping @openzepplin=node_modules/@openzeppelin`:

```json
{
    "filename": "benchmarks/10Power/TenPower.sol",
    "remappings: [
        "@openzeppelin=node_modules/@openzeppelin"
    ]
}
```

In addition to the specifying the command line arguments, you can list the
specific {ref}`types of mutations <mutation-types>` that you want to apply, the
specific functions you wish to mutate, and more.  See {ref}`gambit-config` for
more details, and [`benchmark/config-jsons` directory][config-examples] for
examples.

[json-spec]: https://json.org/
[examples]: https://github.com/Certora/gambit/blob/master/benchmarks/config-jsons/
[test6]: https://github.com/Certora/gambit/blob/master/benchmarks/config-jsons/test6.json


#### Configuring the Set of Mutations, Functions, and Contracts
If you are using Gambit through a configuration file,
  you can localize the mutations to some
  functions and contracts.
You can also choose which mutations you want (see {ref}`mutation-types` for the list of possible mutations).
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

(mutation-types)=
## Mutation Types
At the moment, Gambit implements the following mutations:
- Binary Operator Mutation: change a binary operator like `+, -, <` to a different operator. For example:
  `x = y + z - 8` might become `x = y * z - 8`.

- Unary Operator Mutation: change a unary operator like `++, --` to a different operator. For example:
   `x++` might become `x--`.

- Require Condition Mutation: negate or change the condition. For example:
  `require (x + y > 6)` might become `require (true)` or `require (!(x + y > 6))`.

- Assignment Mutation: change the right hand side of an assignment. For example,
`x = true;` might become `x = false`.
- Delete Expression Mutation: comment out some expression. For example,
`for (uint256 i = 0; i < x; i++)` might become `for (uint256 i = 0; i < x; /* i++ */)`
- Function Call Mutation: randomly replace a function call with one of its operands. For example
  `return foo(x, y)` might become `return y`.
- If Statement Mutation: change the condition. For example,
   `if (cond)` might become `if (false)`.
- Swap Function Arguments Mutation: swap the arguments to a function. For example
`foo(a, b)` might become `foo(b, a)`.
- Swap Operator Arguments Mutation: swap the operands of a non-commutative
  binary operator. For example,
    `a - b` might become `b - a`.
- Swap Lines Mutation: swap two lines. For example,
```
x = foo (y, z);
x += 2;
```
might become
```
x += 2;
x = foo (y, z);
```
- Eliminate Delegate Mutation: replace a delegate call by `call`. For example,
```
_contract.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num)
```
might become
```
_contract.call(abi.encodeWithSignature("setVars(uint256)", _num)
```

As you can imagine, many of these mutations may lead to invalid mutants
  that do not compile.
At the moment, Gambit simply compiles the mutants and only keeps valid ones --
  we are working on using additional type information to reduce the generation of
  invalid mutants by constructions.
Gambit does not apply any mutations to libraries unless they are
  explicitly passed to it.
