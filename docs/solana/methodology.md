(solana_methodology)=
# Methodology

The previous pages showed *what* the cvlr / cvlr-solana primitives do.
This one is about *how to use them well* — practical guidelines distilled
from real specs that close on real protocols.

## 1. Write the property in English first, with an ID

Before you write any Rust, write the property as a sentence. Tag it with
an ID. Use that ID in the rule name and the doc-comment.

```rust
/// P-04. After any successful deposit, vault solvency is preserved:
/// `post.shares <= post.tokens`.
#[rule]
pub fn rule_p04_deposit_preserves_solvency() { /* … */ }
```

Why:

- Forces you to know what you're proving before you fight the Prover.
- Makes Prover output traceable to a written specification.
- Gives reviewers a unit to look up.

A property without an ID is a property you'll forget you have.

## 2. Sanity-check every harness

Every parametric harness should ship with a "sanity rule" whose body is the
harness followed by `cvlr_assert!(false)`. If that rule does **not** fail,
the harness is unreachable — and any rule built on it is silently vacuous.

```rust
#[rule]
pub fn rule_sanity_deposit() {
    base_deposit::<TrueProperty>();      // a property whose checks always pass
    cvlr_assert!(false);                 // expected to fail; if it doesn't, the harness is dead
}
```

`TrueProperty` is a property struct whose `assume_pre` is empty and whose
`check_post` does nothing. The sanity rule fails iff the harness reaches
the assertion — which is what you want. Run it on every harness, every
build.

Pair this with `"rule_sanity": "basic"` in your conf so the Prover *also*
runs its automatic vacuity check on every other rule.

## 3. Catch vacuity early

Two contradicting `cvlr_assume!`s make every assertion trivially "pass".
Show this to yourself once with a deliberate vacuous rule:

```rust
#[rule]
pub fn rule_vacuous_demo() {
    let x: u64 = nondet();
    cvlr_assume!(x < 10);
    cvlr_assume!(x > 100);     // contradiction
    cvlr_assert!(false);        // "passes" because no execution exists
}
```

Without `rule_sanity`, this passes silently. With `"rule_sanity": "basic"`,
the Prover reports the rule as vacuous — see {ref}`solana-sanity-vacuity`.

Vacuity is not exotic — it shows up routinely when you tighten an `assume`
to silence a counterexample.

```{warning}
**If a rule passes after you added an `assume`, ask yourself whether the
assume excludes the very thing you wanted to verify.**
```

## 4. Scope rules small

Verify one handler at a time. Havoc state at the boundary instead of
running the whole program. Mock heavy collaborators.

A rule that calls `process_full_transaction(...)` and expects to verify a
deep invariant will time out. The same property as `process_one_step(...)`
will close in seconds.

If you must reason about sequences (multisig flows, time-locked actions),
use the {ref}`macro chain pattern <solana_parametric_rules>` to enumerate
transitions explicitly — but keep the per-step body tiny.

## 5. Mock vs. inline — the trade-off

| You're calling…                                            | Default                              |
| ---------------------------------------------------------- | ------------------------------------ |
| Code under verification                                    | Inline (don't mock)                  |
| Pure arithmetic that fits in `NativeInt`                   | Inline                               |
| A loop bounded by a small constant                         | Inline                               |
| A loop bounded by a configurable constant                  | Inline if small (≤ 4); else mock     |
| A CPI                                                      | Mock (Pattern D — track the call)    |
| Heavy table-driven math                                    | Mock (Pattern A or B with `nondet`)  |
| A function whose result the rule does not use              | Mock with `Ok(())`                   |

Two principles:

- **A mock should be the *weakest* function consistent with the contract.**
  `nondet()` returns are usually right; pinning a specific value hides
  bugs.
- **Don't change production signatures for verification.** Use
  `cvlr::mock_fn` or trait indirection — see {ref}`solana_mocks`.

## 6. Pre/post snapshots are the workhorse

The vast majority of useful properties have the shape:

> *Before the handler ran, X. After it ran, Y.*

Read state into a value-only struct before, run the handler, read it again
after. The {ref}`CvlrProp trait <solana_parametric_rules>` formalises this.

If you find yourself writing the same `let pre = …; let post = …;
cvlr_assert!(…)` pattern more than three times, factor it into a property
struct.

## 7. Use `NativeInt` for arithmetic invariants

`u64` arithmetic in the Prover is exact, including wraparound. Spurious
overflow counterexamples are common. When you mean *mathematical*
inequality, use `cvlr::mathint::NativeInt`:

```rust
use cvlr::mathint::NativeInt;

let t: NativeInt = pre_tokens.into();
let s: NativeInt = pre_shares.into();
cvlr_assume!(s <= t);
let total = t + NativeInt::from(amount);
cvlr_assume!(NativeInt::is_u64(total));     // bound when needed
cvlr_assert!(s * total <= (s + NativeInt::from(amount)) * t);
```

When *not* to use `NativeInt`: when wraparound is the actual semantics
(counters, cyclic indices). Use it for invariants ("solvency", "monotonic",
"no dilution"), not for simulating native arithmetic.

## 8. `clog!` aggressively

A counterexample without logged inputs is unreadable. The rule is simple:
**every value you produced with `nondet()` should appear in some `clog!`
before the assertion that depends on it.**

```rust
let amount: u64 = nondet();
let fee:    u64 = nondet();
cvlr_assume!(fee <= amount);
clog!(amount, fee);                  // log the inputs
let net = amount - fee;
clog!(net);                          // log derived values too
cvlr_assert!(/* … */ true);
```

For struct-valued snapshots, implement `CvlrLog` once (see
{ref}`speclanguage`) and `clog!(pre, post)` everywhere.

## 9. `multi_assert_check` for compound rules

A rule with several independent asserts will report only the first failing
one and stop. To get a per-assert report, set `multi_assert_check` in the
conf:

```json
{
    "rule": ["rule_three_invariants"],
    "multi_assert_check": true
}
```

Use this when one rule expresses a checklist of properties — each becomes
its own child result.

When *not* to use it: when the asserts are sequential (later ones depend on
earlier ones holding). Then split the rule.

## 10. Conf hygiene

A typical project keeps a `base.conf` with shared prover args, then per-rule
confs that inherit from it.

```json
// certora/conf/base.conf
{
    "loop_iter":    "3",
    "rule_sanity":  "basic",
    "smt_timeout":  "6000",
    "prover_args": [
        "-solanaOptimisticJoin true",
        "-solanaOptimisticOverlaps true",
        "-solanaOptimisticMemcpyPromotion true",
        "-solanaOptimisticMemcmp true",
        "-solanaOptimisticNoMemmove true",
        "-solanaTACOptimize 3",
        "-solanaTACMathInt true",
        "-unsatCoresForAllAsserts true",
        "-s [z3:def{randomSeed=1},z3:def{randomSeed=2},z3:def{randomSeed=3}]"
    ]
}
```

```json
// certora/conf/deposit.conf
{
    "files": ["base.conf"],
    "rule":  ["rule_solvency_deposit", "rule_monotonicity_deposit"]
}
```

A few guidelines:

- **Pin `loop_iter`.** Default unrolling depth; bump only if you have a
  loop that genuinely needs more iterations.
- **Bump `solanaStackSize` only when you hit stack errors.** It does not
  help otherwise.
- **Multiple Z3 random seeds reduce flakiness on hard rules.** Listing 3-10
  seeds and letting the Prover race them is a low-cost robustness boost.
- **`smt_timeout`** in seconds. 6000 (100 minutes) is a reasonable upper
  bound for hard rules; ratchet down for fast ones.

## 11. `package.metadata.certora`

This block in your `Cargo.toml` controls what `cargo certora-sbf` ships to
verification:

```toml
[package.metadata.certora]
sources = [
    "Cargo.toml",
    "src/**/*.rs",
    # Cross-crate dependencies — list explicitly:
    # "../shared/Cargo.toml",
    # "../shared/src/**/*.rs",
]
solana_inlining  = ["certora/summaries/cvlr_inlining_core.txt"]
solana_summaries = ["certora/summaries/cvlr_summaries_core.txt"]
```

Keep `sources` minimal. Every extra file adds compile time. If you have a
multi-crate workspace, list only the crates this verification job actually
touches.

`solana_inlining.txt` and `solana_summaries.txt` are environment files used
to fine-tune which functions the Prover inlines and which it summarises.
Start without them; add entries only when a specific rule demands it.

## 12. Layout convention

The recurring layout this guide assumes:

```
src/certora/
├── mod.rs              # module declarations
├── nondet.rs           # `impl Nondet for …` for project types
├── hooks.rs            # static flags + hook helpers
├── log.rs              # msg! stub + CvlrLog impls for project types
├── mocks/              # mirrors src/ tree, replaces heavy fns
│   ├── mod.rs
│   └── …
└── specs/
    ├── mod.rs
    ├── base.rs         # parametric harnesses (`base_deposit`, …)
    └── solvency/       # one folder per property family
        ├── mod.rs
        ├── props.rs    # `impl CvlrProp for SolvencyInvariant`
        └── solvency.rs # one #[rule] per (handler × property)
```

You don't have to follow it exactly, but the prove-it-works experience is
much better when files have predictable shapes:

- `nondet.rs` — only `impl Nondet`s, nothing else.
- `mocks/foo.rs` — only mock implementations, mirroring `src/foo.rs`.
- `specs/<topic>/<topic>.rs` — only `#[rule]` functions, one or two lines
  each.
- `specs/<topic>/props.rs` — only `CvlrProp` impls.

When something doesn't fit any of those buckets, that's a signal: you're
probably solving a different problem than you think you are.

## 13. Iterate on rules in a tight loop

A practical workflow:

1. Write the property in English. Give it an ID.
2. Write a sanity rule for the harness; confirm it fails (`cvlr_assert!(false)`).
3. Write a property struct + a `#[rule]` instantiating it.
4. Run on the cloud. Read the counterexample if any.
5. If the counterexample is real → fix the production code, **not** the
   spec.
6. If the counterexample is spurious → tighten an `assume`, or model the
   collaborator more precisely. Add a comment explaining why.
7. Re-run. Repeat.

```{tip}
The rule of thumb: **never silence a counterexample without writing down
why it was OK to ignore.**
```

## 14. Common antipatterns

- **A passing rule that asserts nothing meaningful.** The fastest way to
  ship a "verified" spec that protects nothing. Sanity-rule everything.
- **A 200-line rule.** Split it. The Prover is happier and so are reviewers.
- **Mocks that hard-code success.** `Ok(())` mocks should be the exception;
  `Ok(nondet())` is the default.
- **Importing production state types into rules and mutating fields by
  hand.** Use `Nondet` and `assume_pre` instead — it's clearer and
  composes.
- **Catching production bugs by reading Prover output, not the code.** When
  a counterexample reveals a real bug, fix the code; don't paper over with
  an assume.

## 15. Where to find more

- The high-level CVLR reference: {ref}`speclanguage`.
- `cvlr` source / API: [github.com/Certora/cvlr](https://github.com/Certora/cvlr).
- `cvlr-solana` source / API:
  [github.com/Certora/cvlr-solana](https://github.com/Certora/cvlr-solana/).
- Worked examples: [Certora/SolanaExamples](https://github.com/Certora/SolanaExamples).

Read the source when in doubt. The crates are small (a few hundred lines
each) and the `prelude` modules are excellent indexes.
