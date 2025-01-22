# Using the Solana Certora Prover 

## Overview

This document provides a guide on how to use the Solana Certora
Prover. It details configuration formats, the build process, and how
to execute verification locally and remotely.


## Project Structure

A typical Solana project integrated with the Solana Certora Prover includes:

- A Solana smart contract written in Rust.

- Configurations for running the Certora Prover in modes: running from
  sources and verifying pre-built contracts.
 
- An executable build script or command for compiling the project and
  preparing it for verification.

## Configuration Formats

### Verifying Pre-Built Contracts

This configuration mode explicitly specifies the pre-built files required for verification:

```json
{
    "files": [
        "solana_contract.so"
    ],
    "process": "sbf",
    "optimistic_loop": false,
    "rule": "rule_solvency"
}
```

### Running from Sources

This configuration mode uses a `build_script` or executable command for dynamic project building and eliminates hardcoded file paths:

```json
{
    "build_script": "./certora_build.py",
    "solana_inlining": "../../cvt_inlining.txt",
    "solana_summaries": "../../cvt_summaries.txt",
    "cargo_features": "<feature1> <feature2> <feature3>",
    "process": "sbf",
    "optimistic_loop": false,
    "rule": "rule_solvency"
}
```

**Key Differences:**

- **Verifying Pre-Built Contracts**: Uses pre-compiled `.so` files for verification.

- **Running from Sources**: Automates the build process through the
  `certora_build.py` script or another executable
  command. See [here](scripts/certora_build.py) for an example of such a script. 

## Execution Examples

### Running from Sources

To run the Certora Prover using the "running from sources" configuration:

```bash
certoraSolanaProver sources_config.conf
```

**Expected Output:**

```
INFO: Building from script ./certora_build.py
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

## Building the Project

### Using the Build Script or Command

The `certora_build.py` script or an equivalent executable command handles project compilation and prepares it for verification. Execute it as follows:

```bash
python3 certora_build.py
```

This ensures the `.so` file is up-to-date and ready for verification.

### Build Script or Command Inputs and Outputs

The script or command connects the project to the Certora Prover by:
1. Compiling the project.
2. Returning a JSON object with project details.
3. Handling build failures appropriately.

#### Inputs

- `-o/--output`: Specifies the output JSON file path.
- `--json`: Dumps JSON to the console.
- `-l/--log`: Displays build logs.
- `-v/--verbose`: Enables verbose mode.

#### Outputs

**Using `--json`**
Prints a JSON structure to `stdout`:

```json
{
    "project_directory": "<path>",
    "sources": ["src/**/*.rs", "Cargo.toml"],
    "executables": "target/release/solana_contract.so",
    "success": true,
    "return_code": 0,
    "log": {
        "stdout": "path/to/stdout",
        "stderr": "path/to/stderr"
    }
}
```

**Using `--output`**
Saves the JSON structure to the file specified by the `--output` flag.

**Without `--json` or `--output`**
Returns `0` if the build is successful and `1` otherwise.

