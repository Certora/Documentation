CallResolutionTable
=================

The code verified by the Prover consists of several modules. However, by default, the Prover is aware of just one module. When the module is calling other modules, the Prover does not know how to identify them, let alone seeing and analyzing their code. In this case, the user guides the Prover by configuring it to identify the different modules and connect them through linking. This can be done through two ways:
1. Inlining- Taking the code of the two modules and building one big module with the code of both.
2. Summarization- This is a mathematical description of the behavior of the module. It is usually short though less precise. It exists in two forms which are either be over approximating (describing more behaviors than there are actually implemented in the module) or under approximating (limiting the scope of what the other module can do).

The `CallResolutionTable` shows information about all the summarized calls in the program.
It helps the user to better understand decisions made by the Prover- which calls in the rule code got inlined, which were replaced by summaries, and why.

Attributes
------

 * **Caller**- The maker of the call. Always resolved by the Prover.

 * **Callee**- The receiver of the call. For internal calls, always resolved. For external calls, might be unresolved, depending on linking, summarization, and more.
See below.

 * **Call Site**- Source information of the call itself. This shows the location of the call file and also a snippet from the source code (the invocation).

 * **Summary**- A brief summary of the call.

 * **Comments**- A list of comments about the resolution of the callee (as mentioned above, this might be unresolved).


The Callee
------

The callee is composed of two elements which should be taken into account:
1. Callee contract- This is the target contract of the call.
2. Callee sighash- This is the sighash of the invoked function.

For internal calls, the callee will always be resolved by the Prover, while for external calls, this is not always the case.
Here all the cases for unresolved callees are introduced:

 * Fully resolved callee: In such a case, the summary will be applied if the application policy of the summary is set to `ALL`
(see {ref}`summaries`).
Note, this does not mean that the call itself is resolved. There could be a case where both the callee contract and the callee sighash are resolved, but the sighash is not found in the contract.
This might happen, due to a wrong linking in the configuration, or, due to a wrong low level call (`abi.encodeWithSignature("fdgf()")`), which is resolved in the bytecode level, even though it’s not an existing function signature.

 * Both callee contract, callee sighash are unresolved.

 * Callee contract unresolved, callee sighash resolved.

 * Callee Contract resolved, callee sighash unresolved.


 Comments
------

The comments specify the resolution status of the callee.
In addition, they give more insights about why the Prover failed to resolve the callee.
For example, if the callee contract is unresolved due to wrong linking, a hint is given to the user. This hint specifies the slot that should be linked, and what are the possible contracts that should be considered when linking (those that contain a function with the resolved sighash, if it is indeed resolved).
Moreover, the comments specify the summary application reason, which may be due to the configuration in the CLI, a summarization written in the spec, or a decision made by the Prover.
For example, if the Prover fails to resolve the callee, it then decides to havoc the call.


Run Example with all the cases (rule per a case):
[Verification Report][report]

[report]: https://vaas-stg.certora.com/output/20941/5deeb346152849f3976f4a68a30c8822?anonymousKey=1bf252ca0e1aae98e20d2daac6c0e6b3a03a0819