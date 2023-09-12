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
                     ( exact_pattern | wildcard_pattern | catch_all_pattern)
                     [ "returns" "(" evm_types ")" ]
                     [ "envfree" |  "with" "(" "env" id ")" ]
                     [ "=>" method_summary [ "UNRESOLVED" | "ALL" ] ]
                     ";"

exact_pattern    ::= [ id "." ] id "(" evm_params ")" visibility [ "returns" "(" evm_types ")" ]
wildcard_pattern ::= "_" "." id "(" evm_params ")" visibility
catch_all_pattern :: id "." "_" "external"

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
    function mint(address _to, uint256 _amount, bytes calldata _data) external;
}
```

(with-env)=
`with(env e)` clauses
---------------------

After the `optional` annotation, an entry may contain a `with(env e)` clause.
The `with` clause introduces a new variable (`e` for `with(env e)`) to represent
the {ref}`environment <env>` that is passed to a summarized function; the
variable can be used in function summaries.  `with` clauses may only be used if
the entry has a function summary. See {ref}`function-summary` below for more
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

```{note}
The most commonly used dispatcher mode is `DISPATCHER(true)`, because in almost
all cases `DISPATCHER(false)` and `AUTO` report the same set of violations.
```

```{note}
`DISPATCHER` summaries cannot be used to summarize library calls.
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

The function call may also use the special variable `calledContract`, which
gives the address of the contract on which the summarized method was called.
This is useful for identifying the called contract in {ref}`wildcard summaries
<cvl2-wildcards>`.  The `calledContract` keyword is only defined in the `methods`
block.

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
        => cvlTransfer(calledContract, e, to, amount);
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
  
Function summaries for *internal* methods have a few additional restrictions on 
their arguments and return types:
 - arrays (including static arrays, `bytes`, and `string`) are not supported
 - struct fields must have [value types][solidity-value-types]
 - `storage` and `calldata` structs are not supported, only `memory`

You can still summarize functions that take unconvertible types as arguments,
but you cannot access those arguments in your summary.

In case of recursive calls due to the summarization, the recursion limit can be set with 
`--prover_args '-contractRecursionLimit N'` where `N` is the number of recursive calls allowed (default 0).
If `--optimistic_loop` is set, the recursion limit is assumed, i.e. one will never get a counterexample going above the recursion limit. 
Otherwise, if it is possible to go above the recursion limit, an assert will fire, producing a counterexample to the rule.

[solidity-value-types]: https://docs.soliditylang.org/en/v0.8.11/types.html#value-types

