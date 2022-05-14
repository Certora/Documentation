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
and are therefore {term}`unsound` (with the exception of `HAVOC_ALL` summaries,
which are always sound).
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
                   | [ "with" "(" "env" id ")" ] block
                   | [ "with" "(" "env" id ")" ] expression

```

See {doc}`types` for the `evm_type` and `cvl_type` productions.  See {doc}`basics`
for the `id` production.  See {doc}`statements` for the `block` production, and
{doc}`expr` for the `expression` production.

(envfree)=
Entries in the `methods` block
------------------------------

Each entry in the methods block denotes either the sighash or the ABI signature
for a contract method.  Methods of contracts that are introduced by {doc}`using
statements <using>` can also be described by prefixing the method name with
the contract variable name.  For example, if contract `C` is introduced by the
statement `using C as c`, then the method `f(uint)` of contract `c` can be
referred to as `c.f(uint)`.

It is possible for a method signature to appear in the `methods` block but not
in the contract being verified.  In this case, the prover will skip any rules
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
first argument.  Second, the prover will verify that the method implementation
in the contract being verified does not depend on any of the environment
variables.  The results of this check are displayed on the verification report
as a separate rule called `envfreeFuncsStaticCheck`.

```{todo}
There is a separate check called `envfreeFuncsAreNonpayable`.  Why is this
necessary?
```

Finally, the method entry may contain an optional summarization (indicated by
`=>` followed by the summary type and an optional application policy).  A
summarized declaration indicates that the prover should replace some calls to
the summarized function by an approximation.  This is an important technique
for working around prover timeouts and also for working with external contracts
whose implementation is not fixed at verification time.

The summary type determines what type of approximation is used to replace the
function calls.  The available types are described in the following sections:

 * {ref}`const-summary`
 * {ref}`havoc-summary`
 * {ref}`dispatcher`
 * {ref}`auto-summary`
 * {ref}`ghost-summary`
 * {ref}`function-summary`

The application policy determines which function calls are replaced by
approximations.  See {ref}`summaries` for details.

(summaries)=
Summarized function calls
-------------------------

Whether a function call is replaced by an approximation depends on the context
in which the function is called in addition to the application policy for its
signature.  If present, the application policy must be either `ALL` or
`UNRESOLVED`; the default policy is TODO.  The decision is made as follows:

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
The default application policy is currently undocumented.
```

```{todo}
The old documentation is ambiguous about the behavior of `UNRESOLVED` summaries
for internal methods.
```

Method summaries apply to all calls, regardless of the receiver address.  There
is currently no way to apply different summaries to different contracts or to
summarize some calls and not others to methods with the same ABI signature.
For this reason, it is not possible to specify a summary for a method that is
qualified by a contract name.

Summary types
-------------

(const-summary)=
### View summaries: `ALWAYS`, `CONSTANT`, `PER_CALLEE_CONSTANT`, and `NONDET`

These four summary types treat the summarized methods as view methods: the
summarized methods are replaced by approximations that do not update the state
of any contract.  They differ in the assumptions made about the return value:

 * The `ALWAYS(v)` approximation assumes that the method always returns `v`

 * The `CONSTANT` approximation assumes that all calls to methods with the given
   signature always return the same result.

 * The `PER_CALLEE_CONSTANT` approximation assumes that all calls to the method
   on a given receiver contract must return the same result, but that the
   returned value may be different for different receiver contracts.

 * The `NONDET` approximation makes no assumptions about the return values; each
   call to the summarized method may return a different result.

```{todo}
The following note from the old documentation needs clarification:

**A technical remark about `returnsize`:** For `CONSTANT` and `PER_CALLEE`
summaries, the summaries extend naturally to functions that return multiple
return values. The assumption is that the return size in bytes is a multiple of
32 bytes (as standard in Solidity). The `returnsize` variable is updated
accordingly and is determined by the size requested by the caller.

If you do not trust the target contract to return exactly the number of
arguments dictated by the Solidity-level interface, **do not use** `CONSTANT`
and `PER_CALLEE_CONSTANT`summaries.

In very special cases, one may set the `returnsize` optimistically even when
havocing, based on information about the invoked function's signature and the
available functions in the verification context, set with
`-optimisticReturnsize`.
```

(havoc-summary)=
### Havoc summaries: `HAVOC_ALL` and `HAVOC_ECF`

The most conservative summary type is `HAVOC_ALL`.  This summary makes no
assumptions at all about the called function: it is allowed to have arbitrary
side effects on the state of any contract (including the calling contract), and
may return any value.  It can also change any contract's ETH balance in an
arbitrary way.  In effect, calling a method that is summarized by `HAVOC_ALL`
obliterates all knowlege that the prover has about the state of the contract
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

(dispatcher)=
### `DISPATCHER` summaries

The `DISPATCHER` summary type provides a useful approximation for methods of
interfaces that are implemented by multiple contracts.  For example, the
methods defined by the ERC20 specification are often summarized using the
`DISPATCHER` summary type.

If a function with a `DISPATCHER` summary is called, the Prover will assume
that the receiver of the call is one of the known contract implementations
containing the given signature; the call will then behave the same way that a
normal method call on the receiver would.  The prover will consider examples
with every possible implementing contract, but multiple `DISPATCHER` method
calls on the same receiver address in the same example will use the same
receiver contract.

The set of contract implementations that the prover chooses from contains
the set of contracts passed as [arguments to the CLI](../cli/options).
In addition, the prover may consider an unknown target contract whose methods
are all interpreted using the {ref}`AUTO summary <auto-summary>`.  The presence
of the unknown contract is determined by the optional boolean argument to the
`DISPATCHER` summary:

 * With `DISPATCHER(false)` or just `DISPATCHER`, the unknown contract is
   considered as a possiblity

 * With `DISPATCHER(true)`, only the known contract instances are considered

The most commonly used option is `DISPATCHER(true)`, because in most cases the
behavior of `DISPATCHER(false)` is equivalent to that of `AUTO`.

(auto-summary)=
### `AUTO` summaries

The behavior of the `AUTO` summary depends on the type of call[^opcodes]:

 * Calls to non-library `view` and `pure` methods use the `NONDET` approximation:
   they keep all state unchanged.

 * Normal calls and constructors use the `HAVOC_ECF` approximation: they are
   assumed to change the state of external contracts arbitrarily but to leave
   the caller's state unchanged.

 * Calls to library methods are assumed to change the caller's state in an
   arbitrary way, but are assumed to leave the state of other contracts
   unchanged.

[^opcodes]: The behavior of `AUTO` summaries is actually determined by the EVM
  opcode used to make the call: calls made using the `STATICCALL` opcode use
  the `NONDET` summary, calls using `CALL` or `CREATE` opcode use the `HAVOC_ECF`
  summary, and calls using the `DELEGATECALL` and `CALLCODE` opcodes havoc the
  current contract only.
  Modern Solidity versions output opcodes that are consistent with the above
  description, but older versions behave differently.  See
  [State Mutability](https://docs.soliditylang.org/en/v0.8.12/contracts.html#state-mutability)
  in the Solidity manual for more details.

(ghost-summary)=
### Ghost summaries

```{todo}
This feature is currently undocumented.
```

(function-summary)=
### Function summaries

```{todo}
This feature is currently undocumented.
```

