(solana_nondet)=
# Nondet & Havoc

Verification reasons about *all* possible inputs and *all* possible starting
states. To get there, you replace concrete values with non-deterministic
("havoced") ones using `nondet()`. This page covers every variant beyond
primitives.

For the basic concept of nondeterministic values and the `nondet::<T>()`
function on primitive types, see the {ref}`speclanguage` page.

## The `Nondet` trait

For your own types, implement `cvlr::nondet::Nondet`:

```rust
use cvlr::nondet::Nondet;
use cvlr::prelude::*;

#[derive(Clone, Copy)]
pub struct Vault {
    pub tokens:  u64,
    pub shares:  u64,
    pub paused:  bool,
}

impl Nondet for Vault {
    fn nondet() -> Self {
        Vault {
            tokens: nondet(),
            shares: nondet(),
            paused: nondet(),
        }
    }
}

// Now you can write:
let v: Vault = nondet();
```

The trait composes recursively. As long as every field has a `Nondet` impl,
you can mechanically derive yours. Project convention is to keep all
`impl Nondet for …` blocks together in `src/certora/nondet.rs`.

## Havocing enums

Enums need a `match` over a nondet discriminant:

```rust
use cvlr::nondet::Nondet;
use cvlr::prelude::*;

pub enum Status {
    Active,
    Paused,
    Closed,
}

impl Nondet for Status {
    fn nondet() -> Self {
        match nondet::<u8>() % 3 {
            0 => Status::Active,
            1 => Status::Paused,
            _ => Status::Closed,
        }
    }
}
```

A `% N` keeps the discriminant in range without an extra `assume`. For enums
where the Prover should be told exactly which variants are valid, use a
fallthrough that panics — the panic acts as a soft assume:

```rust
impl Nondet for Status {
    fn nondet() -> Self {
        match nondet::<u8>() {
            0 => Status::Active,
            1 => Status::Paused,
            2 => Status::Closed,
            _ => panic!(),       // unreachable in any meaningful execution
        }
    }
}
```

For bitflags or types with sparse valid encodings, list each valid value
explicitly in the match.

## Havocing `Pubkey` and `Option<Pubkey>`

`cvlr-solana` provides Solana-aware nondet helpers:

```rust
use cvlr_solana::{cvlr_nondet_pubkey, cvlr_nondet_option_pubkey};
use solana_program::pubkey::Pubkey;

let key: Pubkey                = cvlr_nondet_pubkey();
let maybe_key: Option<Pubkey>  = cvlr_nondet_option_pubkey();
```

Use `cvlr_nondet_pubkey()` rather than `nondet::<Pubkey>()` so that the Prover
treats it as an opaque 32-byte identifier rather than havocing 32 individual
bytes (the latter is slower and gives the Prover more rope to hang itself
with).

## `alloc_ref_havoced` and `alloc_mut_ref_havoced`

Some Solana code passes around `&'static T` or `&'static mut T` references —
typically because the data lives in account memory. To produce a havoced
reference of that flavor, use the helpers in `cvlr::nondet::havoc`:

```rust
use cvlr::nondet::havoc::{alloc_ref_havoced, alloc_mut_ref_havoced};

let pool:    &'static     Pool    = alloc_ref_havoced::<Pool>();
let config:  &'static mut Config  = alloc_mut_ref_havoced::<Config>();
```

What this gives you:

- A reference of the right lifetime, which can be passed straight into
  handlers that expect `&'static (mut) T`.
- The pointed-to memory is havoced — every field is independently nondet.

When to use which:

| You want                                         | Use                            |
| ------------------------------------------------ | ------------------------------ |
| A nondet *value* of `T`                          | `let t: T = nondet();`         |
| A nondet *reference* `&T` (read-only borrow)     | `alloc_ref_havoced::<T>()`     |
| A nondet *mutable reference* `&mut T`            | `alloc_mut_ref_havoced::<T>()` |

If the type is small (a few words) and your handler takes it by value or by
short-lived reference, prefer plain `nondet()` and pass `&v` / `&mut v`. Use
`alloc_*` only when the handler signature genuinely demands a `'static`
reference.

## Bounding nondet values

Pure havoc is often too wide. You usually want to restrict to "valid" states
with `cvlr_assume!`:

```rust
let mut vault: Vault = nondet();
cvlr_assume!(vault.shares <= vault.tokens);     // protocol invariant
cvlr_assume!(!vault.paused);                    // we're proving the active path
```

Patterns like the above scale poorly when repeated across every rule. Factor
them into a property struct's `assume_pre()` method — see
{ref}`solana_parametric_rules`.

(solana_nondet_vectors)=
## Bounded vectors

`Vec<T>` is unbounded by default, which makes most properties undecidable. To
verify code that takes a `Vec<T>`, use the **bounded vector** macros from
`cvlr-vectors`:

```rust
use cvlr_vectors::cvt_no_resizable_vec;
use cvlr::nondet::Nondet;

// A Vec<u64> of capacity 10, populated with two nondet elements.
let v: Vec<u64> = cvt_no_resizable_vec!([nondet::<u64>(), nondet::<u64>()]; 10);

// An empty Vec<Pubkey> with capacity reserved for 16 elements.
let v: Vec<Pubkey> = cvt_no_resizable_vec!([]; 16);
```

The capacity is a fixed compile-time bound. The Prover unrolls loops up to
that bound, so keep it as small as your spec actually needs (often 4 or 8).

```{tip}
**Capacity choice.** The Prover unrolls every loop over a bounded vector up
to the capacity. A capacity of 4 is often enough; 10 is a comfortable
default; 16 is reasonable for "list of accounts" cases. Don't pick 100 —
verification will time out.
```

For projects where you'll havoc many `Vec<T>`s of the same element type, wrap
the macro in your own helper and use it consistently:

```rust
#[macro_export]
macro_rules! my_vec_cap10 {
    ($items:tt) => { cvlr_vectors::cvt_no_resizable_vec!($items; 10) };
}
```

## `nondet()` is not a no-op

A common pitfall: assuming `nondet()` produces a "zero" or "default" value.
It produces *any* value. If the rest of your code relies on something that
`Default::default()` would have given you (e.g. an enum starting in some
state), you must `cvlr_assume!` that explicitly:

```rust
let mut vault: Vault = nondet();
cvlr_assume!(vault.shares == 0);     // start from a freshly initialised vault
cvlr_assume!(vault.tokens == 0);
```

If you find yourself writing many such assumes for the same starting state,
factor them into a constructor function:

```rust
fn fresh_vault() -> Vault {
    let mut v: Vault = nondet();
    cvlr_assume!(v.shares == 0);
    cvlr_assume!(v.tokens == 0);
    v
}
```

## What's next

- {ref}`solana_mocks` — when nondet isn't enough and you need to swap whole
  functions.
- {ref}`solana_accounts` — havocing `AccountInfo` arrays for handler harnesses.
- {ref}`solana_parametric_rules` — sharing pre-state setup across many rules.
