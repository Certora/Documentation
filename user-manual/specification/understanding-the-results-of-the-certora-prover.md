# Understanding the results of the Certora Prover

The Certora Prover produces a table with the verification results as a web page. For each rule, it either displays a thumbs-up if it formally proved the rule or displays an input that triggers a violation of the rule. For example, below is a violation of the rule `others_can_only_increase` when simulated on the transfer function. A call trace demonstrating the violation is shown. It shows the arguments passed to each simulated function and the resulting return value \(displayed after the slash\). This example shows that a transfer of an amount that is close to `MAX_INT` causes the balance of the recipient account to decrease.



![Example output of the Certora Prover](https://lh6.googleusercontent.com/HnyfTHV5HDKVGfO50dAZX6zdHDsC3U21ykNEcfwTcgmkcDv5zi2WkEQuF2pwp2VURxNWulWAnZ2qrerzUOhrYXSdHCuKvWEtfOULD5p892UzCReJKTjR1flcoP_j0N4BNOLnpe9-)

