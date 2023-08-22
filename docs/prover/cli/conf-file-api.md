Certora Prover Conf File API
============================

The **Conf File API** is an alternative API for  `certoraRun` . In terms of functionality 
this API is identical to the [CLI Options](options.md). Instead of calling `certoraRun` 
with a list of shell flags, some or all the flags can be stored in a [JSON](https://www.json.org/json-en.html) file:

```bash
certoraRun my_params.conf
```
<div style="background-color: #FFFFE0; padding: 10px; border: 1px solid #E6DB55;">
To denote a text file as a conf file use the <strong>.conf</strong> suffix
</div>

Converting from CLI Options to JSON
-----------------------------------

**JSON Keys**

JSON keys in the conf file are the flag names without the leading dashes:
```
The CLI flag --verify will be stored under the "verify" in the conf file
```
The JSON key for the input files in the CLI API is **"files"**

**String Value CLI Options**

Flags in CLI API that accept a single string will be stored as **JSON Strings**. Example:
```
"solc": "solc4.25"
```
**Number Value CLI Options**

Flags in CLI API that accept numbers will be store as **JSON Strings** not as **JSON Numbers**. Example:

```
"smt_timeout": "600"
```

**Boolean Value CLI Options**

Since boolean flags in CLI API do not get a value they will be store as **JSON true**. Example:

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

<div style="background-color: #FFFFE0; padding: 10px; border: 1px solid #E6DB55;">
Whenever certoraRun completes execution successfully the equivalent 
conf file is generated
and is stored as <strong>run.conf</strong> in the build directory under <strong>.certora_interal.</strong>
<p>Conf file of the latest run can be found in:
<div style="text-align:center;">
<strong>./.certora_internal/latest/run.conf</strong>
</div>
</div>

**Complete Example**

```
certoraRun SolcArgs/A.sol SolcArgs/A.sol:B SolcArgs/C.sol --verify A:SolcArgs/Trigger.spec --solc_map SolcArgs/A.sol=solc6.1,B=solc6.1,C=solc5.12 --multi_assert_check 
```
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
