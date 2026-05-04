(solana_mocks)=
# Mocks & Feature Gates

Real Solana programs are full of code the Prover should not — and sometimes
*cannot* — reason about exactly: cross-program invocations (CPIs), heavy
arithmetic, syscalls, large tables, third-party libraries. The standard
technique is to keep the production code unchanged and **swap in a simpler
implementation when verifying**. This page collects the four patterns that
cover virtually every case.

The mechanism is always the same: conditional compilation under
`#[cfg(feature = "certora")]`. The `certora` feature is enabled only when
`certoraSolanaProver` builds your crate.

## The `certora` feature

Every verification-time crate dependency and code path lives behind this
flag, as introduced in {ref}`solana_project_setup`:

```toml
[features]
default       = []
no-entrypoint = []
certora       = ["no-entrypoint", "dep:cvlr", "dep:cvlr-solana"]

[dependencies]
cvlr        = { workspace = true, optional = true }
cvlr-solana = { workspace = true, optional = true }
```

In `lib.rs`:

```rust
#[cfg(feature = "certora")]
pub mod certora;
```

When the feature is off (production builds), nothing in `src/certora/` is
compiled, no cvlr code is linked, and your binary is unchanged.

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
- Callers don't need to observe side effects.

Use a **trait-based mock** (Pattern C) instead when behaviour must vary
per-rule.

## Pattern B — `cvlr::mock_fn` attribute

Editing a production function to add `#[cfg]` blocks is invasive. The
`cvlr::mock_fn` attribute lets you redirect the call site instead, leaving
the original function definition untouched at the source level:

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

The optional `when="..."` argument lets you toggle individual mocks per conf
without rebuilding — used when one rule wants the real function and another
wants the mock:

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
specific simplification.

## Pattern D — `cvlr_hook_on_exit` for tracking calls

Sometimes the body of a mock is `Ok(())` but you still want to *observe*
that it was called — for example, to assert "after handler X runs, function
Y was called exactly once". The `cvlr::cvlr_hook_on_exit` attribute lets a
mock raise a side-effect when it returns. Many specs alias it as
`cvt_hook_end` for brevity.

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

use cvlr::cvlr_hook_on_exit as cvt_hook_end;
use cvlr::nondet::nondet;
use crate::certora::hooks::*;
use solana_program::{program_error::ProgramError, pubkey::Pubkey};

#[cfg_attr(feature = "certora", cvt_hook_end(transfer_was_called()))]
pub fn mock_token_transfer(
    _from: &Pubkey,
    _to: &Pubkey,
    _amount: u64,
) -> Result<(), ProgramError> {
    Ok(())
}

#[cfg_attr(feature = "certora", cvt_hook_end(burn_was_called()))]
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

This pattern shines when:

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

Keep mocks under `src/certora/mocks/` and mirror the production tree:

```
src/
├── processor.rs
├── state.rs
├── math.rs
└── certora/
    ├── mod.rs
    ├── hooks.rs
    ├── log.rs
    └── mocks/
        ├── mod.rs
        ├── math.rs              ← compute_fee_mock, compute_interest_mock
        ├── cpi.rs               ← mock_token_transfer, mock_token_burn
        └── processor.rs         ← optional: alternative processor variants
```

This makes it trivial to find the mock for a production function: same path,
under `certora/mocks/`.

## When to mock vs. when to leave it real

| Situation                                                   | Mock?                                                  |
| ----------------------------------------------------------- | ------------------------------------------------------ |
| Pure arithmetic that fits in `NativeInt`                    | No — let the Prover see the math.                       |
| Loop with bound > a handful of iterations                   | Yes — the Prover unrolls. Mock or split the rule.      |
| Cross-program invocation (`invoke`, `invoke_signed`)        | Yes — almost always. Use Pattern D if you need to track. |
| SPL Token transfer / mint / burn                            | Yes. Use Pattern D to assert which side ran.           |
| Borrow rate / price / oracle math with rounding tables      | Yes. Pattern A or B with `nondet()`.                   |
| The function whose property you're verifying                | **No.** Don't mock the system under test.              |

Two design principles:

1. **A mock should be the *weakest* function consistent with the contract.**
   Returning `nondet()` is usually right — it forces the Prover to consider
   every outcome. Pinning a return value (e.g. `Ok(0)`) is acceptable only
   when the rule explicitly does not care.

2. **Don't change the production signature for verification.** That is what
   `cvlr::mock_fn` and trait indirection are for. Keeping signatures stable
   means specs continue to compile after refactors and the spec is closer to
   the production code.

## What's next

- {ref}`solana_accounts` — putting account harnesses together.
- {ref}`solana_parametric_rules` — using trait-based mocks across many rules
  without copy-paste.
