# Solana-Specific Options / CLI Flags

This page documents Solana-specific Certora Prover options, which include CLI flags or ``prover_args`` flags.

The ``certoraSolanaProver`` utility invokes the Rust compiler and then sends the job to Certora's servers.

The most commonly used command is:

```bash
certoraSolanaProver --build_script <path_to_build_script>
```

If a precompiled execution is desired, the run command can skip the compilation step by executing:

```bash
certoraSolanaProver <path_to_binary_file>
```

A short summary of these options can be seen by invoking:
```bash
certoraSolanaProver --help
```

## Using Configuration (Conf) Files

For larger projects, the command line for running the Certora Prover can become large and cumbersome. It is therefore recommended to use configuration files instead.
These files are in [JSON5](https://json5.org/) format and use a ``.conf`` extension. They hold the parameters and options for the Prover.
For more details, see [Conf File](https://docs.certora.com/en/latest/docs/prover/cli/conf-file-api.html#conf-files).

## Modes of Operation

The Certora Solana Prover has two modes of operation, using a predefined build script, and passing precompiled binary directly.
These modes are mutually exclusive - you cannot run the tool with more than one mode at a time.

### --build_script

**What does it do?**

Specifies the location of the script that has to be called to compile the Rust project.
The build script should output 0 on success and 1 on failure unless it's being executed using the ``--json`` flag.
In this case, the build script should output the following:

- ``project_directory``: Path to the project root directory.
- ``sources``: List of source files or directories used or imported in the program. Source files should be relative to the ``project_directory`` with support of wildcards. All files declared in this list will be uploaded as sources to the cloud and displayed in the rule report. Source files are required, for instance, for the jump to source feature to work.
- ``executables``: List of compiled binary files, which are the target of the Rust program.
- ``success``: Boolean flag indicating if the build phase passed successfully.
- ``return_code``: The return code of the script.
- ``log``: Optionally provide paths to files for `stdout` and `stderr` of the build.
- ``solana_inlining``: List of paths to [inlining](#--solana_inlining) files for Solana contracts.
- ``solana_summaries``: List of paths to [summaries](#--solana_summaries) files for Solana contracts.

See an example of a [build script](https://github.com/Certora/SolanaExamples/blob/main/first_example/certora_build.py) and refer to the
[usage](./usage.md) section for more information about it.

**When to use it?**

Use this mode to prove properties on source code while providing an automatic compilation method. This is especially useful during development when files are modified frequently.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --rule rule_name
```

### precompiled binary

**What does it do?**

Runs formal verification of specified properties on a precompiled Rust project by providing a path to the binary target file.

**When to use it?**

Use this mode to prove properties on source code without recompiling the project for every execution. Ideal when files are stable and unchanged.

**Example**

```bash
certoraSolanaProver <path_to_binary_file> --rule rule_name
```

## Most Frequently Used Options

(--solana_inlining)=
### --solana_inlining

**What does it do?**

Provides the Prover with a list of paths to inlining files for Solana contracts.
These files are parsed and used to prove properties.
See an [example](https://github.com/Certora/SolanaExamples/blob/main/first_example/certora/inlining.txt).

**When to use it?**

This option is currently required for every project.
It can be provided to the Prover by passing this list as a flag or by retrieving it from the build script.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --solana_inlining <path_to_inlining_file>  --rule rule_name
```

(--solana_summaries)=
### --solana_summaries

**What does it do?**

Provides the Prover with a list of paths to summary files for Solana contracts.
These files are parsed and used to prove properties.
See an [example](https://github.com/Certora/SolanaExamples/blob/main/first_example/certora/summaries.txt).

**When to use it?**

This option is currently required for every project.
It can be provided to the Prover by passing this list as a flag or by retrieving it from the build script.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --solana_summaries <path_to_summaries_file> --rule rule_name
```

### --cargo_features

**What does it do?**

Provides the Prover with a whitespace-separated list of extra [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html) passed to the build script.
These features are then passed to ``cargo`` to build the project.

**When to use it?**

Use it when there is a need to enable a specific [Cargo feature](https://doc.rust-lang.org/cargo/reference/features.html) to compile the source code.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --cargo_features <feature_1> <feature_2> --rule rule_name
```

### --msg

**What does it do?**

Adds a description message to your run, similar to a commit message. This message appears on the Prover dashboard and in the rule report.
Note that you need to wrap your message in quotes if it contains spaces.

**When to use it?**

Adding a message makes it easier to track several runs. It is very useful if you are running many verifications simultaneously.
It is also helpful to keep track of a single file verification status over time, so we recommend always providing an informative message.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --msg 'Removed an assertion' --rule rule_name
```

### --rule

**What does it do?**

Formally verifies one or more specified rules.

**When to use it?**

This option is required to specify which rules the Prover should verify.

**Example**

If a Rust module includes the following:
```rust
#[rule]
fn rule_withdraw_succeeds() {
    ...
}

#[rule]
fn rule_withdraw_fails() {
    ...
}
```

To verify only `rule_withdraw_succeeds`, run:
```bash
certoraSolanaProver --build_script <path_to_build_script> --rule rule_withdraw_succeeds
```

To verify both `rule_withdraw_succeeds` and `rule_withdraw_fails`, run:
```bash
certoraSolanaProver --build_script <path_to_build_script> --rule rule_withdraw_succeeds rule_withdraw_fails
```
