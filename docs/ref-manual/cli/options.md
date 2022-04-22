Certora Prover CLI Options
==========================

The `certoraRun` utility invokes the Solidity compiler and afterwards sends the job to Certora’s servers. 

The most commonly used command is:

```bash
certoraRun contractFile:contractName --verify contractName:specFile
```

If `contractFile` is named `contractName.sol`, the run command can be simplified to  
```bash
certoraRun contractFile --verify contractName:specFile
```

A short summary of these options can be seen by invoking `certoraRun --help`

```{contents} Overview
```

Modes of operation
------------------

The Certora Prover has three modes of operation. The modes are mutually exclusive - you cannot run the tool with more than one mode at a time.

(--verify)=
### `--verify`

**What does it do?**  
It runs formal verification of properties specified in a .spec file on a given contract. Each contract must have been declared in the input files or have the same name as the source code file it is in.  
**When to use it?**  
When you wish to prove properties on the source code. This is by far the most common mode of the tool.  
**Example**  
If we have a Solidity file `Bank.sol`, with a contract named `Bank` inside it, and a specification file called `Bank.spec`, the run command would be:  
`certoraRun Bank.sol --verify Bank:Bank.spec`

### `--assert`

**What does it do?**  
Replaces all EVM instructions that cause a non-benign revert in the smart contract with an assertion. Non-benign reverts include division by 0, bad dereference of an array, `throw` command, and more.  
Each contract must have been declared in the input files or have the same name as the source code file it is in.  
**When to use it?**  
When you want to see if a suspect instruction can fail in the code, without writing a `.spec` file.  
**Example**  
If we have a solidity file `Bank.sol`, with a contract named `Investor` inside it which we want to assert, we write:  
`certoraRun Bank.sol:Investor --assert Investor`

Most Frequently Used Options
----------------------------

### `--msg`

**What does it do?**

Adds a message description to your run, similar to a commit message. This message will appear in the title of the completion email sent to you. Note that you need to wrap your message in quotes if it contains spaces.  
**When to use it?**  
Adding a message makes it easier to track several runs. It is very useful if you are running many verifications simultaneously. It is also helpful to keep track of a single file verification status over time, so we recommend always providing an informative message.

**Example**  
To create the message above, we used  
`certoraRun Bank.sol --verify Bank:Bank.spec --msg 'Removed an assertion'`

### `--rule`

**What does it do?**  
Formally verifies a single property instead of the whole specification file. An invariant can also be selected.  
**When to use it?**  
This option saves a lot of run time. Use it whenever you care about only a single property. The most common case is when you add a new rule to an existing specification. The other is when code changes cause a specific rule to fail; in the process of fixing the code, updating the rule, and understanding counterexamples, you likely want to verify only that specific rule.  
**Example**  
If `Bank.spec` includes the following properties:  
`invariant address_zero_cannot_become_an_account()`

`rule withdraw_succeeds()`

If we want to verify only `withdraw_succeeds`, we run  
`certoraRun Bank.sol --verify Bank:Bank.spec --rule withdraw_succeeds`

Options affecting the type of verification run
----------------------------------------------

### `--multi_assert_check`

**What does it do?**

This mode checks each assertion statement that occurs in a rule, separately. The check is done by decomposing each rule into multiple sub-rules, each of which checks one assertion, while it assumes all preceding assertions. In addition, all assertions that originate from the Solidity code (as opposed to those from the specification), are checked together by a designated, single sub-rule.

As an illustrative example, consider the following rule `R` that has two assertions:

```cvl
…
assert a1
…
assert a2
…
```

The `multi_assert_check` mode would generate and check two sub-rules: `R1` where `a1` is proved while `a2` is removed, and `R2` where `a1` is assumed (i.e., transformed into a requirement statement), and `a2` is proved.

`R` passes if and only if, `R1` and `R2` both pass. In particular, in case `R1` (resp. `R2`) fails, the counter-example shows a violation of `a1` (resp. `a2`).

```{caution}
We suggest using this mode carefully. In general, as this mode generates and checks more rules, it may lead to worse running-time performance. Please see indications for use below.
```

**When to use it?**

When you have a rule with multiple assertions:

1.  As a timeout mitigation strategy: checking each assertion separately may, in some cases, perform better than checking all the assertions together and consequently solve timeouts.
    
2.  If you wish to get multiple counter-examples in a single run of the tool, where each counter-example violates a different assertion in the rule.
    

**Example**

`certoraRun Bank.sol --verify Bank:Bank.spec --multi_assert_check`

(--rule_sanity)=
### `--rule_sanity`

**What does it do?**
This mode will do some sanity checks for each rule, based on the attached value, which is allowed to be one of the following: `none`, `basic`, `advanced`.
There are 3 kinds of sanity checks:
1. Reachability- checks that even when ignoring all the user-provided assertions, the end of the rule is reachable. Namely, that the combination of requirements does not create an “empty” rule that is always true.

    An example of an “empty” rule:  
    ```cvl
    rule empty_rule() {
      ...
    }
    ```

    _We expect all rules to fail this check._ The exception is the fallback function, which might pass.

2. Assert-Vacuity- checks for each `assert` command in the rule, whether the `assert` is vacuously true.
An `assert` is considered to be vacuously true if after all the previous preconditions (`requires` and `if` statements where the `assert` is nested in) are removed, it evaluates to true on every example that reaches it.
For example, each `assert` with expression which is semantically equivalant to tautology, will be considered as vacuosly true.

3. Require-Redundancy- checks for each `require` command in the rule, whether the `require` is redundant.
A `require` is considered to be redundant if it can be removed without affecting the satisfiability of the rule.
For example, each `require` with expression which is semantically equivalant to tautology, will be considered as redundant.

The `rule_sanity` flag accepts one of the following values: `none`, `basic`, `advanced`, to control which sanity checks should be executed.
The `none` keyword behaves the same as not mentioning the `rule_sanity` flag in the configuration at all. No sanity-checks will be executed.
The `basic` keyword is intended for running only the reachability check for all the rules and the `assert-vacuity` check, but only for invariants.
Using the `advanced` keyword, all the sanity checks will be executed, for all the invariants/rules.
It is recommended to start with the `basic` mode, since using the `advanced` mode might results in some false positive alarms.

**When to use it?**  
We suggest using this option often - before each commit to changes of the source code or verification at the very least. Signs to suspect the rule is “empty“ is when it passes “too easily“ or too quickly.

**Example**

`certoraRun Bank.sol --verify Bank:Bank.spec --rule_sanity basic`

### `--short_output`

**What does it do?**  
Reduces the verbosity of the tool.

**When to use it?**  
When we do not care much for the output. It is recommended when running the tool in continuous integration.  

**Example**

`certoraRun Bank.sol --verify Bank:Bank.spec --short_output`

Options that control the Solidity compiler
------------------------------------------

### `--solc`

**What does it do?**  
Use this option to provide a path to the Solidity compiler executable file. We check in all directories in the `$PATH` environment variable for an executable with this name. If `--solc` is not used, we look for an executable called `solc`, or `solc.exe` on windows platforms.  
**When to use it?**  
Whenever you want to use a Solidity compiler executable with a non-default name. This is usually used when you have several Solidity compiler executable versions you switch between.  
**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --solc solc8.1`

### `--solc_args`

**What does it do?**  
Gets a list of arguments to pass to the Solidity compiler. The arguments will be passed as is, without any formatting, in the same order.  
**When to use it?**  
When the source code is compiled using non-standard options by the Solidity compiler.  
**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --solc_args "['--optimize', '--optimize-runs', '200']"`

### `--solc_map`

**What does it do?**  
Compiles every smart contract with a different Solidity compiler executable. All used contracts must be listed.  
**When to use it?**  
When different contracts have to be compiled for different Solidity versions.  
**Example**  
`certoraRun Bank.sol Exchange.sol --verify Bank:Bank.spec --solc_map Bank=solc4.25,Exchange=solc6.7`

### `--path`

**What does it do?**  
Use the given path as the root of the source tree instead of the root of the filesystem.  
**When to use it?**  
By default, we use `$PWD/contracts` if exists, else `$PWD`. If the root of the source tree is not the default, you must use `--path`.  
Example  
`certoraRun Bank.sol --verify Bank:Bank.spec --path ~/Projects/Bank`

### `--packages_path`

**What does it do?**  
Gets the path to a directory including the Solidity packages.  
**When to use it?**  
By default, we look for the packages in `$NODE_PATH`. If the packages are in any other directory, you must use `--packages_path`.  
**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --packages_path Solidity/packages`

### `--packages`

**What does it do?**  
For each package, gets the path to a directory including that Solidity package.  
**When to use it?**  
By default we look for the packages in `$NODE_PATH`. If there are packages are in several different directories, use `--packages`.  
**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --packages ds-stop=$PWD/lib/ds-token/lib/ds-stop/src ds-note=$PWD/lib/ds-token/lib/ds-stop/lib/ds-note/src`

Options regarding source code loops
-----------------------------------

(--optimistic_loop)=
### `--optimistic_loop`

**What does it do?**

The Certora Prover unrolls loops - if the loop should be executed three times, it will copy the code inside the loop three times. After we finish the loop's iterations, we add an assertion to verify we have actually finished running the loop. For example, in a `while (a < b)` loop, after the loop’s unrolling, we add `assert a >= b`. We call this assertion the _loop unwind condition_.  
This option changes the assertions of the loop unwind condition to requirements (in the case above `require a >= b`). That means, we ignore all the cases where the loop unwind condition does not hold, instead of considering them as a failure.  
**When to use it?**  
When you have loops in your code and are getting a counterexample labeled `loop unwind condition`. In general, you need this flag whenever the number of loop iterations varies. It is usually a necessity if using [`--loop_iter](#loop_iter). Note that `--optimistic_loop` could cause [vacuous rules](#rule_sanity).  
**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_loop`

(--loop_iter)=
### `--loop_iter`

**What does it do?**

Sets the maximal number of loop iterations we verify for. The way the Certora Prover handles loops is by unrolling them - if the loop should be executed three times, it will copy the code inside the loop three times. This option sets the number of unrolls. Be aware that the run time grows exponentially by the number of loop iterations.  
**When to use it?**  
The default number of loop iterations we unroll is one. However, in many cases, bugs only occur when there are several iterations. Common scenarios include iteration over list elements. Two, or in some cases three, is usually the most you will ever need to uncover bugs.  
**Example**

`certoraRun Bank.sol --verify Bank:Bank.spec --loop_iter 2`

Options that help reduce the running time
-----------------------------------------

### `--method`

**What does it do?**

Parametric rules will only verify the method with the given signature, instead of all public and external methods of the contract. Note that you will need to wrap the method’s signature with quotes, as the shell doesn’t interpret parenthesis correctly otherwise.

**When to use it?**  
When you are trying to solve/understand a counterexample of a parametric rule on a specific method.

**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --method 'withdraw(uint256,bool)'`

### `--cache`

**What does it do?**  
A cache in the cloud for optimizing the pre-analysis before running the SMT solvers. The cache used is the argument this option gets. If a cache with this name does not exist, it creates one with this name.  
**When to use it?**  
By default, we do not use a cache. If you want to use a cache to speed up the building process, use this option.  
**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --cache bank_regulation`

### `--smt_timeout`

**What does it do?**  
Sets the maximal timeout for all the [SMT solvers](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories). Gets an integer input, which represents seconds.  
The Certora Prover generates a logical formula from the specification and source code. Then, it passes it on to an array of SMT solvers. The time it can take for the SMT solvers to solve the equation is highly variable, and could potentially be infinite. This is why they must be limited in run time.  
**When to use it?**  
The default time out for the solvers is 600 seconds. There are two use cases for this option.  
One is to decrease the timeout. This is useful for simple rules, that are solved quickly by the SMT solvers. Here, it is beneficial to reduce the timeout, so that when a new code breaks the specification, the tool will fail quickly. This is the more common use case.  
The second use is when the solvers can prove the property, they just need more time. Usually, if the rule isn’t solved in 600 seconds, it will not be solved in 2,000 either. It is better to concentrate your efforts on simplifying the rule, the source code, add more summaries, or use other time-saving options. The prime causes for an increase of `--smt_timeout` are rules that are solved quickly, but time out when you add a small change, such as a requirement, or changing a strict inequality to a weak inequality.  
**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --smt_timeout 300`  

Options to set addresses and link contracts
-------------------------------------------

### `--link`

**What does it do?**  
Links a slot in a contract with another contract.  
**When to use it?**  
Many times a contract includes the address of another contract as one of its fields. If we do not use `--link`, it will be interpreted as any possible address, resulting in many nonsensical counterexamples.  
**Example**  
Assume we have the contract `Bank.sol` with the following code snippet:  
`IERC20 public underlyingToken;`

We have a contract `BankToken.sol`, and `underlyingToken` should be its address. To do that, we use:  
`certoraRun Bank.sol BankToken.sol --verify Bank:Bank.spec --link Bank:underlyingToken=BankToken`

See {doc}`/docs/confluence/advanced/linking` for more information.

### `--address`

**What does it do?**  
Sets the address of a contract to a given address.  
**When to use it?**  
When we have an external contract with a constant address. By default, the Python script assigns addresses as it sees fit to contracts.  
**Example**

If we wish the `Oracle` contract to be at address 12, we use  
`certoraRun Bank.sol Oracle.sol --verify Bank:Bank.spec --address Oracle:12`

### `--structLink`

**What does it do?**  
Links a slot in a struct with another contract. To do that you must calculate the slot number of the field you wish to replace.  
**When to use it?**  
Many times a contract includes the address of another contract inside a field of one of its structs. If we do not use `--link`, it will be interpreted as any possible address, resulting in many nonsensical counterexamples.  
**Example**  
Assume we have the contract `Bank.sol` with the following code snippet:  
`TokenPair public tokenPair;`

Where `TokenPair` is  
`struct TokenPair {`  
`IERC20 tokenA;`

`IERC20 tokenB;`

`}`

We have two contracts `BankToken.sol` and `LoanToken.sol`. We want `tokenA` of the `tokenPair` to be `BankToken`, and `tokenB` to be `LoanToken`. Addresses take up only one slot. We assume `tokenPair` is the first field of Bank (so it starts at slot zero). To do that, we use:  
`certoraRun Bank.sol BankToken.sol LoanToken.sol --verify Bank:Bank.spec --structLink Bank:0=BankToken Bank:1=LoanToken`

Debugging options
-----------------

### `--debug`

**What does it do?**  
Adds debug prints to the output of the run.  
**When to use it?**  
When the tool has an error you do not understand.  
**Example**  
`certoraRun Bank.sol Oracle.sol --verify Bank:Bank.spec --debug`

### `--version`

**What does it do?**  
Shows the version of the local installation of the tool you have.

**When to use it?**  
When you suspect you have an old installation. To install the newest version, use `pip install --upgrade certora-cli`.  
**Example**

`certoraRun --version`

### `--typecheck_only`

**What does it do?**  
Stops after running the Solidity compiler and typechecking of the spec, before submitting the verification task.

**When to use it?**  
If you want only to check your spec, or include it in an automated task (e.g., a git pre-commit hook).  
**Example**

`certoraRun Bank.sol --verify Bank:bank.spec --typecheck_only`

Advanced options
----------------

### `--javaArgs`

**What does it do?**

Allows setting configuring the underlying JVM.

**When to use it?**

Upon instruction from the Certora team.

**Example**

`--javaArgs '"-Dcvt.default.parallelism=2"'` - will set the number of “tasks” that can run in parallel to 2.

### `--rerun_verification`

**What does it do?**  
Repeats a previous run, but skips CVL compilation and TAC optimization phases for a single rule, by using a saved binary file from a previous run.

**When to use it?**  
When you want to run the same configuration, but save some run-time (for example when encountering a timeout). This should be used with the same parameters to the solver (i.e. same source, specs and optimization configurations). To save a binary to rerun use `--settings -saveRerunData`, and the binary file will be save in outputs.  
**Example**

`certoraRun Bank.sol --verify Bank:bank.spec --settings -saveRerunData`

`certoraRun Bank.sol --verify Bank:bank.spec --rerun_verification rerun_checkBank.rerunbin`

