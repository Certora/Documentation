# Introduction

**Ranger** is Certora’s bounded model checker for smart contracts. It complements formal verification by offering a lightweight, developer-friendly approach for quickly identifying violations of contract invariants.

Unlike the Certora Prover, which explores all reachable states of a program, Ranger starts from a specific initial state and explores all function call sequences **up to a bounded depth**. This ensures that every violation corresponds to a **realistic execution path**, removing the need to filter out spurious counterexamples.

---

## Why Ranger?

Formal Verification (FV) provides strong guarantees, but it can be slow, complex, and prone to false positives from unreachable states. Fuzzing, on the other hand, is faster and more intuitive, but lacks completeness and soundness.

Ranger offers a practical middle ground:

- ✅ **Realistic counterexamples**: All violations are reachable from the initial state.
- ✅ **Faster time to value**: Minimal setup required to get useful results.
- ✅ **Fewer false positives**: No need to precondition rules to filter out invalid states.

---

## What Ranger Does

- Starts from a **user-defined initial state** (or uses the constructor by default).
- Symbolically executes all function call sequences up to depth `K`.
- Stops once a configurable number of violations are found (default: 10).
- Generates a dedicated **Ranger Job Report** showing execution ranges, invariant statuses, and violations.

---

## Scope and Limitations

Ranger is in active development and currently supports:

- ✅ Solidity contracts
- ✅ Invariant checking with CVL
- ❌ No support for Vyper, CVL rules, or reruns from the UI

> For details on writing CVL invariants, refer to the [Certora Prover language guide](https://docs.certora.com/en/latest/docs/cvl/index.html).
