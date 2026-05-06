(solana_anchor)=
# Anchor

The Anchor framework wraps `AccountInfo` in typed `Account<'info, T>`,
`Signer<'info>`, and `Program<'info, T>` handles, and dispatches handlers
through a `Context<T>`. Verifying Anchor programs uses the same
`cvlr-solana` primitives covered in {ref}`solana_accounts` (especially
`cvlr_deserialize_nondet_accounts`), with a thin layer of project-local
helpers on top to bridge between raw `AccountInfo`s and the Anchor types.

This page collects those helpers and shows the end-to-end harness shape.

## Project-local Anchor helpers

Anchor verification harnesses do **not** come bundled with `cvlr-solana` —
every Anchor-using project defines its own set of helpers. The helpers
are short and mostly identical between projects; copy this set into
`src/certora/anchor.rs` and adjust to taste:

```rust
//! src/certora/anchor.rs
use anchor_lang::prelude::*;
use cvlr::prelude::*;

/// Build a havoced `Account<'info, T>` from an `AccountInfo`.
/// The inner `T` is fully nondet; mutate fields after construction
/// to set up a specific starting state.
pub fn cvlr_anchor_account<'info, T>(info: &'info AccountInfo<'info>) -> Account<'info, T>
where
    T: Clone + AccountSerialize + AccountDeserialize + Owner + Nondet,
{
    Account { account: nondet(), info }
}

/// Same as above but goes through the real `try_deserialize` path on
/// nondet bytes — useful when you want the deserializer's checks to run.
pub fn cvlr_anchor_account_try_from<'info, T>(info: &'info AccountInfo<'info>) -> Account<'info, T>
where
    T: Clone + AccountSerialize + AccountDeserialize + Owner,
{
    cvlr_assume!(info.owner == &T::owner());
    let mut data: &[u8] = &info.try_borrow_data().unwrap();
    let account = AccountDeserialize::try_deserialize(&mut data).unwrap();
    Account { account, info }
}

#[macro_export]
macro_rules! into_signer {
    ($from:expr) => { Signer::try_from($from).unwrap() };
}

#[macro_export]
macro_rules! into_program {
    ($from:expr) => { Program::try_from($from).unwrap() };
}

#[macro_export]
macro_rules! cvlr_anchor_new_context {
    ($accounts:expr, $bumps:expr) => {
        Context::new(&crate::ID, $accounts, &[], $bumps)
    };
}
```

Two things to choose between:

- **`cvlr_anchor_account`** bypasses Anchor's `try_deserialize` and
  places a fully nondet `T` directly into `Account`. Faster for the
  Prover; does not exercise the deserializer's owner / discriminator
  checks.
- **`cvlr_anchor_account_try_from`** runs the real `try_deserialize` on
  nondet bytes. Slower, but lets you verify that the deserializer's checks
  hold under the `info.owner == &T::owner()` precondition.

Use the first by default; reach for the second when a rule needs to
exercise deserialization.

### Basic usage

```rust
#[account]
pub struct Settings {
    pub authority: Pubkey,
    pub threshold: u16,
}

let settings: Account<'_, Settings> = cvlr_anchor_account(&acc_infos[0]);
```

The returned `Account<'_, T>` has a havoced `T` inside. Mutate fields
directly to set up a starting state, then assemble the Anchor `Context` and
call the handler.

## Anchor harness end-to-end

When the program is Anchor-based, you'll be assembling Anchor `Accounts`
structs and `Context` values. Reach for the project-local helpers shown
above:

- `cvlr_anchor_account(&info)` — build an `Account<'_, T>` with a havoced inner `T`.
- `into_signer!(&info)` — turn an `AccountInfo` into a `Signer<'_>`.
- `into_program!(&info)` — turn an `AccountInfo` into a `Program<'_, T>`.
- `cvlr_anchor_new_context!(accounts, bumps)` — build the `Context`.

```rust
use anchor_lang::prelude::*;
use cvlr::prelude::*;
use cvlr_solana::{
    cvlr_anchor_account, cvlr_deserialize_nondet_accounts, cvlr_nondet_pubkey,
};

#[derive(Accounts)]
pub struct DepositCtx<'info> {
    #[account(mut)] pub vault:           Account<'info, Vault>,
    #[account(mut)] pub user_token:      AccountInfo<'info>,
    #[account(mut)] pub vault_token:     AccountInfo<'info>,
                    pub user:            Signer<'info>,
                    pub token_program:   Program<'info, Token>,
}

pub fn deposit(ctx: Context<DepositCtx>, amount: u64) -> Result<()> { /* … */ Ok(()) }

#[rule]
pub fn rule_deposit_anchor() {
    let acc_infos: [AccountInfo; 8] = cvlr_deserialize_nondet_accounts();

    let mut deposit_ctx = DepositCtx {
        vault:         cvlr_anchor_account(&acc_infos[0]),
        user_token:    acc_infos[1].clone(),
        vault_token:   acc_infos[2].clone(),
        user:          into_signer!(&acc_infos[3]),
        token_program: into_program!(&acc_infos[4]),
    };

    let program_id = cvlr_nondet_pubkey();
    let ctx = Context::new(&program_id, &mut deposit_ctx, &[], DepositCtxBumps::default());

    let amount: u64 = nondet();
    deposit(ctx, amount).unwrap();

    cvlr_assert!(/* your post-condition */ true);
}
```

The pattern is mechanical: build the `Accounts` struct, build a `Context`
around it, call the handler, assert.

## Anchor-specific pitfalls

- **Missing `clone()` on `AccountInfo`.** When stuffing accounts into an
  Anchor `Accounts` struct, you typically need `.clone()` because the struct
  takes ownership of the fields it doesn't borrow.
- **Forgetting `DepositCtxBumps::default()`.** Anchor's `Context::new`
  takes a bumps argument; for verification you usually want a default-zero
  bumps struct unless the rule specifically tests PDA derivation.
- **Mixing `cvlr_anchor_account` and `_try_from` in the same harness.**
  Pick one per `Accounts` field — mixing them makes pre-conditions harder
  to reason about.

## What's next

- {ref}`solana_accounts` — the underlying account-handling primitives that
  the Anchor helpers wrap.
- {ref}`solana_parametric_rules` — factoring the snapshot pattern across
  many rules.
