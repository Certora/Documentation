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
certoraMutate --prover_conf path/to/prover/prover.conf --mutation_conf path/to/mutation/mutation.conf
```

```{note}
You must run `certoraMutate` from the root of the Solidity project directory.
The files `prover.conf` and `mutation.conf`
can be in their own directories.
All paths in `mutation.conf` are relative to the parent directory containing `mutation.conf`.
This is different from how `prover.conf` is written, where the paths are all relative to the root
of the project directory, which is assumed to be the working directory.
```

## Configurations
The tool expects two separate configuration files:
the configuration file which defines the execution of mutant generation (`--mutation_conf`),
and the configuration file which defines execution of the Prover (`--prover_conf`).
Here is a simple configuration file setup using the example above:

In `prover.conf`:

```json
{
  "files": [
    "C.sol"
  ],
  "verify": "C:c.spec"
}
```
In `mutation.conf`:

```json
{
  "filename" : "C.sol",
  "num-mutants": 5
}
```

### Manual Mutations
You can add manual mutations to `mutation.conf` like so:

```json
{
  "filename" : "C.sol",
  "num-mutants": 5,
  "manual_mutants": {
     "C.sol": "path/to/dir/with/manual_mutants/for/C"
  }
}
```
If you set `num_mutants` to 0 in the above file, `gambit` will not generate any mutants, you will only run
`certoraMutate` on manually written mutants.

## CLI Options

`certoraMutate` runs in two distinct modes: synchronous and asynchronous.
Use the `--sync` flag to run the entire tool synchronously
in your shell, from mutant generation to the web report UI. 
Alternatively, running without the `--sync` flag will dump
data about the mutation verification jobs in the `collect.json` file in the working directory. These jobs are submitted
to the server environment specified and run asynchronously. 
They may be polled later with
`certoraMutate --collect_file collect.json`.

Usually, the synchronous mode is suitable when the original specification run finishes quickly. 
The asynchronous mode is suitable for bigger specifications of more complicated contracts, where each run takes more than just several minutes. It avoids depending on an active internet connection for the entire duration of the original run and the mutations.
Soon, Certora will enable automatic notifications for asynchronous mutation testing runs, so that manual checks will not be necessary.

`certoraMutate` supports the following options; for a comprehensive list, run `certoraMutate --help`:

| Option                         | Description                                                                                                           |
|:-------------------------------|:----------------------------------------------------------------------------------------------------------------------|
| `--prover_conf`                | specify the Prover configuration file for verifying mutants                                                           |
| `--mutation_conf`              | specify the configuration file for mutant generation                                                                  |
| `--num_mutants`                | request the mutant generator to generate a specific number of mutants. Defaults to 5                                  |
| `--prover_version`             | specify the version of `certoraRun` to use for verification. Defaults to the installed version of `certoraRun`        |
| `--server`                     | specify the server environment to run on. Defaults to the value specified in the file of `--prover_conf`, if the field exists otherwise whatever `certoraRun` uses by default   |
| `--debug`                      | show additional logging information during execution                                                                  |
| `--gambit_out`                 | specify the output directory for gambit. Defaults to a new directory which is added in the working directory          |
| `--applied_mutants_dir`        | specify the target directory for mutant verification build files. Defaults to a hidden Prover internal directory      |
| `--ui_out`                     | specify a JSON file to dump the mutant verification report used for the web UI                                   |
| `--dump_link`                  | specify a text file to write the UI report link                                                                       |
| `--dump_csv`                   | specify a csv file to write the verification JSON report                                                              |
| `--collect_file`               | specify the collect file from which to run in asynchronous mode                                                       |
| `--sync`                       | enable synchronous execution                                                                                          |
| `--max_timeout_attempts_count` | specify the maximum number of times a web request is attempted                                                        |
| `--request_timeout`            | specify the length in seconds for a web request timeout                                                               |
| `--poll_timeout`               | specify the number of minutes to poll a task in sync mode before giving up. Polling is possible even after the timeout with another call to `certoraMutate`     |

## Troubleshooting

At the moment, there are a few ways in which `certoraMutate` can fail. Here are some suggestions on how to troubleshoot when that happens. We are actively working on mitigating them.

- Sometimes it might be useful to first run `gambit` without going through `certoraMutate`.
  `gambit` can be found under the `site-packages` directory under `certora_bins`.
  * Run `gambit mutate --json foo.json` or `gambit mutate --filename solidity.sol` to identify the issue.
  * Here, `foo.json` can also be `foo.conf`.
  * **Note.** you must remove the field `manual_mutants` from the `json` if it is present, before running `gambit`.
- Try running the Prover on your mutants individually using `certoraRun`. 
  Usually the mutant setup will be in `.certora_internal/applied_mutants_dir` and can be retried by running the Prover's `.conf` file with `certoraRun`.
  It is also possible that you are encountering a bug with the underlying version of the Prover.
- In sync mode, even if the polling timeout was hit, it is possible to re-run `certoraMutate` with just the `--collect_file` option to to retry getting the results without restarting the entire mutation testing task.

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

