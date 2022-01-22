Advanced Debugging
==================

Memory Analysis
---------------

The memory analysis makes sure that memory access is safe. That is, the allocation of objects and the update of the free memory pointer are done correctly, and pointers are consistent.

In `Results.txt` one can find indications of whether the points-to analysis (a major component of the memory analysis) fails or not, e.g., `Pointer analysis failed while analyzing` as in the full message, also indicating the source location:

```
[main] WARN POINTS_TO - Pointer analysis failed while analyzing simplifiedVaultHarness-batchSwap @ LTACCmd(ptr=CmdPointer(block=24991_998_0_0_0_0_0_0, pos=2), cmd=ByteStore R38900:bv256 R39227:bv256 tacM:bytemap (5059:58:5:0xce4604a0000000000000000000000004) // .certora_config/simplifiedVaultHarness.sol_4/5_SignaturesValidator.sol)
```
