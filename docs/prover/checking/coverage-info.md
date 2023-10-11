Coverage Info via Unsat Cores
==================
The {ref}`--coverage_info [none|basic|advanced]` option enables automatic computation of `.sol` and `.spec` files coverage w.r.t. the underlying Certora Prover verification task. In particular, using this flag can help you answer questions such as:

* *Are all solidity functions from the input involed in proving my rules?*
* *Are all solidity commands from the input involed in proving my rules?*
* *Supposing an `assert` in my rule is not reachable, what is the reason for the unreachability?*
* *Do I really need all hooks that are defined in my .spec file(s)?*
* *Do I really need all `require` statements in my rule?*
* *Do I really need to initialise a CVL variable in my rule?*
* *Do I really need all preserved blocks in my CVL `invariant`?*

To answer the above questions, CVT generates a so-called *minimal unsat core* which, intuitively, represents the minimal subset of the commands in the input `.sol` and `.spec` files that are needed to prove the CVL properties. If some of the input `.sol` commands are not needed to derive the proof, it might indicate that the specification does not cover all behaviour implemented in the smart contract. If some of the input `.spec` commands are not needed to derive the proof, typically unnecessary `require` statements or variable initialisations, it indicates that the CVL rules/invariants can be make stronger. 

We visualise this *coverage* information in a dedicated HTML file: `zipOutput/Reports/UnsatCoreVisualisation.html`. Furthermore, we also visualise the unsat core coverage information on our `TAC` representation of the verification condition. 

In the rest of this section, we provide a more detailed explanation of the concept of unsat cores and provide several particular example usages of the unsat cores. 

 
(unsat-cores)=
Unsat Cores
--------------
The Certora Prover prover works as follows:
1. It takes as an input `.sol` and `.spec` files.
2. It compiles the `.sol` input into EVM bytecode.
3. For each single *property*, i.e. elementary rule/invariant, in the `.spec` file(s), it converts the property & the bytecode into a TAC program.
4. Each TAC program is then converted to an SMT formula such that the formula is unsatisfiable if and only if the property holds (i.e. cannot be violated). 

The SMT formula, say `F`, is built from a set `A` of *assertions*, say `A1, A2, ..., An`, that are built over a set of *variables*. Intuitively, can see the assertions as mathematical equations. The formula is satistiable if there exists an assignment to the variables that satisfies all the assertions simultaneously. Otherwise, the formula is unsatisfiable. In practise, it is often the case that already a subset of `A` is unsatisfiable. An especially, one can extract a *minimal unsatisfiable subset* `U` of `A`. The *minimality* here means that if you remove any assert from `U` then it becames satistiable, i.e., it is not a *minimum cardinality*. We call a minimal unsatisfiable subset of `A` an *unsat core* of `A`. 

** EXAMPLE ** (TODO: Format this somehow)

Assume that `A = {a, !a, !b, a || b}` where `a` and `b` are Boolean variables. 
There are two minimal unsatisfiable subsets (i.e. unsat cores) of this formula:
`{a, !a}` and `{!a, !b, a || b}`.

** END of Example **

There are roughly two types of assertions in `A`:
1. assertions encoding the verification conditions and the program control flow, 
2. and assertions encoding individual commands from the underlying TAC program. 

In particular, for every `assign`, `assume` and `assert` command `Ci` from the TAC there is a corresponding assert `Ai` in `A`. Suppose we obtain an unsat core `U` of `A`. Then, the meaning of every excluded assert `Ai in (A - U)` is the following:

- if `Ci` is an `assume` or `assert` command then `Ci` can be completely removed from the TAC without causing a violation of the underlying CVL property
- if `Ci` is an `assign` command, for instance `x = y + z`, then the right hand side of the equation can be `havoc'd` without violating the underlying CVL property, i.e. in our example we can replace `x = y + z` with `x = havoc`.








- If an unsat core `U` of `A` does not contain an assert `Ai` that corresponds to an `assume` command from TAC






The **vacuity** sanity check ensures that even when ignoring all the
user-provided assertions, the end of the rule is reachable. This check ensures
that that the combination of `require` statements does not rule out all
possible counterexamples.  Rules that rule out all possible counterexamples
are called {term}`vacuous` rules.  Since they don't actually check any
assertions, they are almost certainly incorrect.

For example, the following rule would be flagged by the vacuity check:
```cvl
rule vacuous {
    uint x;
    require x > 2;
    require x < 1;
    assert f(x) == 2, "f must return 2";
}
```

Since there are no models satisfying both `x > 2` and `x < 1`, this rule
will always pass, regardless of the behavior of the contract.  This is an
example of a {term}`vacuous` rule &mdash; one that passes only because the
preconditions are contradictory.

The vacuity check also flags situations where counterexamples are ruled
out for reasons other than `require` statements.  A common example comes from
reusing `env` variables.  Consider the following poorly-written rule:

```cvl
env e; uint amount; address recipient;

require balanceOf(recipient) == 0;
require amount > 0;

deposit(e, amount);
transfer(e, recipient, amount);

assert balanceOf(recipient) > 0,
    "depositing and then transferring makes recipient's balance positive";
```

Although it looks like this rule is reasonable, it may actually be vacuous.
The problem is that the environment `e` is reused, and in particular
`e.msg.value` is the same in the calls to `deposit` and `transfer`.  Since
`transfer` is not payable, it will always revert if `e.msg.value != 0`.  On the
other hand, `deposit` always reverts when `e.msg.value == 0`.  Therefore every
example will either cause `deposit` or `transfer` to revert, so there are no
models that reach the `assert` statement.

(sanity-assert-tautology)=
Assert tautology checks
---------------------

The **assert tautology** sanity check ensures that individual `assert` statements
are not {term}`tautologies <tautology>`.  A tautology is a statement that is
true on all examples, even if all the `require` and `if` conditions are
removed. Tautology checks also consider the bodies of the contract functions. For
example, `assert square(x) >= 0;` is a tautology if `square` is a contract
function that squares its input.

For example, the following rule would be flagged by the assert tautology check:

```cvl
rule tautology {
  uint x; uint y;
  require x != y;
  ...
  assert x < 2 || x >= 2,
   "x must be smaller than 2 or greater than or equal to 2";
}
```

Since every `uint` satisfies the assertion, the assertion is tautological, which
may indicate an error in the specification.

(sanity-trivial-invariant)=
Trivial invariant checks
------------------------

The **Trivial invariant** sanity check ensures that invariants are not trivial.
A trivial invariant is one that holds in all possible states, not just in
reachable states.

For example, the following invariant is trivial:

```cvl
invariant squaresNonNeg(int x)
    x * x >= 0
```

While it does hold in every reachable state, it also holds in every
non-reachable state.  Therefore it could be more efficiently checked as a rule:

```cvl
rule squaresNonNeg(int x) {
    assert x * x >= 0;
}
```

The rule version is more efficient because it can do a single check in an
arbitrary state rather than separately checking states after arbitrary method
invocations.

(sanity-assert-structure)=
Assertion structure checks
--------------------------

The **assertion structure** sanity check ensures that complex assert statements
can't be replaced with simpler ones.

If an assertion expression is more complex than necessary, it can pass for
misleading reasons.  For example, consider the following assertion:

```cvl
uint x;
assert (x < 5) => (x >= 0);
```

In this case, the assertion is true, but only because `x` is a `uint` and is
therefore *always* non-negative.  The fact that `x >= 0` has nothing to do with
the fact that `x < 5`.  Therefore this complex assertion could be replaced with
the more informative assertion `assert x >= 0;`.

Similarly, if the premise of the assertion is always false, then the implication
is {term}`vacuously <vacuous>` true.  For example:

```cvl
uint x;
assert (x < 0) => (x >= 5);
```

This assertion will pass, but only because the unsigned integer `x` is never
negative.  This may mislead the user into thinking that they have checked that
`x >= 5` in some interesting situation, when in fact they have not.  The simpler
assertion `assert x >= 0;` more clearly describes what is going on.

Overly complex assertions like this may indicate a mistake in the rule.  In this
case, for example, the fact that the user was checking that `x >= 0` may
indicate that they should have declared `x` as an `int` instead of a `uint`.

The assertion structure check tries to prove some complex logical statements by
breaking them into simpler parts.  The following situations are reported by the
assertion structure check:

* `assert p => q;` is reported as a sanity violation if `p` is false whenever the
  assertion is reached (in which case the simpler assertion `assert !p;` more
  clearly describes the situation), or if `q` is always true (in which case
  `assert q;` is a clearer alternative).

* `assert p <=> q;` is reported as a sanity violation if either `p` and `q` are
  both true whenever the assertion is reached (in which case the simpler
  assertions `assert p; assert q;` more clearly describe the situation), or if
  neither `p` nor `q` are ever true (in which case `assert !p; assert !q;` is a
  clearer alternative).

* `assert p || q;` is reported as a sanity violation if either `p` is true
  whenever the assertion is reached
  (in which case `assert p;` more clearly describes the situation) or if `q` is
  always true (in which case `assert q;` is a clearer alternative).

(sanity-redundant-require)=
Redundant require checks
------------------------

The **require redundancy** sanity check highlights redundant `require` statements.
A `require` is considered to be redundant if it does not rule out any {term}`models <model>`
that haven't been ruled out by previous requires.

For example, the require-redundancy check would flag the following rule:
```cvl
rule require_redundant {
  uint x;
  require x > 3;
  require x > 2;
  assert f(x) == 2, "f must return 2";
}
```

In this example, the second requirement is redundant, since any `x` greater
than 3 will also be greater than 2.

