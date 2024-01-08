Specification Files
===================

The Certora Prover verifies that a smart contract satisfies a set of rules
written in a language called Certora Verification Language (CVL).  The syntax
of CVL is similar to Solidity, but CVL contains additional features
that are useful for writing specifications.

A spec may contain any of the following:

 - **[Import statements](imports):** CVL files can import the contents of other CVL files.

 - **[Use statements](imports):** A `use` statement instructs the Certora Prover to check
   a rule that is imported from another spec or from the built-in rules.

 - **[Using statements](using):** Using statements allow a specification to reference
   multiple contracts.

 - **[Methods blocks](methods):** `methods` blocks contain information on how methods
   should be summarized by the Prover during verification.

 - **[Rules](rules-main):** A rule describes the expected behavior of the methods of a
   contract.

 - **{ref}`invariants`:** Invariants describe facts about the state of a contract that
   should always be true.

 - **[Functions](functions):** CVL functions contain CVL code that can be reused throughout the spec.

 - **[Definitions](defs):** CVL definitions contain CVL expressions that can be reused throughout the spec.

 - **[Sorts](sorts):** Sorts define simple types that can be compared for equality.

 - **[Ghosts](ghosts-doc):** Ghosts define additional variables that can be used to keep track
   of state changes in the contracts.

 - **{ref}`Hooks <hooks>`:** Hooks allow the specification to instrument the contracts being
   verified to insert additional CVL code when various instructions are executed.

The remainder of this chapter describes the syntax and semantics of a
specification file in detail.

(ebnf-syntax)=
Syntactic Conventions
---------------------

Many of the pages in this guide describe the syntax of parts of the Certora
Verification Language using a modified version of the [EBNF format][EBNF].

[EBNF]: https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form

When reading the syntax blocks, keep the following in mind:

 - Text in double quotes is a terminal that matches the exact string.
   For example, `"ghost"` matches `ghost`, and `"."` matches `.`

 - Names that are not in double quotes are nonterminals that refers to other
   parts of the grammar.  For example, `number` matches `1` or `2` or `372`.

 - Multiple items placed next to each other can be separated
   by whitespace.  For example, `"pragma" "specify" number "." number` matches `pragma specify 1.5`
   and also `pragma     specify 0.3`.  Note that this is different from the
   EBNF format described in the link above (that format would add a comma between items).

 - An item surrounded by square brackets is optional.  For example, `"pragma" "specify" number [ "." number ]`
   matches `pragma specify 3.1` and also matches `pragma specify 3`.

 - An item surrounded by curly braces may be repeated 0 or more times.  For example,
   `number { "." number }` matches `3` and `3.1` and `3.1.4.1.5`

 - Items separated by a vertical bar represent different alternatives.  For example,
   `"use" "rule" id | "use" "invariant" id | "use" "builtin" "rule" id` matches
   `use rule foo` and also matches `use invariant bar` but does not match
   `use rule foo use invariant bar`.

