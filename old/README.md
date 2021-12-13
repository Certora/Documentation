---
description: This document explains how to install and run the Certora Prover
---

# Quick Guide to the Certora Prover

## Installation

### Step 1: Prerequisites

* Python3.5 and later
* Java 11 and later
* [Solidity compiler](https://github.com/ethereum/solidity/releases) \(ideally v0.5 and up\)

### Step 2: Install the Certora Prover package

```
pip install certora-cli
```

### Step 3: Set access key as an environment variable

The Certora Prover requires a valid key when running the tool. For ease of use, it is recommended to set it in an environment variable called `CERTORAKEY`.

```text
export CERTORAKEY=value
```

\(_value_ is the key provided by the Certora team.\)

### **Step 4: Add the solidity compiler \(solc\) executable's folder to your PATH**

\(How to do this depends on you operating system.\)

### Step 5: Download examples

It's highly recommended to first try out the tool on basic examples, such as those available in [this repository](https://github.com/Certora/CertoraProverSupplementary). The repository also includes syntax highlighting of specification files for common editors \(VSCode, notepad++\).

```text
git clone git@github.com:Certora/CertoraProverSupplementary.git
```

## Running the Certora Prover

We start with a simple example. After cloning the [examples repository](https://github.com/Certora/CertoraProverSupplementary), run:

```text
cd CertoraProverSupplementary/Examples/Simple
certoraRun CounterBroken.sol:Counter --verify Counter:Counter.spec
```

{% hint style="info" %}
Windows users should run the tool with `certoraRun.exe`
{% endhint %}

The above command will trigger the verification of the contract `Counter` located in the Solidity file `InvertibleBroken.sol`, using the rules defined in the specification file `Counter.spec`. After authorizing the request based on the provided access key, the tool sends the job to Certora's server. Messages will be printed to the command line, informing about its progress. Note that even if you interrupt the process, the job continues to process. An email notification is sent when the verification is complete, containing links to the results. If the CLI tool is not interrupted, the output will also contain the links to the results:

```text
Status page: https://prover.certora.com/jobStatus/...?anonymousKey={anonymousKey}
Verification report: https://prover.certora.com/output/...?anonymousKey={anonymousKey}
Full report: https://prover.certora.com/zipOutput/...?anonymousKey={anonymousKey}
```

Follow this link to view the results. A verification report is an HTML file presenting a table with all the spec file rules. Each formally proved rule has a green color, and violated rules are colored red. The report will also include the call trace and the arguments that led to the violation. In this example, the Certora Prover finds a violation of the `monotone` rule. Click the rule to see the call trace and try to figure out the reason. 

Need some help? Try to run another verification on `CounterFixed.sol` and see the difference.

An explanation of the results is briefly described [here](user-manual/specification/specification-basics-in-specify/understanding-the-results-of-the-certora-prover.md). To find out more about how to run the tool, see [Certora Prover CLI Options](certora-prover-cli-options.md). 

Congratulations! You have just completed a verification using Certora Prover.



