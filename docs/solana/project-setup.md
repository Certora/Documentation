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

```{tip}
**Quick start.** Most projects should bootstrap from the
[Certora Solana spec template](https://github.com/Certora/solana-spec-template)
rather than wire everything by hand. Clone it into your contract's source
directory as `certora/` and run `python certora-setup.py`. The template
ships with the recommended `run.conf`, the baseline `cvlr_inlining*.txt`
and `cvlr_summaries*.txt` environment files (Rust/Solana stdlib, Anchor),
and a `justfile` for common tasks. The rest of this page documents the
layout and contents the template produces, so you can read or modify
them with confidence.
```

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
sources          = ["src/**/*.rs"]
solana_inlining  = ["src/certora/envs/cvlr_inlining.txt"]
solana_summaries = ["src/certora/envs/cvlr_summaries.txt"]
```

The `[package.metadata.certora]` block tells `cargo certora-sbf` (and through
it the Prover) which files to ship to the verification cloud and where to
find inlining / summaries. Keep `sources` tight — extra files slow
compilation. If you have a multi-crate workspace, list only the crates this
verification job actually touches.

`cvlr_inlining.txt` and `cvlr_summaries.txt` are **required** environment
files: they tell the Prover which Rust / Solana standard-library functions
to inline (`memcpy`, `Pubkey::find_program_address`, allocator routines,
…) and which to summarise (`AccountInfo` field offsets, `CVT_nondet_*`
helpers, …). Without them, verification of any non-trivial program will
fail. Start from the
[spec template's set](https://github.com/Certora/solana-spec-template/tree/main/envs)
— it covers the core stdlib, anchor, and a place to drop project-specific
entries — rather than from empty files. See {ref}`--solana_inlining` and
{ref}`--solana_summaries` for the CLI flags.

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
└── src/
    ├── lib.rs                ← `#[cfg(feature = "certora")] pub mod certora;`
    ├── processor.rs          ← real handlers (deposit, withdraw, …)
    ├── state.rs              ← real state types (Vault, …)
    └── certora/
        ├── mod.rs            ← module declarations
        ├── nondet.rs         ← `impl Nondet for …` for project types
        ├── hooks.rs          ← static flags + hook helpers
        ├── log.rs            ← `msg!` stub + `CvlrLog` impls
        ├── confs/            ← run configs (.conf files)
        │   ├── run.conf      ← default conf shipped by the template
        │   └── deposit.conf  ← per-rule confs that extend run.conf
        ├── envs/             ← inlining and summaries environment files
        │   ├── cvlr_inlining.txt
        │   └── cvlr_summaries.txt
        ├── mocks/            ← mirrors src/ tree, replaces heavy fns
        │   └── …
        └── specs/
            ├── mod.rs
            ├── base.rs       ← parametric harnesses (CvlrProp trait)
            └── solvency/
                ├── props.rs  ← `impl CvlrProp for SolvencyInvariant`
                └── solvency.rs   ← one `#[rule]` per (handler × property)
```

This is the layout produced by the spec-template setup script. Older
projects sometimes keep `confs/` and the env files at the project root
(`<crate>/certora/conf/` and `<crate>/certora/summaries/`) instead of
under `src/certora/`; both are supported, and the path you put in
`[package.metadata.certora]` is the source of truth.

This layout is a convention, not a requirement, but the rest of this guide
assumes it. The intent is that each file has a predictable shape:

- `nondet.rs` — only `impl Nondet`s, nothing else.
- `mocks/foo.rs` — only mock implementations, mirroring `src/foo.rs`.
- `specs/<topic>/<topic>.rs` — only `#[rule]` functions, one or two lines
  each.
- `specs/<topic>/props.rs` — only `CvlrProp` impls.

When something doesn't fit any of those buckets, that is a signal that you're
probably solving a different problem than you think you are.

## 5. The default `run.conf`

The spec template ships the following
[`run.conf`](https://github.com/Certora/solana-spec-template/blob/main/confs/run.conf)
as the recommended starting point:

```json
{
    "msg":                  "Certora Verification Rules",
    "loop_iter":            1,
    "optimistic_loop":      false,
    "smt_timeout":          6000,
    "cargo_tools_version":  "v1.43",
    "java_args": ["-Dlevel.sbf=info"],
    "prover_args": [
        "-unsatCoresForAllAsserts true",
        "-solanaSkipCallRegInst true",
        "-solanaTACOptimize 2",
        "-solanaStackSize 8192",
        "-solanaTACMathInt true"
    ]
}
```

Use this as `confs/run.conf` and override `rule` / `msg` per invocation, or
extend it with per-rule files (e.g. `deposit.conf` with `"files":
["run.conf"]` and a specific `rule` list). Add `"rule_sanity": "basic"`
when you want vacuity checks on every rule (recommended — see
{ref}`solana-sanity-vacuity`).

Run it from the program directory:

```sh
certoraSolanaProver src/certora/confs/run.conf --rule rule_my_first_property
```

The Prover invokes `cargo certora-sbf` to build the project. Building with
the `certora` feature is handled automatically. Results are posted to the
Certora cloud; the URL is printed on the terminal.

See {ref}`solana_methodology` for guidance on per-rule conf hygiene and
when each `prover_arg` is worth tuning.

## What's next

- {ref}`solana_usage` — running the Prover from the command line.
- {ref}`speclanguage` — the CVLR primitives.
- {ref}`solana_methodology` — practical guidelines for organising specs.
