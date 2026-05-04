(solana_project_setup)=
# Project Setup

How to wire CVLR into a Cargo workspace so that the Certora Solana Prover can
build and verify your program. This page complements
{ref}`solana_usage`, which focuses on the run-time configuration. Here we
focus on the source tree.

This page targets **`cvlr ≥ 0.4`** and **`cvlr-solana ≥ 0.4.3`**, the current
crates.io releases of the 0.4 line.

| Crate          | Current version | Source                                                                            |
| -------------- | --------------- | --------------------------------------------------------------------------------- |
| `cvlr`         | `0.4` (≥ 0.4.0) | crates.io or `git+https://github.com/Certora/cvlr.git` (branch `v0.4`)            |
| `cvlr-solana`  | `0.4` (≥ 0.4.3) | crates.io or `git+https://github.com/Certora/cvlr-solana.git` (branch `v0.4`)     |
| `cvlr-vectors` | `0.4`           | crates.io (only needed for bounded-`Vec` macros, see {ref}`solana_nondet_vectors`) |

## 1. Workspace `Cargo.toml`

```toml
[workspace.dependencies]
cvlr         = "0.4"
cvlr-solana  = "0.4"
cvlr-vectors = "0.4"   # optional: only if you use bounded vectors
```

If you need the bleeding-edge branch instead of crates.io:

```toml
[workspace.dependencies]
cvlr        = { git = "https://github.com/Certora/cvlr.git",        branch = "v0.4" }
cvlr-solana = { git = "https://github.com/Certora/cvlr-solana.git", branch = "v0.4" }
```

## 2. Per-program `Cargo.toml`

The verification crates are **optional** — they are only pulled in when you
build with the `certora` feature. This keeps them out of your production
binary.

```toml
[features]
default       = []
no-entrypoint = []
certora       = ["no-entrypoint", "dep:cvlr", "dep:cvlr-solana"]

[dependencies]
cvlr        = { workspace = true, optional = true }
cvlr-solana = { workspace = true, optional = true }
# cvlr-vectors = { workspace = true, optional = true }   # if needed

[package.metadata.certora]
sources = [
    "Cargo.toml",
    "src/**/*.rs",
]
solana_inlining  = ["certora/summaries/cvlr_inlining_core.txt"]
solana_summaries = ["certora/summaries/cvlr_summaries_core.txt"]
```

The `[package.metadata.certora]` block tells `cargo certora-sbf` (and through
it the Prover) which files to ship to the verification cloud and where to
find any inlining / summary hints. Keep `sources` tight — extra files slow
compilation. If you have a multi-crate workspace, list only the crates this
verification job actually touches.

`solana_inlining.txt` and `solana_summaries.txt` are environment files used to
fine-tune which functions the Prover inlines and which it summarises. Start
without them; add entries only when a specific rule demands it. See
{ref}`--solana_inlining` and {ref}`--solana_summaries` for details.

## 3. Wire the `certora` module into your crate

In `lib.rs` (or `src/lib.rs`):

```rust
#[cfg(feature = "certora")]
pub mod certora;
```

When the feature is off (production builds), nothing in `src/certora/` is
compiled, no cvlr code is linked, and your binary is unchanged.

## 4. Recommended directory layout

```
my_program/
├── Cargo.toml
├── certora/                  ← run configs and environment files
│   ├── conf/
│   │   ├── base.conf         ← shared prover_args
│   │   └── deposit.conf      ← per-rule conf, inherits from base
│   └── summaries/
│       ├── cvlr_inlining_core.txt
│       └── cvlr_summaries_core.txt
└── src/
    ├── lib.rs                ← `#[cfg(feature = "certora")] pub mod certora;`
    ├── processor.rs          ← real handlers (deposit, withdraw, …)
    ├── state.rs              ← real state types (Vault, …)
    └── certora/
        ├── mod.rs            ← module declarations
        ├── nondet.rs         ← `impl Nondet for …` for project types
        ├── hooks.rs          ← static flags + hook helpers
        ├── log.rs            ← `msg!` stub + `CvlrLog` impls
        ├── mocks/            ← mirrors src/ tree, replaces heavy fns
        │   └── …
        └── specs/
            ├── mod.rs
            ├── base.rs       ← parametric harnesses (CvlrProp trait)
            └── solvency/
                ├── props.rs  ← `impl CvlrProp for SolvencyInvariant`
                └── solvency.rs   ← one `#[rule]` per (handler × property)
```

This layout is a convention, not a requirement, but the rest of this guide
assumes it. The intent is that each file has a predictable shape:

- `nondet.rs` — only `impl Nondet`s, nothing else.
- `mocks/foo.rs` — only mock implementations, mirroring `src/foo.rs`.
- `specs/<topic>/<topic>.rs` — only `#[rule]` functions, one or two lines
  each.
- `specs/<topic>/props.rs` — only `CvlrProp` impls.

When something doesn't fit any of those buckets, that is a signal that you're
probably solving a different problem than you think you are.

## 5. A minimal `Default.conf`

Create `certora/conf/Default.conf` next to your program:

```json
{
    "msg": "rule_my_first_property",
    "rule": ["rule_my_first_property"],
    "rule_sanity": "basic",
    "optimistic_loop": false,
    "loop_iter": 3,
    "prover_args": [
        "-solanaOptimisticJoin true",
        "-solanaOptimisticOverlaps true",
        "-solanaOptimisticMemcpyPromotion true",
        "-solanaOptimisticMemcmp true",
        "-solanaOptimisticNoMemmove true"
    ]
}
```

Run it from the program directory:

```sh
cd certora/conf
certoraSolanaProver Default.conf
```

The Prover invokes `cargo certora-sbf` to build the project. Building with
the `certora` feature is handled automatically. Results are posted to the
Certora cloud; the URL is printed on the terminal.

For larger projects, split the conf into a shared `base.conf` and per-rule
files that inherit from it. See {ref}`solana_methodology` for guidelines on
conf hygiene and recommended `prover_args`.

## What's next

- {ref}`solana_usage` — running the Prover from the command line.
- {ref}`speclanguage` — the CVLR primitives.
- {ref}`solana_methodology` — practical guidelines for organising specs.
