Syntactic conventions
---------------------

Many of the pages in this guide describe the syntax of parts of the Certora
Verification Language using a modified version of the [EBNF format][EBNF].

[EBNF]: https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form

When reading the syntax blocks, keep the following in mind:

 - Text in double quotes is a terminal that matches the exact string.
   For example, `"pragma"` matches `pragma`, and `"."` matches `.`

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

