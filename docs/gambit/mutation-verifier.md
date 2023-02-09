# Using Gambit with the Prover

This is the mutation verifier which
 checks that variants of the original
 solidity program do not pass the specification.
It uses mutations from the [Gambit](https://github.com/Certora/gambit)
  mutation generator.
It also allows users to include manually generated mutants.
If a mutated program passes the specification,
it may indicate that the specification is vacuous or not rigorous enough.
In the rest of the document,
  we refer to both the mutation generator and the verifier as Gambit.

## Installations and Setup

You will require java to run the mutation testing jar.
Installation instructions can be found [here](https://www.java.com/en/download/help/download_options.html).

## Running the Mutation Verifier

- Example:
```
java -ea -jar $CERTORA/certora_jars/MutationTest.jar /path/to/config/file/example.conf
```

- **NOTE: if a path has spaces, put quotes around it to ensure correct parsing by Kotlin's libraries**

```{info}
Gambit supports {ref}`--staging`.

However, Gambit currently has trouble with
{ref}`--send_only` and {ref}`--cloud` in the run scripts.
If you have these flags, please remove them for now.
Apologies for the temporary inconvenience!
```

(gambit-prover-config)=
## Configuration
The tool expects a configuration file (extension `.conf` is required).
which is a JSON object.
Here is an example configuration file:

```
{
    "project_folder" : "Test/10Power",
    "run_script" : "Test/10Power/runDefault.sh",
    "gambit" : {
        "filename" : "Test/10Power/TenPower.sol",
        "solc" : "solc8.10"
    },
    "staging" : "master",
    "manual_mutations" : {
        "path/to/original/file.sol" : "path/to/manual/mutations/",
        ...
    },
    ...
}
```

Note: This configuration is separate from CVT's `.conf` file and also from the
  configuration file of the mutation generator ({ref}`gambit-config`).
Importantly, notice that to use this tool, you can embed the configuration
for generating the mutants in this `.conf` file; you don't need to write
  two separate configurations.

### Required Keys for the JSON Configuration File:
- `"project_directory"` : the directory containing the original CVT project on which to perform mutation testing
- `"run_script"` : the bash script used to run verification on the original project, usually `project_directory/run.sh` or similar.
  Gambit will pull the configuration for `certoraRun` from this shell script and verify each mutant using this configuration.
- `"gambit"` : the JSON configuration element for invoking Gambit. May be a path to a gambit configuration file
or the explicit JSON element contained therein.  See {ref}`gambit-config` for more information about the gambit configuration.
The `solc` specific arguments (including the version of the compiler) should be provided here
  even if they are present in the `run_script`.

### Optional Keys for the JSON Configuration File
- `"num_threads"` : the maximum number of threads to use for verification, as an integer
- `"manual_mutations"` : optionally supplement the random mutant generation with your own manually-written mutants.
Expects a JSON object whose keys are the paths to the original files and whose values are paths to directories containing
manually-written mutants as `.sol` files.

```{info}
Any manual mutations files provided must follow the naming
convention `OriginalFileName.<unique-name>.sol`, where `<unique-name>` is a string ID unique with respect to the other
manual mutants (for example you might name them `OriginalFileName.m1.sol`, `OriginalFileName.m2.sol` and so on).
```

### Additional Optional Flags for Certora Internal Use
- `"offline"` : run mutation testing without internet connection, skipping the UI output and other web functions.
Expects a boolean and defaults to `false`.
- `"staging"` : if your run script does not already have `--staging`, you can also add it to Gambit.
  Similar to CVT, you can provide the
  branch name for running mutant verification on `--staging`.
We support `"staging" : true` as an alternative to `"staging" : "master"`.
Omitting this key will cause verification to run locally
  (unless the run script has it).
- `"use_cli_certora_run"` : Use CLI `certoraRun` rather than `certoraRun.py`. Expects a boolean and defaults to `false`.


## Visualization

The mutation verification results are
  summarized in an user-friendly visualization.
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

