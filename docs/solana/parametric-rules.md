(solana_parametric_rules)=
# Parametric Rules & Macros

Once you have more than one or two rules, you'll notice copy-paste piling
up: every rule reads the same accounts, calls the same handler, snapshots
state, and asserts a property. This page covers the two techniques that
scale rule count without the duplication: **trait-parameterised harnesses**
and **`macro_rules!` for environment generation**.

## Why factor at all?

A naive spec for a vault with two handlers (`deposit`, `withdraw`) and three
properties (`solvency`, `monotonicity`, `no_dilution`) is a 6-rule
copy-paste. A real protocol has 10+ handlers and a similar number of
properties — that's 100+ near-identical rules. Factoring is not a luxury.

The two patterns below cover essentially every spec organisation you'll
need. **Use traits when the harness is uniform across properties, and
macros when the setup itself differs per rule.**

## Pattern 1 — Trait-parameterised harnesses

This is the workhorse. Define one trait describing what a "property" is,
write one harness per handler that runs the handler and checks any property
implementing that trait, and write one struct per property. The
cross-product of (handler × property) is then trivial:

```rust
//! src/certora/specs/base.rs

use cvlr::log::CvlrLog;
use cvlr::prelude::*;
use crate::state::Vault;
use crate::operations::{vault_deposit, vault_withdraw, DepositEffect};

pub struct OpParams { pub amount: u64 }

/// Every property checked over a vault implements this trait.
pub trait CvlrProp: CvlrLog {
    /// Snapshot the parts of the vault state this property cares about.
    fn new(vault: &Vault) -> Self;
    /// Restrict the pre-state to legal inputs for this property.
    fn assume_pre(&self);
    /// Assert what should hold after the handler runs.
    fn check_post(&self, old: &Self, params: OpParams);
}

#[inline(always)]
pub fn base_deposit<P: CvlrProp>() {
    let mut vault: Vault = nondet();
    let pre = P::new(&vault);
    pre.assume_pre();

    let amount: u64 = nondet();
    let _effect: DepositEffect = vault_deposit(&mut vault, amount).unwrap();

    let post = P::new(&vault);
    clog!(pre, post);
    post.check_post(&pre, OpParams { amount });
}

#[inline(always)]
pub fn base_withdraw<P: CvlrProp>() {
    let mut vault: Vault = nondet();
    let pre = P::new(&vault);
    pre.assume_pre();

    let amount: u64 = nondet();
    vault_withdraw(&mut vault, amount).unwrap();

    let post = P::new(&vault);
    clog!(pre, post);
    post.check_post(&pre, OpParams { amount });
}
```

A property is a tiny struct + impl:

```rust
//! src/certora/specs/solvency/props.rs

use cvlr::log::{cvlr_log_with, CvlrLog, CvlrLogger};
use cvlr::mathint::NativeInt;
use cvlr::prelude::*;
use crate::certora::specs::base::{CvlrProp, OpParams};
use crate::state::Vault;

pub struct SolvencyInvariant {
    tokens: NativeInt,
    shares: NativeInt,
}

impl CvlrLog for SolvencyInvariant {
    #[inline(always)]
    fn log(&self, tag: &str, l: &mut CvlrLogger) {
        l.log_scope_start(tag);
        cvlr_log_with("tokens", &self.tokens, l);
        cvlr_log_with("shares", &self.shares, l);
        l.log_scope_end(tag);
    }
}

impl CvlrProp for SolvencyInvariant {
    fn new(v: &Vault) -> Self {
        Self { tokens: v.tokens.into(), shares: v.shares.into() }
    }
    fn assume_pre(&self) {
        cvlr_assume!(self.shares <= self.tokens);
    }
    fn check_post(&self, _old: &Self, _: OpParams) {
        cvlr_assert_le!(self.shares, self.tokens);
    }
}
```

And a second one:

```rust
pub struct Monotonicity {
    tokens: u64,
}

impl CvlrLog for Monotonicity { /* … */ }

impl CvlrProp for Monotonicity {
    fn new(v: &Vault) -> Self { Self { tokens: v.tokens } }
    fn assume_pre(&self) { /* nothing */ }
    fn check_post(&self, old: &Self, p: OpParams) {
        // After a deposit, tokens go up by amount.
        cvlr_assert_eq!(self.tokens, old.tokens + p.amount);
    }
}
```

The rule files are then trivial:

```rust
//! src/certora/specs/solvency/solvency.rs

use cvlr::prelude::*;
use crate::certora::specs::base::{base_deposit, base_withdraw};
use crate::certora::specs::solvency::props::SolvencyInvariant;

#[rule] pub fn rule_solvency_deposit()  { base_deposit::<SolvencyInvariant>(); }
#[rule] pub fn rule_solvency_withdraw() { base_withdraw::<SolvencyInvariant>(); }
```

```rust
//! src/certora/specs/monotonicity/monotonicity.rs

#[rule] pub fn rule_monotonicity_deposit() { base_deposit::<Monotonicity>(); }
```

To add a new property, write one struct + impl. To add a new handler, write
one `base_handler` function. The cross-product gets a one-line rule each.

### When the harness needs accounts

The same pattern works when the harness builds an account array. The trait
becomes parameterised over `&AccountInfo` rather than over the value
struct:

```rust
pub trait CvlrAccountProp: CvlrLog {
    fn new(vault: &AccountInfo, user: &AccountInfo) -> Self;
    fn assume_pre(&self);
    fn check_post(&self, old: &Self);
}

#[inline(always)]
pub fn base_deposit_accounts<P: CvlrAccountProp>() {
    let acc_infos: [AccountInfo; 8] = cvlr_deserialize_nondet_accounts();
    let vault_info = &acc_infos[0];
    let user_info  = &acc_infos[1];

    let pre = P::new(vault_info, user_info);
    pre.assume_pre();

    let amount: u64 = nondet();
    process_deposit(&acc_infos, amount).unwrap();

    let post = P::new(vault_info, user_info);
    clog!(pre, post);
    post.check_post(&pre);
}
```

## Pattern 2 — `macro_rules!` for environment generation

Traits stop being convenient once the *setup itself* differs across rules
— for example, you need to havoc a `Vec<T>` of varying length, or call a
sequence of handlers in different orders. Then reach for macros.

### A small setup macro

```rust
/// Returns a fresh nondet Vault that satisfies basic invariants.
#[macro_export]
macro_rules! setup_vault {
    () => {{
        let mut v: $crate::state::Vault = cvlr::nondet();
        cvlr::cvlr_assume!(v.shares <= v.tokens);
        cvlr::cvlr_assume!(v.tokens <= 1_000_000_000);   // bound to keep TAC small
        v
    }};
}
```

```rust
#[rule]
pub fn rule_deposit_keeps_solvency() {
    let mut v = setup_vault!();
    let amount: u64 = cvlr::nondet();
    vault_deposit(&mut v, amount).unwrap();
    cvlr_assert_le!(v.shares, v.tokens);
}
```

### Binding multiple nondet values in a block

```rust
#[macro_export]
macro_rules! with_two_distinct_users {
    ($a:ident, $b:ident => $body:block) => {{
        let $a: solana_program::pubkey::Pubkey = cvlr_solana::cvlr_nondet_pubkey();
        let $b: solana_program::pubkey::Pubkey = cvlr_solana::cvlr_nondet_pubkey();
        cvlr::cvlr_assume!($a != $b);
        $body
    }};
}
```

```rust
with_two_distinct_users!(alice, bob => {
    transfer(&alice, &bob, 100).unwrap();
    cvlr_assert!(/* … */ true);
});
```

### Generating nondet `Vec<T>` constructors

Solana data structures often hold homogeneous lists (members, instructions,
lookups). A reusable macro that defines a nondet constructor for each
element type keeps boilerplate down:

```rust
#[macro_export]
macro_rules! nondet_vec_of {
    ($elem:ty, $name:ident, $cap:expr) => {
        pub fn $name() -> Vec<$elem> {
            let len: usize = cvlr::nondet();
            cvlr::cvlr_assume!(len <= $cap);
            let mut v: Vec<$elem> = Vec::with_capacity($cap);
            for _ in 0..len {
                v.push(cvlr::nondet());
            }
            v
        }
    };
}

// Instantiate once per element type:
nondet_vec_of!(u64,    nondet_vec_u64,    8);
nondet_vec_of!(Pubkey, nondet_vec_pubkey, 8);
```

For projects with very large element types, the prover-friendly pattern is
to allocate via an `extern "C"` symbol the Prover already understands and
wrap it in a small constructor — but the simpler form above is enough for
most rules.

### Building multi-step state machines

When verifying handlers that depend on prior handler calls (proposal
lifecycle, multisig flows), a setup macro that runs an *arbitrary* sequence
of state transitions is invaluable:

```rust
/// Run zero or more arbitrary state transitions on a proposal,
/// returning the resulting (multisig, proposal).
#[macro_export]
macro_rules! arbitrary_proposal_transition {
    ($multisig:expr, $proposal:expr, $member:expr) => {{
        match cvlr::nondet::<u8>() % 4 {
            0 => { /* approve */ proposal_approve(/* … */).unwrap(); }
            1 => { /* reject  */ proposal_reject (/* … */).unwrap(); }
            2 => { /* cancel  */ proposal_cancel (/* … */).unwrap(); }
            _ => { /* no-op   */ }
        }
        ($multisig, $proposal)
    }};
}

/// Build a proposal in an arbitrary reachable state via two transitions.
#[macro_export]
macro_rules! nondet_env_for_proposal {
    ($member1:expr, $member2:expr) => {{
        let m  = nondet_multisig!();
        let p0 = nondet_proposal!(&m);
        let (m1, p1) = arbitrary_proposal_transition!(m,  p0, $member1);
        let (m2, p2) = arbitrary_proposal_transition!(m1, p1, $member2);
        (m2, p2)
    }};
}
```

A single rule can then say "given any proposal that has been touched by two
arbitrary actions, the next thing must succeed":

```rust
#[rule]
pub fn rule_can_always_cancel() {
    let m1 = cvlr_nondet_pubkey();
    let m2 = cvlr_nondet_pubkey();
    cvlr_assume!(m1 != m2);
    let (multisig, proposal) = nondet_env_for_proposal!(m1, m2);
    proposal_cancel(/* … */).unwrap();   // must not panic from any reachable state
}
```

This is more powerful than what trait-parameterised harnesses give you,
because the *path through the protocol* is part of the search.

## Bounded vectors via `cvlr-vectors`

`cvlr-vectors::cvt_no_resizable_vec!` is the recommended primitive for
constructing a `Vec<T>` of a specific compile-time capacity:

```rust
use cvlr_vectors::cvt_no_resizable_vec;

let xs: Vec<u64>     = cvt_no_resizable_vec!([nondet::<u64>(), nondet::<u64>()]; 10);
let empty: Vec<u64>  = cvt_no_resizable_vec!([]; 10);
```

A thin project-local wrapper macro keeps the capacity choice consistent:

```rust
#[macro_export]
macro_rules! cvlr_vec10 {
    ($items:tt) => { cvlr_vectors::cvt_no_resizable_vec!($items; 10) };
}
```

See {ref}`solana_nondet_vectors` for the capacity choice trade-offs.

## Hooks for invariant tracking

A complementary pattern: when an invariant must be *checked at runtime*
inside the handler (not just before/after), use a hook to record that the
check ran. The mechanism is an `unsafe static` flag flipped by a hook on
function exit (see {ref}`solana_mocks` for the underlying mechanism).

```rust
//! src/certora/hooks.rs
static mut INVARIANT_CHECKED: bool = false;
pub fn reset_invariant()      { unsafe { INVARIANT_CHECKED = false; } }
pub fn invariant_was_checked(){ unsafe { INVARIANT_CHECKED = true;  } }
pub fn was_invariant_checked() -> bool { unsafe { INVARIANT_CHECKED } }
```

```rust
//! src/state.rs
use cvlr::cvlr_hook_on_exit as cvt_hook_end;

#[cfg_attr(feature = "certora", cvt_hook_end(crate::certora::hooks::invariant_was_checked()))]
pub fn check_invariant(v: &Vault) {
    assert!(v.shares <= v.tokens);
}
```

```rust
//! src/certora/specs/invariants.rs
#[rule]
pub fn rule_deposit_runs_invariant_check() {
    crate::certora::hooks::reset_invariant();
    let mut v = setup_vault!();
    vault_deposit(&mut v, nondet()).unwrap();
    cvlr_assert!(crate::certora::hooks::was_invariant_checked());
}
```

This catches refactors that accidentally remove an invariant check from a
handler.

## When to choose which

| Situation                                                        | Use                              |
| ---------------------------------------------------------------- | -------------------------------- |
| Many properties × many handlers, uniform setup                   | Trait-parameterised harnesses    |
| Different rules need different starting states                   | `macro_rules!` for setup          |
| Multi-step state-machine exploration (sequence of handler calls) | `macro_rules!` chains             |
| Bounded `Vec<T>` of varying element types                        | `nondet_vec_of!` + `cvlr-vectors` |
| Verifying that a runtime check actually runs                     | `cvlr_hook_on_exit` + static flag |

The two patterns compose cleanly: a trait-parameterised harness can call
into setup macros, and a property's `assume_pre` / `check_post` can use
hook-flag readers.

## What's next

- {ref}`solana_methodology` — practical guidelines for writing rules that
  actually verify, not just compile.
