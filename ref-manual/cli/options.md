Command Line Arguments
======================

```
optional arguments:
  -h, --help            show this help message and exit

Mode of operation. Please choose one, unless using a .conf or .tac file:
  --verify VERIFY [VERIFY ...]
                        Matches specification files to contracts. For example: --verify [contractName:specName.spec ...]
  --assert ASSERT_CONTRACTS [ASSERT_CONTRACTS ...]
                        The list of contracts to assert. Usage: --assert [contractName ...]
  --bytecode BYTECODE_JSONS [BYTECODE_JSONS ...]
                        List of EVM bytecode json descriptors. Usage: --bytecode [bytecode1.json ...]
  --bytecode_spec BYTECODE_SPEC
                        Spec to use for the provided bytecodes. Usage: --bytecode_spec myspec.spec

Most frequently used options:
  --msg MSG             Add a message description (alphanumeric string) to your run.
  --rule RULE           Name of a specific property (rule or invariant) you want to verify.

Options affecting the type of verification run:
  --rule_sanity         Check that all rules are not vacuous - there is an input that reaches their final assertion (we expect the callback function only to fail this check)
  --short_output        Reduces verbosity. It is recommended to use this option in continuous integration
  --typecheck_only      Stop after typechecking
  --send_only           Do not wait for verifications results

Options that control the Solidity compiler:
  --solc SOLC           Path to the solidity compiler executable file
  --solc_args SOLC_ARGS
                        List of string arguments to pass for the solidity compiler, for example: "['--optimize', '--optimize-runs', '200']"
  --solc_map SOLC_MAP   Matches each Solidity contract with a Solidity compiler executable file. Usage: <contract_1>=<solc_1>,<contract_2>=<solc_2>[,...]
  --path PATH           Use the given path as the root of the source tree instead of the root of the filesystem. Default: $PWD/contracts if exists, else $PWD
  --packages_path PACKAGES_PATH
                        Path to a directory including the Solidity packages (default: $NODE_PATH)
  --packages PACKAGES [PACKAGES ...]
                        A mapping [package_name=path, ...]

Options regarding source code loops:
  --optimistic_loop     After unrolling loops, assume the loop halt conditions hold
  --loop_iter LOOP_ITER
                        The maximal number of loop iterations we verify for. Default: 1

Options that help reduce running time:
  --method METHOD       Parametric rules will only verify given method. Usage: --method 'fun(uint256,bool)'
  --cache CACHE         name of the cache to use
  --smt_timeout SMT_TIMEOUT
                        Set max timeout for all SMT solvers in seconds, default is 600

Options to set addresses and link contracts:
  --link LINK [LINK ...]
                        Links a slot in a contract with another contract. Usage: ContractA:slot=ContractB
  --address ADDRESS [ADDRESS ...]
                        Set an address manually. Default: automatic assignment by the python script. Format: <contractName>:<number>
  --structLink STRUCT_LINK [STRUCT_LINK ...]
                        Linking to a struct field, <contractName>:<number>=<contractName>

Debugging options:
  --debug               Use this flag to see debug prints
  --version             Show the tool version

```
