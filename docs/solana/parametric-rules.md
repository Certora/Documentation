(solana_parametric_rules)=
# Parametric Rules & Macros

Specs with more than one or two rules accumulate duplicated boilerplate:
each rule reads the same accounts, calls the same handler, snapshots
state, and asserts a property. This page covers the two techniques that
scale rule count without the duplication: the **`cvlr-spec` layer**
(`cvlr_spec!` + `cvlr_rules!`) and **`macro_rules!` for environment
generation**.

## Why factor at all?

A vault with two handlers (`deposit`, `withdraw`) and three properties
(`solvency`, `monotonicity`, `no_dilution`) requires 6 rules. A
production protocol with 10+ handlers and a similar number of properties
produces 100+ near-identical rules. A well-defined project structure for
verification is required.

The two patterns below are recommended spec organisation practices. **Use
the spec layer when the harness is uniform across properties; reach for
macros when the setup itself differs per rule.**

## Pattern 1 — `cvlr-spec` and `cvlr_rules!`

The `cvlr-spec` crate (shipped with `cvlr ≥ 0.6`) provides the building
blocks: `CvlrFormula` for predicates, `CvlrSpec` for `(requires, ensures)`
pairs, and `cvlr_rules!` to instantiate them across many handler harnesses.
The full primitive reference lives in {ref}`solana_spec`, and the
end-to-end Vault example there shows what a finished spec looks like.
This page covers the parts that the spec page doesn't: how the
`base_<handler>` harness is shaped, how the project-local glue macro
hooks `cvlr_rules!` into your `#[rule]`s, and how the same pattern
extends to handlers that take `&[AccountInfo]`.

### The `base_<handler>` shape

Each base harness is generic over `S: CvlrSpec`. It havocs a pre-state,
calls `spec.assume_requires(&pre)`, runs the handler with nondet
arguments, snapshots the post-state, and calls
`spec.check_ensures(&post, &pre)`:

```rust
//! src/certora/specs/base.rs

use cvlr::prelude::*;
use cvlr::spec::CvlrSpec;
use crate::state::Vault;
use crate::operations::{vault_deposit, vault_withdraw};

#[inline(always)]
pub fn base_deposit<S>(spec: &S)
where
    S: CvlrSpec<Context = Vault>,
{
    let mut v: Vault = nondet();
    let pre = v;
    spec.assume_requires(&pre);

    let amount: u64 = nondet();
    vault_deposit(&mut v, amount).unwrap();

    clog!(pre, v);
    spec.check_ensures(&v, &pre);
}

#[inline(always)]
pub fn base_withdraw<S>(spec: &S)
where
    S: CvlrSpec<Context = Vault>,
{
    let mut v: Vault = nondet();
    let pre = v;
    spec.assume_requires(&pre);

    let amount: u64 = nondet();
    vault_withdraw(&mut v, amount).unwrap();

    clog!(pre, v);
    spec.check_ensures(&v, &pre);
}
```

For these to compile, `Vault` needs `Nondet`, `CvlrLog`, and `Copy` —
derive the first two with `cvlr::derive::Nondet` and
`cvlr::derive::CvlrLog`.

### The project-local glue macro

`cvlr_rules!` expands to one `cvlr_rule_for_spec!` per base, which calls a
project-supplied macro `cvlr_impl_rule!`. That macro is where you
control how a `(rule_name, spec, base)` triple becomes a `#[rule]`. A
minimal version:

```rust
//! src/certora/specs/glue.rs

#[macro_export]
macro_rules! cvlr_impl_rule {
    ($rule_name:ident, $spec:expr, $base:ident) => {
        #[rule]
        pub fn $rule_name() {
            $base(&$spec);
        }
    };
}
```

The spec template ships a default `cvlr_impl_rule!`; copy or import it.
With the glue in place, the `cvlr_rules!` block (see
{ref}`solana_spec`) generates one `#[rule]` per base function in the
list.

### When the harness reads from accounts

Real Solana handlers don't take a value-typed `Vault` — they take a
`&[AccountInfo]`. The spec layer still applies; the predicate's context
is a value-only *view* of the account state, and the base harness reads
it from the account before and after the handler runs:

```rust
#[derive(cvlr::derive::Nondet, cvlr::derive::CvlrLog, Clone, Copy)]
pub struct VaultView { tokens: u64, shares: u64 }

impl<'a> From<&AccountInfo<'a>> for VaultView { /* … */ }

#[predicate]
fn vv_solvent(v: &VaultView) {
    v.shares <= v.tokens;
}

#[inline(always)]
pub fn base_deposit_accounts<S>(spec: &S)
where
    S: CvlrSpec<Context = VaultView>,
{
    let acc_infos: [AccountInfo; 8] = cvlr_deserialize_nondet_accounts();
    let vault_info = &acc_infos[0];

    let pre: VaultView = vault_info.into();
    spec.assume_requires(&pre);

    let amount: u64 = nondet();
    process_deposit(&acc_infos, amount).unwrap();

    let post: VaultView = vault_info.into();
    clog!(pre, post);
    spec.check_ensures(&post, &pre);
}
```

The same `cvlr_rules!` block then drives this base harness — the spec
doesn't need to know whether the pre-state came from a havoced value or
a havoced account.

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

## Hooks for invariant tracking

A complementary pattern: when an invariant must be *checked at runtime*
inside the handler (not just before/after), use a hook to record that
the check ran. The mechanism — an `unsafe static` flag flipped by a
`cvlr_hook_on_exit` on the runtime check function — is documented as
Pattern D in {ref}`solana_mocks`. Reuse it directly:

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

This catches refactors that accidentally remove an invariant check from
a handler.

## When to choose which

| Situation                                                        | Use                              |
| ---------------------------------------------------------------- | -------------------------------- |
| Many properties × many handlers, uniform setup                   | `cvlr_spec!` + `cvlr_rules!`     |
| Same invariant pre/post across many handlers                     | `cvlr_invar_spec!` + `cvlr_invariant_rules!` |
| Different rules need different starting states                   | `macro_rules!` for setup          |
| Multi-step state-machine exploration (sequence of handler calls) | `macro_rules!` chains             |
| Bounded `Vec<T>` of varying element types                        | `nondet_vec_of!` + `cvlr-vectors` |
| Verifying that a runtime check actually runs                     | `cvlr_hook_on_exit` + static flag |

The two patterns compose cleanly: a `base_<handler>` harness can call into
setup macros, and a predicate's body can read hook-flag state via plain
function calls.

## What's next

- {ref}`solana_spec` — full reference for `CvlrFormula`, predicates,
  lemmas, and the spec macros used in Pattern 1.
- {ref}`solana_methodology` — practical guidelines for writing rules that
  actually verify, not just compile.
