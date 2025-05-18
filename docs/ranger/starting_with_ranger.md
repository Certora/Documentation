# Getting Started

This guide will help you run your first Ranger job using a Solidity contract and a [CVL](/docs/cvl/index) [invariant](/docs/cvl/invariants).

Ranger uses the same installation process, configuration files, and spec files as the [Certora Prover](/docs/user-guide/index). If you're already familiar with the Prover, getting started with Ranger will feel familiar.

---

## 1. Install Certora Tools

Ranger is part of the `certora` Python package. You can install or upgrade it using `pip`:

```bash
pip install certora-cli
```
For full installation instructions and troubleshooting, see the Certora Prover [installation guide](/docs/user-guide/install).

## 2. Prepare Your Files
You'll need three files:

- A compiled Solidity contract (e.g. `MyContract.sol`)
- A CVL spec file with at least one invariant (e.g. `MyContract.spec`)
- A configuration file (e.g. `ranger.conf`)

Example `ranger.conf`:

```json
{
    "files": ["MyContract.sol"],
    "verify": "MyContract:MyContract.spec"
}
```

## 3. Run Ranger
Use the certoraRanger command to launch the job:

```bash
certoraRanger ranger.conf
```

This will start the Ranger process. A link to the Ranger Job Report in the dashboard will be pasted into your command line when the job is submitted.

```{warn}
Ranger is compute-intensive: It performs symbolic exploration of many function call sequences. For faster feedback, avoiding timeouts, and better resource usage, consider one of the following:

1. Use {ref}`--rule` to focus on a single invariant or rule.

2. Use {ref}`--split_rules` to automatically run each rule/invariant in a separate job.
```


## 4. View the Results
A link to the Ranger Job Report in the dashboard will be pasted in your command line 
when the job is submitted. 
You can explore the results in the web-based Ranger Report by following the link. 
