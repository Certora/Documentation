CallResolutionTable
=================

The `CallResolutionTable` shows information about all the summarized calls in the program.
It helps the user to better understand decisions made by the Prover- which calls in the rule code got inlined, which were replaced by summaries, and why.

Attributes
------

 * **Caller**- The caller of the call. Always resolved by the Prover.

 * **Callee**- The callee of the call. For internal calls, always resolved. For external calls, might be unresolved, depending on linking, summarization, and more.
See below.

 * **Call Site**- source information of the call itself. Shows the location of the call (which file, which line), and a snippet from the source code (the invocation itself).

 * **Summary**- what summary got applied for the call.

 * **Comments**- a list of comments about the resolution of the callee (which as mentioned above, might be unresolved), the applied summarization.
See below.


The Callee
------

The callee is composed of two elements which should be taken into account: 1. Callee contract 2. Callee sighash.
The callee contract is the target contract of the call, the callee sighash is the sighash of the invoked function.
As mentioned above, for internal calls, the callee will always be resolved by the tool, while for external calls, it’s not always the case.
Here all the cases for unresolved callees are introduced:

 * Fully resolved callee: In such a case, the summary will be applied iff the application policy of the summary is `ALL` 
(see {doc}`The Methods Block — Certora Prover Documentation 0.0 documentation <summary-types>`).
Notice, this does not mean that the call itself is resolved- it might happen, that both the callee contract and the callee sighash are resolved, but the sighash is not found in the contract.
This might happen, for example, due to a wrong linking in the configuration, or, due to a wrong low level call (`abi.encodeWithSignature("fdgf()")`), which is resolved in the bytecode level, even though it’s not an existing function signature.

 * Both callee contract, callee sighash are unresolved.

 * Callee contract unresolved, callee sighash resolved.

 * Callee Contract resolved, callee sighash unresolved.


 Comments
------

In the comments, it is specified what is the resolution status of the callee.
In addition, they give more insights about why the prover failed to resolve the callee.
For example, if the callee contract is unresolved due to a wrong linking, a hint is given to the user, which specifies the slot that should be linked, and what are the possible contracts that should be considered to be linked (those that contain a function with the resolved sighash, if it is indeed resolved).
Moreover, the comments specify the summary application reason, which may be due to the configuration in the CLI, a summarization written in the spec, or a decision made by the Prover.
For example, if the Prover fails to resolve the callee, it decides to havoc the call.


Run Example with all the cases (rule per a case):
[Verification Report][report]

[report]: https://vaas-stg.certora.com/output/20941/5deeb346152849f3976f4a68a30c8822?anonymousKey=1bf252ca0e1aae98e20d2daac6c0e6b3a03a0819