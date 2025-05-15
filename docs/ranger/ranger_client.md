# The Ranger Client

Ranger introduces a new CLI entry point: certoraRanger.

This command is part of the certora Python package and acts as a lightweight wrapper around certoraRun, 
tailored specifically for bounded model checking. 
It comes with new defaults and additional under-approximations to make finding concrete counterexamples easier and faster.

The certoraRanger client submits jobs to the Certora Cloud, just like the Prover. You'll receive a dashboard link with the results once the job is submitted

# Usage: certoraRanger

Ranger uses the same input format and job flow as certoraRun, allowing teams to reuse existing configuration and spec files.

// TODO: Not sure what to add here.

# Ranger-specific flags

(--range)=
## `range`

**What does it do?**
Sets the maximal length of function call sequences to check (0 ≤ K).
This flag controls how deep Ranger explores function call sequences from the initial state.
Higher values can uncover deeper bugs but may increase analysis time.

When not assigned, the default value is defined as 5

**When to use it?**
When you wish to assign a different value than the default one.
Increasing this flag will execute longer sequences, or decreasing when you wish to execute faster runs.

**Example**

```sh
certoraRanger ranger.conf --range K
```

(--range_failure_limit)=
## `range_failure_limit`

**What does it do?**
Sets the minimal number of violations to be found.
Once we reach this limit, no new Ranger call sequence checks will be started.
Checks already in progress will continue, thus we are expected to see at least N violations.

When not assigned, the default value is defined as 1

**When to use it?**
When you wish to assign a different value than the default one.
Increasing this flag will execute more sequences, until we will reach the desired amount of violations.

**Example**

```sh
certoraRanger ranger.conf --range_failure_limit N
```

## `Default Under-approximations`

By default, certoraRanger enables the following Prover flags to favor usability over full soundness:

{ref}`--optimistic_loop`

{ref}`--loop_iter` 3

{ref}`--optimistic-fallback`

{ref}`--optimistic-hashing`

{ref}`--auto-dispatcher`

These options help prune unrealistic paths, reduce false positives, and improve performance.

Unresolved calls will be treated as nondeterministic

You can override any of these defaults in your .conf file or via the CLI. Ranger will never fail due to unsupported overrides—it will simply continue and print a warning if needed.


# Unsupported Prover flags


The following certoraRun flags are not supported in Ranger:

{ref}`--project-sanity`

{ref}`--rule-sanity`

{ref}`--coverage-info`

{ref}`--multi-example`

{ref}`--foundry`

{ref}`--independent-satisfy`

{ref}`--multi-assert-check`

If any of these are used, Ranger will emit a warning, ignore the flag, and continue the job.


# Config file compatibility

Ranger supports the same .conf format as the Certora Prover.
You can reuse your existing .conf files without changes.

- Ranger will ignore Prover-only flags in the config file.
- Prover will ignore Ranger-only flags, like --range.

This ensures that a single configuration file can work for both tools, enabling easier integration and faster iteration across your workflows.
