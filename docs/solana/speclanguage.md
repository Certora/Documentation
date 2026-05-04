(speclanguage)=
# Certora Verification Language for Rust (CVLR)

CVLR stands for Certora Verification Language for Rust. It is pronounced like "cavalier".
CVLR provides the basic primitives for writing verification rules that specify
pre- and post-conditions for client code. Unlike CVL for Solidity, CVLR is
embedded in Rust. It is compiled by the Rust compiler and has simple operational
semantics.

CVLR is deployed to [crates.io](https://crates.io/crates/cvlr). The development
version can be found at [https://github.com/Certora/cvlr](https://github.com/Certora/cvlr).
CVLR is independent of the Solana ecosystem; Solana-specific helpers live in
[`cvlr-solana`](https://crates.io/crates/cvlr-solana).

```{note}
This page documents the language at a high level. For end-to-end patterns
(account harnesses, mocks, parametric rules, methodology) see the dedicated
pages listed in the {ref}`Contents <solana_index>` of this section.
```

## The `cvlr::prelude`

The recommended import for spec files is:

```rust
use cvlr::prelude::*;
```

The prelude pulls in the items you almost always need:

| From the prelude   | What it is                                     |
| ------------------ | ---------------------------------------------- |
| `rule`             | the `#[rule]` attribute                        |
| `nondet`           | the `nondet::<T>()` function                   |
| `cvlr_assert!`     | assertion macro                                |
| `cvlr_assert_eq!`  | equality assertion (logs both sides)           |
| `cvlr_assert_lt!`  | strict less-than assertion                     |
| `cvlr_assert_le!`  | less-or-equal assertion                        |
| `cvlr_assume!`     | restrict the search space (precondition)       |
| `cvlr_satisfy!`    | existential check (at least one execution …)  |
| `clog!`            | log values into counterexamples                |

Individual items can also be imported directly (e.g. `use cvlr::{rule, nondet};`).

## CVLR Rules

Specifications are written as pre- and post-conditions in rules. A rule is
similar to a unit test. However, instead of being executed for some specific
input, the rule is symbolically analyzed for all possible
non-deterministic values.

In CVLR, rules are regular Rust functions, annotated with `#[rule]`.

A complete example of a specification with several rules is shown below.
The function being verified is `compute_fee`. We have included it in the spec
file for simplicity.

```rust
use cvlr::prelude::*;

pub fn compute_fee(amount: u64, fee_bps: u16) -> Option<u64> {
    if amount == 0 { return None; }
    let fee = amount.checked_mul(fee_bps).checked_div(10_000);
    fee
}

#[rule]
pub fn rule_fee_sanity() {
   compute_fee(nondet(), nondet()).unwrap();
   cvlr_satisfy!(true);
}

#[rule]
pub fn rule_fee_assessed() {
    let amt: u64 = nondet();
    let fee_bps: u16 = nondet();
    cvlr_assume!(fee_bps <= 10_000);
    let fee = compute_fee(amt, fee_bps).unwrap();
    clog!(amt, fee_bps, fee);
    cvlr_assert!(fee <= amt);
    if fee_bps > 0 { cvlr_assert!(fee > 0); }
}

#[rule]
pub fn rule_fee_liveness() {
    let amt: u64 = nondet();
    let fee_bps: u16 = nondet();
    cvlr_assume!(fee_bps <= 10_000);
    let fee = compute_fee(amt, fee_bps);
    clog!(amt, fee_bps, fee);
    if fee.is_none() { cvlr_assert!(amt == 0); }
}
```

The rule `rule_fee_sanity` checks that the function under verification has at
least one panic-free execution. A rule like that is called a sanity rule. It is
a good practice to start a specification with such a rule.

The rule `rule_fee_assessed` checks that a fee can be computed for an arbitrary
amount. It has two assertions. The first checks that the fee is never greater
than the amount. The second checks that the fee is always assessed when
required. The first assertion is not violated. However, the second is. Can you
spot the bug? Note that we have also added calls to the log macro `clog!` that
is similar to the `dbg!` macro in Rust. The `clog!` macro will instruct the
Prover to produce the values of the desired variables in any violating
execution.

The rule `rule_fee_liveness` checks that the fee is always computed, except
when the fee rate is 0. This assertion is violated. Can you spot the bug?

## Assertions

The simplest feature of CVLR is assertions. An assertion is written as
`cvlr_assert!(cond)`, where `cond` is the condition being asserted.
The semantics is the same as traditional asserts in Rust — an assertion is
violated if there is (a panic-free) execution that reaches `cvlr_assert!(cond)`
and in the current execution state `cond` is false.

For example, `cvlr_assert!(true)` is never violated, while `cvlr_assert!(false)`
is always violated when reached.

What makes `cvlr_assert!` special is that it is verified symbolically by the
Certora Prover. That is, the Prover returns `Violated` if there is an input and
an execution of the program that reaches that assertion and violates it.

### Assertion variants

All assertion macros come from `cvlr::prelude::*`. They desugar to the same
thing: a check that fails the rule when the condition is false. The
specialised forms (`_eq!`, `_lt!`, `_le!`) produce better counterexample
messages because they report both sides of the comparison.

| Macro                        | Use for                                                | Equivalent to                               |
| ---------------------------- | ------------------------------------------------------ | ------------------------------------------- |
| `cvlr_assert!(cond)`         | a single boolean condition                             | the canonical form                          |
| `cvlr_assert_eq!(a, b)`      | equality between values (logs both on failure)         | `cvlr_assert!(a == b)` with better messages |
| `cvlr_assert_lt!(a, b)`      | strict less-than                                       | `cvlr_assert!(a < b)`                       |
| `cvlr_assert_le!(a, b)`      | less-or-equal                                          | `cvlr_assert!(a <= b)`                      |

```rust
use cvlr::prelude::*;

#[rule]
pub fn rule_assert_basics() {
    let x: u64 = nondet();
    let y: u64 = nondet();
    cvlr_assume!(x <= 100 && y <= 100);

    cvlr_assert!(x + y >= x);
    cvlr_assert_eq!(x.saturating_sub(y) + y, x.max(y));
    cvlr_assert_le!(x.min(y), x);
    cvlr_assert_lt!(x.saturating_sub(101), 1);
}
```

```{note}
**Version note.** Older code (cvlr ≤ 0.4.0) imports `cvt_assert!` /
`cvt_assume!` from `cvlr::asserts::cvt::*`. Current code uses
`cvlr_assert!` / `cvlr_assume!` from `cvlr::prelude::*`. The semantics are
identical; it is a rename only. New rules should use the `cvlr_*` forms.
```

### `cvlr_satisfy!` — existential checks

Often, the intended meaning of an assertion is that it should not be violated,
i.e., to hold on all possible executions. However, sometimes it is useful to
check whether some execution is possible. In that case, the specification
intends for the assertion to be reachable. For such cases, CVLR provides a
satisfy assertion, called `cvlr_satisfy!(cond)`.

The semantics of `cvlr_satisfy!(cond)` is that it is `Violated` when it is
either not reached, or when every execution that reaches it violates the
condition. For example, `cvlr_satisfy!(true)` is violated only if it is never
reachable (i.e., part of dead code), and `cvlr_satisfy!(false)` is always
violated.

```rust
#[rule]
pub fn rule_zero_is_reachable() {
    let x: u64 = nondet();
    cvlr_assume!(x < 10);
    cvlr_satisfy!(x == 0);              // passes: x = 0 is reachable
}
```

Inside a rule that contains `cvlr_satisfy!`, ordinary `cvlr_assert!`s become
additional constraints (treated like assumes). This means you can write rules
of the form *"is there an execution that reaches X without violating Y?"*.

Typical uses:

- Reachability of a code path (`cvlr_satisfy!(reached_branch)`).
- "Liveness" sanity: "the protocol can move from state A to state B".

## Assumptions

Assumptions provide a way to restrict input to reflect some pre-condition. CVLR
provides an assumption macro `cvlr_assume!(cond)`. If an execution reaches
`cvlr_assume!(cond)`, it continues only if `cond` is true in the current
program state. Otherwise, the execution aborts.

For example, `cvlr_assume!(true)` is a noop, while `cvlr_assume!(false)` blocks
all executions that reach it.

A typical use of `cvlr_assume!` is to restrict a range of a value beyond the
restriction afforded by its type. For example, restricting the maximum value
of a variable to `100` can be done as follows:

```rust
let fee_bps = get_some_fee();
cvlr_assume!(fee_bps <= 100)
// computation reaches here only if fee_bps is no greater than 100
```

`cvlr_assume!` is the right tool when:

- You need a precondition (`amount > 0`).
- You're encoding an invariant the rest of the system maintains
  (`shares <= tokens`).
- You want to filter to the slice of state that is interesting for a given
  rule.

It is the **wrong** tool when:

- You're trying to silence a counterexample. If a counterexample is real, the
  property is wrong; tightening the assume hides bugs.
- You want a property to hold "in practice". Either prove it, or document the
  precondition and prove it separately.

```{warning}
**Watch out for vacuity.** Two contradicting assumes (`x > 10` and `x < 5`)
make every assertion trivially "pass". The Prover's vacuity check (enabled
via `"rule_sanity": "basic"`) catches this — see {ref}`solana-sanity-vacuity`.
```

## Nondeterministic Values

A specification must tell the Prover what are the (symbolic) inputs that the
Prover has to explore. Such values are called non-deterministic. The name
comes from the fact that the Prover chooses the values non-deterministically
(i.e., not following any specific pre-determined exploration scheme or
probability distribution). Nondet values are similar to *arbitrary* values in
property-based testing, except that they are not chosen randomly, but are
explored exhaustively via symbolic reasoning.

CVLR provides a generic function `nondet()` that can generate non-deterministic
values of all primitive integers. For example, `nondet::<u64>()` returns a
non-deterministic `u64`, and `nondet::<u16>()` returns a non-deterministic
`u16`.

```rust
let x: u64   = nondet();
let b: bool  = nondet();
let v: i32   = nondet::<i32>();        // turbofish if no type context
let arr: [u8; 32] = nondet();
```

Every call returns a fresh, independent havoced value. The Prover treats them
as universally quantified: any execution that demonstrates a property
violation, for any combination of these values, is a counterexample.

For non-primitive types and Solana-specific helpers (Pubkey, AccountInfo,
bounded vectors, ...) see {ref}`solana_nondet`.

## Logging with `clog!`

`clog!` writes values into the counterexample report. It is a no-op when the
rule passes, so it is essentially free to leave in.

```rust
clog!();                       // breadcrumb / marker
clog!(amount);                 // single primitive
clog!(x, y, r);                // multiple primitives in one call
clog!(pre, post);              // structs implementing CvlrLog
```

```{tip}
**Rule of thumb:** every value you produced with `nondet()` should appear in
some `clog!` before any assertion that depends on it. A counterexample
without logged inputs is hard to read.
```

### `CvlrLog` — log your own structs

To `clog!` a custom struct, implement the `CvlrLog` trait. The pattern is
boilerplate; copy it for every snapshot type you define.

```rust
use cvlr::log::{cvlr_log_with, CvlrLog, CvlrLogger};

pub struct VaultSnapshot {
    pub tokens: u64,
    pub shares: u64,
}

impl CvlrLog for VaultSnapshot {
    #[inline(always)]
    fn log(&self, tag: &str, logger: &mut CvlrLogger) {
        logger.log_scope_start(tag);
        cvlr_log_with("tokens", &self.tokens, logger);
        cvlr_log_with("shares", &self.shares, logger);
        logger.log_scope_end(tag);
    }
}
```

Now you can write:

```rust
let pre  = VaultSnapshot { tokens: vault.tokens, shares: vault.shares };
// ... run handler ...
let post = VaultSnapshot { tokens: vault.tokens, shares: vault.shares };
clog!(pre, post);
cvlr_assert_le!(post.shares, post.tokens);
```

Counterexamples will then show both snapshots with all named fields.

## `mathint::NativeInt` — arithmetic without overflow noise

When you write `cvlr_assert!(post.tokens >= pre.tokens)`, you mean it
*mathematically* — but the Prover sees `u64` arithmetic with wraparound. Tiny
overflow corner cases will then become spurious counterexamples.

`cvlr::mathint::NativeInt` is an unbounded integer that the Prover treats as
mathematical. Convert at the boundary, do arithmetic in `NativeInt`, and
optionally re-bound at the end.

```rust
use cvlr::mathint::NativeInt;
use cvlr::prelude::*;

#[rule]
pub fn rule_no_dilution() {
    let pre_tokens: u64  = nondet();
    let pre_shares: u64  = nondet();
    let amount:     u64  = nondet();

    // Lift into NativeInt for safe arithmetic.
    let t: NativeInt = pre_tokens.into();
    let s: NativeInt = pre_shares.into();
    let a: NativeInt = amount.into();

    // Express the precondition mathematically.
    cvlr_assume!(s <= t);

    // Constrain to the representable range when needed.
    let new_tokens = t + a;
    cvlr_assume!(NativeInt::is_u64(new_tokens));

    // The property: new ratio is no worse than the old one.
    cvlr_assert!(s * new_tokens <= (s + a) * t);
}
```

Useful operations on `NativeInt`:

| Method                     | Purpose                                       |
| -------------------------- | --------------------------------------------- |
| `NativeInt::from(x: u64)`  | lift a `u64`                                  |
| `n.into() : NativeInt`     | (same, via `Into`)                            |
| `NativeInt::is_u64(n)`     | true if `n` fits in `u64`                     |
| `NativeInt::is_u128(n)`    | true if `n` fits in `u128`                    |
| `+`, `-`, `*`, comparison  | unbounded arithmetic                          |

Use `NativeInt` for solvency / monotonicity invariants where overflow would
only be a real bug if it could actually happen. Don't reach for it when `u64`
is genuinely the right model (e.g. simulating a counter that wraps).

## Putting it together

The shape of most practical specs is: snapshot the pre-state, restrict it
with `assume_pre`, run the handler, snapshot the post-state, log both, and
assert a relation:

```rust
use cvlr::mathint::NativeInt;
use cvlr::prelude::*;

// Snapshot type with a CvlrLog impl as shown in the previous section
// (substituting NativeInt for the field types).
pub struct Snapshot { tokens: NativeInt, shares: NativeInt }
// impl CvlrLog for Snapshot { /* … as above … */ }

#[rule]
pub fn rule_deposit_preserves_solvency() {
    let mut tokens: u64 = nondet();
    let mut shares: u64 = nondet();
    let pre = Snapshot { tokens: tokens.into(), shares: shares.into() };
    cvlr_assume!(pre.shares <= pre.tokens);

    let amount: u64 = nondet();
    cvlr_assume!(NativeInt::is_u64(pre.tokens + NativeInt::from(amount)));
    tokens = (pre.tokens + NativeInt::from(amount)).try_into().unwrap();
    shares = nondet();

    let post = Snapshot { tokens: tokens.into(), shares: shares.into() };
    clog!(pre, post);
    cvlr_assume!(post.shares <= post.tokens);
    cvlr_assert_le!(post.shares, post.tokens);
}
```

This `pre` / `assume_pre` / run / `post` / `clog!` / assert shape is the
workhorse of practical specs. It is generalised in {ref}`solana_parametric_rules`.

## What's next

- {ref}`solana_project_setup` — wiring CVLR into a Cargo workspace.
- {ref}`solana_nondet` — nondet beyond primitives: enums, references,
  bounded vectors.
- {ref}`solana_mocks` — feature-gated mocks for CPIs and heavy code.
- {ref}`solana_accounts` — verifying handlers that take `&[AccountInfo]`.
- {ref}`solana_parametric_rules` — scaling specs with traits and macros.
- {ref}`solana_methodology` — best practices for writing rules that close.
