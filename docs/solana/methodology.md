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

Start from the
[spec template's `run.conf`](https://github.com/Certora/solana-spec-template/blob/main/confs/run.conf)
and extend it per rule rather than reinventing the prover-args set per
project. The template ships:

```json
// run.conf
{
    "msg":                  "Certora Verification Rules",
    "loop_iter":            1,
    "optimistic_loop":      false,
    "smt_timeout":          6000,
    "cargo_tools_version":  "v1.43",
    "java_args": ["-Dlevel.sbf=info"],
    "prover_args": [
        "-unsatCoresForAllAsserts true",
        "-solanaSkipCallRegInst true",
        "-solanaTACOptimize 2",
        "-solanaStackSize 8192",
        "-solanaTACMathInt true"
    ]
}
```

Per-rule confs inherit and override:

```json
// deposit.conf
{
    "files":       ["run.conf"],
    "rule":        ["rule_solvency_deposit", "rule_monotonicity_deposit"],
    "rule_sanity": "basic"
}
```

A few guidelines for tuning these defaults:

- **`loop_iter`** controls loop unrolling depth. The template defaults to
  `1`; bump only for loops that genuinely need more iterations, and prefer
  bounded `Vec<T>` (see {ref}`solana_nondet_vectors`) for spec-driven
  bounds.
- **`solanaStackSize`** the template ships with `8192`; raise further only
  if you hit stack errors. Lowering does not help.
- **`smt_timeout`** is in seconds. 6000 (100 minutes) is a reasonable upper
  bound for hard rules; ratchet down for fast ones.
- **Multiple Z3 random seeds** are a low-cost robustness boost on flaky
  rules — append e.g.
  `"-s [z3:def{randomSeed=1},z3:def{randomSeed=2},z3:def{randomSeed=3}]"`
  to `prover_args`. Not in the template default; opt in when you need it.
- **`rule_sanity: basic`** runs the vacuity check on every rule (see
  {ref}`solana-sanity-vacuity`). Recommended for every conf.

## 11. Keep `package.metadata.certora` minimal

The `[package.metadata.certora]` block in your `Cargo.toml` controls what
`cargo certora-sbf` ships to verification. Every extra entry in `sources`
adds compile time, so list only the crates this verification job actually
touches; in a multi-crate workspace, do **not** glob the whole tree.

`cvlr_inlining.txt` and `cvlr_summaries.txt` are baseline annotations the
Prover needs to handle Rust / Solana stdlib correctly — they are required
scaffolding, not optional fine-tuning. Use the
[spec template's set](https://github.com/Certora/solana-spec-template/tree/main/envs)
unmodified for the stdlib parts, and add project-specific entries on top
when a particular rule demands it.

See {ref}`solana_project_setup` for the canonical block.

## 12. Layout convention

{ref}`solana_project_setup` shows the recommended source-tree layout. The
prove-it-works experience is much better when files have predictable
shapes:

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
- The Certora Solana spec template (recommended starting scaffold):
  [Certora/solana-spec-template](https://github.com/Certora/solana-spec-template).
- `cvlr` source / API: [github.com/Certora/cvlr](https://github.com/Certora/cvlr).
- `cvlr-solana` source / API:
  [github.com/Certora/cvlr-solana](https://github.com/Certora/cvlr-solana/).
- Worked examples: [Certora/SolanaExamples](https://github.com/Certora/SolanaExamples).

Read the source when in doubt. The crates are small (a few hundred lines
each) and the `prelude` modules are excellent indexes.
