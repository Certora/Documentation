(prover-release-notes)=
Prover Release Notes
=============

```{contents}
```


4.12.1 (September 17, 2023)
---------------------------

### CVL
- [bugfix] fix to bitwise operations
- [bugfix] verify range of `nativeBalances[addr]` values
- [bugfix] no duplication of multi-dimensional ghosts with axioms
- [feat] delete summary qualifiers for faster preprocessing and dealing with analysis-breaking external functions. If a function is never called from spec, it will not be processed. In cases where it is externally called from Solidity, the summary will apply.
- [feat] greater flexibility of internal summaries - allows accepting as arguments and returning certain reference types: primitive arrays, `bytes`, and structs which may (in nested structs too) contain primitive arrays
- [feat] support multiple return values from CVL functions
- [bugfix] Support keywords as struct fields and user defined type names
- [bugfix] Fix to multi-assert mode when multiple CVL asserts in a rule share the same message
- [UX] Skip rules where all methods are filtered out
- [bugfix] Do not drop quantifiers when instrumenting vacuity checks
- [UX] Improved error messages for preserved block errors
- [bugfix] Support invariant preserved blocks for functions with an argument which is an array of structs
- [feat] New keyword: `executingContract` available inside opcode hooks
- [bugfix] Applying the CALL opcode hook even if the balance transfer fails
- [bugfix] Support assigning to a wildcard variable
- [bugfix] Fail if CVL function is non-void and does not end with a return statement

### Performance
- [feat] Optimizations for safe math handling, in particular for `solc` versions 8.19 and up
- [feat] Better performance of `string` and array types

### Call Trace & Rule Report
- [feat] Show storage changed since the start
- [feat] More frequent rule-report update
- [bugfix] Rule running time to show time interval instead of sum of sub-rules intervals
- [feat] Show state of ghosts together with contract state
- [bugfix] Fix formatting of values of type `bytesN` and of storage locations

### CLI
- [bugfix] link to CVL2 migration document fixed
- [bugfix] support for other formats of protocol author in `package.json` files
- [bugfix] fix error message when passing global timeout setting
- [bugfix] less verbose prints in terminal
- [UX] Validate rule names
- [UX] Show number of splits solved per rule and their "weight"
- [bugfix] Fixes to equivalence checker

### Mutation Verification
- [bugfix] correct traversing of rules
- [feat] improved csv output

### Equivalence Checker
- [feat] Support void functions
- [feat] Support compiler comparison
- [bugfix] Making comparison more reliable in terms of initial state and with respect to low-level calls

4.10.1 (August 21, 2023)
------------------------

### CVL
- [feat] Support Solidity calls also from internal summaries
- [feat] Allowing `with(env)` for summaries {ref}`with-env`
- [bugfix] `lastStorage` comparison fix for ghost maps
- [bugfix] Bitwidth for `bytesK` variables is ensured, important for revert characteristic rules for methods accepting `bytesK`
- [bugfix] Fixing `struct`s encoding
- [bugfix] Matching method summaries for methods accepting `interface`s
- [bugfix] Some improvements to how quantifiers calling Solidity functions are handled

### Mutation Verification
- [feat] Output CSV files of the results
- [bugfix] Manual mutations work and support for multiple manual mutations
- [bugfix] `certoraMutate` working when running from project’s root


### Timeouts and performance
- [feat] Show informative messages about cache hits
- [bugfix] fix hashes of constant strings in constructors vs. in executable bytecode

### Linking
- [bugfix] Fixing source-based heuristics linking to decrease chance for wrong matches
- [bugfix] Fixes to sighash resolution
- [bugfix] Correct revert handling in dispatched calls

### Vyper
- [bugfix] Support for versions below 0.2.16 (from before storage layout output was introduced in Vyper)


4.8.0 (August 13, 2023)
-----------------------

### New features and enhancements

#### CVL
- Better expressivity: `ALWAYS` summaries can get `bytesK` arguments, e.g. `... => ALWAYS(to_bytesK(...))`
- Support for `ALL_SLOAD` and `ALL_SSTORE` hooks (see {ref}`rawhooks`)
- Improved ABI encoding/decoding in CVL
- More efficient handling of skipped rules
- Allow calling Solidity functions from expression summaries

#### Call Trace and Rule Report
- Display havoced return values
- Fixes to dump generation
- Improved timeout visualization in TAC dumps
- Fixes to presentation of quantified formulas in Call Trace
- Better presentation of timeouts
- Rule report will contain warnings about unused summaries
- Display native balances
- More friendly text for dispatcher-based resolutions
- Improved ghost presentation

#### Performance
- Rule cache is enabled
- Reducing number of iterations of static analyses
- Improved decompiler performance

#### Mutation Verifier
- Manual mutants now supported in `certoraMutate`

#### Equivalence Checker
- Support for Vyper for the equivalence checker (`certoraEqCheck` utility)

#### CLI
- Allowing more Solidity file names
- More compact zip input to cloud
- Users can reduce the global timeout below 2 hours using {ref}`--global_timeout`

### Bug fixes

#### CVL
- More graceful handling of bit-vector mode so that it emits less errors. It should be noted that numbers are forced to the 256-bit range and thus it is not recommended to use bit-vector mode. 
- Declaration of wildcard (i.e. `_`) variable names in rules or rule arguments is disallowed
- Internal summaries - disallow `NONDET` summary on functions returning a pointer, as well as `HAVOC` or `HAVOC_ECF` summaries
- Better checks on ghost axioms, especially if they refer to definitions
- Fixing array literal assignments
- Forbid assignments to array elements, i.e. `uint[] a; a[0] = x;` is disallowed
- Internal summarization did not work in certain tricky cases involving loops and external calls
- Fixing "Certora Prover Internal Error" sometimes appearing when reasoning on complex-typed arrays
- Fixes for structs with contract types as fields

#### Call Trace
- Fix call trace generation issues for `forall` expressions

#### Mutation Verifier
- Correctly dealing with original runs where rules were originally violated

#### Misc.
- Static analyses bug fixes
- Fixes to read-only reentrancy rule
- Avoiding an exception when `-dontStopAtFirstSplitTimeout` completes with all splits timing out

### Other improvements
- Better parallelism and utilization
- Timeout cores and more difficulty traces and hints to study timeout causes
- Support for Solidity compiler version 0.8.20 and up


4.5.1 (July 15, 2023)
---------------------

### New features

#### CVL

- Better expressivity: Allow binding the called contract in summaries using `calledContract` (see {ref}`function-summary`)
- Ease of use: Support reading and passing complex array and struct types in CVL. For example, you can write now:
```cvl
env e;
uint v;
Test.MyComplexStruct x;
uint[] thingArray = x.nested[v].thing;
require thingArray.length == 3;
assert foo(e, x, v) == 3;
```

For the Solidity snippet of a contract `Test`:
```solidity
struct MyComplexStruct {
    MyInnerStruct[] nested;
}

struct MyInnerStruct {
    uint[] thing;
    uint field;
}

function foo(MyComplexStruct memory z, uint x) external returns (uint) {
    return z.nested[x].thing.length;
}
```

- Ease of use: Support access for storage variables whose type is either a primitive, a user defined value, or an enum

- Ease of use: Enum types can be cast to integer types in CVL using the usual `assert_TYPE` and `require_TYPE` operators (see {ref}`cvl2-integer-types`)

- A built-in rule for read-only reentrancy vulnerabilities

#### Call Trace
- Better view of the storage state at storage assignments, storage restore points, and storage comparisons

#### Multi-contract handling
- Improvements to the call resolution fallback mechanism in case main analyses fail, allowing linking and summarizations despite the failures

- Introducing `summarizeExtLibraryCallsAsNonDetPreLinking` Prover option for easier setup of library-heavy code. See {ref}`library_timeouts`

#### Mutation Verifier
- New and easier to use `certoraMutate`. See {doc}`/docs/gambit/mutation-verifier`

### Bug fixes

#### CVL
- Fix issue when CVL functions are invoked within ternary expressions
- Fix evaluation of power expressions such as 2^256
- Make sure CVL keywords can appear as struct fields and be accessible from CVL

#### Performance
- Performance optimizations for the contract preprocessing step
- Performance improvements in Prover
- Performance improvements in CVL type checker (allows for faster job submission)

#### UX
- Show primary contract under verification even when a job is queued but not yet started
- {ref}`envfree <envfree>` checks failures presented not just in rules section, but also in the problems view for highlighting
- Make sure more files generated by `certoraRun` are stored in `.certora_internal`
- Allow equivalence checker to have the same function name appear in two contracts


4.3.1 (July 2, 2023)
--------------------

### New features

#### CVL
- New builtin rules: {ref}`sanity <built-in-sanity>` and {ref}`deepSanity <built-in-deep-sanity>`
- Support a new keyword in CVL: {ref}`satisfy <satisfy>`
- User-defined types can appear in hook patterns
- Support using `currentContract` in ghosts and quantified expressions
- Support conversion of `uintN` to `bytesK` with casting {ref}`bytesN-support`
- Support {ref}`nativeBalances <special-fields>` in CVL
- Making access of user-defined-types (enums, structs, user-defined type values) in Solidity consistent, whether those types are declared in a contract or outside of a contract. Specifically, for a user-defined type that's declared in a contract, the access to it in a spec file is `DeclaringContract.TypeName`. For top-level user-defined types (declared outside of any contract/library) the access is using the using contract `UsingContract.TypeName`.
- Support for {ref}`EVM opcode hooks <opcodes>`

#### CallTrace
- Display CVL functions in Call Trace
- CallTrace presenting skolemized variables for quantified expressions
- Gather all setup labels in CallTrace to be under one label
- Make CallTrace accept invocation of internal solidity functions from CVL

#### Summarization
- Early summarization of internal functions for improved performance and precision
- {ref}`“catch-all” summaries <library_timeouts>`. For example, given a library `L` on which we wish to apply the same summary for all external methods in `L`, write `function L._ external => NONDET`

#### Performance
- More stable generation of formulas for more predictable, consistent running times of rules
- Basic parallel splitting for improved running time of rule solving

#### Other improvements
- Change default to new `certora-cli` API
- Check for an invalid rule name (given with `--rule`) locally, before sending a request to the server
- Adapt CVL AST serialization to JSON to enable LSP for CVL2
- Visualize unsolved splits in timeouts

### Bug fixes
- Warn if `CONST` summary is applied to methods that return nothing
- The type checker will fail if an internal method summary uses an inheriting contract name instead of the declaring contract name
- Disallow shadowing of ghost variables
- Support exists as a struct field in spec files
- `require_` and `assert_` casts disallowed in ghost axioms
- CallTrace bug fixes


4.0.5 (June 7, 2023) CVL 2
--------------------------

### Breaking changes

 - Upgrade to CVL 2 (see {doc}`/docs/cvl/cvl2/changes` and {doc}`/docs/cvl/cvl2/migration`) 
 - Change the minimal python required version from 3.8.0 to 3.8.16

### New features

 - {ref}`storage-comparison`
 - Add support for Vyper
 - Support `CONSTANT` summaries for all non-dynamic return types
 - New {ref}`built-in rules <built-in>` `sanity` and `deepSanity`
 - Added `--protocol_name` and `--protocol_owner` flags

### Other improvements

 - Performance improvements
 - Bug fixes and internal improvements
 - Improved error messages
 - Improved console output
 - Improved call resolution output

