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

The syntax for the `methods` block is given by the following [EBNF grammar](syntax):

```
methods          ::= "methods" "{" { method_spec } "}"

method_spec      ::= "function"
                     ( exact_pattern | wildcard_pattern | catchall_pattern )
                     [ "returns" types ]
                     [ "envfree" ]
                     [ "=>" method_summary [ "UNRESOLVED" | "ALL" ] ]
                     ";"

exact_pattern    ::= [ id "." ] id "(" evm_params ")" visibility [ "returns" "(" evm_types ")" ]
wildcard_pattern ::= "_" "." id "(" evm_params ")" visibility
catchall_pattern ::= id "." "_"

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
                   | id "(" [ id { "," id } ] ")"
```

See {doc}`types` for the `evm_type` production.  See {doc}`basics`
for the `id` production.  See {doc}`expr` for the `expression` production.

Methods entry patterns
----------------------

Each entry in the methods block contains a pattern that matches some set of
contract functions.

 - {ref}`exact-methods-entries` match a single method of a single contract.
 - {ref}`wildcard-methods-entries` match a single method signature on all contracts.
 - {ref}`catchall-methods-entries` match all methods of a single contract.

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

Exact entries may contain {ref}`summaries <summaries>`, {ref}`envfree`, and
{ref}`optional`.

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

(catchall-methods-entries)=
### Catch-all entries

```{versionadded} 4.0
% TODO: link to changelog
```

Catch-all entries match all methods of a given contract.

% TODO: finish

### Location annotations

```{versionadded} 4.0
Location annotations were {ref}`introduced with CVL 2 <cvl2-locations>`.
```

Methods block entries for internal functions must contain either `calldata`,
`memory`, or `storage` annotations for all arguments with reference types (such
as arrays).

For methods block entries of external functions the location annotation must be
omitted unless it's the `storage` annotation on an external library function, in
which case it is required (the reasoning here is to have the information required
in order to correctly calculate a function's sighash).

(methods-visibility)=
### Visibility modifiers

```{versionadded} 4.0
Visibility modifiers were {ref}`introduced with CVL 2 <cvl2-visibility>`.
```

Entries in the methods block must be marked either `internal` or `external`; the
entry will only match a function with the indicated visibility.

If a function is declared `public` in Solidity, then the Solidity compiler
creates an internal implementation method, and an external wrapper method that
calls the internal implementation.  Therefore, you can summarize a `public`
method by marking the summarization `internal`.

The behavior of `internal` vs. `external` summarization for public methods can
be confusing, especially because functions called directly from CVL are not
summarized.

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
contract contains the `mint` method and are skipped otherwise.  For example:

```cvl
methods {
    function mint(address _to, uint256 _amount, bytes calldata _data) external;
}
```

To do so, you can add the `optional` annotation to the exact methods block
entry for the function.  Any rules that reference an optional method will be
skipped if the method does not exist in the contract.

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

 - {ref}`dispatcher`.  A `DISPATCHER` summary assumes that the receiver
   of the method call is one of a specific set of contracts.

 - {ref}`function-summary` replace calls to the summarized method with {doc}`functions`
   or {ref}`ghost-axioms`.

 - {ref}`auto-summary` are the default for unresolved calls.

### Summary application

To decide whether to summarize a given internal or external function call, the
Prover first determines whether it matches any of the declarations in the
methods block, and then uses the declaration and the calling context to
determine whether the call should be replaced by an approximation.[^dont-summarize]

To determine whether a function call is replaced by an approximation, the
Prover considers the context in which the function is called in addition to the
application policy for its signature.  If present, the application policy must
be either `ALL` or `UNRESOLVED`; the default policy is `ALL` with the exception
of `DISPATCHER` summaries, which have a default of `UNRESOLVED`.  The decision
to replace a call by an approximation is made as follows:

 * If the function is called from CVL rather than from contract code then it is
   never replaced by a summary.

 * If the code for the function is known at verification time, either because
   it is a method of `currentContract` or because the receiver contract is
   {ref}`linked <linking>`, then the function is only summarized if the
   resolution type is `ALL`.

 * If the code for the function is not known at verification time, then the
   function call must be summarized.  If no summary is given, the default summary
   type is {ref}`AUTO <auto-summary>`, whose behavior is determined by the type of
   function call.  In this case, the verification report will contain a contract
   call resolution warning.

[^dont-summarize]: The `@dontsummarize` tag on method calls affects the
  summarization behavior.  See {ref}`call-expr`.

### Summary types

(view-summary)=
#### View summaries: `ALWAYS`, `CONSTANT`, `PER_CALLEE_CONSTANT`, and `NONDET`

These four summary types treat the summarized methods as view methods: the
summarized methods are replaced by approximations that do not update the state
of any contract (aside from any balances transferred with the method call
itself).  They differ in the assumptions made about the return value:

 * The `ALWAYS(v)` approximation assumes that the method always returns `v`

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

% TODO: restrictions on summaries

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

```{note}
The most commonly used dispatcher mode is `DISPATCHER(true)`, because in almost
all cases `DISPATCHER(false)` and `AUTO` report the same set of violations.
```

(auto-summary)=
#### `AUTO` summaries

The behavior of the `AUTO` summary depends on the type of call[^opcodes]:

 * Calls to non-library `view` and `pure` methods use the `NONDET` approximation:
   they keep all state unchanged.

 * Normal calls and constructors use the `HAVOC_ECF` approximation: they are
   assumed to change the state of external contracts arbitrarily but to leave
   the caller's state unchanged.

 * Calls to library methods and `delegatecall`s are assumed to change
   the caller's storage in an arbitrary way, but are assumed to leave ETH
   balances and the storage of other contracts unchanged.

[^opcodes]: The behavior of `AUTO` summaries is actually determined by the EVM
  opcode used to make the call: calls made using the `STATICCALL` opcode use
  the `NONDET` summary, calls using `CALL` or `CREATE` opcode use the `HAVOC_ECF`
  summary, and calls using the `DELEGATECALL` and `CALLCODE` opcodes havoc the
  current contract only.
  Modern Solidity versions output opcodes that are consistent with the above
  description, but older versions behave differently.  See
  [State Mutability](https://docs.soliditylang.org/en/v0.8.12/contracts.html#state-mutability)
  in the Solidity manual for details.

(function-summary)=
#### Function summaries

Contract methods can also be summarized using CVL {doc}`functions` or
{ref}`ghost-axioms` as approximations.  Contract calls to the summarized method
are replaced by calls to the specified CVL functions.

To use a CVL function or ghost as a summary, use a call to the function in
place of the summary type.  The function call can only refer directly to the
variables defined as arguments in the summary declarations; expressions
that combine those variables are not supported.

There are a few restrictions on the functions that can be used as approximations:

 - Functions used as summaries are not allowed to call contract functions.

 - The types of any arguments passed to or values returned from the summary
   must be {ref}`convertible <type-conversions>` between CVL and Solidity types.
   Arguments that are not accessed in the summary may have any type.

Function summaries for *internal* methods have a few additional restrictions on
their arguments and return types:
 - arrays (including static arrays, `bytes`, and `string`) are not supported
 - struct fields must have [value types][solidity-value-types]
 - `storage` and `calldata` structs are not supported, only `memory`

You can still summarize functions that take unconvertible types as arguments,
but you cannot access those arguments in your summary.

[solidity-value-types]: https://docs.soliditylang.org/en/v0.8.11/types.html#value-types

