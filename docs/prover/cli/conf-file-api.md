Certora Prover Conf File API
============================

The **Conf File API** is an alternative API for `certoraRun`. In terms of functionality 
this API is identical to the [CLI Options](options.md) API. Instead of calling `certoraRun` 
with a list of shell flags, some or all the flags can be stored in a [JSON](https://www.json.org/json-en.html) file 
(to be more precise the format is [JSON5](https://json5.org/)):

```
certoraRun my_params.conf
```

Conf files must use the `.conf` suffix


How CLI Options are mapped to JSON
----------------------------------

**JSON Keys**

JSON keys in the conf file are the CLI option flag names without the leading dashes.
For example, 
the CLI flag **--verify** will be stored under the **"verify"** in the conf file

The JSON key for the input files in the CLI API is **"files"**

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

A conf file is generated each time `certoraRun` completes execution successfully.
The conf file is stored as `**run.conf**` in the build directory under **`.certora_internal`**.
<p>Conf file of the latest run can be found in:

```
./.certora_internal/latest/run.conf
```


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
