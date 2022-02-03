Understanding the Results of the Certora Prover
===============================================

The Certora Prover produces a table with the verification results as a web
page. For each rule, it either displays a thumbs-up if it formally proved the
rule or displays an input that triggers a violation of the rule. For example,
below is a violation of the rule `others_can_only_increase` when simulated on
the transfer function. A call trace demonstrating the violation is shown. It
shows the arguments passed to each simulated function and the resulting return
value (displayed after the slash). This example shows that a transfer of an
amount close to `MAX_INT` causes the balance of the recipient account to
decrease.

![example output](output.png)
