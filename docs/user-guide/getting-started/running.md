# Running the Certora Prover

The `certoraRun` utility simplifies the verification process by invoking the Solidity compiler and then sending the job to Certora’s servers.

The most commonly used command is:

```bash
certoraRun contractFile:contractName --verify contractName:specFile
```

If `contractFile` is named `contractName.sol`, the command can be further simplified to:

```bash
certoraRun contractFile --verify contractName:specFile
```

A concise summary of these options can be viewed by using:

```bash
certoraRun --help
```

## Usage Example with ERC20 Contract

To demonstrate the usage, let's consider an ERC20 contract named `ERC20.sol` from the [Certora Tutorials Repository](https://github.com/Certora/tutorials-code/blob/master/lesson2_started/erc20/ERC20.sol). The corresponding spec file is named `ERC20.spec`:

```cvl
/** @title Transfer must move `amount` tokens from the caller's
 *  account to `recipient`
 */
rule transferSpec(address recipient, uint amount) {

    env e;
    
    // `mathint` is a type that represents an integer of any size
    mathint balance_sender_before = balanceOf(e.msg.sender);
    mathint balance_recip_before = balanceOf(recipient);

    transfer(e, recipient, amount);

    mathint balance_sender_after = balanceOf(e.msg.sender);
    mathint balance_recip_after = balanceOf(recipient);

    // Operations on mathints can never overflow nor underflow
    assert balance_sender_after == balance_sender_before - amount,
        "transfer must decrease sender's balance by amount";

    assert balance_recip_after == balance_recip_before + amount,
        "transfer must increase recipient's balance by amount";
}
``` 

You can run the Certora Prover with the following command:

```bash
certoraRun ERC20.sol --verify ERC20:ERC20.spec --solc solc8.0
```

This command triggers a verification run on the `ERC20` contract from the solidity file `ERC20.sol`, checking all rules in the specification file `ERC20.spec`. The `--solc` option specifies the version of the Solidity compiler to be used (in this case, version 0.8.0).

## Results

While running, the Prover will print various information to the console about the run. In the end, the output will look similar to this:

```text
...
[INFO]: Process returned with 100

Job is completed! View the results at [Certora Prover Platform](https://prover.certora.com/)

Finished verification request
ERROR: Prover found violations:
ERROR: [rule] transferSpec
```

The output indicates that the Prover completed the verification request, and it provides a link to view the results on the Certora platform. However, it also reports that the Prover found violations in the specified rule (`transferSpec`). The details of the violation and the counterexample can be further explored by visiting the provided link or accessing the Certora platform directly.

## Using Configuration (Conf) Files

For larger projects, managing the command line for Certora Prover can become complex. It is advisable to use configuration files (with a `.conf` extension) that hold the parameters and options for the Prover. These JSON5 configuration files simplify the process and enhance manageability. Refer to [Configuration (Conf) Files](../../../docs/prover/cli/conf-file-api.md) for more detailed information.