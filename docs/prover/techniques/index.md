Techniques Used by Certora Prover
=================================

In this chapter we describe techniques used by the Certora Prover whose understanding can be relevant for an expert-level usage of the Prover.

(control-flow-splitting)=
## Control Flow Splitting

There is a brief explanation of control flow splitting in the 
[webinar on timeouts](https://www.youtube.com/watch?v=mntP0_EN-ZQ).

% TODO write this -- tracked in https://certora.atlassian.net/browse/DOC-351

(storage-and-memory-analysis)=
## Storage and Memory Analysis

The Certora Prover works on EVM bytecode as its input. To the bytecode, the
address space of both Storage and Memory are flat number lines. That two
contract fields `x` and `y` don't share the same memory is an arithmetic
property. With more complex data structures like mappings, arrays, and structs,
this means that every
["non-aliasing"](https://en.wikipedia.org/wiki/Aliasing_(computing)) argument
requires reasoning about multiplications, additions, and hash functions. Certora
Prover models this reasoning correctly, but this naive low-level modeling can
quickly overwhelm SMT solvers. In order to handle storage efficiently, Certora
Prover analyses Storage (Memory) accesses in EVM code in order to understand the
Storage (Memory) layout, thus making information like "an update to mapping `x`
will never overwrite the scalar variable `y`" much more obvious to the SMT
solvers. For scaling SMT solving to larger programs, these simplifications are
essential.

