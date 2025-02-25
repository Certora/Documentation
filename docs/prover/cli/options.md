(prover-cli-options)=
CLI Options
===========

The `certoraRun` utility invokes the Solidity compiler and afterwards sends the job to Certora's servers. 

The most commonly used command is:

```sh
certoraRun contractFile:contractName --verify contractName:specFile
```

If `contractFile` is named `contractName.sol`, the run command can be simplified to
```sh
certoraRun contractFile --verify contractName:specFile
```

A short summary of these options can be seen by invoking `certoraRun --help`

For larger projects, the command line for running the Certora Prover can become large
and cumbersome. It is therefore recommended to use configuration files instead.
These are [JSON5](https://json5.org/) files (with `.conf` extension) that hold the parameters and options for the Prover.
See {ref}`conf-files` for more information.

```{contents} Overview
```

Most frequently used options
============================

(--verify)=
## `--verify`

**Usage**
```sh
--verify <contract>:<spec_file>
```

**What does it do?**
It runs formal verification of properties specified in a .spec file on a given contract. Each contract must have been declared in the input files or have the same name as the source code file it is in.

**When to use it?**
When you wish to prove properties on the source code. This is by far the most common mode of the tool.

**Example**
If we have a Solidity file `Bank.sol`, with a contract named `Bank` inside it, and a specification file called `Bank.spec`, the run command would be:
```sh
certoraRun Bank.sol --verify Bank:Bank.spec
```

(--msg)=
## `--msg`

**Usage**
```sh
--msg <description>
```

**What does it do?**
Adds a message description to your run, similar to a commit message. This message will appear in the title of the completion email sent to you. 

```{note}
You need to wrap your message in quotes if it contains spaces.
```

**When to use it?**
Adding a message makes it easier to track several runs on [the Prover Dashboard](https://prover.certora.com/). It is very useful if you are running many verifications simultaneously. It is also helpful to keep track of a single file verification status over time, so we recommend always providing an informative message.

**Example**
To create the message above, we used
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --msg 'Removed an assertion'
```

(--rule)=
## `--rule`

**Usage**
```sh
--rule <rule_name_pattern>...
```

**What does it do?**
Formally verifies one or more given properties instead of the whole specification file. An invariant can also be selected.

**When to use it?**
This option saves a lot of run time. Use it whenever you care about only a
specific subset of a specification's properties. The most common case is when
you add a new rule to an existing specification. The other is when code changes
cause a specific rule to fail; in the process of fixing the code, updating the
rule, and understanding counterexamples, you likely want to verify only that
specific rule.

One can either specify a specific rule name, or use pattern matching with a `*`.

You can specify this flag multiple times to filter in several rules or rule patterns.

**Example**
If `Bank.spec` includes the following properties:

```cvl
invariant address_zero_cannot_become_an_account()
rule withdraw_succeeds()
rule withdraw_fails()
```

If we want to verify only `withdraw_succeeds`, we run
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --rule withdraw_succeeds
```

If we want to verify both `withdraw_succeeds` and `withdraw_fails`, we run
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --rule withdraw_succeeds withdraw_fails
```

Alternatively, to verify both `withdraw_succeeds` and `withdraw_fails`, we could
simply run 
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --rule withdraw*
```

(--exclude_rule)=
## `--exclude_rule`

**Usage**
```sh
--exclude_rule <rule_name_pattern>...
```

**What does it do?**
This flag is the opposite of {ref}`--rule` - it allows you to specify a list of rules that _should not_ be run.

You can specify this flag multiple times to filter out several rules or rule patterns.

**When to use it?**
Use this flag when certain rules take too long to run or require a different configuration than the current verification run.

**Example**
If `Bank.spec` includes the following properties:

```cvl
invariant address_zero_cannot_become_an_account()
rule withdraw_succeeds()
rule withdraw_fails()
```

If we want to skip both rules we could run
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --exclude_rule withdraw*
```

(--split_rules)=
## `--split_rules`

**Usage**
```sh
--split_rules <rule_name_pattern>...
```

**What does it do?**
Typically, all rules (after being filtered by {ref}`--rule` and {ref}`--exclude_rule`) are evaluated in a single Prover job.
With `--split_rules` the user can run specific rules on separate dedicated Prover jobs. A new job will be created and 
executed for each rule that matches the rule patterns in `--split_rules` an additional job will be created for
the rest of the rules. After launching the generated jobs, the original job will return with a link to the dashboard, 
listing the status of the generated jobs.

You can specify this flag multiple times to denote several rules or rule patterns.

**When to use it?**
This option is useful when some rules take a much longer time than the rest. Split the difficult rules to 
their own dedicated Prover jobs will give them more resources that will potentially reduce their chance to 
timeout and will decrease the time to get the final job result for the less computationally intensive rules. 

**Example**
If `Bank.spec` includes the following properties:

```cvl
invariant address_zero_cannot_become_an_account()
rule withdraw_succeeds()
rule withdraw_fails()
```

If we want to run the invariant on different Prover jobs we could run
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --split_rules address_zero_cannot_become_an_account
```

The rest of the rules (`withdraw_succeeds` and `withdraw_fails`) will run together in a different Prover job.

```{note}
When used together with the {ref}`--rule` flag the logic is to collect all rules
that pass the `--rule` flag(s) and then subtract from them all rules that match
any {ref}`--exclude_rule` flag(s).
```

(--method)=
## `--method`

**Usage**
```sh
--method <method_signature>...
```

**What does it do?**
Only uses functions with the given method signature when instantiating
{term}`parametric rule`s and {term}`invariant`s. The method signature is the ABI
representation of the method, optionally prepended by a contract name or
wildcard (`_`). If no contract is specified the primary contract is assumed, and
if the wildcard is used then all methods with this signature across all
contracts in the {term}`scene` will be used.

You may provide multiple method signatures, in which case the Prover will run on
each of the listed methods.

**When to use it?**
This option is useful when focusing on a specific counterexample; running on a
specific contract method saves time.

**Example**
Suppose we are verifying an ERC20 contract, and we have the following
{term}`parametric rule`:

```cvl
rule r {
    method f; env e; calldataarg args;
    address owner; address spender;

    mathint allowance_before = allowance(owner, spender);
    f(e,args);
    mathint allowance_after  = allowance(owner, spender);

    assert allowance_after > allowance_before => e.msg.sender == owner;
}
```

If we discover a counterexample in the method `deposit(uint)` of contract `C`,
and wish to change the contract or the spec to rerun, we can just rerun on
the `C.deposit` method:

```sh
certoraRun --method 'C.deposit(uint)'
```

If we discover a counterexample in several methods, we could rerun just those:

```sh
certoraRun --method 'deposit(uint)' --method '_.transfer(address,uint256)'
```

In the last example the `transfer` method of all contracts in the
scene will be used, but only the `deposit` method of the primary contract.

```{note}
Many shells will interpret the `(` and `)` characters specially, so
the method signature argument will usually need to be quoted as in the example.
```

(--parametric_contracts)=
## `--parametric_contracts`

```{versionadded} 5.0
Prior to version 5, method variables and invariants were only instantiated with
methods of {ref}`currentContract`.
```

**Usage**
```sh
--parametric_contracts <contract_name>...
```

**What does it do?**
Only uses methods on the specified contract when instantiating
{term}`parametric rule`s or {term}`invariant`s.  The contract name must be one
of the contracts included in the {term}`scene`.

**When to use it?**
As with the {ref}`--rule` and {ref}`--method` options, this option is used to
avoid rerunning the entire verification

**Example**
Suppose you are working on a multicontract verification and wish to debug a
counterexample in a method of the `Underlying` contract defined in the file
`Example.sol`:

```sh
certoraRun Main:Example.sol Underlying:Example.sol --verify Main:Example.spec \
    --parametric_contracts Underlying
```

(--wait-for-results)=
## `--wait_for_results`

**What does it do?**
Wait for verification results after sending the verification request.
By default, the program exits after the request.
The return code will not be zero if the verification finds a violation.

**When to use it?**
Use it to receive verification results in the terminal or a wrapping script.

In CI, the default behavior is different: the Prover waits for verification results,
and the return code will not be zero if a violation is found.
You can force the Prover not to wait for verification results by using `--wait_for_results NONE`.
In that case, the return code will be zero if the jobs were sent successfully.

**Example**
```sh
certoraRun Example.sol --verify Example:Example.spec --wait_for_results
```

Options affecting the type of verification run
==============================================

(--coverage_info)=
## `--coverage_info`

**Usage**
```sh
--coverage_info <none|basic|advanced>
```

**What does it do?**
This option enables .sol and .spec coverage analysis and visualization.  The `--coverage_info` option may
be followed by one of `none`, `basic`, or `advanced`;
See {doc}`../checking/coverage-info` for more information about the analysis.

**When to use it?**
We suggest using this option when you have finished (a subset of) your rules and the prover verified them. The analysis tells you which parts of the solidity input are covered by the rules, and also which parts of the rules are actually needed to prove the rules.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --coverage_info advanced
```

(--foundry)=
## `--foundry`

**What does it do?**
Collects all test files in the project (files ending with `.t.sol`), and runs
the {ref}`foundry_integration` on them (specifically, the
`verifyFoundryFuzzTestsNoRevert` builtin rule). As with the
{ref}`--project_sanity` option, the search is over files in the current git
repository if such exists, otherwise over all files in the tree under the
current working directory.

```{note}
This option implicitly enables the {ref}`--auto_dispatcher` option.
```


**When to use it?**
When we want to run all foundry fuzz tests in the project with the prover.

**Example**
```sh
certoraRun --foundry
```

(--independent_satisfy)=
## `--independent_satisfy`

**What does it do?**
The independent satisfy mode checks each {ref}`satisfy statement <satisfy>` independently from all other satisfy statements that occurs in a rule.
Normally, each satisfy statement will be turned into a sub-rule (similarly to the {ref}`--multi_assert_check` mode),
but previously encountered satisfy statements will be still considered when creating a satisfying assignment.

As an illustrative example of the default mode, consider the following rule `R` that has two satisfy statements:

```cvl
rule R {
  bool b;
  satisfy b, "R1";
  satisfy !b, "R2";
}
```

The statements for "R1" and "R2" will actually create two sub-rules equivalent to:
```cvl
rule R1_default {
  bool b;
  satisfy b, "R1";
}

rule R2_default {
  bool b;
  // Previous satisfy statements are required in default mode.
  require b; // R1
  // Due to requiring `b`, this satisfy statement is equivalent to 'satisfy b && !b, "R2";'
  satisfy !b, "R2";
}
```

Without turning `independent_satisfy` mode on, `R2` would have failed, as it would try to satisfy `b && !b`, an unsatisfiable contradiction.
Turning on the `independent_satisfy` mode will ignore all currently unchecked satisfy statements for each sub-rule.
It would also generate and check two sub-rules, but with a slight difference: `R1` where `b` is satisfied (by `b=true`) while `satisfy !b` is removed, and `R2` where `satisfy b` is removed, and `!b` is satisfied (by `b=false`).

The two `independent_satisfy` generated sub-rules will be equivalent to:

```cvl
rule R1_independent {
  bool b;
  satisfy b, "R1";
}

rule R2_independent {
  bool b;
  // require b;
  satisfy !b, "R2";
}
```

**When to use it?**
When you have a rule with multiple satisfy statements, and you would like to demonstrate each statement separately.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --independent_satisfy
```

(--multi_assert_check)=
## `--multi_assert_check`

**What does it do?**
This mode checks each assertion statement that occurs in a rule, separately. The check is done by decomposing each rule into multiple sub-rules, each of which checks one assertion, while it assumes all preceding assertions. In addition, all assertions that originate from the Solidity code (as opposed to those from the specification), are checked together by a designated, single sub-rule.

As an illustrative example, consider the following rule `R` that has two assertions:

```cvl
...
assert a1
...
assert a2
...
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
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --multi_assert_check
```

(--project_sanity)=
## `--project_sanity`

**What does it do?**
Runs the builtin sanity rule on all methods in the project. If the Prover is run
from within a git project, all `.sol` files in the in the git repository are added
to the scene and the {ref}`builtin sanity rule <built-in-sanity>` is run on
them. Otherwise, _all_ `.sol` files in the tree under the current working
directory are collected.

Alternatively, a list of files can be provided in the `.conf` file and then the
builtin sanity rule will run on all methods of the specified files.

```{Note}
This option implicitly enables the {ref}`--auto_dispatcher` option.
```

**When to use it?**
Mostly used as a first step when starting to work on a new project, in order to
"get a feeling" of the complexity of the project for the tool, and what methods
may be hot spots for summarization etc.

**Example**
```sh
certoraRun --project_sanity
```

(--rule_sanity)=
## `--rule_sanity`

**Usage**
```sh
--rule_sanity <none|basic|advanced>
```

**What does it do?**
This option enables sanity checking for rules.  The `--rule_sanity` option may
be followed by one of `none`, `basic`, or `advanced`;
See {doc}`../checking/sanity` for more information about sanity checks.

**When to use it?**
We suggest using this option routinely while developing rules.  It is also a
useful check if you notice rules passing surprisingly quickly or easily.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --rule_sanity basic
```

(--short_output)=
## `--short_output`

**What does it do?**
Reduces the verbosity of the tool.

**When to use it?**
When we do not care much for the output. It is recommended when running the tool in continuous integration.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --short_output
```

Options that control the Solidity compiler
==========================================
(--compiler_map)=
(--solc_map)=
## `--compiler_map`

**Usage**
```sh
--compiler_map <contract>=<version>,...
```

**What does it do?**
Compiles every smart contract with a different compiler executable (Solidity version or Vyper). All used contracts must be listed.

**When to use it?**
When different contracts have to be compiled for different Solidity versions.

**Example**
```sh
certoraRun Bank.sol Exchange.sol Token.vy --verify Bank:Bank.spec --compiler_map Bank=solc4.25,Exchange=solc6.7,Token=vyper0.3.10
```

(--packages)=
## `--packages`

**Usage**
```sh
--packages <name>=<path>...
```

**What does it do?**
For each package, gets the path to a directory including that Solidity package.

**When to use it?**
By default we look for the packages in `$NODE_PATH`. If there are packages are in several different directories, use `--packages`.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --packages ds-stop=$PWD/lib/ds-token/lib/ds-stop/src ds-note=$PWD/lib/ds-token/lib/ds-stop/lib/ds-note/src
```

```{note}
In Solidity projects, information about packages' location is usually stored in `remappings.txt` file. 
```

(--packages_path)=
## `--packages_path`

**Usage**
```sh
--packages_path <path>
```

**What does it do?**
Gets the path to a directory including the Solidity packages.

**When to use it?**
By default, we look for the packages in `$NODE_PATH`. If the packages are in any other directory, you must use `--packages_path`.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --packages_path Solidity/packages
```

(--solc)=
## `--solc`

**Usage**
```sh
--solc <solc_executable>
```

**What does it do?**
Use this option to provide a path to the Solidity compiler executable file. We check in all directories in the `$PATH` environment variable for an executable with this name. If `--solc` is not used, we look for an executable called `solc`, or `solc.exe` on windows platforms.

**When to use it?**
Whenever you want to use a Solidity compiler executable with a non-default name. This is usually used when you have several Solidity compiler executable versions you switch between.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --solc solc8.1
```

(--solc_allow_path)=
## `--solc_allow_path`

**Usage**
```sh
--solc_allow_path <path>
```

**What does it do?**
Passes the value of this option as is to the solidity compiler's option `--allow-paths`.
See [--allow-path specification](https://docs.soliditylang.org/en/v0.8.16/path-resolution.html#allowed-paths)

**When to use it?**
When we want to add an additional location the Solidity compiler to load sources from

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --solc_allow_path ~/Projects/Bank
```

(--solc_evm_version)=
## `--solc_evm_version`

**Usage**
```sh
--solc_evm_version <version>
```

**What does it do?**
Passes the value of this option  to the solidity compiler's option `--evm-version`.

**When to use it?**
When we want to select the Solidity compiler EVM version

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --solc_evm_version Istanbul
```

(--solc_evm_version_map)=
## `--solc_evm_version_map`

**Usage**
```sh
--solc_evm_version_map <contract>=<version>,...
```

**What does it do?**
Set EVM version values when different files run with different EVM versions
Passes the value of this option as is to the solidity compiler's option `--evm-version`.

**When to use it?**
When different contracts have to be compiled with different Solidity EVM versions.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --solc_evm_version_map Bank=prague,Exchange=cancun
```

(--solc_optimize)=
## `--solc_optimize`

**Usage**
```sh
--solc_optimize <n>
```

**What does it do?**
Passes the value of this option as is to the solidity compiler's option `--optimize` and `--optimize-runs`.

**When to use it?**
When we want to activate in the solidity compiler the opcode-based optimizer for the generated bytecode and control the
number of times the optimizer will be activated (if no value is set, the compiler's default is 200 runs)

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --solc_optimize 300
```

(--solc_optimize_map)=
## `--solc_optimize_map`

**Usage**
```sh
--solc_optimize_map <contract>=<n>,...
```

**What does it do?**
Set optimize values when different files run with different number of runs
Passes the value of this option as is to the solidity compiler's option `--optimize` and `--optimize-runs`.

**When to use it?**
When we want to activate in the solidity compiler the opcode-based optimizer for the generated bytecode and control the
number of times the optimizer will be activated (if no value is set, the compiler's default is 200 runs)

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --solc_optimize_map Bank=200,Exchange=300
```


(--solc_via_ir)=
## `--solc_via_ir`

**What does it do?**
Passes the value of this option  to the solidity compiler's option `--via-ir`.

**When to use it?**
When we want to enable the IR-based code generator

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --solc_via_ir
```

Options regarding source code loops
===================================

(--loop_iter)=
## `--loop_iter`

**Usage**
```sh
--loop_iter <n>
```

**What does it do?**
Sets the maximal number of loop iterations we verify for. The way the Certora Prover handles loops is by unrolling them - if the loop should be executed three times, it will copy the code inside the loop three times. This option sets the number of unrolls. Be aware that the run time grows exponentially by the number of loop iterations.

**When to use it?**
The default number of loop iterations we unroll is one. However, in many cases, bugs only occur when there are several iterations. Common scenarios include iteration over list elements. Two, or in some cases three, is usually the most you will ever need to uncover bugs.

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --loop_iter 2
```

(--optimistic_loop)=
## `--optimistic_loop`

**What does it do?**
The Certora Prover unrolls loops - if the loop should be executed three times, it will copy the code inside the loop three times. After we finish the loop's iterations, we add an assertion to verify we have actually finished running the loop. For example, in a `while (a < b)` loop, after the loop's unrolling, we add `assert a >= b`. We call this assertion the _loop unwind condition_.
This option changes the assertions of the loop unwind condition to requirements (in the case above `require a >= b`). That means, we ignore all the cases where the loop unwind condition does not hold, instead of considering them as a failure.

**When to use it?**
When you have loops in your code and are getting a counterexample labeled `loop unwind condition`. In general, you need this flag whenever the number of loop iterations varies. It is usually a necessity if using {ref}`--loop_iter`. 

```{caution}
`--optimistic_loop` could cause {ref}`vacuous rules <--rule_sanity>`.
```

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_loop
```

Options regarding summarization
===============================

(--auto_dispatcher)=
## `--auto_dispatcher`

**What does it do?**
In case a call's callee cannot be precomputed but the called method's sighash
can be (e.g. `MyInterface(addr).foo()` in solidity, where `addr` is some
`address` typed variable), the default behavior of the Prover in this case is to
Havoc. In this case the user can specify a {ref}`dispatcher` summary in the
{ref}`methods-block` so that the prover will inline all methods in the scene
that have this sighash.

This option will cause all such unknown callee with known sighash cases to behave
as if an `DISPATCHER(optimistic=true)` was added for that method in the methods
block.

One important difference from manually placing the `DISPATCHER` summary in the
methods block is that when it's manually written there with `optimistic=true`
and no such function is found in the scene the Prover will exit with an error,
but when using the flag it will fall back to the default havoc.

**When to use it?**
When there are many unresolved callee methods, or as a first step to solve
call resolution failures.

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --auto_dispatcher
```

(--nondet_difficult_funcs)=
## `--nondet_difficult_funcs`

**What does it do?**
When this option is set, the Prover will auto-summarize
view or pure internal functions that return a value type and are
currently not summarized, and that are found to be heuristically difficult
for the Prover.

For more information, see {ref}`detect-candidates-for-summarization`.

**When to use it?**
Using this option is recommended when beginning to work on a large code
base that includes functions that could be difficult for the Prover.
It can help the user get faster feedback, both in the form of faster
verification results, as well as highlighting potentially difficult functions.

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --nondet_difficult_funcs
```

(--nondet_minimal_difficulty)=
## `--nondet_minimal_difficulty`

**Usage**
```sh
--nondet_minimal_difficulty <n>
```

**What does it do?**
This option sets the minimal difficulty threshold for the auto-summarization mode enabled by {ref}`--nondet_difficult_funcs`.

**When to use it?**
If the results of an initial run with {ref}`--nondet_difficult_funcs` were unsatisfactory,
one can adjust the default threshold to apply the auto-summarization to potentially more or fewer internal functions.

The notification in the rule report that contains the applied summaries will present the current threshold used by the Prover.

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --nondet_difficult_funcs --nondet_minimal_difficulty 20
```

(--optimistic_summary_recursion)=
## `--optimistic_summary_recursion`

**What does it do?**
In case there's a call to some Solidity function within a summary, we may end up
with recursive calls to this summary. For example, if in the summary of `foo` we
call the Solidity function `bar`, and `bar`'s Solidity code contains a call to
`foo`, we'll summarize `foo` again, which will lead to another call to `bar`
etc. In this case if this flag is set to `false` we may get an assertion failure
with a message along the lines of
```text
Recursion limit (...) for calls to ..., reached during compilation of summary ...
```
Such recursion can also happen with {ref}`dispatcher summaries <dispatcher>` &mdash;
if a contract method `f` makes an unresolved external call to a different method
`f`, and if `f` is summarized with a `DISPATCHER` summary, then the Prover will
consider paths where `f` recursively calls itself. Without `--optimistic_summary_recursion`,
the Prover may report a rule violation with the following assert message:
```text
When summarizing a call with dispatcher, found we already have it in the stack: ... consider removing its dispatcher summary.
```
The default behavior in this case is to assert that the recursion limit is not
reached (the limit is controlled by the {ref}`--summary_recursion_limit` flag).
With `--optimistic_summary_recursion`, the Prover will instead assume that the
limit is never reached.

**When to use it?**
Use this flag when there is recursion due to summaries calling Solidity
functions, and this causes an undesired assertion failure. In this case one can
either make the limit larger (via {ref}`--summary_recursion_limit`) or set this
flag to `true`.

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_summary_recursion
```

```{caution}
This flag could cause unsoundness - even if such recursion
_could_ actually happen in the deployed contract, this code-path won't be verified.
```

(--summary_recursion_limit)=
## `--summary_recursion_limit`

**Usage**
```sh
--summary_recursion_limit <n>
```

**What does it do?**
Summaries can cause recursion (see {ref}`--optimistic_summary_recursion`). This
option sets the summary recursion level, which is the number of recursive calls
that the Prover will consider.

If the Prover finds an execution in which a function is called recursively more
than the contract recursion limit, the Prover will report an assertion failure (unless
{ref}`--optimistic_summary_recursion` is set, in which case the execution
will be ignored).
The default value is zero (i.e. no recursion is allowed).

**When to use it?**
1. Use this option when there is recursion due to summaries calling Solidity
functions, and this leads to an assertion failure. In this case one can either
make the limit larger or set (via {ref}`--optimistic_summary_recursion`) flag
to `true`.

2. Use it if you get the following assertion failure, and disabling {ref}`optimistic fallback <-optimisticFallback>` is not possible: 
```text
When inlining a fallback function, found it was already on the stack. Consider disabling optimistic fallback mode.
```

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --summary_recursion_limit 3
```


Options regarding hashing of unbounded data
===========================================

(--optimistic_hashing)=
## `--optimistic_hashing`

**What does it do?**

When hashing data of potentially unbounded length (including unbounded arrays,
like `bytes`, `uint[]`, etc.):

1. If `optimistic_hashing` is set the Proves _assumes_
   the data's length is bounded by the `--hashing_length_bound` option.
2. If `optimistic_hashing` is not set, the Prover will check whether
   the data's length can exceed the `hashing_length_bound`, and report an
   assertion violation if it can.

See {ref}`hashing_unbounded` for more details.


**When to use it?**

When the assertion regarding unbounded hashing is thrown, but it is acceptable for the Prover to ignore cases where the length hashed values exceeds the current bound.

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_hashing
```

(--hashing_length_bound)=
## `--hashing_length_bound`

**Usage**
```sh
--hashing_length_bound <n>
```

**What does it do?**

Constraint on the maximal length of otherwise unbounded data chunks that are being hashed. This constraint is either assumed or checked by the Prover, depending on whether `--optimistic_hashing` has been set. The bound is specified as a number of bytes.

The default value of this option is 224 (224 bytes correspond to 7 EVM machine words as 7 * 32 == 224).

**When to use it?**
Reason to lower this value:

Lowering potentially improves SMT performance, especially if there are many occurrences of unbounded hashing in the program.

Reasons to raise this value:

 - when `--optimistic_hashing` is not set: avoid the assertion being violated when the hashed values are actually bounded, but by a bound that is higher than the default value (in case of `--optimistic_hashing` being not set)
 - when `--optimistic_hashing` is set: find bugs that rely on a hashed array being at least of that length. (Optimistic hashing excludes all cases from the scope of verification where something being hashed is longer than this bound.)

**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --hashing_length_bound 128
```


Options that help reduce the running time
=========================================

(--compilation_steps_only)=
## `--compilation_steps_only`

**What does it do?**
Exits the program after source code and spec compilation without sending
a verification request to the cloud.

**When to use it?**
Use it to check if the spec has correct syntax but do not wish
to send a verification request and wait for its results.

Here are a few example scenarios:
1. When writing hooks, ghosts, summaries, or CVL functions, you can verify the spec before continuing to write rules.
2. In CI, you can check CVL correctness after every PR but run the expensive and long verification only on nightly runs.
3. When you have no internet connection but still want to develop spec offline.

**Example**
```sh
certoraRun Example.sol --verify Example:Example.spec --compilation_steps_only
```

## `--disable_local_type_checking`

**What does it do?**

This flag disables the local syntax and type checking of your CVL specifications before they are sent to the cloud for verification. When used, simple syntax or type errors will not be caught locally and will only become visible during the cloud run, potentially causing unnecessary delays and confusion.

**When to use it?**

This flag should only be used in rare cases when you believe the local syntax or type checking has produced an incorrect error, and you are confident that the specification is valid. Before using this flag, it is recommended to first attempt reinstalling the Prover by following the instructions in the {ref}`installation` section. Using this flag is **strongly discouraged** as it bypasses an essential layer of error detection, increasing the likelihood of issues being encountered later during the verification process.

**Example**

```sh
certoraRun MyContract.sol --verify MyContract:MySpec --disable_local_typechecking
```

```{caution}
Avoid using this flag unless absolutely necessary. It is always better to fix syntax or type issues locally to ensure a smoother verification process.
```


(--global_timeout)=
## `--global_timeout`

**Usage**
```sh
--global_timeout <seconds>
```

**What does it do?**

Sets the maximal timeout for the Prover.
Gets an integer input, which represents seconds.

The Certora Prover is bound to run a maximal time of 2 hours (7200 seconds).
Users may opt to set this number lower to facilitate faster iteration on specifications.
Values larger than two hours (7200 seconds) are ignored.

Jobs that exceed the global timeout will simply be terminated, so the result
reports may not be generated.

The global timeout is different from the {ref}`--smt_timeout` option: the
`--smt_timeout` flag constrains the amount of time allocated to the processing
of each individual rule, while the `--global_timeout` flag constrains the
processing of the entire job, including static analysis and other
preprocessing.

**When to use it?**
When running on just a few rules, or when willing to make faster iterations on specs without waiting too long for the entire set of rules to complete.

```{note}
Even if in the shorter running time not all rules were processed, a second run may pull some results from cache, and therefore more results will be available.
```

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --global_timeout 60
```

## `--method`

See {ref}`--method`

(--smt_timeout)=
## `--smt_timeout`

**Usage**
```sh
--smt_timeout <seconds>
```

**What does it do?**
Sets the maximal timeout for all the
[SMT solvers](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories).
Gets an integer input, which represents seconds.

The Certora Prover generates a logical formula from the specification and
source code. Then, it passes it on to an array of SMT solvers. The time it can
take for the SMT solvers to solve the equation is highly variable, and could
potentially be infinite. This is why they must be limited in run time.

The SMT timeout applies separately to each individual rule (or each method
for parametric rules). To set the global timeout, see {ref}`--global_timeout`.

```{note}
While this is the most prominent timeout, this is not the only timeout that
applies to SMT solvers, for details see {ref}`-mediumTimeout` and
{ref}`control-flow-splitting`.
```

**When to use it?**
The default time out for the solvers is 300 seconds. There are two use cases for this option.
One is to decrease the timeout. This is useful for simple rules, that are solved quickly by the SMT solvers. Here, it is beneficial to reduce the timeout, so that when a new code breaks the specification, the tool will fail quickly. This is the more common use case.
The second use is when the solvers can prove the property, they just need more time. Usually, if the rule isn't solved in 600 seconds, it will not be solved in 2,000 either. It is better to concentrate your efforts on simplifying the rule, the source code, add more summaries, or use other time-saving options. The prime causes for an increase of `--smt_timeout` are rules that are solved quickly, but time out when you add a small change, such as a requirement, or changing a strict inequality to a weak inequality.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --smt_timeout 300
```


Options to set addresses and link contracts
===========================================

(--address)=
## `--address`

**Usage**
```sh
--address <contract>:<address>
```

**What does it do?**
Sets the address of a contract to a given address.

**When to use it?**
When we have an external contract with a constant address. By default, the Python script assigns addresses as it sees fit to contracts.

**Example**

If we wish the `Oracle` contract to be at address 12, we use
```sh
certoraRun Bank.sol Oracle.sol --verify Bank:Bank.spec --address Oracle:12
```

(--contract_extensions)=
## `--contract_extensions`

**What does it do?**
In order to support extendability and upgradeability of smart contracts, the proxy
pattern is used. In this patterns there is a base contract (the proxy) which delegate-calls
into "extension" contracts (see e.g. https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies
for more details).
This flag allows specifying that some contract is actually an extension of another one, to help the Prover
analyze low-level calls and resolve them correctly in this case.
In practice the Prover "moves" all the external function implementations from the
extension contract into the base contract, which means that to access them from CVL
one should use the _base_ contract as the receiver, and not the extension contract.

**When to use it?**
If you use the proxy pattern in your smart contracts.

**Example**
Say we have a base contract `A` that uses an extension contract `B`.
Since in this pattern the storage of the two contracts may "overlap", let's also
assume they both have some `uint public n`.
In the .conf file one should add
```json
"contract_extensions": {
    "A": [
        {
            "extension": "B",
            "exclude": ["n"]
        }
    ]
}
```

This tells the prover that `B` is an extension contract of `A`, but that it shouldn't
"transfer" the getter for n from the extension into the base contract (since the base
contract already has such a function and this would cause a conflict).

[For a more detailed example click here.](https://github.com/Certora/Examples/tree/master/CVLByExample/ExtensionContracts)


(--contract_recursion_limit)=
## `--contract_recursion_limit`

**Usage**
```sh
--contract_recursion_limit <n>
```

**What does it do?**
Contract inlining can cause recursion (see {ref}`--optimistic_contract_recursion`). This
option sets the contract recursion level, which is the number of recursive calls
that the Prover will consider when inlining contracts linked using, e.g., `--link` or `--struct_link`.

```{note}
In this context, recursion refers to the state where the same _external_ function
appears twice in the call stack.
Contracts can also exhibit recursive behavior due to recursive calls to _internal_ functions,
which is unrelated to this option.
```

If a counterexample causes a function to be called recursively more than the
contract recursion limit, it will report an assertion failure (unless
{ref}`--optimistic_contract_recursion` is set, in which case the counterexample
will be ignored).
The default value is zero (i.e., no recursion is allowed).

**When to use it?**
Use this option when after linking the resulting program may have paths
with recursive calls to external Solidity
functions, and this leads to a recursion-specific assertion failure,
showing the message `Contract recursion limit reached`.
In this case one can either
make the limit larger or set `--optimistic_contract_recursion` flag
to `true`.

```{note}
Increasing the limit is not always sufficient,
as the code may in fact allow theoretically unbounded recursion.
```


**Example**

```sh
certoraRun Bank.sol --verify Bank:Bank.spec --contract_recursion_limit 3
```

(--link)=
## `--link`

**Usage**
```sh
--struct_link <contract>:<slot>=<address>
```

**What does it do?**
Links a slot in a contract with another contract.

**When to use it?**
Many times a contract includes the address of another contract as one of its fields. If we do not use `--link`, it will be interpreted as any possible address, resulting in many nonsensical counterexamples.

**Example**
Assume we have the contract `Bank.sol` with the following code snippet:
`IERC20 public underlyingToken;`

We have a contract `BankToken.sol`, and `underlyingToken` should be its address. To do that, we use:
```sh
certoraRun Bank.sol BankToken.sol --verify Bank:Bank.spec --link Bank:underlyingToken=BankToken
```

(--optimistic_contract_recursion)=
## `--optimistic_contract_recursion`

**What does it do?**
Contract linking can cause recursion (see also {ref}`--contract_recursion_limit`).
This option sets the Prover to optimistically assume that recursion cannot go
beyond what is defined by {ref}`--contract_recursion_limit`,
but only if {ref}`--contract_recursion_limit` is set to a number higher than 0.

**When to use it?**
1. When the recursion due to contract linking is unbounded.
2. When we are interested only in a limited recursion depth due to contract linking.

```{caution}
This flag could be another cause for unsoundness - even if such recursion
_could_ actually happen in the deployed contract, this code-path won't be verified
beyond the specified recursion limit ({ref}`--contract_recursion_limit`).
```

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_contract_recursion true --contract_recursion_limit 1
```

(-optimisticFallback)=
(--optimistic_fallback)=
## `--optimistic_fallback`

**What does it do?**

This option controls how the Prover handles unresolved external calls with an empty input buffer (length 0). By default, such calls will havoc all storage state of external contracts. When `--optimistic_fallback` is enabled, these calls will instead:

- Execute the fallback function in the specified contract (if it exists).
- Revert if no fallback function is available.
- Execute a transfer if applicable.

This modifies the behavior of {ref}`AUTO summaries <auto-summary>` by preventing unnecessary state havoc for empty input calls.

**When to use it?**

Enable this option to avoid spurious counter examples for external calls with empty input buffers.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_fallback
```

(--struct_link)=
## `--struct_link`

**Usage**
```sh
--struct_link <contract>:<slot>=<address>
```

**What does it do?**
Links a slot in a struct with another contract. To do that you must calculate the slot number of the field you wish to replace.

**When to use it?**
Many times a contract includes the address of another contract inside a field of one of its structs. If we do not use `--struct_link`, it will be interpreted as any possible address, resulting in many nonsensical counterexamples.

**Example**
Assume we have the contract `Bank.sol` with the following code snippet:
`TokenPair public tokenPair;`

Where `TokenPair` is
```solidity
struct TokenPair {
    IERC20 tokenA;
    IERC20 tokenB;
}
```

We have two contracts `BankToken.sol` and `LoanToken.sol`. We want `tokenA` of the `tokenPair` to be `BankToken`, and `tokenB` to be `LoanToken`. Addresses take up only one slot. We assume `tokenPair` is the first field of Bank (so it starts at slot zero). To do that, we use:

```sh
certoraRun Bank.sol BankToken.sol LoanToken.sol --verify Bank:Bank.spec --struct_link Bank:0=BankToken Bank:1=LoanToken
```

Options for controlling contract creation
=========================================

(--dynamic_bound)=
## `--dynamic_bound`

**Usage**
```sh
--dynamic_bound <n>
```

**What does it do?**
If set to zero (the default), contract creation (via the `new` statement or the `create`/`create2` instructions) will result in a havoc, like any other unresolved external call. If non-zero, then dynamic contract creation will be modeled with cloning, where each contract will be cloned at most n times.

**When to use it?**
When you wish to model contract creation, that is, simulating the actual creation of the contract. Without it, `create` and `create2` commands simply return a fresh address; the Prover does not model their storage, code, constructors, immutables, etc. Any interaction with these generated addresses is modeled imprecisely with conservative havoc.

**Example**
Suppose a contract `C` creates a new instance of a contract `Foo`, and you wish to inline the constructor of `Foo` at the creation site.
```sh
certoraRun C.sol Foo.sol --verify C:C.spec --dynamic_bound 1
```

(--dynamic_dispatch)=
## `--dynamic_dispatch`

**What does it do?**
By default, contract method invocations on newly created instances remain unresolved, requiring explicit {ref}`` DISPATCHER <dispatcher>`` summaries for all such method calls.
With this option, the Prover will automatically apply the `DISPATCHER` summary on a best-effort basis for call sites where the receiver is proven to be a newly created contract.

**Limitations**
- This option only applies when the Prover can prove that the callee is a created contract.
- If a contract instance is assigned from both a newly created contract and another source (e.g., storage), calls will remain unresolved. For example:
```solidity
MyFoo f;
if(*) {
   f = new MyFoo(...);
} else {
  f = storageStruct.myFoo;
}
f.bar();
```

**When to use it?**
Use this flag when you prefer not to manually add explicit `DISPATCHER` summaries for methods invoked by the created contract.

**Example**
Suppose a contract `C` creates a new instance of a contract `Foo`, and you wish to inline the constructor of `Foo` at the creation site,
and `Foo` calls some method `m()` which you wish to automatically link to the newly created contract.
```sh
certoraRun C.sol Foo.sol --verify C:C.spec --dynamic_bound 1 --dynamic_dispatch
```

```{note}
You must also use the {ref}`--dynamic_bound` option.
```

(--prototype)=
## `--prototype`

**Usage**
```sh
--prototype <hex string>=<contract>
```

**What does it do?**
Instructs the Prover to use a specific contract type for the return value from a call to `create` or `create2` on the given hexadecimal string as a prefix. The hexadecimal string represents proxy code that forwards calls to another contract. As we are using the prototype flag to skip calls to the proxy, no constructor code is being simulated for these contract creation resolutions.

**When to use it?**
If you are verifying a contract creation that uses low level calls to `create` or `create2` for contract creation.

**Example**
Suppose you have a contract `C` that creates another contract `Foo` like this:
```solidity
assembly {
     let ptr := mload(0x40)
     mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
     mstore(add(ptr, 0x14), shl(0x60, implementation))
     mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
     instance := create(0, ptr, 0x37)
}
```
Then you can set the string `3d602d80600a3d3981f3363d3d373d3d3d363d73` appearing in the first `mstore` after the `0x` prefix as a "prototype" for `Foo`.
The Prover will then be able to create a new instance of `Foo` at the point where the code creates it:
```sh
certoraRun C.sol Foo.sol --verify C:C.spec --prototype 3d602d80600a3d3981f3363d3d373d3d3d363d73=Foo --dynamic_bound 1
```

```{Note}
This argument has no effect if the {ref}`dynamic bound <--dynamic_bound>` is zero.
```

```{Note}
The hex string must be:
- A strict prefix of the memory region passed to the create command.
- Must be unique within each invocation of the tool.
- Must not contain gaps, e.g., `3d602d80600a3d3981f3363d3d373d3d3d363d730000` in the above example will not work (those last four bytes will be overwritten) but `3d602d80600a3d3981f3363d3d373d3d3d363d` will.
```


Version options
===============

(--version)=
## `--version`

**What does it do?**
Shows the version of the local installation of the tool you have.

**When to use it?**
When you suspect you have an old installation. To install the newest version, use `pip install --upgrade certora-cli`.

**Example**

```sh
certoraRun --version
```



Advanced options
================

(--allow_solidity_calls_in_quantifiers)=
## `--allow_solidity_calls_in_quantifiers`

**What does it do?**

Instructs the Prover to permit contract method calls in quantified expression
bodies.

**When to use it?**

Upon instruction from the Certora team.

**Example**

`--allow_solidity_calls_in_quantifiers` instructs the Prover to not generate an
error on encountering contract method calls in quantified expression bodies.

(--java_args)=
## `--java_args`

**What does it do?**

Allows setting configuring the underlying JVM.

**When to use it?**

Upon instruction from the Certora team.

**Example**

`--java_args '"-Dcvt.default.parallelism=2"'` - will set the number of “tasks” that can run in parallel to 2.

(--precise_bitwise_ops)=
## `--precise_bitwise_ops`

**What does it do?**
This option models bitwise operations exactly, instead of using the default {term}`overapproximation`. It is useful when the Prover reports a counterexample caused by incorrect modeling of bitwise operations, but enabling this option can significantly increase verification time.

**Limitations**
- This encoding does not model `mathint` precisely.
- The maximum supported integer value is {math}`2^{256} - 1`, effectively restricting `mathint` to a `uint256`.
- There is currently no encoding that precisely models both bitwise operations and `mathint` simultaneously.

**When to use it?**
Use this option if a counterexample suggests that incorrect modeling of bitwise operations is affecting verification results.

**Example**
```sh
certoraRun Bank.sol --verify Bank:Bank.spec --precise_bitwise_ops
```

(--prover_args)=
## `--prover_args`

The `--prover_args` option allows you to provide fine-grained tuning options to the
Prover.  `--prover_args` receives a string containing Prover-specific options, and will be sent as-is to the Prover.
`--prover_args` cannot set Prover options that are set by standalone `certoraRun` options (e.g. the Prover option `--t` is
set by `--smt_timeout` therefore cannot appear in `--prover_args`). `--prover_args` value must be quoted.

(-enablestoragesplitting)=
### `-enableStorageSplitting`

This option disables the storage splitting optimization.

**Usage**
```sh
--prover_args '-enableStorageSplitting false'
```

(-maxnumberofreachchecksbasedondomination)=
### `-maxNumberOfReachChecksBasedOnDomination`

This option sets the number of program points to test with the `deepSanity`
built-in rule.  See {ref}`built-in-deep-sanity`.

**Usage**
```sh
--prover_args '-maxNumberOfReachChecksBasedOnDomination <n>'
```

(-optimisticreturnsize)=
### `-optimisticReturnsize`

This option determines whether {ref}`havoc summaries <havoc-summary>` assume
that the called method returns the correct number of return values.
It will set the value returned by the `RETURNSIZE` EVM instruction according to the
called method.

```{note}
Certain conditions should hold in order for the option to take effect.
Namely, if there is a single candidate method in the havoc site,
and all instances of this method in the {term}`scene` have exactly the same
expected number of return values, then the `RETURNSIZE` value will be set to
the expected size matching the methods in the scene.
Otherwise, `RETURNSIZE` will remain non-deterministic.
```

**Usage**
```sh
--prover_args '-optimisticReturnsize true'
```

(-smt_groundquantifiers)=
### `-smt_groundQuantifiers`

This option disables quantifier grounding.  See {ref}`grounding` for more
information.

**Usage**
```sh
--prover_args '-smt_groundQuantifiers false'
```

(-superoptimisticreturnsize)=
### `-superOptimisticReturnsize`

This option determines whether {ref}`havoc summaries <havoc-summary>` assume
that the called method returns the correct number of return values.
It will set the value returned by the `RETURNSIZE` EVM instruction
to the size of the output buffer as specified by the summarized `CALL` instruction.

**Usage**
```sh
--prover_args '-superOptimisticReturnsize true'
```


(control-flow-splitting-options)=
Control flow splitting options
------------------------------

See [here](control-flow-splitting) for an explanation of control flow splitting.

(-depth)=
### `-depth`

**Usage**
```sh
--prover_args '-depth <number>'
```

**What does it do?**

Sets the maximum splitting depth.

**When to use it?**

When the deepest {term}`split`s are too heavy to solve, but not too high in
number, increasing this will lead to smaller, but more numerous
{term}`split leaves`, which run at the full SMT timeout (as set by
{ref}`--smt_timeout`).
Conversely, if run time is too high because there are too many splits,
decreasing this number means that more time is spent on fewer, but bigger split
leaves.
The default value for this option is 10.

**Example**

```sh
certoraRun Bank.sol --verify Bank:bank.spec --prover_args '-depth 5'
```

(-dontstopatfirstsplittimeout)=
### `-dontStopAtFirstSplitTimeout`

**Usage**
```sh
--prover_args '-dontStopAtFirstSplitTimeout <true/false>'
```

**What does it do?**

We can tell the Certora Prover to continue even when the a {term}`split` has had
a maximum-depth timeout. Note that this is only useful when there exists a
{term}`counterexample` for the rule under verification, since in order to prove
the absence of counterexamples (i.e. correctness), all splits need to be
counterexample-free. (In case of a rule using `satisfy` rather than `assert`,
the corresponding statements hold for {term}`witness example`s. In that case,
this option is only useful if the rule is correct.)

**When to use it?**

When looking for a SAT result and observing an [SMT-type timeout](timeouts-introduction).
The default value for this option is `false`.

**Example**

```sh
certoraRun Bank.sol --verify Bank:bank.spec --prover_args '-dontStopAtFirstSplitTimeout true'
```

(-mediumtimeout)=
### `-mediumTimeout`

The "medium timeout" determines how much time the SMT solver gets for checking a
{term}`split` that is not a {term}`split leaf`.
(For split leaves, the full {ref}`--smt_timeout` is used.)

**Usage**
```sh
--prover_args '-mediumTimeout <seconds>'
```

**What does it do?**

Sets the time that non-leaf splits get before being split again.

**When to use it?**

When a little more time can close some splitting subtrees early, this can save a
lot of time, since the subtree's size is exponential in the remaining depth. On
the other hand, if something will be split further anyway, this can save the
run time spent on intermediate "TIMEOUT" results. Use
{ref}`-smt_initialSplitDepth` to eliminate that time investment altogether up to
a given depth.

**Example**

```sh
certoraRun Bank.sol --verify Bank:bank.spec --prover_args '-mediumTimeout 20'
```

(-smt_initialsplitdepth)=
### `-smt_initialSplitDepth`

With this option, the splitting can be configured to skip the SMT solver-based checks
at low splitting levels, thus generating sub-{term}`split`s up to a given depth immediately.

**Usage**
```sh
--prover_args '-smt_initialSplitDepth <number>'
```

**What does it do?**

The first `<number>` split levels are not checked with the SMT solver, but rather
split immediately.

**When to use it?**

When there is a lot of overhead induced by processing and trying to solve splits
that are very hard, and thus run into a timeout anyway.

```{note} 
The number of splits generated here is equal to {math}`2^n` where `n` is the initial 
splitting depth (assuming the program has enough branching points, 
which is usually the case);
thus, low numbers are advisable. For instance setting this to 5 means that the
Prover will immediately produce 32 splits.
```

```{note}
The {ref}`-depth` setting has precedence over this setting. I.e., if `-depth`
is set to a lower value than `-smt_initialSplitDepth`, the initial splitting
will only proceed up to the splitting depth given via `-depth`.
```

**Example**

```sh
certoraRun Bank.sol --verify Bank:bank.spec --prover_args '-smt_initialSplitDepth 3'
```

