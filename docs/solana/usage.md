(solana_usage)=
# Using the Certora Solana Prover

## Overview

This page is a guide to using the Certora Solana Prover. It covers wiring
CVLR into a Cargo workspace, the configuration formats accepted by the
Prover, and how to execute verification locally and remotely.

A typical Solana project integrated with the Certora Solana Prover includes:

- A Solana smart contract written in Rust.

- Configurations for running the Certora Prover: the Prover can be executed
  either by starting from source files or by verifying pre-compiled code.

The [Certora Solana Examples](https://github.com/Certora/SolanaExamples)
repository contains a collection of example projects.

(solana_project_setup)=
## Project Setup

This section covers how to wire CVLR into a Cargo workspace so that the
Certora Solana Prover can build and verify your program. The remainder of
the page focuses on the run-time configuration.

This guide targets **`cvlr ≥ 0.6`** and **`cvlr-solana ≥ 0.5`**, the current
crates.io releases. Most code on the page works on `cvlr ≥ 0.4`; features
flagged with a "since 0.5" / "since 0.6" note (the `cvlr::derive` macros
and the `cvlr::spec` layer) require the corresponding minimum.

| Crate          | Minimum version | Source                                                                            |
| -------------- | --------------- | --------------------------------------------------------------------------------- |
| `cvlr`         | `0.6`           | crates.io or `git+https://github.com/Certora/cvlr.git`                            |
| `cvlr-solana`  | `0.5`           | crates.io or `git+https://github.com/Certora/cvlr-solana.git`                     |
| `cvlr-vectors` | `0.4`           | crates.io (only needed for bounded-`Vec` macros, see {ref}`solana_nondet_vectors`) |

```{tip}
**Quick start.** Most projects should bootstrap from the
[Certora Solana spec template](https://github.com/Certora/solana-spec-template)
rather than wire everything by hand. Clone it into your contract's source
directory as `certora/` and run `python certora-setup.py`. The template
ships with the recommended `run.conf`, the baseline `cvlr_inlining*.txt`
and `cvlr_summaries*.txt` environment files (Rust/Solana stdlib, Anchor),
and a `justfile` for common tasks. The rest of this section documents the
layout and contents the template produces, so you can read or modify
them with confidence.
```

### Workspace `Cargo.toml`

```toml
[workspace.dependencies]
cvlr         = "0.6"
cvlr-solana  = "0.5"
cvlr-vectors = "0.4"   # optional: only if you use bounded vectors
```

If you need the development branch instead of crates.io:

```toml
[workspace.dependencies]
cvlr        = { git = "https://github.com/Certora/cvlr.git" }
cvlr-solana = { git = "https://github.com/Certora/cvlr-solana.git" }
```

### Per-program `Cargo.toml`

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
it the Prover) which files to submit to a cloud job and where to
find inlining / summaries.

The `sources` glob lists the files that are uploaded to the Certora cloud
**alongside the compiled binary**. They power the *Jump to Source* feature
in the rule report: clicking an entry in a counterexample's call trace
opens the originating Rust source. Without `sources`, Jump to Source is
disabled, but verification itself still runs.

```{warning}
**Source-code leakage risk.** Files listed in `sources` are uploaded to
the Certora cloud and persisted there. **By default, Certora reports
are private to the user submitting the jobs. If the user however decides
to shared the URL _publicly_ via the "Copy Link", the source files are exposed**
 — anyone with the URL can browse the code in the report's source viewer. If your
program is closed-source, treat report URLs as containing the source.
Two practical consequences:

- **Trim `sources` to the minimum** needed for your verification job —
  not your whole repository. A workspace-wide glob (`../**/*.rs`)
  uploads more than you probably want.
- **Audit before going public.** Before making a Certora report public
  PR, blog post, or chat, decide whether the linked source is OK to
  publish. If not, keep the URL private or run verification with a 
  narrower `sources` set.
```

`cvlr_inlining.txt` and `cvlr_summaries.txt` are **required** environment
files: they tell the Prover which Rust / Solana standard-library functions
to inline. Start from the
[spec template's set](https://github.com/Certora/solana-spec-template/tree/main/envs)
— it covers the core stdlib, anchor, and a place to drop project-specific
entries — rather than from empty files. With these defaults, for instance, `solana_program::account_info::lamports` is inlined, while `rust_alloc` and `rust_dealloc` are not. The summaries file describes points-to summaries for important functions; as an example, the defaults summarize the impact of `solana_pubkey::Pubkey::create_program_address`. See {ref}`--solana_inlining` and
{ref}`--solana_summaries` for the CLI flags.

### Wire the `certora` module into your crate



### Recommended directory layout

```
my_program/
├── Cargo.toml
└── src/
    ├── lib.rs                ← #[cfg(feature = "certora")] pub mod certora;
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
            ├── base.rs       ← parametric harnesses (`base_<handler>` fns)
            └── solvency/
                ├── preds.rs  ← `#[cvlr::predicate]` definitions
                └── solvency.rs   ← `cvlr_rules! { … }` block per property
```

This is the layout produced by the spec-template setup script. Ensure that the attributes in `[package.metadata.certora]` point to the right path.

This layout is a convention, not a requirement, but the rest of this guide assumes it. We recommend following this structure.

- In `lib.rs` (or `src/lib.rs`), add:

```rust
#[cfg(feature = "certora")]
pub mod certora;
```

When the `certora` feature is off (production builds), nothing in `src/certora/` is
compiled, no cvlr code is linked, and your binary is unchanged.

- `nondet.rs` — only `Nondet` derives / impls, nothing else.
- `mocks/foo.rs` — only mock implementations, mirroring `src/foo.rs`.
- `specs/<topic>/<topic>.rs` — only `#[rule]` functions and the
  `cvlr_rules!` blocks that emit them; the predicates they reference live
  in `specs/<topic>/preds.rs` (see {ref}`solana_spec` and
  {ref}`solana_parametric_rules`).

## Configuration Formats

### Running from Sources

This configuration mode calls `cargo certora-sbf` for building the project.
A minimal conf file looks like:

```json
{
    "msg": "Message describing the rule",
    "rule": "rule_solvency",
    "optimistic_loop": false,
    "loop_iter": 3
}
```

The `sources`, `solana_inlining`, and `solana_summaries` entries are read
from `[package.metadata.certora]` in the project's `Cargo.toml`
(see {ref}`solana_project_setup`).

#### The default `run.conf`

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
}
```

Use this as `confs/run.conf` and override `rule` / `msg` per invocation, or
extend it with per-rule files (e.g. `deposit.conf` with `"files":
["run.conf"]` and a specific `rule` list). Add `"rule_sanity": "basic"`
when you want vacuity checks on every rule (recommended — see
{ref}`solana-sanity-vacuity`).

See {ref}`solana_methodology` for guidance on per-rule conf hygiene and
when each `prover_arg` is worth tuning.

### Verifying Pre-Built Contracts

This configuration mode explicitly specifies the pre-built files required for verification:

```json
{
    "files": [
        "solana_contract.so"
    ],
    "solana_inlining": "../../cvt_inlining.txt",
    "solana_summaries": "../../cvt_summaries.txt",
    "process": "sbf",
    "optimistic_loop": false,
    "rule": "rule_solvency"
}
```

**Key Differences:**

- **Verifying Pre-Built Contracts**: Uses pre-compiled `.so` files for verification.

- **Running from Sources**: Builds the project by calling `cargo certora-sbf`.
  Furthermore, fetches the metadata for the Prover from the `Cargo.toml` file.

## Execution Examples

### Running from Sources

To run the Certora Prover using the "running from sources" configuration:

```bash
certoraSolanaProver sources_config.conf
```

Or, with the spec-template layout, from the program directory:

```sh
certoraSolanaProver src/certora/confs/run.conf --rule rule_my_first_property
```

**Expected Output:**

```
INFO: Building by calling ['cargo', 'certora-sbf', '--json']
Connecting to server...
Job submitted to server.
Manage your jobs at <https://prover.certora.com>.
Follow your job and see verification results at <https://prover.certora.com/output/{job_id}/{unique_key}>.
```

### Verifying Pre-Built Contracts

To run the Certora Prover using the "verifying pre-built contracts" configuration:

```bash
certoraSolanaProver prebuilt_config.conf
```

**Expected Output:**

```
Connecting to server...
Job submitted to server.
Manage your jobs at <https://prover.certora.com>.
Follow your job and see verification results at <https://prover.certora.com/output/{job_id}/{unique_key}>.
```

## Building Projects

The `cargo certora-sbf` command compiles the project and prepares it for
verification, passing all the relevant metadata to the Prover. Building
with the `certora` feature is handled automatically. The metadata is read
from the `[package.metadata.certora]` section of the project's `Cargo.toml`
(see {ref}`solana_project_setup` for the canonical block).

The command `cargo certora-sbf` offers various CLI options.
For instance, the `--json` option will print the result of the compilation in
JSON format.
To see the complete list of command line options for `cargo certora-sbf` run
`cargo certora-sbf --help`.

## What's next

- {ref}`speclanguage` — the CVLR primitives.
- {ref}`solana_methodology` — practical guidelines for organizing specs.
