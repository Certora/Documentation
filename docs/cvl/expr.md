Expressions
===========

A CVL expression is anything that represents a value.  This page documents all
possible expressions in CVL and explains how they are evaluated.

```{contents}
```

Syntax
------

The syntax for CVL expressions is given by the following [EBNF grammar](syntax):

```
expr ::= literal
       | unop expr
       | expr binop expr
       | "(" exprs ")"
       | expr "?" expr ":" expr
       | [ "forall" | "exists" ] type id "." expr

       | expr "." id
       | id [ "[" expr "]" { "[" expr "]" } ]
       | id "(" types ")"

       | function_call

       | expr "in" id

function_call ::=
       | [ id "." ] id
         [ "@" ( "norevert" | "withrevert" | "dontsummarize" ) ]
         "(" exprs ")"
         [ "at" id ]


literal ::= "true" | "false" | number | string

unop  ::= "~" | "!" | "-"

binop ::= "+" | "-" | "*" | "/" | "%" | "^"
        | ">" | "<" | "==" | "!=" | ">=" | "<="
        | "&" | "|" | "<<" | ">>" | "&&" | "||"
        | "=>" | "<=>" | "xor" | ">>>"

specials_fields ::=
           | "block" "." [ "number" | "timestamp" ]
           | "msg"   "." [ "address" | "sender" | "value" ]
           | "tx"    "." [ "origin" ]
           | "length"
           | "selector" | "isPure" | "isView" | "numberOfArguments" | "isFallback"

special_vars ::=
           | "lastReverted" | "lastHasThrown"
           | "lastStorage"  | "currentStorage"
           | "allContracts"
           | "lastMsgSig"
           | "_"
           | "max_uint" | "max_address" | "max_uint8" | ... | "max_uint256"
           | "nativeBalances"
           | "calledContract"

cast_functions ::=
    | require_functions | to_functions | assert_functions

require_functions ::=
    | "require_uint8" | ... | "require_uint256" | "require_int8" | ... | "require_int256"

to_functions ::=
    | "to_mathint" | "to_bytes1" | ... | "to_bytes32"

assert_functions ::=
   | "assert_uint8" | ... | "assert_uint256" | "assert_int8" | ... | "assert_int256"

contract ::= id | "currentContract"
```

See {doc}`basics` for the `id`, `number`, and `string` productions.
See {doc}`types` for the `type` production.

Basic operations
----------------

CVL provides the same basic arithmetic, comparison, bitwise, and logical
operations for basic types that solidity does, with a few differences listed
in this section and the next.  The [precedence and associativity rules][operators]
are standard.

[operators]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Operator_Precedence#table

```{caution}
One significant difference between CVL and Solidity is that in Solidity, `^`
denotes bitwise exclusive or and `**` denotes exponentiation, whereas in CVL,
`^` denotes exponentiation and `xor` denotes exclusive or.
```

```{todo}
The `>>>` operator is currently undocumented.
```

See {doc}`mathops` for more information about the interaction between
mathematical types and the meaning of mathematical operations.

(string-interpolation)=
String interpolation
--------------------

String literals that appear in assertion messages or rule descriptions can
contain placeholders that are replaced by explicit values in the verification
report.  A variable can be included by prefixing it with a `$`, while more
complex expressions can be included by surrounding them with `${...}`.

For example:

```cvl
rule example(method f, uint x)
description "$f should output 0 on $x with ${e.msg.sender}"
{
    env e;
    assert f(e,x) == 0, "failed with timestamp ${e.block.timestamp}";
}
```

(logic-exprs)=
Extended logical operations
---------------------------

CVL also adds several useful logical operations:

 * Like `&&` or `||`, an *implication* expression `expr1 => expr2` requires
   `expr1` and `expr2` to be boolean expressions and is itself a boolean
   expression.  `expr1 => expr2` evaluates to `false` if and only if `expr1`
   evaluates to `true` and `expr2` evaluates to `false`.  `expr1 => expr2` is
   equivalent to `!expr1 || expr2`.

   For example, the statement `assert initialized => x > 0;` will only report
   counterexamples where `initialized` is true but `x` is not positive.

```{todo}
Whether implications (and other boolean connectors) are short-circuiting is
currently undocumented.
```

 * Similarly, an *if and only if* expression (also called a *bidirectional implication*)
   `expr1 <=> expr2` requires `expr1` and `expr2` to be boolean
   expressions and is itself a boolean expression.  `expr1 <=> expr2` evaluates
   to `true` if `expr1` and `expr2` evaluate to the same boolean value.

   For example, the statement `assert balanceA > 0 <=> balanceB > 0;` will
   report a violation if exactly one of `balanceA` and `balanceB` is positive.

 * An *if-then-else* (*ITE*) expression of the form
   `cond ? expr1 : expr2` requires `cond` to be a boolean expression and
   requires `expr1` and `expr2` to have the same type; the entire
   if-then-else expression has the same type as `expr1` and `expr2`.  The
   expression `cond ? expr1 : expr2` should be read "if `cond` then `expr1`
   else `expr2`.  If `cond` evaluates to `true` then the entire 
   expression evaluates to `expr1`; otherwise the entire expression evaluates
   to `expr2`.

   For example, the expression
   ```cvl
   uint balance = address == owner ? ownerBalance()
                                   : userBalance(address);
   ```
   will set `balance` to `ownerBalance()` if `address` is `owner`, and will set
   it to `userBalance(address)` otherwise.

   Conditional expressions are *short-circuiting*: if `expr1` or `expr2` have
   side-effects (such as updating a [ghost variable](ghosts)), only the
   side-effects of the expression that is chosen are performed.

 * A *universal* expression of the form `forall t v . expr` requires `t`
   to be a [type](types) (such as `uint256` or `address`) and `v` to be
   a variable name; `expr` should be a boolean expression and may refer to
   the identifier `v`.  The expression evaluates to `true` if *every* possible
   value of the variable `v` causes `expr` to evaluate to `true`.

   For example, the statement
   ```cvl
   require (forall address user . balance(user) <= balance(biggestUser));
   ```
   will ensure that every other user has a balance that is less than or equal
   to the balance of `biggestUser`.

 * Like a universal expression, an *existential* expression of the form
   `exists t v . expr` requires `t` to be a [type](types) and `v` to be a
   variable name; `expr` should be a boolean expression and may refer to the
   variable `v`.  The expression evaluates to `true` if there is *any* possible
   value of the variable `v` that causes `expr` to evaluate to `true`.

   For example, the statement
   ```cvl
   require (exists uint t . priceAtTime(t) != 0);
   ```
   will ensure that there is some time for which the price is nonzero.

```{note}
The symbols `forall` and `exist` are sometimes referred to as *quantifiers*,
and expressions of the form `forall type v . e` and `exist type v . e` are
referred to as *quantified expressions*.
```

````{caution}
`forall` and `exists` expressions are powerful and elegant ways to express rules
and invariants, but they require the Prover to consider all possible values of
a given type.  In some cases they can cause significant slowdowns for the
Prover.

If you have rules or invariants using `exists` that are running slowly or
timing out, you can remove the `exists` by manually computing the value that
exists.  For example, you might replace
```cvl
require (exists uint t . priceAtTime(t) != 0);
```
with
```cvl
require priceAtTime(startTime) != 0;
```

````

Accessing fields and arrays
---------------------------

One can access the special fields of built-in types, fields of user-defined
`struct` types, and members of user-defined `enum` types using the normal
`expr.field` notation.  Note that as described in {ref}`user-types`,
access to user-defined types must be qualified by a contract name.

Access to arrays also uses the same syntax as Solidity.


Contracts, method signatures and their properties
-------------------------------------------------

Writing the ABI signature for a contract method produces a `method` object,
which can be used to access the {ref}`method fields <method-type>`.

For example,
```cvl
method m;
require m.selector == sig:balanceOf(address).selector
     || m.selector == sig:transfer(address, uint256).selector;
```
will constrain `m` to be either the `balanceOf` or the `transfer` method.


One can determine whether a contract has a particular method using the `s in c`
where `s` is a method selector and `c` is a contract (either `currentContract`
or a contract introduced with a {ref}`using statement <using-stmt>`.  For
example, the statement
```cvl
if (burnFrom(address,uint256).selector in currentContract) {
  ...
}
```
will check that the current contract supports the optional `burnFrom` method.

(special-fields)=
Special variables and fields
----------------------------

Several of the CVL types have special fields; see {doc}`types` (particularly
{ref}`env`, {ref}`method-type`, and {ref}`arrays`).

There are also several built-in variables:

 * `bool lastReverted` and `bool lastHasThrown` are boolean values that
   indicate whether the most recent contract function reverted or threw an
   exception.

   ````{caution}
   The variables `lastReverted` and `lastHasThrown` are updated after each
   contract call, even those called without `@withrevert` (see {ref}`call-expr`).
   This is a common source of errors.  For example, the following rule is
   vacuous:
   ```cvl
   rule revert_if_paused() {
     withdraw@withrevert();
     assert isPaused() => lastReverted;
   }
   ```

   In this rule, the call to `isPaused` will update `lastReverted` to `true`,
   overwriting the value set by `withdraw`.
   ````
 
 * `currentStorage` refers to the most recent state of the EVM storage.
   `lastStorage` is a deprecated synonym for `currentStorage`.  See
   {ref}`storage-type` for more details.

 * You can use the variable `_` as a placeholder for a value you are not
   interested in.

 * The maximum values for the different integer types are available as the
   variables `max_uint`, `max_address`, `max_uint8`, `max_uint16` etc.

  * `nativeBalances` is a mapping of the native token balances, i.e. ETH for Ethereum.
    The balance of an `address a` can be expressed using `nativeBalances[a]`.

 * `calledContract` is only available in {ref}`function summaries <function-summary>`.
   It refers to the receiver contract of a summarized method call.


CVL also has several built-in functions for converting between
numeric types.  See {doc}`mathops` for details.


(call-expr)=
Calling contract functions
--------------------------

There are many kinds of function-like things that can be called from CVL:

 * Contract functions
 * {ref}`Method variables <method-type>`
 * {ref}`ghost-functions`
 * {doc}`functions`
 * {doc}`defs`

There are several additional features that can be used when calling contract
functions (including calling them through {ref}`method variables <method-type>`).

The method name can optionally be prefixed by a contract name.  If a contract is
not explicitly named, the method will be called with `currentContract` as the
receiver.

It is possible for multiple contract methods to match the method call.  This can
happen in two ways:
 1. The method to be called is a {ref}`method variable <method-type>`
 2. The method to be called is overloaded in the contract (i.e. there are two
   methods of the same name), and the method is called with a {ref}`calldataarg
   <calldataarg>` argument.

In either case, the Prover will consider every possible resolution of the method
while verifying the rule, and will provide a separate verification report for
each checked method.  Rules that use this feature are referred to as
{term}`parametric rule`s.


After the function name, but before the arguments, you can write an optional
method tag, one of `@norevert`, `@withrevert`, or `@dontsummarize`.
 * `@norevert` indicates that examples where the method revert should not be
   considered.  This is the default behavior if no tag is provided
 * `@withrevert` indicates that examples that would revert should still be
   considered.  In this case, the method will set the `lastReverted` and
   `lastHasThrown` variables to `true` in case the called method reverts or
   throws an exception.
 * ```{todo}
   The `@dontsummarize` tag is currently undocumented.
   ```

After the method tag, the method arguments are provided.  Unless the method
is declared {ref}`envfree <envfree>`, the first argument must be an
{ref}`environment value <env>`.  The remaining arguments must either be a
single {ref}`calldataarg value <calldataarg>`, or the same types of arguments
that would normally be passed to the contract method.

After the method arguments, a method invocation can optionally include `at s`
where `s` is a {ref}`storage variable <storage-type>`.  This indicates that
before the method is executed, the EVM state should be restored to the saved
state `s`.

### Type restrictions

When calling a contract function, the Prover must convert the arguments and
return values from their Solidity types to their CVL types and vice-versa.
There are some restrictions on the types that can be converted.  See
{ref}`type-conversions` for more details.

(storage-comparison)=
Comparing storage
-----------------

As described in {ref}`the documentation on storage types <storage-type>`, CVL represents the entirety of the EVM and its 
{ref}`ghost state <ghost-functions>`
in variables with `storage` type. Variables of this type can be checked for equality and inequality.

The basic form of this expression is `s1 == s2`, where `s1` and `s2` are variables of type `storage`.
This expression compares the states represented by `s1` and `s2`; that is, it checks equality of the following:

1. The values in storage for all contracts,
2. The balances of all contracts,
3. The state of all ghost variables and functions

Thus, if any field in any contract's storage differs between `s1` and `s2`, the expression will return `false`.
The expression `s1 != s2` is shorthand for `!(s1 == s2)`.

Storage comparisons also support narrowing the scope of comparison to specific components of the global
state represented by `storage` variables. This syntax is `s1[r] == s2[r]` or `s1[r] != s2[r]`, where `r` is a "storage comparison basis",
and `s1` and `s2` are variables of type `storage`. The valid bases of comparison are:

1. The name of a contract imported with a {ref}`using statement <using-stmt>`,
2. The keyword `nativeBalances`, or
3. The name of a ghost variable or function

It is an error to use different bases on different sides of the comparison operator, and it is also
an error to use a comparison basis on one side and not the other.
The application of the basis restricts the comparison
to only consider the portion of global state identified by the basis.

If the qualifier is a contract identifier
imported via `using`, then the comparison operation will only consider the storage fields of that contract. For example:

```cvl
using MyContract as c;
using OtherContract as o;

rule compare_state_of_c(env e) {
   storage init = currentStorage;
   o.mutateOtherState(e); // changes `o` but not `c`
   assert currentStorage[c] == init[c];
}
```

will pass verification whereas:

```cvl
using MyContract as c;
using OtherContract as o;

rule compare_state_of_c(env e) {
   storage init = currentStorage;
   c.mutateContractState(e); // changes `c`
   assert currentStorage[c] == init[c];
}
```

will not. 

```{note}
Comparing contract's state using this method will **not** compare the balance of the contract between the
two states.
```

If the qualifier is the identifier `nativeBalances`, then the account balances
of all contracts are compared between the two storage states. 
Finally, if the basis is the name of a ghost function or variable, the values of that
function/variable are compared between storage states.

Two ghost functions are considered equal if they have the same outputs for all input arguments.

```{warning}
The default behavior of the Prover on unresolved external calls is to pessimistically havoc contract
state and balances. This behavior will render most storage comparisons that incorporate such
state useless. Care should be taken (using {ref}`summarization <summaries>`) to ensure that rules
that compare storage do not encounter this behavior.
```

```{warning}
The grammar admits storage comparisons for both equality and inequality
that occur arbitrarily nested within expressions. However, support within the Prover for
these comparisons is primarily aimed at assertions of storage equality, e.g., `assert s1 == s2`.
Support for storage inequality as well as nesting comparisons within other expressions is considered
experimental.
```

```{warning}
The storage comparison checks for exact equality between every single slot of storage which can
lead to surprising failures of storage equality assertions. 
In particular, these failures can happen if an uninitialized storage slot is
written and then later cleared by Solidity (via the `pop()` function or the `delete` keyword). After the
clear operation the slot will definitely hold 0, but the Prover will not make any assumptions
about the value of the uninitialized slot which means they can be considered different.
```
