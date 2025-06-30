# Solana-Specific Options / CLI Flags

This page documents Solana-specific Certora Prover options, which include CLI flags or ``prover_args`` flags.
The ``certoraSolanaProver`` utility invokes the Rust compiler and then sends the job to Certora's servers.
The most commonly used command is:

```bash
certoraSolanaProver --rule <rule_name>
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

The Certora Solana Prover has two modes of operation, using `cargo certora-sbf`, or passing a precompiled binary directly.
These modes are mutually exclusive - you cannot run the tool with more than one mode at a time.
By not specifying the path to a binary executable, the default mode is calling `cargo certora-sbf`.
Both modes require the user to specify which rules must be verified by using the ``--rule`` option.

## Most Frequently Used Options

### `--rule`

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
certoraSolanaProver --rule rule_withdraw_succeeds
```

To verify both `rule_withdraw_succeeds` and `rule_withdraw_fails`, run:
```bash
certoraSolanaProver --rule rule_withdraw_succeeds rule_withdraw_fails
```

(--solana_inlining)=
### `--solana_inlining`

**What does it do?**

Provides the Prover with a list of paths to inlining files for Solana programs.
These files are parsed and used to prove properties.
See an [example](https://github.com/Certora/SolanaExamples/blob/main/certora/summaries/cvlr_inlining_core.txt).

**When to use it?**

This option is currently required for every project.
It can be provided to the Prover by passing this list as a flag or by retrieving
it from the `Cargo.toml` file in the `[package.metadata.certora]` section.

**Example**

```bash
certoraSolanaProver --solana_inlining <path_to_inlining_file>  --rule <rule_name>
```

(--solana_summaries)=
### `--solana_summaries`

**What does it do?**

Provides the Prover with a list of paths to summary files for Solana contracts.
These files are parsed and used to prove properties.
See an [example](https://github.com/Certora/SolanaExamples/blob/main/certora/summaries/cvlr_summaries_core.txt).

**When to use it?**

This option is currently required for every project.
It can be provided to the Prover by passing this list as a flag or by retrieving
it from the `Cargo.toml` file in the `[package.metadata.certora]` section.

**Example**

```bash
certoraSolanaProver --solana_summaries <path_to_summaries_file> --rule <rule_name>
```

### `--cargo_features`

**What does it do?**

Provides the Prover with a whitespace-separated list of extra [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html) passed to the build script.
These features are then passed to ``cargo`` to build the project.

**When to use it?**

Use it when there is a need to enable a specific [Cargo feature](https://doc.rust-lang.org/cargo/reference/features.html) to compile the source code.

**Example**

```bash
certoraSolanaProver --cargo_features <feature_1> <feature_2> --rule <rule_name>
```

### `--msg`

**What does it do?**

Adds a description message to your run, similar to a commit message. This message appears on the Prover dashboard and in the rule report.
Note that you need to wrap your message in quotes if it contains spaces.

**When to use it?**

Adding a message makes it easier to track several runs on [the Prover Dashboard](https://prover.certora.com/). It is very useful if you are running many verifications simultaneously.
It is also helpful to keep track of a single file verification status over time, so we recommend always providing an informative message.

**Example**

```bash
certoraSolanaProver --msg 'Removed an assertion' --rule <rule_name>
```

### `--rule_sanity`

**What does it do?**

When used with `--rule_sanity: basic`, this flag executes a job in sanity mode which performs a vacuity check for a rule.

**When to use it?**

Sanity mode is helpful to check for the correctness of a rule. For details, see also [Rule Sanity Checks](./sanity.md).

**Example**

```bash
certoraSolanaProver --rule_sanity basic
```


## `--multi_assert_check`

**What does it do?**
This flags translates each assertion statement in a rule into a separate verification task. All preceding assertions are assumed to be true - they are hence translated into assume statements.
An example can be found [here](https://github.com/Certora/SolanaExamples/blob/66c1f406755893db5a081f39ca5cdd583a6f9991/cvlr_by_example/first_example/certora/conf/MultiAssertMode.conf).


```{caution}
We suggest using this mode carefully. In general, as this mode generates generates one verification task per assert, it may lead to worse running-time performance. Please see indications for use below.
```

**When to use it?**
When you have a rule with multiple assertions:

1.  As a timeout mitigation strategy: checking each assertion separately may, in some cases, perform better than checking all the assertions together and consequently solve timeouts. For instance, you can identify complex to verify asserts in a rule.

2.  If you wish to get multiple counter-examples in a single run of the tool, where each counter-example violates a different assertion in the rule.

**Example**

```bash
certoraSolanaProver --multi_assert_check
```