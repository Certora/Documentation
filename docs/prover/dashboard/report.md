(verification-report)=
Certora Verification Reports
============================


```{toctree}

storage-in-calltrace.md
```


Understanding counter-examples
------------------------------

There could be many reasons for false counterexamples, but here are a few common ones.

A counterexample that looks fishy does not rule out a potential bug that the rule can uncover.

1.  **External call havocs.** Look for warnings in the Call Resolution table - this could indicate _havocs_. Havocs are a common cause of counterexamples that seem to come out of nowhere!
    
2.  **Links are not applied as expected.** Note that if you use `--link` to link, you may sometimes need to require that the field is equal to the linked-to contract's address within the rule itself. (Dispatcher links do not have this issue.)
    
3.  **Bitwise operations.** By default, the tool will overapproximate bitwise
    operations applied in a non-standard way (xor, or, and non 2^n-1 masks for
    and). Try to look over the dump and look for red-background lines.  You may
    be able to solve these by passing the `--precise_bitwise_ops` option
    on the command line

4.  **Aliasing.** Be on the lookout if your environment’s `msg.sender` is the same as `currentContract` or any linked contract. The tool should report these more clearly but read the call trace carefully. Also, note trivial assignments like 0.
    
5.  **Correct storage modeling.** Suppose you have a rule that calls some getter, then you call a function that’s expected to affect the results of that getter, but in the counterexample it stays the same. It could be that the code invoked is not reaching the expected write to the relevant storage slot, or it computed the slot’s address differently. The deepest level in the call trace for stores and loads will show the actual number used for the slot’s address, so you can find-in-page the slot number from the getter and see if you find any match for it inside the function.
