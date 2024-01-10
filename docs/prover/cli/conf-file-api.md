Conf Files
==========

Conf files are an alternative way for setting arguments for the
 `certoraRun` tool. In terms of functionality 
using conf files is identical to the use of the [CLI Options](options.md). Instead of calling `certoraRun` 
with a list of shell flags, some or all the flags can be stored in a JSON file 
(to be more precise the format is [JSON5](https://json5.org/)):

```sh
certoraRun my_params.conf
```

Conf files must use the `.conf` suffix.



How CLI options are mapped to JSON
----------------------------------

Command-line arguments are stored as key-value pairs in the conf file. 
The keys are the names of the CLI options (with the leading `--` removed). 
For example,
```sh
certoraRun --verify Example:example.spec
```
is equivalent to running with the following conf file:

```json
{ "verify": "Example:example.spec" }
```
The values in the map depend on the type of arguments:

* The input files in the CLI API will be stored as a list under the key `files`.  For example,

    ```
    certoraRun example.sol  ...
    ```
  will appear in the conf file as:
    ```
    {
      ...
      "files": [ "example.sol" ], 
      ...
    }
    ```

* Boolean options are options that take no arguments (for example {ref}`--send_only`). In 
the conf file all keys must come with a value, the value for boolean options is `true`. 
Since the default value of boolean options is `false` there is no need to set a boolean attribute to values other than `true`
    ```sh
    certoraRun --send_only
    ```

    would be encoded as:
    ```
    { "send_only": true }
    ```

* Options that expect a single argument (for example {ref}`--solc`) or {ref}`--loop_iter`) 
 are encoded as a JSON string. For example,
    ```
    certoraRun --solc solc4.25 --loop_iter 2
    ```
    would be encoded as:
    ```
    { "solc": "solc4.25", "loop_iter": "2" }
    ```
    Note that in conf files numbers are also encoded as strings.


* Options that expect multiple arguments (for example {ref}`--packages`)
are encoded as JSON lists. For example,
    ```
    certoraRun --packages @balancer-labs/v2-solidity-utils=pkg/solidity-utils \
                      @balancer-labs/v2-vault=pkg/vault
    ```
    would be encoded as:
    ```
    {
      "packages": [
        "@balancer-labs/v2-solidity-utils=pkg/solidity-utils",
        "@balancer-labs/v2-vault=pkg/vault"
      ] 
    }
    ```

* Options that are maps ({ref}`--solc_map` and {ref}`--solc_optimize_map`) will be stored as JSON objects.
  For example,
    ```
    certoraRun --solc_map A=solc5.11,B=solc5.9,C=solc6.8
    ```
  would be encoded as:
    ```
  
    "solc_map": {
        "A": "solc5.11",
        "B": "solc5.9",
        "C": "solc6.8"
    }
    
    ```
    and 
  
    ```
    certoraRun --solc_optimize_map A=200,B=200,C=300
    ```

  would be encoded as:
    ```
    "solc_optimize_map": {
        "A": "200",
        "B": "200",
        "C": "300"
    }
    
    ```
## Generating a Conf File

After each successful run of `certoraRun` a conf file is generated and is
stored in the file `run.conf` under the internal directory of that run.
The conf file of the latest run can be found in:

```
.certora_internal/latest/run.conf
```

Instead of generating a complete conf file from scratch, users can take 
one of these generated conf files as a basis for their modifications.

## Conf Files in the VS Code IDE Extension
The [Certora IDE Extension](https://marketplace.visualstudio.com/items?itemName=Certora.vscode-certora-prover)
automatically generates conf files for each configured job; these conf files
are stored in the VS code project under the folder  `certora/confs`.
Once the job is completed, a link to the job's conf file can also be found in the files section of the 
run report.

### Complete Example

The command line:
```
certoraRun SolcArgs/A.sol SolcArgs/A.sol:B SolcArgs/C.sol \
  --verify A:SolcArgs/Trigger.spec \
  --solc_map SolcArgs/A.sol=solc6.1,B=solc6.1,C=solc5.12 \
  --multi_assert_check 


```

will generate the conf file below:
```
{
    "files": [
        "SolcArgs/A.sol",
        "SolcArgs/A.sol:B",
        "SolcArgs/C.sol"
    ],
    "multi_assert_check": true,
    "solc_map": {
        "B": "solc6.1",
        "C": "solc5.12",
        "SolcArgs/A.sol": "solc6.1"
    },
    "verify": "A:SolcArgs/Trigger.spec"
}
```
