# Certora Solidity Mutation Tester

This project is a mutation tester which
 checks that variants of the original
 solidity program do not pass the specification.
If a mutated program passes the specification,
it may indicate that the specification is vacuous or not rigorous enough.

# Running the Mutation Tester

- Example:
```
java -ea -jar $CERTORA/certora_jars/MutationTest.jar /path/to/config/file/Example.conf
```

- Remember to `yarn install` or `npm install` when working
  on customer code if required by the customer code infra!

- **NOTE: if a path has spaces, put quotes around it to ensure correct parsing by Kotlin's libraries**

- Gambit **does** support `--staging`!
**However, Gambit currently has trouble with
`--send_only` and `--cloud` in the run scripts.
If you have these flags, please remove them for now.**
Apologies for the temporary inconvenience!

The tool expects a configuration file (extension `.conf` is required)
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

Required Keys for the JSON Configuration File:
- `"project_directory"` : the directory containing the original CVT project on which to perform mutation testing
- `"run_script"` : the bash script used to run verification on the original project, usually `project_directory/run.sh` or similar
- `"gambit"` : the JSON configuration element for invoking Gambit. May be a path to a gambit configuration file
or the explicit JSON element contained therein. Refer to the open source Gambit repository for more details regarding Gambit configuration files.

Optional Keys for the JSON Configuration File:
- `"staging"` : the branch name for running mutant verification on `--staging`. We support `"staging" : true` as an
alternative to `"staging" : "master"`. Omitting this key will cause verification to run locally.
- `"num_threads"` : the maximum number of threads to use for verification, as an integer
- `"manual_mutations"` : optionally supplement the random mutant generation with your own manually-written mutants.
Expects a JSON object whose keys are the paths to the original files and whose values are paths to directories containing
manually-written mutants as `.sol` files. **IMPORTANT:** any manual mutations files provided must follow the naming
convention `OriginalFileName.<unique-name>.sol`, where `unique-name` is a string ID unique with respect to the other
manual mutants. It is recommended to use `mN` for brevity, where `N` is a unique integer.
- `"use_cli_certora_run"` : Use CLI `certoraRun` rather than `certoraRun.py`. Expects a boolean and defaults to `false`.
- `"offline"` : run mutation testing without internet connection, skipping the UI output and other web functions.
Expects a boolean and defaults to `false`.

For implementation details regarding the generation of mutants, refer to the open source repository for Gambit.

# Visualization

The mutation verification results are
  summarized in an user-friendly visualization.
[Here](https://mutation-testing-beta.certora.com/reports/mutation?id=c7c659d7-d500-46f2-acf1-1392eee714b5&anonymousKey=f4b40ba6-2160-4993-9f50-02625b291cae) is an example summary
  for the [Borda example](https://github.com/Certora/CodeExamples/tree/master/Borda).
Rules are represented by the green outer circles
  and the mutants are represented by the gray dots.
Selecting a rule shows which mutants it killed
  and selecting a mutant shows which rules killed it.
The coverage metric is computed as the fraction
  of total generated mutants that were killed.
Clicking on a mutant's patch also shows the
  diff with respect to the original program.

# Implementation Details

The mutation tester invokes Gambit using the provided Gambit configuration
JSON, adding randomly generated mutants to the (possibly empty) collection of
manual mutations provided by the user. Then, it attempts to verify each mutant
and generates a report comparing the results of verifying mutants against the
results of verifying the original program.

In order to compile and verify the mutants, the script generates various
temporary directories within the specified project folder. The version of
`solc` is specified on a per-file basis as part of the Gambit configuration,
defaulting to `solc`.

All the reports and mutants are placed in a new directory named
`project_directory + "Mutants"`, which lives in the parent directory of the
project directory. Upon successfully generating a verification report, we print
a link to a graphic UI presentation of the results.
