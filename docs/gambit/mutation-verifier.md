# Using Gambit with the Prover

This is the mutation verifier which
 checks that variants of the original
 solidity program do not pass the specification.
It uses mutations from the {doc}`Gambit <gambit>`
  mutation generator.
It also allows users to include manually generated mutants.
If a mutated program passes the specification,
it may indicate that the specification is vacuous or not rigorous enough.
In the rest of the document,
  we refer to both the mutation generator and the verifier as Gambit.

## Installations and Setup

To use the mutation verifier,
  first {ref}`install the Certora Prover and its dependencies <installation>`.
To install it, run

```sh
pip install certora-cli
```

If you already have `certora-cli` installed and
  the `certoraMutate` command is not available,
  you may need to update to a newer version by running

```sh
pip install --upgrade certora-cli
```


## Running the Mutation Verifier

Once you have updated your `certora-cli` installation using `pip` to get the relevant
dependencies, run Gambit from the command line:

```
certoraMutate --prover_conf path/to/prover/prover.conf --gambit_conf path/to/gambit/gambit.conf
```

## Configuration
The tool expects two separate configuration files (extension `.conf` is required for both):
the configuration file which defines the execution of mutant generation (`--gambit_conf`),
and the configuration file which defines execution of the prover (`--prover_conf`).
Here is a simple configuration file setup using the example above:

In `prover.conf`:

```json
{
  "files": [
    "C.sol"
  ] ,
  "process": "emv",
  "prover_args": [
    " -adaptiveSolverConfig false -smt_nonLinearArithmetic false"
  ],
  "solc": "solc8.1",
  "verify": "C:c.spec"
}
```
In `gambit.conf`:

# In prover.conf:
```json
{
  "filename" : "Test/10Power/TenPower.sol",
  "num_mutants": 5
}
```

### CLI Options

`certoraMutate` runs in two distinct modes: synchronous and asynchronous. Use the `--sync` flag to run the entire tool synchronously
in your shell, from mutant generation to the web report UI. Alternatively, running without the `--sync` flag will dump
data about the mutation verification jobs in the `collect.json` file in the working directory. These jobs are submitted
to the server environment specified and run asynchronously. They may be polled later with
`certoraMutate --collect_file collect.json`.

`certoraMutate` supports the following options; for a comprehensive list, run `certoraMutate --help`:

| Option                         | Description                                                                                                           |
|:-------------------------------|:----------------------------------------------------------------------------------------------------------------------|
| `--prover_conf`                | specify the prover configuration file for verifying mutants                                                           |
| `--gambit_conf`                | specify the configuration file for mutant generation                                                                  |
| `--auto_conf`                  | build the gambit_conf file from the prover_conf file and exit; the file at gambit_conf must not exist                 |
| `--manual_mutations`           | specify the JSON file describing the manually-written mutants to include                                              |
| `--num_mutants`                | request the mutant generator to generate a specific number of mutants. Defaults to 5                                  |
| `--prover_version`             | specify the version of `certoraRun` to use for verification. Defaults to the latest installed version                 |
| `--server`                     | specify the server environment to run on. Defaults to the environment specified in the prover_conf                    |
| `--debug`                      | show additional logging information during execution                                                                  |
| `--gambit_out`                 | specify the output directory for gambit . Defaults to a new directory is added in the working directory               |
| `--applied_mutants_dir`        | specify the target directory for mutant verification build files. Defaults to a special directory in prover internals |
| `--ui_out`                     | specify the directory of the mutant verification report JSON used for the web UI                                      |
| `--dump_link`                  | specify a text file to write the UI report link                                                                       |
| `--collect_file`               | specify the collect file from which to run in asynchronous mode                                                       |
| `--sync`                       | enable synchronous execution                                                                                          |
| `--max_timeout_attempts_count` | specify the maximum number of times a web request is attempted                                                        |
| `--request_timeout`            | specify the length in seconds for a web request timeout                                                               |
| `--poll_timeout`               | specify the number of minutes to continue polling a submitted task in sync mode                                       |


### Troubleshooting

At the moment, there are a few ways in which `certoraMutate` can fail. Here are some suggestions on how to troubleshoot when that happens. We are actively working on mitigating them.

- Since Gambit requires you to provide the solidity compiler flags to compile the mutants, sometimes it might be useful to first identify what those flags should be. See {ref}`gambit-config` for more information. A strategy you can adopt is
  * first run `gambit` without going through `certoraMutate` (you likely have the `gambit` binary in your path already if you are running the tool).
  * Run `gambit mutate --json foo.json` to identify the issue.
- Try running the prover on your mutants individually using `certoraRun`. It is also possible that you are encountering a bug with the underlying version of the prover.

## Visualization

The mutation verification results are
  summarized in a user-friendly visualization.
[Here](https://mutation-testing-beta.certora.com/reports/mutation?id=c7c659d7-d500-46f2-acf1-1392eee714b5&anonymousKey=f4b40ba6-2160-4993-9f50-02625b291cae) is an example summary
  for the [Borda example](https://demo.certora.com/?Borda).
Rules are represented by the green outer circles
  and the mutants are represented by the gray dots.
Selecting a rule shows which mutants it detected
  and selecting a mutant shows which rules detected it.
The coverage metric is computed as the fraction
  of total generated mutants that were detected.
Clicking on a mutant's patch also shows the
  diff with respect to the original program.

