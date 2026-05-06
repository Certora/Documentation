(solana_spec)=
# Specifications and Lemmas

The `cvlr-spec` crate (shipped with `cvlr ≥ 0.6`) lets you express
preconditions, postconditions, and invariants as first-class **values**
that can be named, composed, reused across rules, and proved as standalone
lemmas.

This page covers the three layers, smallest first:

1. **Predicates** — boolean expressions over a context type
   ([`CvlrFormula`](#cvlrformula)).
2. **Lemmas** — verified theorems that can be reused inside other rules
   ([`cvlr_lemma!`](#lemmas)).
3. **Specs** — packaged (requires, ensures) pairs for handlers, instantiated
   as a cross-product of rules
   ([`cvlr_spec!`](#specs-for-handlers) and [`cvlr_rules!`](#bulk-rule-generation)).

```{note}
Everything on this page is opt-in. The lower-level primitives covered in
{ref}`speclanguage` (`cvlr_assert!`, `cvlr_assume!`, `nondet`, …) keep
working as before and can be mixed freely with the spec layer.
```

## `CvlrFormula`

A `CvlrFormula` is a boolean expression with an associated `Context` type.
The trait surface is:

```rust
pub trait CvlrFormula {
    type Context;

    fn eval(&self, ctx: &Self::Context) -> bool;

    // Single-state assert / assume — default impls call eval()
    fn assert(&self, ctx: &Self::Context);
    fn assume(&self, ctx: &Self::Context);

    // Two-state — for postconditions that compare pre and post
    fn eval_with_states(&self, post: &Self::Context, pre: &Self::Context) -> bool;
    fn assert_with_states(&self, post: &Self::Context, pre: &Self::Context);
    fn assume_with_states(&self, post: &Self::Context, pre: &Self::Context);
}
```

The two-state variants default to "ignore the pre-state and call the
single-state version", so simple predicates only have to implement `eval`.

Three built-in formulas:

| Builder | Meaning |
| -------- | -------- |
| `cvlr_true::<Ctx>()` | constant `true` for any context |
| `cvlr_and(a, b)` / `cvlr_and!(a, b, c, …)` | logical AND (up to 6 conjuncts) |
| `cvlr_implies(a, b)` / `cvlr_implies!(a, b)` | logical implication `a → b` |

A predicate is a `CvlrFormula` that you write yourself (see next section).
Both compose: `cvlr_and!(IsPositive, IsBounded)` is itself a `CvlrFormula`.

## Defining predicates

There are four ways to produce a `CvlrFormula`. Lead with the attribute
form; reach for the others when it doesn't fit.

### `#[cvlr::predicate]` — the default

A proc-macro attribute that turns a Rust function into a unit struct
implementing `CvlrFormula`. The function name (snake_case) is converted to
the struct name (PascalCase):

```rust
use cvlr::prelude::*;
use cvlr::predicate;

#[derive(cvlr::derive::Nondet, cvlr::derive::CvlrLog)]
pub struct Vault { tokens: u64, shares: u64 }

#[predicate]
fn is_solvent(v: &Vault) {
    v.shares <= v.tokens;
}

// `IsSolvent` is now a unit struct with a `CvlrFormula<Context = Vault>` impl.
let v: Vault = nondet();
IsSolvent.assume(&v);                 // assume v.shares <= v.tokens
IsSolvent.assert(&v);                 // assert it instead
let b: bool = IsSolvent.eval(&v);     // get a bool back
```

The function body is a sequence of boolean expressions; multiple
expressions are conjoined. Comparisons (`==`, `!=`, `<`, `<=`, `>`, `>=`)
are lowered to the corresponding specialised `cvlr_assert_*` /
`cvlr_assume_*` macro automatically, so counterexamples include both
sides of the comparison.

**`let` bindings** are allowed before the conditions:

```rust
#[predicate]
fn deposit_room(v: &Vault) {
    let cap: u64 = 1_000_000;
    v.tokens < cap;
    v.shares <= v.tokens;
}
```

**`if` expressions** are also allowed; both branches are bool expressions:

```rust
#[predicate]
fn shape_constraint(v: &Vault) {
    if v.shares > 0 {
        v.tokens > 0
    } else {
        true
    };
}
```

**Two-state predicates.** A function with two `&Ctx` parameters becomes a
two-state `CvlrFormula` (the first parameter is the post-state, the second
is the pre-state):

```rust
#[predicate]
fn solvency_preserved(post: &Vault, pre: &Vault) {
    post.shares <= post.tokens;
    post.tokens >= pre.tokens;
}

let pre: Vault = nondet();
let post: Vault = run_handler(pre);
SolvencyPreserved.assert_with_states(&post, &pre);
```

Calling `.eval()` / `.assert()` / `.assume()` (without `_with_states`) on a
two-state predicate panics — they need both states.

### `cvlr_predicate!` — anonymous

When you don't want to name the predicate, the function-form macro returns
an `impl CvlrFormula<Context = Ctx>` value:

```rust
let pred = cvlr_predicate! { |v: Vault| -> {
    v.tokens > 0;
    v.shares <= v.tokens
} };

if pred.eval(&v) { /* … */ }
```

Use this when the predicate is one-shot, e.g. inline inside a `cvlr_spec!`:

```rust
let spec = cvlr_spec! {
    requires: cvlr_predicate! { |v: Vault| -> { v.shares <= v.tokens } },
    ensures:  SolvencyPreserved,
};
```

### `cvlr_def_predicate!` — named, no proc-macros

A `macro_rules!` form of `#[cvlr::predicate]`. Use it when you can't or
don't want to depend on the proc-macro:

```rust
cvlr_def_predicate! {
    pred IsSolvent (v: Vault) {
        v.shares <= v.tokens
    }
}

cvlr_def_predicates! {
    pred IsPositive (v: Vault) { v.tokens > 0 }
    pred IsBounded  (v: Vault) { v.tokens < 1_000_000 }
}
```

For two-state predicates, `cvlr_def_states_predicate!` mirrors the
two-arg form of the attribute:

```rust
cvlr_def_states_predicate! {
    pred Increases ( [ post, pre ] : Vault ) {
        post.tokens > pre.tokens
    }
}
```

### Manual `impl CvlrFormula`

For full control — e.g. a predicate that does something non-trivial in
`assume` (like calling specialised `cvlr_assume_*` helpers):

```rust
struct VaultWellFormed;

impl CvlrFormula for VaultWellFormed {
    type Context = Vault;
    fn eval(&self, v: &Vault) -> bool {
        v.shares <= v.tokens && v.tokens > 0
    }
}
```

### Combining predicates

```rust
let p = cvlr_and!(IsPositive, IsBounded, IsSolvent);
let q = cvlr_implies!(IsBounded, IsSolvent);
```

`cvlr_and!` accepts 2 to 6 arguments; for longer conjunctions, nest. Use
`cvlr_pif_and!` to combine predicates by their snake_case **function**
names instead of their PascalCase struct names — it auto-converts:

```rust
cvlr_pif_and!(is_positive, is_bounded, is_solvent)
// equivalent to: cvlr_and!(IsPositive, IsBounded, IsSolvent)
```

`cvlr_pif_and!` only works with predicates defined as functions via
`#[cvlr::predicate]` — the macro relies on the proc-macro's snake-case →
PascalCase conversion. If a predicate was defined with
`cvlr_def_predicate!` (which produces a unit struct directly), reference
it by its struct name and use `cvlr_and!` instead.

## Lemmas

A **lemma** is a logical statement of the form *"if `requires` holds, then
`ensures` also holds"*, defined over a single context. You can prove a
lemma directly (no handler involved) and then *use* it inside other rules.

The most common form uses the block syntax:

```rust
use cvlr::prelude::*;
use cvlr::predicate;

#[derive(cvlr::derive::Nondet, cvlr::derive::CvlrLog)]
pub struct Vault { tokens: u64, shares: u64 }

cvlr_lemma! {
    SolventStaysSolvent(v: Vault) {
        requires -> {
            v.shares <= v.tokens;
        }
        ensures -> {
            v.shares <= v.tokens;
        }
    }
}
```

`SolventStaysSolvent` is a unit struct implementing `CvlrLemma`. The
context type must implement `Nondet` and `CvlrLog` so the lemma can havoc
its own input — both come from `cvlr::derive`.

The lemma exposes three methods:

| Method | What it does | Use it for |
| ------ | ------------ | ---------- |
| `verify()` | havoc a `Ctx`, assume `requires`, assert `ensures` | the `#[rule]` that proves the lemma |
| `verify_with_context(&ctx)` | same, but with a caller-supplied `ctx` | when the harness builds the context itself |
| `apply(&ctx)` | assert `requires`, assume `ensures` | use a previously proved lemma inside another rule |

### Proving a lemma

```rust
#[rule]
pub fn rule_solvent_stays_solvent() {
    SolventStaysSolvent.verify();
}
```

That single line is a complete spec: the `verify()` default impl havocs a
nondet `Vault`, calls `clog!(ctx)` so the counterexample is readable,
assumes `requires`, and asserts `ensures`.

### Using a lemma in another rule

Once a lemma is proved, you can `apply` it elsewhere. Where `verify`
*proves* the lemma (assume requires → assert ensures), `apply` *uses* it
(assert requires → assume ensures):

```rust
#[rule]
pub fn rule_after_deposit_invariant() {
    let mut v: Vault = nondet();
    cvlr_assume!(v.shares <= v.tokens);
    deposit(&mut v, nondet());
    SolventStaysSolvent.apply(&v);   // free-standing fact: v stays solvent
    // … further reasoning that depends on v being solvent …
}
```

This is how proofs decompose: prove a lemma once, then `.apply()` it
wherever you need its conclusion without redoing the proof.

### Expression form

When the requires / ensures are predicates you've already defined, the
expression form is shorter:

```rust
cvlr_lemma! {
    AndStaysSolvent for Vault {
        requires: cvlr_and!(IsPositive, IsSolvent),
        ensures:  IsSolvent,
    }
}
```

## Specs (for handlers)

A `CvlrSpec` is the two-state generalisation of a lemma: the precondition
holds before the handler runs; the postcondition holds after, and may
compare post-state to pre-state.

```rust
use cvlr::predicate;

#[predicate]
fn is_solvent(v: &Vault) {
    v.shares <= v.tokens;
}

#[predicate]
fn solvency_preserved(post: &Vault, pre: &Vault) {
    post.shares <= post.tokens;
}

let deposit_spec = cvlr_spec! {
    requires: IsSolvent,
    ensures:  SolvencyPreserved,
};
```

The spec exposes two methods, used directly inside a handler harness:

```rust
#[rule]
pub fn rule_deposit_preserves_solvency() {
    let mut v: Vault = nondet();
    deposit_spec.assume_requires(&v);     // assumes v.shares <= v.tokens
    let pre = v;

    deposit(&mut v, nondet());

    deposit_spec.check_ensures(&v, &pre); // asserts SolvencyPreserved over (post, pre)
}
```

For invariants — "this fact holds in pre and post, full stop" —
`cvlr_invar_spec!` is the right shape. The invariant is one-state, and the
spec assumes it pre and asserts it post:

```rust
let invar = cvlr_invar_spec! {
    assumption: IsBounded,    // additional precondition
    invariant:  IsSolvent,    // assumed pre, asserted post
};
```

## Bulk rule generation

`cvlr_rules!` generates a `#[rule]` per `(name, base_function)` pair. The
typical use is one spec across many handlers:

```rust
fn base_deposit()     { /* harness for deposit  */ }
fn base_withdraw()    { /* harness for withdraw */ }
fn base_increment()   { /* harness for increment */ }

cvlr_rules! {
    name: "solvency",
    spec: deposit_spec,
    bases: [base_deposit, base_withdraw, base_increment],
}
```

This expands to three rules — `solvency_deposit`, `solvency_withdraw`,
`solvency_increment` — each invoking the right base harness with the spec.
The `base_` prefix is stripped from the rule names; if a base function
doesn't start with `base_`, its name is used verbatim.

`cvlr_invariant_rules!` is the matching convenience for invariants:

```rust
cvlr_invariant_rules! {
    name: "non_negative",
    assumption: cvlr_predicate! { |v: Vault| -> { v.tokens > 0 } },
    invariant:  IsSolvent,
    bases: [base_deposit, base_withdraw, base_increment],
}
```

```{note}
**Project-local glue.** `cvlr_rules!` and `cvlr_invariant_rules!` expand to
`cvlr_rule_for_spec! { name, spec, base }`, which in turn calls a
project-supplied macro `cvlr_impl_rule!` to produce the actual `#[rule]`.
The spec template ships a default `cvlr_impl_rule!`; if you're not using
the template you'll need to define one. Its job is to take a rule name, a
spec, and a base function, and emit a `#[rule]` that calls the base while
threading `assume_requires` / `check_ensures`.
```

## Specs in action — end-to-end

Putting the pieces together: a single property defined once, instantiated
across multiple handlers. This is the shape customer specs converge on
once the harness stabilises.

```rust
//! src/certora/specs/solvency.rs
use cvlr::prelude::*;
use cvlr::predicate;
use cvlr::spec::CvlrSpec;
use crate::operations::{vault_deposit, vault_withdraw, vault_redeem};

#[derive(cvlr::derive::Nondet, cvlr::derive::CvlrLog, Clone, Copy)]
pub struct VaultView { pub tokens: u64, pub shares: u64 }

#[predicate]
fn is_solvent(v: &VaultView) {
    v.shares <= v.tokens;
}

#[predicate]
fn solvency_preserved(post: &VaultView, pre: &VaultView) {
    post.shares <= post.tokens;
}

#[inline(always)]
fn base_deposit<S>(spec: &S) where S: CvlrSpec<Context = VaultView> {
    let pre: VaultView = nondet();
    spec.assume_requires(&pre);
    let mut v = pre;
    vault_deposit(&mut v, nondet()).unwrap();
    let post = v;
    clog!(pre, post);
    spec.check_ensures(&post, &pre);
}

#[inline(always)]
fn base_withdraw<S>(spec: &S) where S: CvlrSpec<Context = VaultView> {
    let pre: VaultView = nondet();
    spec.assume_requires(&pre);
    let mut v = pre;
    vault_withdraw(&mut v, nondet()).unwrap();
    let post = v;
    clog!(pre, post);
    spec.check_ensures(&post, &pre);
}

#[inline(always)]
fn base_redeem<S>(spec: &S) where S: CvlrSpec<Context = VaultView> {
    let pre: VaultView = nondet();
    spec.assume_requires(&pre);
    let mut v = pre;
    vault_redeem(&mut v, nondet()).unwrap();
    let post = v;
    clog!(pre, post);
    spec.check_ensures(&post, &pre);
}

cvlr_rules! {
    name: "solvency",
    spec: cvlr_spec! {
        requires: IsSolvent,
        ensures:  SolvencyPreserved,
    },
    bases: [base_deposit, base_withdraw, base_redeem],
}
```

The `cvlr_rules!` block expands to three `#[rule]` functions —
`solvency_deposit`, `solvency_withdraw`, and `solvency_redeem` — each
calling the matching base harness with the same spec. To verify a new
property, define one predicate pair and write one `cvlr_rules!` block; to
add a new handler, write one `base_<handler>`. The cross-product is
implicit.

For harnesses that build their pre-state from `&[AccountInfo]` rather
than havocing a value type directly, see
{ref}`solana_parametric_rules` — the `base_<handler>` shape is the same;
only the body changes.

## When to use what

| Situation | Use |
| --------- | --- |
| Reusable named assertion over one state | `#[cvlr::predicate]` |
| One-shot, inline | `cvlr_predicate!` |
| Comparing pre-state and post-state | `#[cvlr::predicate]` with two args |
| Proved theorem reused in many rules | `cvlr_lemma!` + `.apply()` |
| Same `(requires, ensures)` across many handlers | `cvlr_spec!` + `cvlr_rules!` |
| Same invariant across many handlers | `cvlr_invar_spec!` + `cvlr_invariant_rules!` |
| Setup that varies per rule | `macro_rules!` chain — see {ref}`solana_parametric_rules` |

## What's next

- {ref}`solana_parametric_rules` — when the harness setup itself varies
  per rule and the spec layer alone isn't enough.
- {ref}`solana_methodology` — practical guidelines for writing rules that
  close.
