Expressions
===========

A CVL expression is anything that represents a value.  This page documents all
possible expressions in CVL and explains how they are evaluated.

```{contents}
```

Syntax
------

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
       | [ "invoke" | "sinvoke" ]
         [ id "." ] id
         [ "@" ( "norevert" | "withrevert" | "dontsummarize" ]
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
           | "lastStorage"
           | "allContracts"
           | "lastMsgSig"
           | "_"
           | "max_uint" | "max_address" | "max_uint8" | ... | "max_uint256"

special_functions ::=
           | "to_uint256" | "to_int256" | "to_mathint"

contract ::= id | "currentContract"

```

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
   will ensure that every other user has a balance that is less than
   `biggestUser`.

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
require m.selector == balanceOf(address).selector
     || m.selector == transfer(address, uint256).selector;
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
 
 * `lastStorage` refers to the most recent state of the EVM storage.  See
   {ref}`storage-type` for more details.

 * ```{todo}
   `allContracts` and `lastMsgSig` are currently undocumented.
   ```

 * You can use the variable `_` as a placeholder for a value you are not
   interested in._

 * The maximum values for the different integer types are available as the
   variables `max_uint`, `max_address`, `max_uint8`, `max_uint16` etc.

CVL also has three built-in functions for casting mathematical types:
`to_uint256`, `to_int256`, and `to_mathint`.  See {doc}`mathops` for details.


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
functions (including calling them through method variables).

A method invocation can optionally be prefixed by `invoke` or `sinvoke`,
although this syntax is deprecated in favor of the `@norevert` and
`@withrevert` syntax described below.  Verification of a method called with
`invoke` will not report a counterexample if the contract method reverts, while
`sinvoke` will.

The method name can optionally be prefixed by a contract name.  If a contract is
not explicitly named, the method will be called with `currentContract` as the
receiver.

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

After the method tag, the method arguments are provided, as usual.

After the method arguments, a method invocation can optionally include `at s`
where `s` is a {ref}`storage variable <storage-type>`.  This indicates that
before the method is executed, the EVM state should be restored to the saved
state `s`.

