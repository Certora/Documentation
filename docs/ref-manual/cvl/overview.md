# Specification files

The Certora Prover verifies that a smart contract satisfies a set of rules
written in a language called Certora Verification Language (CVL).  The syntax
of CVL is similar to Solidity, but CVL contains additional features
that are useful for writing specifications.

The beginning of a spec file contains some header information:

 - **[Version pragma](pragmas):** The CVL version can be specified using `pragma specify <version>`.

 - **[Import statements](imports):** CVL files can import the contents of other CVL files.

 - **[Using statements](using):** Using statements allow a specification to reference
   multiple contracts.

 - **[The methods block](methods):** This section contains information on how methods
   should be summarized by the prover during verification

 - **[The events block](events):** This section is currently unused

All of the above header sections are optional, but if they appear they must
appear in the order they are listed here, and they must come before any of the
items listed below.

After the header sections, a CVL file can contain any of
the following items in any order:

 - **[Rules](rules):** A rule describes the expected behavior of the methods of a
   contract.

 - **[Invariants](invariants):** Invariants describe facts about the state of a contract that
   should always be true.

 - **[Use statements](imports):** A `use` statement instructs the Certora Prover to check
   a rule that is imported from another spec or from the built-in rules.

 - **[Functions](functions):** CVL functions contain CVL code that can be reused throughout the spec.

 - **[Definitions](defs):** CVL definitions contain CVL expressions that can be reused throughout the spec.

 - **[Sorts](sorts):** Sorts define simple types that can be compared for equality.

 - **[Ghosts](ghosts):** Ghosts define additional variables that can be used to keep track
   of state changes in the contracts.

 - **[Hooks](hooks):** Hooks allow the specification to instrument the contracts being
   verified to insert additional CVL code when various instructions are executed.

The remainder of this chapter describes the syntax and semantics of a
specification file in detail.

