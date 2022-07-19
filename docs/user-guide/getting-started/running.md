Running the Certora Prover
==========================

Basic examples are available in [this repository](https://github.com/Certora/CertoraProverSupplementary). The repository also includes syntax highlighting of specification files for common editors (VSCode, notepad++).

```bash
git clone git@github.com:Certora/CertoraProverSupplementary.git
```

We start with a simple example. After cloning the [examples repository](https://github.com/Certora/CertoraProverSupplementary), open terminal and move to the specified directory:

```bash
cd CertoraProverSupplementary/Examples/Simple
```

Then run the following command to specify a verification job:

```bash
certoraRun CounterBroken.sol:Counter --verify Counter:Counter.spec
```

```{note}
Windows users should run the tool with `certoraRun.exe`
```

The above command will trigger the verification of the contract `Counter` located in the Solidity file `CounterBroken.sol`, using the rules defined in the specification file `Counter.spec`.

After authorizing the request based on the provided access key, the tool sends the job to Certora's server. Messages will be printed to the command line, informing about its progress. Note that even if you interrupt the process, the job continues to process. An email notification is sent when the verification is complete, containing links to the results.

If the CLI tool is not interrupted, the output will also contain the links to the results:

```
Status page: https://prover.certora.com/jobStatus/...?anonymousKey={anonymousKey}
Verification report: https://prover.certora.com/output/...?anonymousKey={anonymousKey}
Full report: https://prover.certora.com/zipOutput/...?anonymousKey={anonymousKey}
```

Follow this link to view the results.

A verification report is an HTML file presenting a table with all the spec file rules. Each formally proved rule has a green color. Violated rules are colored red. The report will also include the call trace and the arguments that led to the violation. In this example, the Certora Prover finds a violation of the `monotone` rule (when run with solidity before 0.8.0). Click the rule to see the call trace and try to figure out the reason. 

Need some help? Try to run another verification on `CounterFixed.sol` and see the difference.

An explanation of the results is briefly described [here](/TODO.md). To find out more about how to run the tool, see Certora Prover CLI Options. 

Congratulations! You have just completed a verification using Certora Prover.

