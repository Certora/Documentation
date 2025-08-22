(methods-block)=
The Methods Block
=================

The `methods` block contains additional information about contract methods.
Although you can call contract functions from CVL even if they are not
declared in the methods block, the methods block allows users to specify
additional information about contract methods, and can help document the
expected interface of the contract.

There are two kinds of declarations:

* **Non-summary declarations** document the interface between the specification
  and the contracts used during verification (see {ref}`envfree`).  Non-summary
  declarations also support spec reuse by allowing specs written against a
  complete interface to be checked against a contract that only implements part
  of the interface (see {ref}`optional`).

* **Summary declarations** are used to replace calls to certain contract methods.
  Summaries allow the Prover to reason about external contracts whose code is
  unavailable.  They can also be useful to simplify the code being verified to
  circumvent timeouts.  See {ref}`summaries`.

```{caution}
Summary declarations change the way that some function calls are interpreted,
and are therefore {term}`unsound` (with the exception of `HAVOC_ALL` summaries
which are always sound, and `NONDET` summaries which are sound for `view`
functions).
```

```{contents}
```

Syntax
------

```{versionchanged} 4.0
The syntax for methods block entries {doc}`changed in CVL 2 <cvl2/changes>`.
```

The syntax for the `methods` block is given by the following [EBNF grammar](ebnf-syntax):

```
methods          ::= "methods" "{" { method_spec } "}"

method_spec      ::= "function"
                     pattern
                     [ "returns" "(" evm_types ")" ]
                     [ "envfree" |  "with" "(" "env" id ")" ]
                     [ "optional" ]
                     [ "=>" method_summary [ "" | "UNRESOLVED" | "ALL" | "DELETE" ] ]
                     ";"
					 | catch_unresolved_calls_entry

catch_unresolved_calls_entry ::= "unresolved external in" pattern "=>" dispatch_list ";"

pattern          ::= exact_pattern | wildcard_pattern | catch_all_pattern

exact_pattern    ::= [ id "." ] id "(" evm_params ")" visibility [ "returns" "(" evm_types ")" ]
wildcard_pattern ::= "_" "." id "(" evm_params ")" visibility
catch_all_pattern ::= id "." "_" "external"

visibility ::= "internal" | "external"

evm_param ::= evm_type [ id ]

method_summary   ::= "ALWAYS" "(" value ")"
                   | "CONSTANT"
                   | "PER_CALLEE_CONSTANT"
                   | "NONDET"
                   | "HAVOC_ECF"
                   | "HAVOC_ALL"
                   | "DISPATCHER" [ "(" ( "true" | "false" ) ")" ]
                   | "AUTO"
                   | "ASSERT_FALSE"
                   | expr [ "expect" id ]
				   | dispatch_list

dispatch_list     ::=
                   | "DISPATCH" [ "(optimistic=false)" ]  "[" dispatch_list_pattern [","] | empty "]" "default" method_summary
                   | "DISPATCH" [ "(optimistic=true)" ]  "[" dispatch_list_pattern [","] | empty "]"

dispatch_list_patterns ::= dispatch_list_patterns "," dispatch_pattern
                          | dispatch_pattern

dispatch_pattern ::= | "_" "." id "(" evm_params ")"
                     | id "." "_"
                     | id "." id "(" evm_params ")"
```

See {doc}`types` for the `evm_type` production.  See {doc}`basics`
for the `id` production.  See {doc}`expr` for the `expr` production.

(methods-entries)=
Methods entry patterns
----------------------

Each entry in the methods block contains a pattern that matches some set of
contract functions.

 - {ref}`exact-methods-entries` match a single method of a single contract.
 - {ref}`wildcard-methods-entries` match a single method signature on all contracts.
 - {ref}`catch-all-entries` apply a single summary to all methods of a specific contract.
 - {ref}`catch-unresolved-calls-entry` apply a summary to calls whose method signature cannot be statically resolved.


(exact-methods-entries)=
### Exact entries

An exact methods block entry matches a single method of a single contract.
If the contract name is omitted, the default is `currentContract`.
For example,
```cvl
methods {
    function C.f(uint x) external returns(uint);
}
```
will match the external function `f` of the contract `C`.

Exact methods block entries must include a return type; the Prover will check
that the declared return type matches the return type of the contract function.

Exact entries may contain {ref}`summaries <summaries>`, {ref}`envfree`,
{ref}`optional`, and {ref}`with-env`.

It is possible for an exact entry to overlap with another entry; see
{ref}`summary-resolution` for information on how summaries are resolved.

(wildcard-methods-entries)=
### Wildcard entries

```{versionadded} 4.0
Wildcard entries were {ref}`introduced with CVL 2 <cvl2-wildcards>`.
```

A wildcard entry matches any function in any contract with the indicated name,
argument types, and visibility.
For example,
```cvl
methods {
    function _.f(uint x) external => NONDET;
}
```
will match any external function called `f(uint)` in any contract.

Wildcard entries must not declare a return type, since different matched
methods may return different types.

Wildcard entries may not have {ref}`envfree` or {ref}`optional`; their only
purpose is {ref}`summarization <summaries>`.  Therefore, wildcard entries must
have a summary.

It is possible for a wildcard entry to overlap with another entry; see
{ref}`summary-resolution` for information on how summaries are resolved.

(catch-all-entries)=
### Catch-all entries

Sometimes the behavior of a contract in the scene is irrelevant
to the properties being verified. For example, the exact behavior of an external library contract
may be unimportant for a particular verification project.

So-called "catch-all" entries are useful in these situations. A catch-all entry is
used to apply a single {ref}`summary <summaries>` to all functions that are declared in
a given contract. For example:

```cvl
methods {
   function SomeLibrary._ external => NONDET;
}
```

Will apply the `NONDET` {ref}`havoc summary <havoc-summary>` in place of
*every* call to a function in the `SomeLibrary` contract. Note that there are no parameter types
*or* return types for this entry: it refers to all methods in a contract, and cannot be
further refined with parameter type information.
Catch-all summaries apply only to `external` methods, and therefore
the `external` {ref}`visibility modifier <methods-visibility>` is required.
Further, the only purpose of catch-all entries is to apply a summary to all
external methods in a contract, so a summary is required. However, only
{ref}`havocing summaries <havoc-summary>` are allowed for these entries.
Finally, {ref}`envfree` and {ref}`optional` keywords are not allowed for
catch-all entries.

It is possible for a catch-all summary to overlap with another entry; see
{ref}`summary-resolution` for information on how summaries are resolved.

```{note}
Catch-all summaries are only applied when the Prover can definitively show that
the target of a call resolves to the contract mentioned in the catch-all summary.
For library contracts (a common use case for these catch-all summaries)
the Prover is almost always able to resolve the target contract.

For example, if you have an entry `function Token._ external => NONDET;`,
where the contract `Token` has a `burn()` method, the Prover will *not*
apply the `NONDET` summary for the call `t.burn()`, unless it can prove that
`t` must hold the address of the `Token` contract. The "Rule Call Resolution" panel
shown in the web report can indicate whether a summary was applied.

```

(catch-unresolved-calls-entry)=
### Catch unresolved-calls entry
Example:
```cvl
methods {
    // Applies to all unresolved calls called within `C.foo()`
    unresolved external in C.foo() => DISPATCH [
        D.baz()
    ] default HAVOC_ECF;

    // Applies to all unresolved calls in the scene (except ones specified by more refined catch-unresolved-calls entries)
    unresolved external in _._ => DISPATCH [
        C.foo(uint),
        _.bar(address), // Will resolve to all available functions with the signature "bar(address)", specifically Other.bar(address)
        C._ // Will resolve to all functions in C, specifically C.foo(uint) and C.baz(bool)
    ] default NONDET;

    // An optimistic dispatcher can be used to enforce resolving all unresolved calls to a specific method.
    // Be aware: In case the method C.foo(uint) doesn't exist or the sighash doesn't match, this create vacuity.
    unresolved external in _._ => DISPATCH(optimistic=true) [
        C.foo(uint)
    ];
}
```

Catch unresolved-calls entries are a special type of summary declaration that
instructs the Prover to replace calls to unresolved external function calls
with a specific kind of summary, dispatch list.
By default, the Prover will use an {ref}`AUTO summary <auto-summary>` for
unresolved function calls, but that may produce spurious counter examples.
Catch unresolved-calls entries let the user refine the summary used for
unresolved function calls.

Note that the catch unresolved-calls entry _only applies_ in cases where the called
function's _sighash_ is unresolved. In the example below there is a function
call `target.call(data)`. The sighash of the called function depends on the parameter
`data` and cannot be known beforehand.

```{cvlinclude} /CVLByExample/UnresolvedCallSummarization/TrusterLenderPool.sol
:start-at: function flashLoan
:end-at: }
:emphasize-lines: 13
```

One can specify the scope (`unresolved external in <scope>`) for which the
unresolved summary will apply. The options are:
* `Contract.functionSignature()` for summarizing unresolved calls within this function
* `_.functionSignature()` for summarizing unresolved calls within this function in any contract
* `Contract._` for summarizing unresolved calls in any function of the given contract
* `_._` for summarizing all unresolved calls in the scene.

If multiple catch unresolved-calls entries exist, the order of precedence is the
order of the above list, from top to bottom.

```{note}
If `C.foo` has a (resolved) external call to `D.bar`, and `D.bar` contains an
unresolved call, a catch-unresolved-calls entry that applies to `C.foo` will
_not_ be applied to this unresolved call - only an entry that matches `D.bar`
will be used.
```

Catch unresolved-calls entries can only be summarized with a dispatch list
summary.

As with `DISPATCHER`, there are optimistic and pessimistic dispatch lists. This can
be specified via `DISPATCH(optimistic=<true|false>). When the `optimistic` option 
is not specified in parentheses, the Prover will use a pessimistic dispatch list to 
ensure sound reasoning.

A dispatch list summary directs the Prover to consider each of the methods
described in the list as possible candidates for this unresolved call.
The Prover will choose dynamically, that is, for each potential run of the
program, which of them to call.
It is done accurately by matching the selector from the call's arguments
to that of the methods described in the dispatch list.
When using a pessimistic dispatch list and no method from the list matches, 
it will use the `default` summary. When using the optimistic dispatch
list, an `ASSUME FALSE;` is inlined by the Prover; see the example below.
The dispatch list will contain a list of patterns and the default summary to use in case no function matched the selector.
The possible patterns are:
1. Exact function - a pattern specifying both a contract, and the
   function signature.
   Example: `C.foo(uint)`
2. Wildcard contract - a pattern specifying the function signature to match
   this signature on all available contracts (including the primary contract).
   Example: `_.bar(address)`
3. Wildcard function - a pattern specifying a contract, and matches all
   external functions in specified contract (This pattern will also include the
   contract's fallback if it's implemented).
   Example: `C._`

The example entry at the head of this section will specify three functions to
route calls to:
1. `C.foo(uint)`
2. `Other.bar(address)`
3. `C.baz(bool)`

Entry annotations ({ref}`envfree`, {ref}`optional`) and the `returns` clause
are not allowed on an unresolved-calls entry.
Also, the visibility is always external, and no policy should be specified.

For an unresolved function call being summarized with the dispatch list above,
the Prover will replace the call with a dynamic resolution of the function call.
That is something in the lines of:
```solidity
function summarized(address a, bytes calldata data) external {
  if (uint32(data[0:4]) == 0x11111111 && address == address(c)) {
    // Function selector was equal to foo's
    // Call C.foo(...)
  } else if (uint32(data[0:4]) == 0x22222222 && address == address(o)) {
    // Function selector was equal to bar's
    // Call O.bar(...)
  } else if (uint32(data[0:4]) == 0x33333333 && address == address(c)) {
    // Function selector was equal to baz's
    // Call C.baz(...)
  } else {
    // In the case of the DISPATCHER(optimistic=false), the summary 
    // specified after the "default" is inlined here. This is typically a HAVOC_ALL,
    // HAVOC_ECF or a NONDET.
    // In the case of the DISPATCHER(optimistic=true) option, no default is used 
    // and the Prover inlines an ASSUME FALSE; at this location marking 
    // this branch as unreachable.
  }
}
```

The dispatch list summary will create a dynamic resolution process that
determines the specific function to call at runtime based on the function
signature and the target contract address.
In the provided example, when an unresolved function call is encountered, the
Prover dynamically resolves it by inspecting the function selector in the
transaction data and the target contract address.
By comparing the function selector against known signatures and verifying the
contract address, the Prover identifies the appropriate function to call.

This dynamic resolution mechanism is crucial for refining specifications
because it enables the Prover to accurately model the behavior of smart
contracts, even when the exact function being called is not known statically.
By replacing unresolved calls with dynamically resolved calls in the dispatch
list summary, the specification becomes more precise, leading to more accurate
verification results and improved assurance in the correctness of the smart
contract.

### Location annotations

```{versionadded} 4.0
Location annotations were {ref}`introduced with CVL 2 <cvl2-locations>`.
```

Methods block entries for internal functions must contain either `calldata`,
`memory`, or `storage` annotations for all arguments with reference types (such
as arrays).

Entries for external functions may have `storage` annotations for argument
references (in Solidity, external library functions may have storage arguments).
If a reference-type argument does not have a `storage` annotation, the entry
will apply to a function that has either a `calldata` or a `memory` annotation
on the argument.

(methods-visibility)=
### Visibility modifiers

```{versionadded} 4.0
Visibility modifiers were {ref}`introduced with CVL 2 <cvl2-visibility>`.
```

Entries in the methods block must be marked either `internal` or `external`; the
entry will only match a function with the indicated visibility.

If a function is declared `public` in Solidity, then the Solidity compiler
creates an internal implementation method, and an external wrapper method that
calls the internal implementation.  An `internal` methods block entry will
apply to the generated implementation method, while an `external` entry will
apply to the generated external wrapper method.

This summarization behavior can be confusing, especially because functions
called directly from CVL are not summarized.

Consider a public function `f`.  Suppose we provide an `internal` summary for
`f`:

 - Calls from CVL to `f` *will* effectively be summarized, because CVL will call
   the external function, which will then call the internal implementation, and
   the internal implementation will be summarized.

 - Calls from another contract to `f` (or calls to `this.f` from `f`'s contract)
   *will* effectively be summarized, again because the external function
   immediately calls the summarized internal implementation.

 - Internal calls to `f` will be summarized.

On the other hand, suppose we provide an `external` summary for `f`.  In this
case:

 - Calls from CVL to `f` *will not* be summarized, because direct calls from
   CVL to contract functions do not use summaries.

 - Internal calls to `f` *will not* be summarized - they will use the original
   implementation.

 - External calls to `f` (from Solidity code that calls `this.f` or `c.f`) will
   be summarized

In most cases, public functions should use an `internal` summary, since this
effectively summarizes both internal and external calls to the function.

(envfree)=
`envfree` annotations
---------------------

Following the `returns` clause of an exact methods entry is an optional
`envfree` tag.  Marking a method
with `envfree` has two effects.  First, {ref}`calls <call-expr>` to the method
from CVL do not need to explicitly pass an {term}`environment` value as the
first argument.  Second, the Prover will verify that the method implementation
in the contract being verified does not depend on any of the environment
variables.  The results of this check are displayed on the verification report
as separate rules called `envfreeFuncsStaticCheck` and
`envfreeFuncsAreNonpayable`[^envfree_nonpayable].

[^envfree_nonpayable]: The effect of payable functions on the contract's
  balance depends on the message value, so payable functions also require an
  `env`.

(optional)=
`optional` annotations
----------------------

```{versionadded} 4.0
Prior to {ref}`CVL 2 <cvl2-optional>`, all methods entries used the `optional`
behavior, and there was no `optional` annotation.
```

When multiple contracts implement a shared interface, it is convenient to write
a generic spec of generic rules.  Some interfaces specify optional methods that
some implementations provide and others don't.  For example, some ERC20
implementations contain a `mint` method, but others don't.

In this situation, you might like to write rules that are checked if the
contract contains the `mint` method and are skipped otherwise.

To do so, you can add the `optional` annotation to the exact methods block
entry for the function.  Any rules that reference an optional method will be
skipped if the method does not exist in the contract.
For example:
```cvl
methods {
    function mint(address _to, uint256 _amount, bytes calldata _data) external optional;
}
```

(with-env)=
`with(env e)` clauses
---------------------

After the `optional` annotation, an entry may contain a `with(env e)` clause.
The `with` clause introduces a new variable (`e` for `with(env e)`) to represent
the {ref}`environment <env>` that is passed to a summarized function; the
variable can be used in function summaries.  `with` clauses may only be used if
the entry has a function summary. See {ref}`expression-summary` below for more
information about the environment provided by the `with` clause.


(summaries)=
Summaries
---------

**Summary declarations** are used to replace calls to methods having the
given signature with something that is simpler for the Prover to reason about.
Summaries allow the Prover to reason about external contracts whose code is
unavailable.  They can also be useful to simplify the code being verified to
circumvent timeouts.

A summary is indicated by adding `=>` followed by the summary to the end of
the entry in the methods block.  For example,
```cvl
function f(uint) external returns(uint) => ALWAYS(0);
```
will replace calls to `f` with an `ALWAYS` summary, while
```cvl
function f(uint x) external returns(uint) => cvl_function(x);
```
will replace calls to `f` with the CVL function `cvl_function`.

There are several kinds of summaries available:

 - {ref}`view-summary`.  These assume that the called method have no side-effects
   and simply replace them with a specific value.

 - {ref}`havoc-summary`.  These assume that the called method can have arbitrary
   side-effects on the storage of some contracts.

 - {ref}`dispatcher` assume that the receiver of the method call could be any
   contract that implements the method.

 - {ref}`expression-summary` replace calls to the summarized method with a CVL expression, typically {doc}`functions`
   or {ref}`ghost-axioms`.

 - {ref}`auto-summary` are the default for unresolved calls.
   
 - {ref}`assert-false-summary`. These replace the method with an assert false, effectively checking that no such method is called.

(delete-summary)=
### Summary application

To decide whether to summarize a given function call at a given call site, the
Prover first determines whether it matches any of the declarations in the
methods block, and then uses the declaration and the _calling context_ to
determine whether the call should be replaced by an approximation.

Specifically, the matching is based on three attributes:

(1) The contract in which the method is defined, or a wildcard contract denoted with `_`.

(2) The method signature, with optional named parameters.

(3) The context in which it is called, either `external` or `internal`.
A Solidity function which is defined as `public` can be specified in the methods block as
either `external` or `internal`, and this affects which call sites of the function will
be summarized.

The ability of the Prover to match a particular call site to a method declaration
depends on whether the call was _resolved_ or not, i.e., whether we know which target
contract is called and which method signature is called.
Internal calls are always resolved, but for external calls it is not always the case.
For example, the target contract may be given by a user input, and there is
no single match for the target contract:
```solidity
function callIt(address it) external {
  IERC20(it).transfer(...); // cast `it` to an IERC20 contract and call the `transfer` method
}
```
Similarly, the method signature may also be not resolvable:
```solidity
function callIt(bytes memory data) external {
  address(this).call(data);
}
```

To determine whether a function call is replaced by an approximation summary, the
Prover considers all three aforementioned attributes, the resolved information,
and in addition to that, also the
application policy.  If present, the application policy must
be either `ALL`, `UNRESOLVED`, or `DELETE`.
The `ALL` policy indicates the summary should be applied to all instances of the
specified method, while `UNRESOLVED` applies only to methods that cannot be fully
resolved (i.e., either target contract or the method signature are unknown).
For internal summaries, the default is `ALL`, as all internal functions
are always resolvable; thus `UNRESOLVED` is impossible and will yield an error.
Similarly, for external summaries with contract-specific entries,
the default policy is `ALL`.
Conversely, for any external summary on wildcard contracts, the default
policy is `UNRESOLVED`. One may apply the `ALL` policy to make the summary apply
on all instances of the wildcard method, even on target contracts for which
it was resolved, e.g. by {ref}`linking <--link>`.

A `DELETE` summary is similar to an `ALL` summary, except that the `DELETE`
summary removes the method from the {term}`scene` entirely.  Calling the method
from CVL will produce a rule violation, and {term}`parametric rule`s will not
be instantiated on the deleted method.  This can drastically improve
performance if the deleted method is complex.

The decision to replace a call by an approximation is made as follows:

 * If the function is called from CVL rather than from contract code then it is
   never replaced by a summary.

 * If the code for the function is known at verification time, either because
   it is a method of `currentContract` or because the receiver contract is
   `linked`, then the function is only summarized if the
   resolution type is `ALL`.

 * If the code for the function is not known at verification time, then the
   function call must be summarized.  If no summary is given, the default summary
   type is {ref}`AUTO <auto-summary>`, whose behavior is determined by the type of
   function call.  In this case, the verification report will contain a contract
   call resolution warning.

(summary-resolution)=
### Summary resolution

With {ref}`wildcard entries <wildcard-methods-entries>`, {ref}`catch-all entries <catch-all-entries>`,
and {ref}`exact entries <exact-methods-entries>`, multiple entries could apply to a method.

For example, given a call to `Token.burn()` with a methods block that contains the
following entries:

```cvl
methods {
   function Token.burn() external => HAVOC_ECF;
   function _.burn() external => HAVOC_ALL;
   function Token._ external => NONDET;
}
```

which summary will apply? In CVL, precedence is given to the
summary attached to the *most specific signature*. Exact entries are considered more exact
than wildcard entries, which are themselves more exact than catch-all entries. In other words,
the order of precedence for summaries are:

1. Summaries given for {ref}`exact entries <exact-methods-entries>`
2. Summaries given for {ref}`wildcard entries <wildcard-methods-entries>`
3. Summaries given for {ref}`catch-all entries <catch-all-entries>`

Thus, in this example, the `HAVOC_ECF` summary would apply.

```{note}
An entry that does not have a summary attached does *not* factor into the
precedence of summary application. For example, if the first entry in the above
was instead `function Token.burn() external envfree;` without a summary,
the `HAVOC_ALL` of the wildcard entry will apply.
```

### Summary types

(view-summary)=
#### View summaries: `ALWAYS`, `CONSTANT`, `PER_CALLEE_CONSTANT`, and `NONDET`

These four summary types treat the summarized methods as view methods: the
summarized methods are replaced by approximations that do not update the state
of any contract (aside from any balances transferred with the method call
itself).  They differ in the assumptions made about the return value:

 * The `ALWAYS(v)` approximation assumes that the method always returns `v`.
   The value `v` must be a literal boolean or integer.

 * The `CONSTANT` approximation assumes that all calls to methods with the given
   signature always return the same result.  If the summarized method is
   expected to return multiple results, the approximation returns the correct
   number of values.

 * The `PER_CALLEE_CONSTANT` approximation assumes that all calls to the method
   on a given receiver contract must return the same result, but that the
   returned value may be different for different receiver contracts.  If the
   summarized method is expected to return multiple results, the approximation
   returns the correct number of values.

 * The `NONDET` approximation makes no assumptions about the return values; each
   call to the summarized method may return a different result.  The number of
   returned values is *not* assumed to match the requested number, unless
   {ref}`-optimisticReturnsize` is specified.

```{warning}
Using `CONSTANT` and `PER_CALLEE_CONSTANT` summaries for functions that have
variable-sized outputs is a potential source of {term}`vacuity` and should be
avoided.  Prefer a `NONDET` summary where possible.
```

(havoc-summary)=
#### Havoc summaries: `HAVOC_ALL` and `HAVOC_ECF`

The most conservative summary type is `HAVOC_ALL`.  This summary makes no
assumptions at all about the called function: it is allowed to have arbitrary
side effects on the state of any contract (including the calling contract), and
may return any value.  It can also change any contract's ETH balance in an
arbitrary way.  In effect, calling a method that is summarized by `HAVOC_ALL`
obliterates all knowledge that the Prover has about the state of the contract
before the call.

The `HAVOC_ALL` approximation is {term}`sound`, but it can be overly
restrictive in practice.  In reality, a contract's state cannot be changed in
arbitrary ways, but only according to the contract's methods.  However, the
Prover does not currently have support for more fine-grained reasoning about
the side effects of unknown methods.

A useful middle ground is the `HAVOC_ECF` summary type.  A `HAVOC_ECF`
summarization for a method encodes the assumption that the called method is not
reentrant.  This summarization approximates a method call by assuming it can
have arbitrary effects on contracts other than the contract being verified, but
that it can neither change the current contract's state nor decrease its ETH
balance (aside from value transferred by the method call itself).

The Prover makes no assumptions about the return value of a havoc summary.  For
methods that return multiple values, the approximations are allowed to return
the incorrect number of results.  In most cases, this will cause the calling
method to revert.  If you want to ignore this particular revert condition, you
can pass the {ref}`-optimisticReturnsize` option.

(dispatcher)=
#### `DISPATCHER` summaries

The `DISPATCHER` summary type provides a useful approximation for methods of
interfaces that are implemented by multiple contracts.  For example, the
methods defined by the ERC20 specification are often summarized using the
`DISPATCHER` summary type.

If a function with a `DISPATCHER` summary is called, the Prover will assume
that the receiver of the call is one of the known contract implementations
containing the given signature; the call will then behave the same way that a
normal method call on the receiver would.  The Prover will consider examples
with every possible implementing contract, but multiple `DISPATCHER` method
calls on the same receiver address in the same example will use the same
receiver contract.

The set of contract implementations that the Prover chooses from contains
the set of contracts passed as [arguments to the CLI](/docs/prover/cli/options).
In addition, the Prover may consider an unknown target contract whose methods
are all interpreted using the {ref}`AUTO summary <auto-summary>`.  The presence
of the unknown contract is determined by the optional boolean argument to the
`DISPATCHER` summary:

 * With `DISPATCHER(false)` or just `DISPATCHER`, the unknown contract is
   considered as a possibility

 * With `DISPATCHER(true)`, only the known contract instances are considered

There is an alternative syntax for determining the presence or absence of the
unknown contract:

 * `DISPATCHER(optimistic=<true|false>)` with `true` and 'false` having the same
   meaning as in the other syntax.

In some cases there's a proxy contract that only has a fallback function and
that fallback then delegates function calls it receives to some other contract.
For this case it could be useful for `DISPATCHER` summaries to also inline the
`fallback` function of known contracts. To enable this use the following syntax:
 * `DISPATCHER(optimistic=<true|false>, use_fallback<true|false>)`

```{note}
The most commonly used dispatcher mode is `DISPATCHER(true)`, because in almost
all cases `DISPATCHER(false)` and `AUTO` report the same set of violations. Since
Certora CLI version 7.7.0 when using `_.someFunc() => DISPATCHER(true)` the Prover
first tests that a method `someFunc()` exists in the scene, and if not will fail.
Before this version, this may cause vacuous results.
```

```{note}
`DISPATCHER` summaries cannot be used to summarize library calls.
```
(dispatch-list)=
#### `DISPATCH` list summaries
Similar to `DISPATCHER` which dispatches an unresolved method call to all contracts
implementing the relevant function, we can also dynamically dispatch unresolved calls
to a user-specified list of possible implementations.
This is most commonly useful on calls where the method sighash is unresolved, see 
{ref}`catch-unresolved-calls-entry` for a detailed example in such a case.
We can also use the `DISPATCH` list on {ref}`wildcard-methods-entries`, to
restrict which contract's implemententations of the method to consider:
```cvl
methods {
    function _.foo() external => DISPATCH(true)[ C._, D._ ];
}
```
This will dispatch unresolved calls of a method `foo` to implementations in contracts
`C` and `D`. 
A `DISPATCH` summary is only useful on unresolved calls, so no policy should be specified.

(auto-summary)=
#### `AUTO` summaries

The behavior of the `AUTO` summary depends on the type of call[^opcodes]:

 * Calls to non-library `view` and `pure` methods use the `NONDET` approximation:
   they keep all state unchanged.


 * Calls to library methods and `delegatecall`s are assumed to change
   the caller's storage in an arbitrary way, but are assumed to leave ETH
   balances and the storage of other contracts unchanged.

 * All other calls and constructors use the `HAVOC_ECF` approximation: they are
   assumed to change the state of external contracts arbitrarily but to leave
   the caller's state unchanged.
   `AUTO` summary behavior for the `CALL` opcode
   with 0 length `calldata` can be changed with {ref}`-optimisticFallback`.

[^opcodes]: The behavior of `AUTO` summaries is actually determined by the EVM
  opcode used to make the call: calls made using the `STATICCALL` opcode use
  the `NONDET` summary, calls using `CALL` or `CREATE` opcode use the `HAVOC_ECF`
  summary, and calls using the `DELEGATECALL` and `CALLCODE` opcodes havoc the
  current contract only.
  Modern Solidity versions output opcodes that are consistent with the above
  description, but older versions behave differently.  See
  [State Mutability](https://docs.soliditylang.org/en/v0.8.12/contracts.html#state-mutability)
  in the Solidity manual for details.


(assert-false-summary)=
#### `ASSERT_FALSE` summaries

This summary is a short syntax for a summary that contains an `assert false;` and checks that the summarized method is not reached.
This can be useful for instance, in the presence of unresolved calls in combination with the `unresolved external` syntax to ensure that every unresolved call is actually dispatched correctly (i.e. use `unresolved external in _._ => DISPATCH [...] default ASSERT_FALSE`). It also enables more optimizations in the Prover and may lead to shorter running times.

(expression-summary)=
#### Expression summaries

Contract methods can also be summarized using CVL expressions, typically {doc}`functions` or
{ref}`ghost-axioms` as approximations.  Contract calls to the summarized method
are replaced by evaluation of the CVL expression.

To use a CVL function or ghost as a summary, use a call to the function in
place of the summary type.

If a wildcard entry has a ghost or function summary, the user must explicitly
provide an `expect` clause to the summary.  The `expect` clause tells the
Prover how to interpret the value returned by the summary.  For example:

```cvl
methods {
    function _.foo() external => fooImpl() expect uint256 ALL;
}
```

This entry will replace any call to any external function `foo()` with a call to
the CVL function `fooImpl()` and will interpret the output of `fooImpl` as a
`uint256`.

If a function does not return any value, the summary should be declared with
`expect void`.

````{warning}
You must check that your `expect` clauses are correct.

The Prover cannot always check that the return type declared in the `expect`
clause matches the return type that the contract expects.  Continuing the above
example, suppose the contract being verified declared a method `foo()` that
returns a type other than `uint256`:

```solidity
function foo() external returns(address) {
    ...
}

function bar() internal {
    address x = y.foo();
}
```

In this case, the Prover would encode the value returned by `fooImpl()` as a
`uint256`, and the `bar` method would then attempt to decode this value as an
`address`.  This will cause undefined behavior, and in some cases the Prover
will not be able to detect the error.
````

The function call can only refer directly to the variables defined as arguments
in the summary declarations; expressions that combine those variables are not
supported.

The function call may also use the special variable `calledContract`, which
gives the address of the contract on which the summarized method was called.
More precisely, it equates to `address(this)` in the context of the original
call that is being summarized.
This is useful for identifying the called contract in {ref}`wildcard summaries
<cvl2-wildcards>`. For internal functions, the `calledContract` is also
the calling contract, since they are the same.
For library functions and delegate calls the `calledContract` is the contract
calling the function.
Similarly, there is another special variable `executingContract`, which
gives the address of the contract making the call to the function that is
summarized. For internal, delegate and library calls, `executingContract` is
the same as `calledContract`. They differ only in non-delegate external calls, 
where `calledContract` will be the receiver of the call and `executingContract`
will be the caller.
The `calledContract` and `executingContract` keywords may only be used inside
the `methods` block, and `executingContract` also 
in {ref}`hook bodies<executingContract>`.

For example, a wildcard summary for a `transferFrom` method may apply to
multiple ERC20 contracts; the summary can update the correct ghost variables as
follows:

```cvl
methods {
    function _.transferFrom(address from, address to, uint256 amount) external
        => cvlTransferFrom(calledContract, from, to, amount);
}

ghost mapping(address => mapping(address => mathint)) tokenBalances;

function cvlTransferFrom(address token, address from, address to, uint amount) {
    if (...) {
        tokenBalances[token][from] -= amount;
        tokenBalances[token][to]   += amount;
    }
}
```

When summarizing an internal library function to an expression, you cannot refer to a variable that is `storage`,
since CVL functions cannot take variables that are `storage`; for summaries involving `storage` references,
refer to {ref}`rerouting summaries <rerouting-summaries>`. You can refer to other variables,
or use a summarization that doesn't take parameters:
```cvl
methods {
    function MyLibrary.guess(int[] storage numbers) internal returns (int) => goodGuess1(numbers); // not allowed
    function MyLibrary.guess(int[] storage numbers, int myGuess) internal returns (int) => goodGuess2(myGuess); // allowed
    function MyLibrary.guess(int[] storage numbers) internal returns (int) => ALWAYS(42); // allowed
}

function goodGuess1(int[] numbers) returns int { return 4; }
function goodGuess2(int myGuess) returns int { return myGuess; }
```

The call can also refer to a variable of type `env` introduced by a
{ref}`with(env) clause <with-env>`.  Here `e` may be replaced with any valid identifier.

The variable defined by the `with` clause contains an {ref}`env type <env>`
giving the context for the summarized function.  This context may be different
from the `env` passed to the original call from the spec.  In particular:

 - `e.msg.sender` and `e.msg.value` refer to the sender and value from the most recent call to a
   non-library[^library-with-env] external function (as in Solidity)

 - The variables `e.tx.origin`, `e.block.number`, and `e.block.timestamp` will
   be the same as the the environment for the outermost function call.

[^library-with-env]: As [in solidity][solidity-delegate-call], `msg.sender` and `msg.value` do not
  change for `delegatecall`s or library calls.

[solidity-delegate-call]: https://docs.soliditylang.org/en/v0.8.6/introduction-to-smart-contracts.html?#delegatecall-callcode-and-libraries

Continuing the above example, one can use the `env` to summarize the `transfer`
method:

```cvl
methods {
    function _.transfer(address to, uint256 amount) external with(env e)
        => cvlTransfer(calledContract, e, to, amount) expect void;
}

function cvlTransfer(address token, env passedEnv, address to, uint amount) {
    ...
}

rule example {
    env e;
    address sender;
    require e.msg.sender == sender;
    c.process(e);
}
```

In this example, if the `process` method calls `t.transfer(...)`, then in the
`cvlTransfer` function, `token` will be `t`, `passedEnv.msg.sender` will be
`c`, and `passedEnv.tx.origin` will be `sender`.


There is a restriction on the functions that can be used as approximations.
Namely, the types of any arguments passed to or values returned from the summary
must be {ref}`convertible <type-conversions>` between CVL and Solidity types.
Arguments that are not accessed in the summary may have any type.

You can still summarize functions that take unconvertible types as arguments,
but you cannot access those arguments in your summary.

In case of recursive calls due to the summarization, the recursion limit can be set with
`--summary_recursion_limit N'` where `N` is the number of recursive calls allowed (default 0).
If `--optimistic_summary_recursion` is set, the recursion limit is assumed, i.e. one will never get a counterexample going above the recursion limit.
Otherwise, if it is possible to go above the recursion limit, an assert will fire, producing a counterexample to the rule.

(rerouting-summaries)=
#### Rerouting summaries
As mentioned above, expression summaries cannot access parameters with `storage` location.
In such cases where summaries require accessing `storage` located variables, rerouting summaries can be used.
As the name suggests, a rerouting summary "reroutes" a function call which accepts `storage` located
values to a harness function written in Solidity.

The syntax for a rerouting summary is exactly the same as an {ref}`expression summary <expression-summary>`, 
except the expression used
as the summary is an invocation of an `external` library function. For example:

```cvl
methods {
   function Bank.computeInterest(
      Bank.Vault storage v, address depositor, uint principal
   ) internal returns (uint)
      => VaultHarness.computeInterestHarness(v, depositor, principal);
}
```

Where `VaultHarness` looks like the following:

```solidity
library VaultHarness {
    function computeInterestHarness(
       Bank.Vault storage v, address depositor, uint principal
    ) external returns (uint) {
	   // ...
    }
}
```

This summary replaces the invocation of the internal function `computeInterest` with a `delegatecall` into `VaultHarness.computeInterestHarness`.
We will call the `VaultHarness.computeInterestHarness` function the "summary harness".
Via the `delegatecall`, the harness body `computeInterestHarness` may access `Bank`'s storage through the parameter `v`.

```{warning}
The harness body (in our example, `computeInterestHarness`) can contain arbitrary Solidity code,
and may thus mutate the storage of the contract under verification in unsafe or unsound ways
via the `storage` parameters. Summary harnesses should avoid modifying the storage if at all
possible, or extreme care should be exercised so that any storage updates are sound.
```

By the same token, any mutations to `memory` parameters will **not** be reflected in the 
summarized function caller's memory. Other environment parameters (e.g., the value of `this`)
are bound using the same semantics as a `delegatecall`.

```{note}
The `calldata` in the summary harness will contain an encoding of the summary harness arguments,
which will not be the same as the `calldata` observed in the original, summarized function.
```

The rerouting summaries come with some restrictions on their use.

1. Rerouting summaries can only be applied to `internal` functions [^public-vs-private]
2. The summary harness must return the same types as the summarized function
3. The rerouting summary must consist **only** of the call to the summary harness. That is, `... => 1 + VaultHarness.computeInterestHarness(...)`
  is illegal.
4. The summary harness **must** be defined as an external function in a library contract.
5. The library contract must be included in the {term}`scene`.
6. The arguments passed to the summary harness must be some permutation of a subset of the
  original function's `storage`, `memory`, and value parameters.[^parameters] Expressions involving the
  internal function parameters may **not** be used.
7. The summary harness' signature must exactly match the parameters passed through by the rerouting summary.

To elaborate on point 6: the arguments in the invocation of the summary harness **must** be one
of the parameters bound by the method entry, provided that parameter does not have `calldata` location.
Eligible parameters may be duplicated, reordered or simply dropped. For example, in our `computeInterestHarness`
example, if the summary harness didn't need the value of `depositor` we could have written:

```cvl
   function Bank.computeInterest(
      Bank.Vault storage v, address depositor, uint principal
   ) internal returns (uint)
      => VaultHarness.computeInterestHarness(v, principal);
```

With the appropriate update to the signature of `computeInterestHarness`. In addition, we could have written
`computeInterestHarness(principal, v)`, again with the appropriate update to the function signature.

Any expression that is not one of the parameters bound by the entry cannot be used. For example,
the following is an **illegal** rerouting summary due to the addition on `principal`:

```cvl
   function Bank.computeInterest(
      Bank.Vault storage v, address depositor, uint principal
   ) internal returns (uint)
      => VaultHarness.computeInterestHarness(v, depositor, principal + 3);
```

Further, the following is also illegal, as the principal argument is now an expression that is not one of the parameters:

```cvl
   function Bank.computeInterest(
      Bank.Vault storage v, address depositor, uint principal
   ) internal returns (uint)
      => VaultHarness.computeInterestHarness(v, depositor, cvlGetPrincipal());
```

When resolving rerouting summaries, there is no subtyping of function arguments; as mentioned in point 7, the summary harness
signature must exactly match the passed arguments. Formally, an entry binds parameters _p{sub}`0`_, _p{sub}`1`_, ..., _p{sub}`k`_,
each with declared type _t{sub}`0`_, _t{sub}`1`_, ..., _t{sub}`k`_. Some permutation of these parameters is passed
as arguments to the summary harness _f_: _p{sub}`i`_, _p{sub}`j`_, .... The types of these parameters, _t{sub}`i`_, _t{sub}`j`_, ...
determine the expected signature of _f_, that is, a function _f_(_t{sub}`i`_, _t{sub}`j`_, ...) must be declared in the library contract.

To give a concrete example, the following would **not** work:

```cvl
   function Bank.computeInterest(
      Bank.Vault storage v, address depositor, uint128 principal
   ) internal returns (uint)
      => VaultHarness.computeInterestHarness(v, depositor, principal);
```
```solidity
library VaultHarness {
   function computeInterestHarness(
      Bank.Vault storage v, address depositor, uint256 principal
   ) external returns (uint) { ... }
}
```

Note that the declared type of `principal` in the signature of `computeInterestHarness` is `uint256`, where as
the type of `principal` bound in the entry is `uint128`.

```{note}
To reiterate: the body of the summary harness is treated like any other Solidity code,
and thus may make external calls, contain loops, or call other internal functions
(which may themselves be summarized).
```

[solidity-value-types]: https://docs.soliditylang.org/en/v0.8.11/types.html#value-types

[^public-vs-private]: As with other summaries, a rerouting `internal` summary can be applied to `public` and `private` functions.

[^parameters]: In other words, parameters with `calldata` location may not be passed through to the summary harness. This restriction may be lifted in the future.
