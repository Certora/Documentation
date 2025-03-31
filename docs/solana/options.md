# Solana-Specific Options / CLI Flags

This page documents Solana-specific Certora Prover options, which include CLI flags or ``prover_args`` flags.

The ``certoraSolanaProver`` utility invokes the Rust compiler and then sends the job to Certora's servers.

The most commonly used command is:

```bash
certoraSolanaProver --build_script <path_to_build_script> --rule <rule_name>
```

If a precompiled execution is desired, the run command can skip the compilation step by executing:

```bash
certoraSolanaProver <path_to_binary_file> --rule <rule_name>
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

The Certora Solana Prover has two modes of operation, using a build script, or passing a precompiled binary directly.
These modes are mutually exclusive - you cannot run the tool with more than one mode at a time.
Both modes require the user to specify which rules must be verified by using the ``--rule`` option.

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
- ``log``: Optionally provided paths to files for `stdout` and `stderr` of the build logs.
- ``solana_inlining``: List of paths to [inlining](#--solana_inlining) files for Solana programs.
- ``solana_summaries``: List of paths to [summaries](#--solana_summaries) files for Solana programs.

See an example of a [build script](https://github.com/Certora/SolanaExamples/blob/main/cvlr_by_example/first_example/certora_build.py) and refer to the
[usage](./usage.md) section for more information about it.

**When to use it?**

Use this mode to prove properties on source code while providing an automatic compilation method. This is especially useful during development when files are modified frequently.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --rule <rule_name>
```

Note: If you want to skip compilation process and run on a precompiled Rust project it's possible to provide a path to the binary target file instead

```bash
certoraSolanaProver <path_to_binary_file> --rule <rule_name>
```

## Most Frequently Used Options

### --rule

**What does it do?**

Formally verifies one or more specified rules.

**When to use it?**

This option is always required to specify which rules the Prover should verify.

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

(--solana_inlining)=
### --solana_inlining

**What does it do?**

Provides the Prover with a list of paths to inlining files for Solana programs.
These files are parsed and used to prove properties.
See an [example](https://github.com/Certora/SolanaExamples/blob/main/cvlr_by_example/first_example/certora/inlining.txt).

**When to use it?**

This option is currently required for every project.
It can be provided to the Prover by passing this list as a flag or by retrieving it from the build script.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --solana_inlining <path_to_inlining_file>  --rule <rule_name>
```

(--solana_summaries)=
### --solana_summaries

**What does it do?**

Provides the Prover with a list of paths to summary files for Solana contracts.
These files are parsed and used to prove properties.
See an [example](https://github.com/Certora/SolanaExamples/blob/main/cvlr_by_example/first_example/certora/summaries.txt).

**When to use it?**

This option is currently required for every project.
It can be provided to the Prover by passing this list as a flag or by retrieving it from the build script.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --solana_summaries <path_to_summaries_file> --rule <rule_name>
```

### --cargo_features

**What does it do?**

Provides the Prover with a whitespace-separated list of extra [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html) passed to the build script.
These features are then passed to ``cargo`` to build the project.

**When to use it?**

Use it when there is a need to enable a specific [Cargo feature](https://doc.rust-lang.org/cargo/reference/features.html) to compile the source code.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --cargo_features <feature_1> <feature_2> --rule <rule_name>
```

### --msg

**What does it do?**

Adds a description message to your run, similar to a commit message. This message appears on the Prover dashboard and in the rule report.
Note that you need to wrap your message in quotes if it contains spaces.

**When to use it?**

Adding a message makes it easier to track several runs on [the Prover Dashboard](https://prover.certora.com/). It is very useful if you are running many verifications simultaneously.
It is also helpful to keep track of a single file verification status over time, so we recommend always providing an informative message.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --msg 'Removed an assertion' --rule <rule_name>
```

### --rule_sanity

**What does it do?**

When used with `--rule_sanity: basic`, this flag executes a job in sanity mode which performs a vacuity check for a rule.

**When to use it?**

Sanity mode is helpful to check for the correctness of a rule. For details, see also [Rule Sanity Checks](./sanity.md).

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --rule_sanity basic
```


## `--multi_assert_check`

**What does it do?**
This flags translates each assertion statement in a rule into a separate verification task. All preceding assertions are assumed to be true - they are hence translated into assume statements.
An example can be found [here](https://github.com/Certora/SolanaExamples/blob/main/cvlr_by_example/first_example/certora/conf/MultiAssertMode.conf).

```{caution}
We suggest using this mode carefully. In general, as this mode generates generates one verification task per assert, it may lead to worse running-time performance. Please see indications for use below.
```

**When to use it?**
When you have a rule with multiple assertions:

1.  As a timeout mitigation strategy: checking each assertion separately may, in some cases, perform better than checking all the assertions together and consequently solve timeouts. For instance, you can identify complex to verify asserts in a rule.

2.  If you wish to get multiple counter-examples in a single run of the tool, where each counter-example violates a different assertion in the rule.

**Example**

```bash
certoraSolanaProver --build_script <path_to_build_script> --multi_assert_check
```