(solana_usage)=
# Using the Solana Certora Prover 

## Overview

This document provides a guide on how to use the Solana Certora
Prover. It details configuration formats, the build process, and how
to execute verification locally and remotely.


## Project Structure

A typical Solana project integrated with the Solana Certora Prover includes:

- A Solana smart contract written in Rust.

- Configurations for running the Certora Prover: the Prover can be executed
  either by starting from source files or by verifying pre-compiled code.

The [Certora Solana Examples](https://github.com/Certora/SolanaExamples)
repository contains a collection of example projects.

## Configuration Formats

### Running from Sources

This configuration mode calls `cargo certora-sbf` for building the project.

```json
{
    "msg": "Message describing the rule",
    "rule": "rule_solvency",
    "optimistic_loop": false,
    "loop_iter": 3
}
```

Information relevant for Certora is fetched from the `Cargo.toml` file in the
`package.metadata.certora` section:

```toml
# Rest of the Cargo.toml file to build the project.
# ...

[package.metadata.certora]
sources = [
    "Cargo.toml",
    "src/**/*.rs"
]
solana_inlining = ["certora/summaries/cvlr_inlining_core.txt"]
solana_summaries = ["certora/summaries/cvlr_summaries_core.txt"]
```

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
verification, passing all the relevant metadata to the Prover.
Some additional information has to be specified by the user in the `Cargo.toml`
file in the `[package.metadata.certora]` section.
For instance, the list of source files that have to be uploaded can be specified as
follows:
```toml
sources = [
    "Cargo.toml",
    "src/**/*.rs"
]
```
For a complete example, see
[Cargo.toml](https://github.com/Certora/SolanaExamples/blob/main/cvlr_by_example/first_example/Cargo.toml)
in the `SolanaExamples` repository.

The command `cargo certora-sbf` offers various CLI options.
For instance, the `--json` option will print the result of the compilation in
JSON format.
To see the complete list of command line options for `cargo certora-sbf` run
`cargo certora-sbf --help`.

