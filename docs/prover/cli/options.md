Certora Prover CLI Options
==========================

The `certoraRun` utility invokes the Solidity compiler and afterwards sends the job to Certora's servers. 

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

Most frequently used options
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
### `--rules`

**What does it do?**  
Formally verifies one or more given properties instead of the whole specification file. An invariant can also be selected.  

**When to use it?**  
This option saves a lot of run time. Use it whenever you care about only a specific subset of a specification's properties. The most common case is when you add a new rule to an existing specification. The other is when code changes cause a specific rule to fail; in the process of fixing the code, updating the rule, and understanding counterexamples, you likely want to verify only that specific rule.  

**Example**  
If `Bank.spec` includes the following properties:  
`invariant address_zero_cannot_become_an_account()`

`rule withdraw_succeeds()`
`rule withdraw_fails()`

If we want to verify only `withdraw_succeeds`, we run  
`certoraRun Bank.sol --verify Bank:Bank.spec --rule withdraw_succeeds`

If we want to verify both `withdraw_succeeds` and `withdraw_fails`, we run  
`certoraRun Bank.sol --verify Bank:Bank.spec --rule withdraw_succeeds withdraw_fails`

Note that `--rules` (plural) may be used alternatively to `--rule`. The two options are identical, but `--rules` may feel more natural when more than one rule is specified. 

(--send_only)=
### `--send_only`

**What does it do?**
Causes the CLI to exit immediately when the job is submitted, rather than waiting
for it to complete.

**When to use it?**
When you want to run many jobs concurrently in a script, or otherwise want the
CLI to not block the terminal.

**Example**
```sh
certoraRun Example.sol --verify Example:Example.spec --send_only
```

Options affecting the type of verification run
----------------------------------------------

(--multi_assert_check)=
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
This option enables sanity checking for rules.  The `--rule_sanity` option may
be followed by one of `none`, `basic`, or `advanced`; these are described below.
See {doc}`../checking/sanity` for more information about sanity checks.

There are 3 kinds of sanity checks:

1. **Reachability** checks that even when ignoring all the user-provided
   assertions, the end of the rule is reachable. This check ensures that that
   the combination of `require` statements does not rule out all possible
   counterexamples.

   For example, the following rule would be flagged by the reachability check:
   ```cvl
   rule vacuous {
     uint x;
     require x > 2;
     require x < 1;
     assert f(x) == 2, "f must return 2";
   }
   ```
   Since there are no models satisfying both `x > 2` and `x < 1`, this rule
   will always pass, regardless of the behavior of the contract.  This is an
   example of a *vacuous* rule - one that passes only because the preconditions
   are contradictory.

   ```{caution}
   The reachability check will *pass* on vacuous rules and *fail* on correct
   rules.  A passing reachability check indicates a potential error in the rule.
   
   The exception is when a {term}`parametric rule` is checked on the default
   fallback function: The default fallback function should always revert, so
   there are no examples that can reach the end of the rule.
   ```

2. **Assert-Vacuity** checks that individual `assert` statements are not
   tautologies.  A tautology is a statement that is true on all examples, even
   if all the `require` and `if` conditions are removed.

   For example, the following rule would be flagged by the assert-vacuity check:
   ```cvl
   rule tautology {
     uint x; uint y;
     require x != y;
     ...
     assert x < 2 || x >= 2,
      "x must be smaller than 2 or greater than or equal to 2";
   }
   ```
   Since every `uint` satisfies the assertion, the assertion is tautological,
   which is likely to be an error in the specification.

3. **Require-Redundancy** checks for redundant `require` statements.
   A `require` is considered to be redundant if it can be removed without
   affecting the satisfiability of the rule.

   For example, the require-redundancy check would flag the following rule:
   ```cvl
   rule require_redundant {
     uint x;
     require x > 3;
     require x > 2;
     assert f(x) == 2, "f must return 2";
   }
   ```
   In this example, the second requirement is redundant, since any `x` greater
   than 3 will also be greater than 2.

The `rule_sanity` flag may be followed by either `none`, `basic`, or `advanced` to control which sanity checks should be executed.
 * With `--rule_sanity none` or without passing `--rule_sanity`, no sanity checks are performed.
 * With `--rule_sanity basic` or just `--rule_sanity` without a mode, the reachability check is performed for all rules and invariants, and the assert-vacuity check is performed for invariants.
 * With `--rule_sanity advanced`, all the sanity checks will be performed for all invariants and rules.

We recommend starting with the `basic` mode, since not all rules flagged by the
`advanced` mode are incorrect.

**When to use it?**  
We suggest using this option routinely while developing rules.  It is also a
useful check if you notice rules passing surprisingly quickly or easily.

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
Passes the value of this option as is to the solidity compiler's option `--allow-paths`.
See [--allow-path specification](https://docs.soliditylang.org/en/v0.8.16/path-resolution.html#allowed-paths)

**When to use it?**  
When we want for security reasons to limit the locations for loaded sources to specific directories

**Example**
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
The Certora Prover unrolls loops - if the loop should be executed three times, it will copy the code inside the loop three times. After we finish the loop's iterations, we add an assertion to verify we have actually finished running the loop. For example, in a `while (a < b)` loop, after the loop's unrolling, we add `assert a >= b`. We call this assertion the _loop unwind condition_.  
This option changes the assertions of the loop unwind condition to requirements (in the case above `require a >= b`). That means, we ignore all the cases where the loop unwind condition does not hold, instead of considering them as a failure.  

**When to use it?**  
When you have loops in your code and are getting a counterexample labeled `loop unwind condition`. In general, you need this flag whenever the number of loop iterations varies. It is usually a necessity if using {ref}`--loop_iter`. Note that `--optimistic_loop` could cause {ref}`vacuous rules <--rule_sanity>`.

**Example**  
```
certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_loop
```

(--loop_iter)=
### `--loop_iter`

**What does it do?**
Sets the maximal number of loop iterations we verify for. The way the Certora Prover handles loops is by unrolling them - if the loop should be executed three times, it will copy the code inside the loop three times. This option sets the number of unrolls. Be aware that the run time grows exponentially by the number of loop iterations.  

**When to use it?**  
The default number of loop iterations we unroll is one. However, in many cases, bugs only occur when there are several iterations. Common scenarios include iteration over list elements. Two, or in some cases three, is usually the most you will ever need to uncover bugs.  

**Example**

```
certoraRun Bank.sol --verify Bank:Bank.spec --loop_iter 2
```

Options regarding hashing of unbounded data
-------------------------------------------

(--optimistic_hashing)=
### `--optimistic_hashing`

**What does it do?**

 When hashing data of potentially unbounded length (including unbounded arrays, like `bytes`, `uint[]`, etc.), assume that its length is bounded by the value set through the `--hashing_length_bound` option. If this is not set, and the length can be exceeded by the input program, the prover reports an assertion violation. I.e., when this option is set, the boundedness of the hashed data assumed checked by the prover, when this option is set that boundedness is assumed instead.

See {doc}`../approx/hashing` for more details.


**When to use it?**  

When the assertion regarding unbounded hashing is thrown, but it is acceptable for the prover to ignore cases where the length hashed values exceeds the current bound.

**Example**

```
certoraRun Bank.sol --verify Bank:Bank.spec --optimistic_hashing
```

(--hashing_length_bound)=
### `--hashing_length_bound`

**What does it do?**

Constraint on the maximal length of otherwise unbounded data chunks that are being hashed. This constraint is either assumed or checked by the prover, depending on whether `--optimistic_hashing` has been set. The bound is specified as a number of bytes. 

The default value of this option is 224 (224 bytes correspond to 7 EVM machine words as 7 * 32 == 224).

**When to use it?**  
Reason to lower this value:

Lowering potentially improves SMT performance, especially if there are many occurrences of unbounded hashing in the program. 

Reasons to raise this value:

 - when `--optimistic_hashing` is not set: avoid the assertion being violated when the hashed values are actually bounded, but by a bound that is higher than the default value (in case of `--optimistic_hashing` being not set)
 - when `--optimistic_hashing` is set: find bugs that rely on a hashed array being at least of that length. (Optimistic hashing excludes all cases from the scope of verification where something being hashed is longer than this bound.)

**Example**

```
certoraRun Bank.sol --verify Bank:Bank.spec --hashing_length_bound 128
```


Options that help reduce the running time
-----------------------------------------

### `--method`

**What does it do?**
Parametric rules will only verify the method with the given signature, instead of all public and external methods of the contract. Note that you will need to wrap the method's signature with quotes, as the shell doesn't interpret parenthesis correctly otherwise.

**When to use it?**  
When you are trying to solve/understand a counterexample of a parametric rule on a specific method.

**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --method 'withdraw(uint256,bool)'`

### `--cache`

**What does it do?**  
A cache in the cloud for optimizing the analysis before running the SMT solvers. The cache used is the argument this option gets. If a cache with this name does not exist, it creates one with this name.  

**When to use it?**  
By default, we do not use a cache. If you want to use a cache to speed up the building process, use this option.  

**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --cache bank_regulation`

(--smt_timeout)=
### `--smt_timeout <seconds>`

**What does it do?**  
Sets the maximal timeout for all the
[SMT solvers](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories).
Gets an integer input, which represents seconds.  

The Certora Prover generates a logical formula from the specification and
source code. Then, it passes it on to an array of SMT solvers. The time it can
take for the SMT solvers to solve the equation is highly variable, and could
potentially be infinite. This is why they must be limited in run time.

Note that the SMT timeout applies separately to each individual rule (or each method
for parametric rules).  To set the global timeout, see {ref}`-globalTimeout`.

**When to use it?**  
The default time out for the solvers is 300 seconds. There are two use cases for this option.  
One is to decrease the timeout. This is useful for simple rules, that are solved quickly by the SMT solvers. Here, it is beneficial to reduce the timeout, so that when a new code breaks the specification, the tool will fail quickly. This is the more common use case.  
The second use is when the solvers can prove the property, they just need more time. Usually, if the rule isn't solved in 600 seconds, it will not be solved in 2,000 either. It is better to concentrate your efforts on simplifying the rule, the source code, add more summaries, or use other time-saving options. The prime causes for an increase of `--smt_timeout` are rules that are solved quickly, but time out when you add a small change, such as a requirement, or changing a strict inequality to a weak inequality.  

**Example**  
`certoraRun Bank.sol --verify Bank:Bank.spec --smt_timeout 300`  

Options to set addresses and link contracts
-------------------------------------------

(--link)=
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

(--address)=
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
```solidity
struct TokenPair {
    IERC20 tokenA;
    IERC20 tokenB;
}
```

We have two contracts `BankToken.sol` and `LoanToken.sol`. We want `tokenA` of the `tokenPair` to be `BankToken`, and `tokenB` to be `LoanToken`. Addresses take up only one slot. We assume `tokenPair` is the first field of Bank (so it starts at slot zero). To do that, we use:  
`certoraRun Bank.sol BankToken.sol LoanToken.sol --verify Bank:Bank.spec --structLink Bank:0=BankToken Bank:1=LoanToken`

Options for controlling contract creation
-----------------------------------------

(--dynamic_bound)=
### `--dynamic_bound <n>`

**What does it do?**
If set to zero (the default), contract creation (via the `new` statement or the `create`/`create2` instructions) will result in a havoc, like any other unresolved external call. If non-zero, then dynamic contract creation will be modeled with cloning, where each contract will be cloned at most n times.

**When to use it?**
When you wish to model contract creation, that is, simulating the actual creation of the contract. Without it, `create` and `create2` commands simply return a fresh address; the Prover does not model their storage, code, constructors, immutables, etc. Any interaction with these generated addresses is modeled imprecisely with conservative havoc.

**Example**
Suppose a contract `C` creates a new instance of a contract `Foo`, and you wish to inline the constructor of `Foo` at the creation site.
`certoraRun C.sol Foo.sol --dynamic_bound 1`

### `--dynamic_dispatch`

**What does it do?**
If false (the default), then all contract method invocations on newly created instances will be unresolved. The user must explicitly write {ref}`` `DISPATCHER` <dispatcher>`` summaries for all methods called on newly created instances. 
If true, the Prover will, on a best-effort basis, automatically apply the `DISPATCHER` summary for call sites that must be with a newly created contract as a receiver.

Importantly, this option is only applicable to cases where the Prover can prove that the callee is a created contract. For example, in the below example, the `bar` function will be unresolved:
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
When you prefer not to add explicit `DISPATCHER` summaries to methods invoked by the created contract.

**Example**
Suppose a contract `C` creates a new instance of a contract `Foo`, and you wish to inline the constructor of `Foo` at the creation site, 
and `Foo` calls some method `m()` which you wish to automatically link to the newly created contract.
Note that you must add a `--dynamic_bound` argument as well.
`certoraRun C.sol Foo.sol --dynamic_bound 1 --dynamic_dispatch true`

### `--prototype <hex string>=<contract>`

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
`certoraRun C.sol Foo.sol --prototype 3d602d80600a3d3981f3363d3d373d3d3d363d73=Foo --dynamic_bound 1`
Note: this argument has no effect if the {ref}`dynamic bound <--dynamic_bound>` is zero.

Also note that the hex string must be: 
- a strict prefix of the memory region passed to the create command
- must be unique within each invocation of the tool
- must not contain gaps, e.g., `3d602d80600a3d3981f3363d3d373d3d3d363d730000` in the above example will not work (those last four bytes will be overwritten) but `3d602d80600a3d3981f3363d3d373d3d3d363d` will


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
Stops after running the Solidity compiler and type checking of the spec, before submitting the verification task.

**When to use it?**  
If you want only to check your spec, or include it in an automated task (e.g., a git `pre-commit` hook).  
**Example**

`certoraRun Bank.sol --verify Bank:bank.spec --typecheck_only`

Advanced options
----------------

(--cloud)=
### `--cloud`

**What does it do?**

Runs the Prover on the cloud.  Note that for non-Certora users, `--cloud` is
the default, so this option does nothing.

**When to use it?**

If you are a Certora employee who usually runs the Prover locally, but want to
run on the cloud instead.

(--staging)=
### `--staging [branch]`

**What does it do?**

Runs a non-standard version of the Prover.

**When to use it?**

Upon instruction from the Certora team.

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

(--settings)=
### `--settings`

The `--settings` option allows you to provide fine-grained tuning options to the
Prover.  `--settings` should be followed by a comma-separated list of options.

```{todo}
This list is incomplete.
```

(-optimisticReturnsize)=
#### `--settings -optimisticReturnsize`

This option determines whether {ref}`havoc summaries <havoc-summary>` assume
that the called method returns the correct number of return values.

(-showInternalFunctions)=
#### `--settings -showInternalFunctions`

**What does it do?**

This option causes the Prover to output a list of all the potentially
summarizable internal function calls on the command line.  The output is also
visible in the log file that you can download from the report.

**When to use it?**

In some cases the Prover is unable to locate all internal function calls, and
so summaries may not be applied.  This option can be useful to determine
whether summary is applied or not.

The Prover's ability to locate a summarizable call depends on the call site,
rather than the method declaration.  In particular, it is possible that the
same internal function is called from two different contract functions, but
only one of those calls is summarizable.

The list that is output by this setting is grouped under the public and external
methods of the contract.  If an external method `f` calls an internal method `g`
which in turn calls another internal method `h`, then both `g` and `h` will be
reported under the entry for `f`.

**Example**

```sh
certoraRun Bank.sol --verify Bank:bank.spec --settings -showInternalFunctions
```

(-globalTimeout)=
#### `--settings -globalTimeout=<seconds>`

This option sets the global timeout in seconds.  By default, the global timeout
is two hours.  Values larger than two hours (7200 seconds) are ignored.

The global timeout is different from the {ref}`--smt_timeout` option: the
`--smt_timeout` flag constrains the amount of time allocated to the processing
of each individual rule, while the `-globalTimeout` flag constrains the
processing of the entire job, including static analysis and other
preprocessing.

Jobs that exceed the global timeout will simply be terminated, so the result
reports may not be generated.

(-solver)=
#### `--settings -solver=<solver spec>`

This option sets the SMT solvers being used within the Prover.  By default, a
portfolio of various different solvers is used.  It can be useful to specify
only a subset of these to save on computation time.  In rare cases, solver
specific options can improve performance as well.

The `solver spec` can be a single solver (`-solver=z3`) or a list of solvers
(`-solver=[cvc5,z3]`), where each such solver can be further modified.  For
example, `cvc5` refers to the default configuration of `cvc5` whereas
`cvc5:nonlin` is better for nonlinear problems.  Additional options can be set
via `z3{randomSeed=17}`.
