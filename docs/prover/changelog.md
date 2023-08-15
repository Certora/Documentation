Release Notes
=============

```{contents}
```

Prod version March 21, 2022
---------------------------

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

