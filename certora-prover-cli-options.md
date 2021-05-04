# Certora Prover CLI Options

The `certoraRun` utility invokes the Solidity compiler and afterwards sends the job to Cerotra’s servers. 

Most commonly used command is:

```text
certoraRun contractFile:contractName --verify contractName:specFile
```

#### Options that control the Solidity Compiler

```text
[--solc EXE (default is solc)]  
[--path ALLOWED_PATH (default: $PWD/contracts/)]
[--packages_path PATH (default: $NODE_PATH)] or 
[--packages [name=path,...]]
```

#### Options that help reduce the running time

```text
[--rule rulename] process only a single rule rulename
[--settings -graphDrawLimit=0] do not generate graphs
[--settings -t=XX] set timeout of SMT solvers to XX, default is 600 (seconds)
```

#### Options for dynamic resolving

```text
[--link [abstractName:slot=contractName ...]]
```

Indicate that the member `slot` in `abstractName` is resolved as `contractName`. This is needed when checking a contract’s interaction with other contracts.

#### Options for dealing with loops

```text
[--settings -assumeUnwindCond,-b=x] 
```

Handle each loop as having at most `b` iterations. Default value of `b` is 1.

Note that you may provide more than one settings options by:

```text
 --settings op1=val1,op2=val2,...
```

Or even:

```text
 --settings op1=val1 --settings op2=val2
```

#### Sanity of rules

Enable sanity checking mode with 

```text
--settings -ruleSanityChecks
```

This mode will check for each rule that even when ignoring all the user-provided assertions, the end of the rule is reachable. Namely, that the combination of requirements does not create an “empty” rule that is always true. For example:

```text
rule empty_rule() {
   env e; 
   address to; 
   uint256 amount;
   // invoke function transfer and assume - caller is e.msg.from
   uint256 balance = getfunds(e.msg.sender);
   require (amount > balance);  
   transfer(e, to, amount);
   // check that transfer reverts if not enough funds 
   assert lastReverted , "insufficient funds"; 
   /* this rule would fail the sanity check, because by default we takw into account only paths that do not revert.
   To consider the revert path, use transfer@withRevert(e, to, amount)*/
}
```

