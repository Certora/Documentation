# Introduction

**Ranger** is Certora’s bounded model checker for smart contracts. It complements formal verification by offering a lightweight, developer-friendly approach for quickly identifying violations of contract invariants.

Unlike the [Certora Prover](/docs/user-guide/index), which explores all program states, Ranger starts from a specific initial state and explores all function call sequences up to a bounded depth. This ensures that every violation corresponds to a realistic execution path, removing the need to filter out spurious counterexamples.

---

## Why Ranger?

Formal Verification provides strong correctness guarantees and checks more program states, but it can be slow, complex, and prone to false positives from unreachable states. {term}`fuzzing`, on the other hand, is faster, but has a lower coverage as it only checks for specific inputs per run.

Ranger offers a practical middle ground:

- ✅ **Realistic counterexamples**: All violations are reachable from the initial state.
- ✅ **Faster time to value**: Minimal setup required to get useful results.
- ✅ **Fewer false positives**: No need to precondition rules to filter out invalid states.
- ✅ **High coverage**: Symbolically tests all function call sequences from the initial state up to a certain range.

---

## Scope and Limitations

Ranger is in active development and currently supports only Solidity contracts.

Currently, Ranger can only check [CVL](/docs/cvl/index) {ref}`invariants`. Rules will be supported in the future.
