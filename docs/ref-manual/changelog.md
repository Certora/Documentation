Changelog
=========

Prod version March 21, 2022
---------------------------

*   Fixing wildcard assignment of booleans.
    
*   `--debug-topics` was renamed `--debug_topics`.
    
*   Now using `--debug_topics` without `--debug` raises an exception.
    
*   Added support for multidimensional ghost mappings.
    
*   Added buttons leading to the older report and the logs (`Results.txt`) in the current verification report.
    
*   Present a friendlier error message when trying to invoke solidity calls from within an init\_state axiom.
    
*   Allow multiple contracts that have the same struct name locally.
    
*   Preliminary fixes of calltrace generation failures.
    
*   Fix for supporting struct types in preserved blocks.
    
*   Support for ABI-encoding of structs from CVL.
    
*   Better checks for BV theory to avoid out-of-bounds.
    
*   Fix for infinite loop in storage analysis.
    
*   More controls for bitwise operations handling and attempt to improve precision for lower precision modes.
    

Prod version March 6, 2022 \[MAJOR\]
------------------------------------

*   Fixing hooks on (packed) signed values
    
*   Support use of user defined types (enum, value types, structs) in CVL.
    
*   A small fix to how we check def-use in a single block.
    
*   Improving internal error messages.
    
*   Fix reverting of transfer via a low level call where rc is not propagated as a revert of the caller.
    
*   Fixing application of CVL functions within expressions in case the CVL function contains parametric method calls.
    

Prod version February 24, 2022
------------------------------

*   Fixing loading of expected file option from conf file run.
    
*   Fixing an unsound application of constant propagation.
    
*   Fixing a crash in pointer simplification.
    
*   Increasing timeout of string unpacking checker.
    
*   Removed a redundant print from the stdout of certora-cli.
    
*   Reducing LIA axioms that are unnecessary.
    
*   Basic support for hooks with bytes keys (no support for passing bytes arguments into a ghost yet).
    
*   Allowing disabling of local type checker for cloud runs.
    
*   Fixing enum packing in storage.
    
*   Fixing internal links in verification report.
    
*   Performance improvements through more efficient modelling of machine arithmetic, enabled by default.
    
*   Dump reproduction files on all runs.
    
*   Simplification of auto-safemath code in solidity 0.8.
    
*   Fixing splitting of storage variables in constructor code.
    

Prod version February 10, 2022
------------------------------

*   When the `postProcessCounterExamples` option is active (it is by default), we now print a statistics line indicating the effects of the post processing . Example: `postProcessCounterExamples: finished normally; adjusted 44 out of 168 candidate values`
    
*   Splitting ignores reverting branch choices
    
*   Very raw splitting information is output in the console and old HTML report
    
*   Bug fix - no longer showing aliasing information in the call trace with precompiled contracts
    
*   Calling the `create` function (for example, via constructors in Solidity) now returns a valid address and does not havoc the state of any contract
    
*   New feature - hooks on the `create` function
    
*   We fail more quickly if a non-existing method name was given to `--method` when using `--assert`
    
*   Generating a new file `resource_errors.json` that shows errors originating from Solidity or spec files
    
*   New logging infrastructure in python scripts
    

Prod version January 30, 2022
-----------------------------

*   Fix `CachingContractLoader` to prevent loading contracts multiple times
    
*   Fix in handling the bitwise-not operation
    
*   Prettifying of counterexample models is now enabled by default
    
*   Adding a missing case of handling of array total length vs. length
    
*   Making sure false warnings don’t show up in console
    
*   Improving robustness of path enumeration mode
    
*   New CLI option `--expected_file` for more advanced expected results checking
    
*   New CLI option `--optimize <num_runs>` as a shorter way to write `--solc_args "['--optimize', '--optimize-runs', '<num_runs>']"`
    
*   Some fixing to unpacking optimizations
    
*   Fix rare folding bugs
    

Prod version January 3rd, 2022
------------------------------

*   Fix a Null Pointer Exception when using `requireInvariant`
    
*   Actually disabling multi assert checking by default
    

Prod version January 1st, 2022
------------------------------

*   We can now run `certoraRun` from a directory that has a space in its name.
    
*   Parallel preprocessing of contracts in `CachingScene` and printing thread dump on global timeout.
    
*   Added a new mode that checks every assert statement in a rule separately. Enable this mode through the `-multiAssertCheck` flag.
    
*   A new API for querying the progress of the verification and getting results per assert statement
    
*   In the call trace, variables' values are displayed, based on their corresponding EVM types.  
    The main changes are:
    
    1.  Exact relevant number of bits are displayed. For example, for variables of type Int8,  
        exactly 8 bits will be displayed (and not like until now, sometimes 256 bits).
        
    2.  Displaying of special values for every EVM type (max/min values).
        
    3.  Values of EVM types address/bytesK will be displayed in hexadecimal.  
        Values greater than 1000 will also be displayed in hexadecimal.
        
*   Displaying of returned values of internal functions.
    
*   Displaying of summarized functions' results.
    
*   Prefix of ret\_k/arg\_k for the k’th argument/returned value of a function, in cases where the values  
    are not displayed sequently, to clarify the order of arguments/returned values.  
    For example, if we are missing the second argument out of 3 arguments of a function, we will display  
    something like arg2=\[value2\].
    
*   Fix bitvector hash bound causing an exception
    
*   Solve size limit issue when uploading tasks to the cloud
    
*   Opt out of auto-cache with an environment variable
    

Prod version December 19, 2021
------------------------------

*   Bug fix in decompiler
    
*   Adding option for highly optimistic handling of return size in havocd calls `-superOptimisticReturnsize`
    
*   Bug fix in registration of axioms
    
*   Parallel preprocessing of contracts
    
*   Support for bytes keys in mappings
    
*   Optimizing decompilation cleanup
    
*   Support for new variables-style ghost syntax, see [https://certora.atlassian.net/l/c/U6d2u7jF](https://certora.atlassian.net/l/c/U6d2u7jF) for documentation.
    
*   Making sure the total length in bytes and number of elements of an array declared in CVL agree
    
*   Fixing a problem where type checker was slow by caching CVL scopes
    
*   Turning off get-difficulty by default due to longer running times
    
*   Fix unpack analysis on storage delete commands
    
*   Improved statsdata for solver races
    

Prod version December 12, 2021
------------------------------

*   Fixing string hashing of length >=32 < 64 to be axiomatized correctly
    
*   Fixing the call trace to show return values of functions invoked from DISPATCHER summaries
    
*   If the user did not specify a cache key, it will be generated automatically
    
*   Fix for calling overloaded functions from spec
    
*   Adding `--bytecode` and `--bytecode_spec` option to check a spec on the underlying bytecode
    
*   Streamlining of logging behaviors
    
*   Fixing decompiler for try-catch blocks within loops, introducing `strictDecompiler` option for controlling sensitivity to failures in presence of function pointers.
    
*   Faster NIA formulas processing
    

Prod version December 4, 2021
-----------------------------

*   Can now add an env variable to generic preserved block via the syntax preserved `with (env e) {...}`
    
*   When a user needs to update `certora-cli`, we give installation instructions to both `pip` and `pip3`
    
*   Better messaging regarding cyclic links
    
*   Lower copy loop unroll factor reduced from 10 to 4
    
*   Better messages when reaching the global timeout
    
*   Variables of an invariant are now in the scope of its preserved blocks
    
*   Fixes to support hooks on boolean values stored in storage
    

Prod version November 16, 2021
------------------------------

*   Fix to how remappings are set
    
*   Fixing bugs in static analyses relevant when handling structs in optimized solidity code
    
*   Fixing multiplication axioms
    

Prod version November 15, 2021
------------------------------

*   Improving caching to cover more transformations
    
*   Fixes to storage handling optimization
    
*   Fix to allow havoc assuming in non-hook context
    
*   Improved calldata splitting
    
*   More efficient axiom instantiation
    
*   Improved internal function finder
    

Prod version November 7, 2021
-----------------------------

*   Fix to handling of mulmod instruction
    
*   Command summaries
    
*   Recursive dispatcher calls now leading to assert false instead of tool error
    
*   Fixing bwand axiomatization failure in unreachable div by 0 code segments
    
*   Handle unpacking of packed ints in structs
    
*   Support for `BASEFEE` instruction
    
*   Support for invariant filtered expressions: `invariant name(…) def… filtered { f -> yourFilter(f) }`
    
*   `--method` now accepts signatures of methods with struct parameters
    
*   Added a new tool option `--send_only` that sends the verification but does not wait for results
    
*   In the calltrace special values are now shown with both a string and the concrete value
    
*   Support `bytes` in preserved blocks together with referring to any other parameters in the preserved block
    

Prod version October 3, 2021
----------------------------

*   Basic support for reasoning about the power operator with powers of 10 (powers of 2 already supported)
    
*   More precise handling of bitwise shift/and/or operations that occur in packing/unpacking of data
    
*   Namespace separation of variables and functions
    
*   Multi-contract named hook slots now supported!
    
*   Better data representation in the call trace
    
*   Show aliasing parameters in the call trace
    
*   `--method` works in a multi-contract setting
    
*   Fixed a bug preventing the run of the tool with `cvc4` only
    
*   Support for `bytes` and `bytes[]` in CVL
    
*   Ensure `delegatecall` modeling preserves `msg.value` in callee without transfering either in call or in revert paths
    
*   Support computation of storage references via `abi.encode` calls and direct access via inline assembly
    
*   More precise storage analysis in presence of shifts
    
*   Performance optimizations
    
*   Additional removal of unreachable code
    
*   Storage splitting for packed structs under maps/arrays
    
*   Sanity checking for all rules including invariants
    
*   Tree view output
    
*   Improvements to memory consumption
    
*   Friendlier CVL error messages
    
*   Fixed a bug that lead to a failure of call trace construction
    
*   More graceful failure in global timeout
    
*   Fix to program splitting
    
*   Bug fixes to Points-to analysis
    
*   Bug fix to CVL variables not appearing in call trace
    

Prod version August 29th, 2021
------------------------------

*   Fixes to cache (deterministic generation of function finders)
    
*   Supporting hooks for root constant storage slots
    
*   Fixing storage analysis when internal functions are annotated
    
*   The zip file is properly removed even if the python process was interrupted by the user (or an exception)
    
*   Proper type checking of `requireInvariant`
    
*   Added mode for typechecking only - `--typecheck_only`
    

Prod version August 8th, 2021
-----------------------------

*   Missing return statements in solidity versions 7 and up now captured as errors when compiling through `certoraRun` (`solc` only reports a warning)
    
*   Modularity in CVL now also includes overriding of CVL definitions and functions, as well as filters of parametric rules
    
*   Bug fix: Path of an imported .spec file is relative to the file that contains the import statement
    
*   Filters of rules' method type parameters allow the use of Boolean CVL definitions
    
*   Enforcing that all elements defined in the outermost scope of a CVL specification, such as rules and invariants, have distinct names. Name collisions result in syntax errors
    
*   Envfree declarations generate corresponding checks also when used with multi-contract; e.g.,`b.foo() returns uint envfree` where `b` is an alias of an imported contract with an external function`foo`
    
*   Multi-contract must not be used in summary declarations; a summary always implicitly applies to a method signature in "any contract"
    
*   Checking of the syntax of CVL spec files is now done earlier, before invoking `solc`. Full type checking occurs after compilation
    
*   Multicontract calls as commands (not expressions) are now supported without having to prefix them with an `invoke` or `sinvoke`
    
*   Fixes to constant evaluation of signed division, and of overflow-safe signed multiplication.
    
*   Reduce max SMT timeout to 5 minutes instead of 10
    
*   Bug fix: `--assert` now works
    
*   Bug regarding CVC4 solver fixed
    
*   Prettier error message when the `certora-cli` package version is not found
    
*   Support for ecrecover precompiled
    
*   Bug fix for very big statically sized arrays in storage
    
*   Better handling of optimized code for nested hash applications
    
*   Allow checking revert conditions in the presence of ALWAYS summaries (constraint return size to 32 bytes).
    
*   Making loop unroller more robust in optimized loops
    
*   Fixing addition optimization
    

Prod version July 18, 2021
--------------------------

*   Fix to calltrace generation when having reverts in internal functions
    
*   Auto-enable CI mode in GitHub Actions
    
*   Hide loading animation on CI/git action
    

Prod version July 17, 2021
--------------------------

*   Help message improved - some options were removed, the rest are now grouped logically and by usability
    
*   Prettier `conf` files - all settings in `--settings` are now separate elements in a list, all lists are now without duplicate values and ordered alphabetically
    
*   Bug fixes in `regTest.py`:
    
    *   Now run scrips that start with whitespace are not skipped
        
    *   Several path issues when running on windows
        
    *   Prettier output
        
*   No need to specify `UNRESOLVED` for `DISPATCHER`
    
*   When the CERTORAKEY is not set, the script uses the Public Key
    

Prod version July 12, 2021
--------------------------

*   Debug logs in the python scripts were shortened and improved.
    
*   Retry verification request on timeout (and 502) exception
    
*   CVL is now enhanced with a new modularity feature that allows importing other .spec files.
    
*   Better error messages. If there was a typo in a contract name, we provide suggestions to which contract name it should be.
    
*   Fixed Sload hooks for simple splitted primitive storage variables
    
*   Support for arrays in CVL
    
*   New axiomatization for hash function applications that is compatible with bitvector logics
    
*   Package version validation now happens before local type checking, so an incompatible package version message will be printed even if local type checking fails (say, as a result of new syntax)
    
*   Support for signed integer comparisons in CVL
    
*   Set `isConvertibleToArithmeticType()` to true for type `bytes32` - Allows for operands of bitwise operations to be `bytes32`
    
*   Make more ghosts appear in calltrace
    
*   Validation of `--rule` (or `--settings -rule`) is now more precise, and will not match rule names in comments
    
*   Allow ite-expressions in hooks
    
*   Fixed bug with ghost handling in reverts
    
*   Support ALL (forced) external summaries and make this default: now behavior is consistent with internal summaries
    
*   Recent jobs file is now renamed when corrupted (or has an incompatible format).
    
*   Improvements to call trace
    

Prod version June 14th, 2021
----------------------------

*   We now only print trackbacks of Python exceptions when we are in debug mode.
    
*   We check the validity of --method argument locally. We give appropriate messages if the method is private or internal, or if just the arguments are wrong. If the name is wrong, we suggest other closely named existing methods.
    
*   Bug fix - previous job list update failed and terminated the user process.
    
*   Fix to allow declaring the same variable within different if-else scopes.
    
    *   Cannot declare method type variables within if-else scopes. Such declarations lead to syntax errors.
        

Prod version June 13th, 2021
----------------------------

*   Replace status prints with a loading animation
    
*   Added recent job file to $CERTORA
    
*   Fixed a bug that prevented version 0.2.5 to run on Windows OS due to wrong file paths.
    
*   Fixed a bug with linking calls that return more than one return value
    
*   Fixes the memory splitter
    
*   More optimization rounds to BW-Ands and path pruning
    
*   Remove unnecessary internal annotations
    

Prod version May 30th, 2021
---------------------------

*   Replay mode
    
*   Recursion detection fix
    
*   Automatic function finders
    
*   Option for better models
    
*   Better handling of fallback flow
    
*   Cache fixes
