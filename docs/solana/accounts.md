(solana_accounts)=
# Solana Accounts

Most real Solana handlers take `&[AccountInfo]` and read/write account data.
To verify them you need a way to produce nondeterministic accounts, read
typed state out of them, and snapshot before/after. This page covers the
account-handling helpers in `cvlr-solana`.

## Producing nondet accounts

### Current pattern: `cvlr_deserialize_nondet_accounts`

The recommended way (cvlr-solana ≥ 0.4.3) to spawn a fixed-size array of
nondeterministic `AccountInfo`s:

```rust
use cvlr::prelude::*;
use cvlr_solana::cvlr_deserialize_nondet_accounts;
use solana_program::account_info::{next_account_info, AccountInfo};

#[rule]
pub fn rule_deposit_smoke() {
    let acc_infos: [AccountInfo; 8] = cvlr_deserialize_nondet_accounts();
    let iter = &mut acc_infos.iter();
    let vault_info     = next_account_info(iter).unwrap();
    let user_info      = next_account_info(iter).unwrap();
    let token_program  = next_account_info(iter).unwrap();
    // ... rest of the harness ...
}
```

What you get:

- An array of `AccountInfo`s with internally-consistent memory layout —
  `try_borrow_data`, `try_borrow_lamports`, `key`, `owner` all work.
- Each account's `data`, `lamports`, `key`, and `owner` are independently
  havoced.
- The array length is a compile-time constant. Pick the smallest size that
  matches your handler's signature. Common values are 4, 8, 16.

### Older pattern: `acc_infos_with_mem_layout!()`

In cvlr-solana 0.4.0–0.4.2 (and still working in newer versions for
backward compatibility) the same role was played by a macro:

```rust
use cvlr_solana::acc_infos_with_mem_layout;

let acc_infos: [AccountInfo; 8] = acc_infos_with_mem_layout!();
```

```{note}
**Version note.** `cvlr_deserialize_nondet_accounts()` and
`acc_infos_with_mem_layout!()` are interchangeable in practice. Prefer the
function form in new code.
```

### Slicing to the right length

Many handlers take exactly `N` accounts. Allocate a generous array, then
slice:

```rust
let acc_infos: [AccountInfo; 16] = cvlr_deserialize_nondet_accounts();
let used = &acc_infos[..5];   // pass `used` to the handler
```

This is convenient because you can keep the same array size across many
rules and only slice differently per handler.

## Pubkeys

```rust
use cvlr_solana::{cvlr_nondet_pubkey, cvlr_nondet_option_pubkey};
use solana_program::pubkey::Pubkey;

let program_id: Pubkey                  = cvlr_nondet_pubkey();
let optional:   Option<Pubkey>          = cvlr_nondet_option_pubkey();
```

Use `cvlr_nondet_pubkey()` rather than `nondet::<Pubkey>()` so the Prover
treats it as an opaque 32-byte identifier rather than havocing 32 individual
bytes (the latter is slower and gives the Prover more rope to hang itself
with).

## Reading typed state out of an account

### POD types via `bytemuck`

If your account state is `#[repr(C)]` and `Pod`, you can borrow it directly
from the account's data buffer:

```rust
use bytemuck::{Pod, Zeroable};
use solana_program::account_info::AccountInfo;

#[repr(C)]
#[derive(Clone, Copy, Pod, Zeroable)]
pub struct Vault {
    pub tokens: u64,
    pub shares: u64,
    pub bump:   u8,
    _padding:   [u8; 7],
}

fn read_vault<'a>(info: &AccountInfo<'a>) -> &'a mut Vault {
    let data = info.try_borrow_mut_data().unwrap();
    bytemuck::from_bytes_mut(unsafe {
        // SAFETY: data borrow lives as long as the AccountInfo
        std::slice::from_raw_parts_mut(data.as_ptr() as *mut u8, data.len())
    })
}
```

In practice you'll also want a value-only snapshot type for `clog!`:

```rust
pub struct VaultView {
    pub tokens: u64,
    pub shares: u64,
}

impl<'a> From<&AccountInfo<'a>> for VaultView {
    fn from(info: &AccountInfo) -> Self {
        let data = info.try_borrow_data().unwrap();
        let v: &Vault = bytemuck::from_bytes(&data[..core::mem::size_of::<Vault>()]);
        VaultView { tokens: v.tokens, shares: v.shares }
    }
}
```

### Anchor accounts

Anchor verification harnesses do not come bundled with `cvlr-solana` — every
Anchor-using project defines a small set of project-local helpers that
adapt cvlr's nondet machinery to Anchor's `Account<'info, T>`,
`Signer<'info>`, and `Program<'info, T>` types. The helpers are short and
mostly identical between projects; copy this set into
`src/certora/anchor.rs`:

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

(Adjust `cvlr_anchor_account` to match how your project's accounts are
constructed — some projects bypass `try_deserialize`, others depend on it.)

Usage:

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

### Account-loader-flavored helpers

Some projects use a trait-bound deserializer (often called something like
`FatAccountLoader`). Where it exists, the verification harness mirrors the
production loader pattern:

```rust
let loader = FatAccountLoader::<Vault>::try_from(&acc_infos[0]).unwrap();
let vault: &mut Vault = loader.load_mut().unwrap();
```

If the production code uses a custom loader, write a `Nondet` impl for the
loaded type and reuse the production loader unchanged. The mock surface
shrinks dramatically when you let the real deserialization paths execute on
nondet bytes.

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

## The clock and other sysvars

Some handlers branch on `Clock::get()`. To control the slot inside a rule,
use `cvlr-solana`'s clock helpers:

```rust
use cvlr_solana::cvlr_advance_clock_slot;

cvlr_advance_clock_slot();             // moves the clock forward by a nondet amount
// run handler that reads Clock::get()
cvlr_advance_clock_slot();             // again, between two handler calls
```

For a full nondet `Clock` value:

```rust
use solana_program::clock::Clock;
let clock: Clock = cvlr::nondet::havoc::alloc_ref_havoced::<Clock>().clone();
```

(or implement `Nondet for Clock` once and reuse).

## The pre/post snapshot pattern

Almost every account-touching rule has the same shape:

```rust
#[rule]
pub fn rule_deposit_preserves_solvency() {
    let acc_infos: [AccountInfo; 8] = cvlr_deserialize_nondet_accounts();
    let vault_info = &acc_infos[0];

    // 1. Read pre-state into a value snapshot.
    let pre: VaultView = vault_info.into();
    cvlr_assume!(pre.shares <= pre.tokens);    // protocol invariant

    // 2. Run the handler with nondet inputs.
    let amount: u64 = nondet();
    process_deposit(&acc_infos, amount).unwrap();

    // 3. Read post-state.
    let post: VaultView = vault_info.into();

    // 4. Log and assert.
    clog!(pre, post);
    cvlr_assert_le!(post.shares, post.tokens);
}
```

Steps 1, 3, 4 are entirely mechanical and look identical across rules. The
{ref}`solana_parametric_rules` page shows how to factor them out so you only
write the parts that vary.

## Common pitfalls

- **Missing `clone()` on `AccountInfo`.** When stuffing accounts into an
  Anchor `Accounts` struct, you typically need `.clone()` because the struct
  takes ownership.
- **Slice length mismatch.** If your handler reads more accounts than you
  pass, it panics in `next_account_info`. Pick the array size to be at
  least as large as the largest handler in your rule set.
- **Forgetting to `.unwrap()` on the handler call.** Without `.unwrap()`,
  the rule trivially succeeds even when the handler errors out — a common
  source of vacuous "passing" rules. Always either `.unwrap()` or
  `cvlr_assume!(result.is_ok())` and assert on the post-state.
- **Sharing `AccountInfo`s across rules unintentionally.** Each `#[rule]`
  is a fresh universe; allocate accounts inside the rule, not in a `static`.

## What's next

- {ref}`solana_parametric_rules` — factor the snapshot pattern into reusable
  harnesses.
- {ref}`solana_methodology` — how to scope rules so the Prover actually
  closes them.
