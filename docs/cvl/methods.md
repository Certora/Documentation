The Methods Block
=================

The `methods` block contains declarations of contract methods.  Although CVL is
able to call contract functions even if they are not declared in the methods
block, the methods block allows users to specify additional information about
contract methods, and can help document the expected interface of the contract.

There are two kinds of declarations:

* **Non-summary declarations** document the interface between the specification
  and the contracts used during verification.  Non-summary declarations also
  support spec reuse by allowing specs written against a complete interface to
  be checked against a contract that only implements part of the interface.

* **Summary declarations** are used to replace calls to methods having the
  given signature with something that is simpler for the Prover to reason about.
  Summaries allow the Prover to reason about external contracts whose code is
  unavailable.  They can also be useful to simplify the code being verified to
  circumvent timeouts.

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

The syntax for the `methods` block is given by the following [EBNF grammar](syntax):

```
methods          ::= "methods" "{" { method_spec } "}"

method_spec      ::= ( sighash | [ id "." ] id "(" evm_params ")" )
                     [ "returns" types ]
                     [ "envfree" ]
                     [ "=>" method_summary [ "UNRESOLVED" | "ALL" ] ]
                     [ ";" ]

evm_param ::= evm_type [ id ]

types ::= cvl_type { "," cvl_type }
        | "(" [ evm_type [ id ] { "," evm_type [ id ] } ] ")"

method_summary   ::= "ALWAYS" "(" value ")"
                   | "CONSTANT"
                   | "PER_CALLEE_CONSTANT"
                   | "NONDET"
                   | "HAVOC_ECF"
                   | "HAVOC_ALL"
                   | "DISPATCHER" [ "(" ( "true" | "false" ) ")" ]
                   | "AUTO"
                   | id "(" [ id { "," id } ] ")" [ "with" "(" "env" id ")" ]

```

See {doc}`types` for the `evm_type` and `cvl_type` productions.  See {doc}`basics`
for the `id` production.  See {doc}`statements` for the `block` production, and
{doc}`expr` for the `expression` production.

(envfree)=
Entries in the `methods` block
------------------------------

Each entry in the methods block denotes either the sighash or the type signature
for a contract method.  Methods of contracts that are introduced by {doc}`using
statements <using>` can also be described by prefixing the method name with
the contract variable name.  For example, if contract `C` is introduced by the
statement `using C as c`, then the method `f(uint)` of contract `c` can be
referred to as `c.f(uint)`.

It is possible for a method signature to appear in the `methods` block but not
in the contract being verified.  In this case, the Prover will skip any rules
that mention the missing method, rather than reporting an error.  This behavior
allows reusing specifications on contracts that only support part of an
interface: only the supported methods will be verified.

Following the method signature is an optional `returns` clause.  If a method
declaration contains a `returns` clause, the declared return type must match
the contract method's return type.  If the `returns` clause is omitted, the
return type is taken from the contract method's return type.

Following the `returns` clause is an optional `envfree` tag.  Marking a method
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

Finally, the method entry may contain an optional summarization (indicated by
`=>` followed by the summary type and an optional application policy).  A
summarized declaration indicates that the Prover should replace some calls to
the summarized function by an approximation.  This is an important technique
for working around Prover timeouts and also for working with external contracts
whose implementation is not fixed at verification time[^internalSummaryCaveat].

[^internalSummaryCaveat]: Because the internal method calls are not explicit in
  the compiled bytecode, the Prover needs to use heuristics to determine where
  internal methods are called in order to summarize them.  Occasionally, these
  heuristics are unable to locate an internal method call, and therefore they
  remain unsummarized.  The {ref}`-showInternalFunctions` option can aid in
  determining whether the Prover was able to identify a specific internal
  function call or not.

The summary type determines what type of approximation is used to replace the
function calls.  The available types are described in the following sections:

 * {ref}`view-summary`
 * {ref}`havoc-summary`
 * {ref}`dispatcher`
 * {ref}`auto-summary`
 * {ref}`function-summary`

The application policy determines which function calls are replaced by
approximations.  See {ref}`summaries` for details.

```{todo}
Some of the method summary types are unsupported for methods having certain
argument or return types.  The exact limitations are currently undocumented.
```

(summaries)=
Which function calls are summarized
-----------------------------------

To decide whether to summarize a given internal or external function call, the
Prover first determines whether it matches any of the declarations in the
methods block, and then uses the declaration and the calling context to
determine whether the call should be replaced by an approximation.

To determine whether a call matches a declaration, the tool computes an ABI
signature for both the call and the method summary.  This ABI signature may be
simpler than the declaration in Solidity or the `methods` block, because
ABI signatures are less expressive than Solidity type signatures.  In
particular, structs are converted into tuples and location annotations such as
`memory` or `calldata` are dropped.  If there are multiple internal functions or
multiple method summaries that are converted to the same summarized ABI
signature, the Prover will report an error.

Method summaries match all calls with the matching ABI signature, including
internal methods and external methods on all contracts.  There is currently no
way to apply different summaries to different contracts or to summarize some
calls and not others to methods with the same ABI signature.  For this reason,
it is not possible to specify a summary for a method that is qualified by a
contract name.

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

```{todo}
The `@dontsummarize` tag on method calls is currently undocumented but likely
affects the summarization behavior.  See {ref}`call-expr`.
```

Summary types
-------------

(view-summary)=
### View summaries: `ALWAYS`, `CONSTANT`, `PER_CALLEE_CONSTANT`, and `NONDET`

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

(havoc-summary)=
### Havoc summaries: `HAVOC_ALL` and `HAVOC_ECF`

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
### `DISPATCHER` summaries

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
### `AUTO` summaries

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
### Function summaries

Contract methods can also be summarized using CVL {doc}`functions` or
{ref}`ghost-axioms` as approximations.  Contract calls to the summarized method
are replaced by calls to the specified CVL functions.

There are a few restrictions on the functions that can be used as approximations:
 - Functions used as summaries are not allowed to call contract functions.
 - Functions used as summaries may not have accept arguments or return values that have struct or array types.

To use a CVL function or ghost as a summary, use a call to the function in
place of the summary type.  The function call can refer to the
variables defined as arguments in the summary declarations; expressions
that combine those variables are not supported.

The function call may also refer to the special variable `calledContract`.
This variable gives address of the contract on which the summarized method was
called (this is useful for identifying the called contract in {ref}`wildcard
summaries <cvl2-wildcards>`).

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

The call can also refer to a variable of type `env` introduced by a `with(env
e)` annotation.  Here `e` may be replaced with any valid identifier.

The variable defined by the `with` clause contains an {ref}`` `env` type <env>``
giving the context for the summarized function.  This context may be different
from the `env` passed to the original call from the spec.  In particular,
`e.msg.sender` refers to the most recent contract to call an external function
(as in Solidity).  The variable `e.tx.origin` will be the same as the
`msg.sender` of the environment for the outermost function call.

Continuing the above example, one can use the `env` to summarize the `transfer`
method:

```cvl
methods {
    function _.transfer(address to, uint256 amount) external
        => cvlTransfer(calledContract, e, to, amount) with(env e);
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

