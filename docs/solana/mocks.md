(solana_mocks)=
# Mocks & Feature Gates

Solana programs may contain code that isn't relevant for the verification
task, or that the Prover *cannot* reason about exactly: cross-program
invocations (CPIs), heavy non-linear arithmetic. The standard technique is
to keep the production code unchanged and **swap in a simpler
implementation when verifying**. This page collects the patterns that can
be used to swap in an implementation for verification (also known as
mocking).

The mechanism is always the same: conditional compilation under
`#[cfg(feature = "certora")]`. The `certora` feature is enabled only when
`certoraSolanaProver` builds your crate.


## Important design consideration

1. **A mock should use the *weakest* assumptions.**
   Returning `nondet()` is usually right — it forces the Prover to consider
   every outcome. Pinning a return value (e.g. `Ok(0)`) is acceptable only
   when the rule explicitly does not care.

2. **Don't change the production signature for verification.** That is what
   `cvlr::mock_fn` and trait indirection are for. Keeping signatures stable
   means specs continue to compile after refactors and the spec is closer to
   the production code.

## The `certora` feature

Every verification-time crate dependency and code path lives behind the
`certora` Cargo feature. {ref}`solana_project_setup` shows the full
`Cargo.toml` block and the changes to your project's `lib.rs`. When the
feature is off (production builds), nothing in `src/certora/` is compiled, 
no cvlr code is linked, and your binary is unchanged.

## Pattern A — full implementation swap

The simplest mock: write two versions of a function and gate them.

```rust
// src/processor.rs

#[cfg(not(feature = "certora"))]
pub fn compute_interest(principal: u64, rate_bps: u16, days: u32) -> u64 {
    // Real, complex implementation (compounding, rounding, …).
    let mut acc: u128 = principal as u128;
    for _ in 0..days {
        acc = acc * (10_000 + rate_bps as u128) / 10_000;
    }
    acc as u64
}

#[cfg(feature = "certora")]
pub fn compute_interest(_principal: u64, _rate_bps: u16, _days: u32) -> u64 {
    // Mock: any u64 is plausible. The Prover explores all cases.
    cvlr::nondet()
}
```

Use this when:

- The function is small and self-contained.
- The result can be modelled as "any value of type T" without losing the
  important contract.
- While this pattern is simple, it also adds a few extra lines to the code base.

Use a **trait-based mock** (Pattern C) instead when behaviour must vary
per-rule.

## Pattern B — `cvlr::mock_fn` attribute

Editing a production function to add `#[cfg]` blocks is invasive. The
`cvlr::mock_fn` attribute lets you redirect the call site instead, leaving
the original function definition untouched at the source level (only one line
needs to be added to the source code):

```rust
// src/processor.rs

#[cfg_attr(
    feature = "certora",
    cvlr::mock_fn(with = crate::certora::mocks::math::compute_fee_mock)
)]
pub fn compute_fee(amount: u64, bps: u16) -> u64 {
    // Real implementation, kept exactly as-is.
    (amount as u128 * bps as u128 / 10_000) as u64
}
```

```rust
// src/certora/mocks/math.rs
use cvlr::nondet;

pub fn compute_fee_mock(_amount: u64, _bps: u16) -> u64 {
    nondet()
}
```

When `--feature certora` is on, calls to `compute_fee` are redirected to
`compute_fee_mock`. The mock's signature **must match** the original.

The optional `when="..."` argument is a regular [cargo feature](https://doc.rust-lang.org/cargo/reference/features.html) that is included in the compiled code when enabled. That is, `Cargo.toml` needs to have an entry `certora-mock-fees = []`, and the environment flag `CARGO_FEATURES="certora-mock-fees"` is used for compilation.

```rust
#[cfg_attr(
    feature = "certora",
    cvlr::mock_fn(
        with = crate::certora::mocks::math::compute_fee_mock,
        when = "certora-mock-fees"
    )
)]
pub fn compute_fee(amount: u64, bps: u16) -> u64 { /* … */ }
```

## Pattern C — trait-based mock indirection

When the production code calls into something whose behaviour must vary by
rule, hide the call behind a trait. Provide a real impl and one or more
verification impls. Each rule picks which one to instantiate.

```rust
// src/state.rs (or wherever your business types live)

pub trait FeePolicy {
    fn fee_for(amount: u64) -> u64;
}

pub struct Production;
impl FeePolicy for Production {
    fn fee_for(amount: u64) -> u64 { amount / 100 }   // real
}

#[cfg(feature = "certora")]
pub struct AnyFee;
#[cfg(feature = "certora")]
impl FeePolicy for AnyFee {
    fn fee_for(_amount: u64) -> u64 { cvlr::nondet() }   // havoc
}

#[cfg(feature = "certora")]
pub struct ZeroFee;
#[cfg(feature = "certora")]
impl FeePolicy for ZeroFee {
    fn fee_for(_amount: u64) -> u64 { 0 }                // pinned
}

pub fn deposit<F: FeePolicy>(vault: &mut Vault, amount: u64) {
    let fee = F::fee_for(amount);
    vault.tokens = vault.tokens.saturating_add(amount - fee);
}
```

Then pick per rule:

```rust
#[rule] pub fn rule_deposit_any_fee()  { /* … */ deposit::<AnyFee >(&mut v, amt); /* … */ }
#[rule] pub fn rule_deposit_zero_fee() { /* … */ deposit::<ZeroFee>(&mut v, amt); /* … */ }
```

Use this when one rule wants the worst-case behaviour and another wants a
specific concrete simplification.

## Pattern D — `cvlr_hook_on_exit` for tracking calls

Sometimes the body of a mock is `Ok(())` but you still want to *observe*
that it was called — for example, to assert "after handler X runs, function
Y was called exactly once". The `cvlr::cvlr_hook_on_exit` attribute lets a
mock raise a side-effect when it returns. 

```rust
// src/certora/hooks.rs
//
// Tiny state machine that tracks which CPI was invoked.
// Used by mocks (via cvlr_hook_on_exit) and by rules.

#[derive(Clone, Copy, Eq, PartialEq)]
pub enum LastCall {
    None,
    Transfer,
    Burn,
}

static mut LAST_CALL: LastCall = LastCall::None;

pub fn reset_calls()        { unsafe { LAST_CALL = LastCall::None; } }
pub fn transfer_was_called(){ unsafe { LAST_CALL = LastCall::Transfer; } }
pub fn burn_was_called()    { unsafe { LAST_CALL = LastCall::Burn; } }

pub fn last_was_transfer() -> bool { unsafe { LAST_CALL == LastCall::Transfer } }
pub fn last_was_burn()     -> bool { unsafe { LAST_CALL == LastCall::Burn } }
```

```rust
// src/certora/mocks/cpi.rs

use cvlr::cvlr_hook_on_exit;
use cvlr::nondet::nondet;
use crate::certora::hooks::*;
use solana_program::{program_error::ProgramError, pubkey::Pubkey};

#[cfg_attr(feature = "certora", cvlr_hook_on_exit(transfer_was_called()))]
pub fn mock_token_transfer(
    _from: &Pubkey,
    _to: &Pubkey,
    _amount: u64,
) -> Result<(), ProgramError> {
    Ok(())
}

#[cfg_attr(feature = "certora", cvlr_hook_on_exit(burn_was_called()))]
pub fn mock_token_burn(
    _owner: &Pubkey,
    _amount: u64,
) -> Result<u64, ProgramError> {
    Ok(nondet())
}
```

```rust
// src/certora/specs/cpi.rs

use cvlr::prelude::*;
use crate::certora::hooks::*;

#[rule]
pub fn rule_withdraw_calls_transfer() {
    reset_calls();
    // … set up nondet state, run withdraw handler …
    cvlr_assert!(last_was_transfer());
    cvlr_assert!(!last_was_burn());
}
```

This pattern is appropriate when:

- You're verifying a handler that performs CPIs you don't want to model
  precisely.
- You still need to know *which* CPI was invoked, not just that the handler
  succeeded.

## Stubbing `msg!`

Solana's `msg!` macro performs a syscall. In TAC it would just produce noise
and slow the Prover down. The convention is to replace it with a no-op via
a project-local macro that shadows the import path used in your code:

```rust
// src/certora/log.rs
//
// No-op msg! used during verification.
#[macro_export]
macro_rules! msg {
    ($msg:expr)         => { };
    ($($arg:tt)*)       => { };
}
```

Re-export it from your `certora` module so callers pick it up:

```rust
// src/certora/mod.rs
#[cfg(feature = "certora")]
pub mod log;
```

Then in production code, import `msg!` through a path that resolves to the
`solana_program` macro normally and to the stub when verifying. The exact
wiring depends on your crate; the simplest version is to
`use crate::log::msg;` in modules that should be stubbed under `certora`.

## File layout convention

Keep mocks under `src/certora/mocks/` and **mirror the production tree** —
the mock for `src/foo.rs` lives at `src/certora/mocks/foo.rs`. This makes it
trivial to find the mock for any production function. See
{ref}`solana_project_setup` for the full recommended source-tree layout.

## What's next

- {ref}`solana_accounts` — putting account harnesses together.
- {ref}`solana_parametric_rules` — using trait-based mocks across many rules
  without copy-paste.
