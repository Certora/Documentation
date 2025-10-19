# The Ranger Client

Ranger introduces a new CLI entry point: `certoraRanger`.

This command is part of the `certora-cli` Python package and provides a streamlined interface for bounded model checking, 
specifically designed for exploring concrete execution paths up to a limited range.
It comes with new defaults and additional under-approximations to make finding concrete counterexamples easier and faster.

The `certoraRanger` client submits jobs to the Certora cloud, just like the Prover. You'll receive a dashboard link with the results once the job is submitted

Ranger uses the same input format and job flow as `certoraRun`, allowing teams to reuse existing configuration and spec files.

## Ranger-specific flags

(--range)=
### `range`

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


## Default Under-approximations

By default, `certoraRanger` enables the following Prover flags to favor usability over full soundness:

{ref}`--optimistic_loop`

{ref}`--loop_iter` 3

{ref}`--optimistic_fallback`

{ref}`--optimistic_hashing`

{ref}`--auto_dispatcher`

These options help prune unrealistic paths, reduce false positives, and improve performance.

Unresolved calls will be treated as nondeterministic.

You can override any of these defaults in your .conf file or via the CLI. Ranger will never fail due to unsupported overrides—it will simply continue and print a warning if needed.


## Unsupported Prover flags


The following `certoraRun` flags are not supported in Ranger:

{ref}`--project_sanity`

{ref}`--rule_sanity`

{ref}`--coverage_info`

{ref}`--multi_example`

{ref}`--foundry`

{ref}`--independent_satisfy`

{ref}`--multi_assert_check`

If any of these are used, Ranger will emit a warning, ignore the flag, and continue the job.


## Config file compatibility

Ranger supports the same `.conf` format as the Certora Prover.
You can reuse your existing `.conf` files without changes.

- Ranger will ignore Prover-only flags in the config file.
- Prover will ignore Ranger-only flags, like {ref}`--range`.

This ensures that a single configuration file can work for both tools, enabling easier integration and faster iteration across your workflows.
