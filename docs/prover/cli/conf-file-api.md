Certora Prover Conf File Format
===============================

Conf files are an alternative way for setting arguments for the
 `certoraRun` tool. In terms of functionality 
using conf files is identical to the use of the [CLI Options](options.md). Instead of calling `certoraRun` 
with a list of shell flags, some or all the flags can be stored in a JSON file 
(to be more precise the format is [JSON5](https://json5.org/)):

```
certoraRun my_params.conf
```

* Conf files must use the `.conf` suffix
* 


How CLI Options are mapped to JSON
----------------------------------

Command-line arguments are stored as key-value pairs in the conf file. 
The keys are the names of the parameters (with the leading -- removed). 
For example,
```
certoraRun --verify Example:example.spec
```
is equivalent to running with the following conf file:

```
{ "verify": "Example:example.spec" }
```
The values in the map depend on the type of arguments:

* for flags that take no additional arguments (such as[--send_only](options.html?highlight=options#send-only)),
the value should be true. For example,
```
certoraRun --send_only
```

would be encoded as:
```
{ "send_only": true }
```

* flags that take a single additional argument (such as[--solc](options.md#--solc)) or as [--loop_iter](options.html?highlight=options#loop-iter) 
 are encoded as a JSON string. For example,
```
certoraRun --solc solc4.25 --loop_iter 2
```

would be encoded as:
```
{ "solc": "solc4.25", "loop_iter": "2" }
```

Note that conf files do not use JSON numbers; numbers are encoded as strings.

* flags that take multiple additional arguments (such as [--packages](highlight=options#packages))
are encoded as JSON lists. For example,
```
certoraRun --packages @balancer-labs/v2-solidity-utils=pkg/solidity-utils @balancer-labs/v2-vault=pkg/vault
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






Command-line arguments are stored as key-value pairs in the conf file.
* The keys are the names of the parameters 
(with the leading -- removed). For example, the **--verify** flag
```
certoraRun ... --verify Example:example.spec ...
```
will appear in the conf file as:
```
{
    ...
    "verify": "Example:example.spec" 
    ...
}
```

* The input files in the CLI API will be stored under the key **files**

```
certoraRun example.sol  ...
```
will appear in the conf file as:
```
{
    ...
    "files": "Example:example.spec" 
    ...
}
```
**String Value CLI Options**

Flags in CLI API that accept a single string will be stored as **JSON Strings**. Example:
```
"solc": "solc4.25"
```
**Number Value CLI Options**

Flags in CLI API that accept numbers will be stored as **JSON Strings** not as **JSON Numbers**. Example:

```
"smt_timeout": "600"
```

**Boolean Value CLI Options**

Since some boolean flags in the CLI API do not get a value they will be stored as **JSON true**. Example:

```
"send_only": true
```
**List Value CLI Options**

Flags in CLI API that accept multiple strings will be stored as **JSON Arrays**. Example:
```
    "packages": [
        "@balancer-labs/v2-solidity-utils=pkg/solidity-utils",
        "@balancer-labs/v2-vault=pkg/vault"
    ]
```

**Map Value CLI Options**

Flags in CLI API that are maps will be stored as **JSON Objects**. Example:
```
    "solc_map": {
        "A": "solc5.11",
        "B": "solc5.9",
        "C": "solc6.8"
    }
    
```
**Generating a Conf File**

After each successful run of `certoraRun` a conf file is generated and is
stored in the file **run.conf** under the internal directory of that run.
The conf file of the latest run can be found in:

```
.certora_internal/latest/run.conf
```

Instead of generating a complete conf file from scratch, users can take 
one of these generated  conf files as a basis for their modifications.

**Conf Files in the VS Code IDE Extension**

VS Code users can generate conf files using the [Certora IDE Extension](https://marketplace.visualstudio.com/items?itemName=Certora.vscode-certora-prover). The extension 
offers an intuitive UI for configuring Prover jobs. Each job 
keeps a conf file that allows rerunning the job. All conf files
are stored in the VS code project under the folder  `certora/confs`. A link to the job's conf file
can also be found in the files section of the run report once the job is completed.

**Complete Example**

The command line:
```
certoraRun SolcArgs/A.sol SolcArgs/A.sol:B SolcArgs/C.sol --verify A:SolcArgs/Trigger.spec --solc_map SolcArgs/A.sol=solc6.1,B=solc6.1,C=solc5.12 --multi_assert_check 
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
