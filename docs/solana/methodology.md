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

- Forces you to define what you're proving before invoking the Prover.
- Makes Prover output traceable to a written specification.
- Gives reviewers a unit to look up.

A property without an ID is easily lost track of.

## 2. Don't disable the default sanity check

Do not overwrite `"rule_sanity"` in your conf without a reason. By default,
`"rule_sanity": "basic"` also executes a sanity check that there exists at least
one input reaching the rule's body end. The Prover internally adds a `cvlr_assert!(false)` to the rule. In case you see a sanity failure, place
`cvlr_assert!(false)` into your rule and verification code until you identify 
code that causes vacuity. For instance, code that always `panic!()` causes vacuity.

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

Verify one handler at a time. Instead of starting the verification at the entry point of the Solana program (`process_instruction`), verify specific handlers.

A rule that calls `process_instruction(...)` and expects to verify a
deep invariant will most likely be too complicated for the Prover and time out. Solana code is typically structured such that
`process_instruction(...)` dispatches the call to specific concrete
handlers using a discriminant. Write rules and invariants for these handlers instead. In case the code uses a framework such as `anchor` and `pinocchio`, dispatching in `process_instruction(...)` is auto-generated. In that case,
verify the code that forms the external API of the Solana program.

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

## 6. Pre/post snapshots

The vast majority of useful properties have the shape:

> *Before the handler ran, X. After it ran, Y.*

Read state into a value-only struct before, run the handler, read it again
after. The {ref}`cvlr-spec layer <solana_spec>` formalizes this —
predicates package the snapshot fields, `cvlr_spec!` packages
requires/ensures, and `cvlr_rules!` instantiates the cross-product across
handlers.

If you find yourself writing the same `let pre = …; let post = …;
cvlr_assert!(…)` pattern more than three times, factor it into a
predicate (`#[cvlr::predicate]`) and a `cvlr_spec!`.

## 7. Reach for `cvlr_rules!` once you have a property × handler grid

A protocol with M handlers and N properties yields M × N rules. Writing
each by hand is repetitive and lets typos drift the rules out of sync.
Once you have a working `cvlr_spec!` and one `base_<handler>` harness
per handler, let `cvlr_rules!` fan out the cross-product:

```rust
cvlr_rules! {
    name: "solvency",
    spec: cvlr_spec! { requires: IsSolvent, ensures: SolvencyPreserved },
    bases: [base_deposit, base_withdraw, base_redeem],
}
```

This expands to `solvency_deposit`, `solvency_withdraw`, and
`solvency_redeem`, each driven by the same spec. Adding a new handler
becomes one more entry in `bases`; adding a new property is one more
`cvlr_rules!` block. See {ref}`solana_spec` for the spec primitives and
{ref}`solana_parametric_rules` for the surrounding harness shape.

## 8. Use `NativeInt` for arithmetic invariants

When you assert a *mathematical* invariant — solvency, monotonicity, no
dilution — `u64` wraparound produces spurious counterexamples. Lift to
`cvlr::mathint::NativeInt` at the boundary, do the arithmetic there, and
re-bound at the end if needed. See {ref}`speclanguage` for the API and a
worked example.

When *not* to use `NativeInt`: when wraparound is the actual semantics
(counters, cyclic indices). Use it for invariants, not for simulating
native arithmetic.

## 9. Log all nondet inputs with `clog!`

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

## 10. `multi_assert_check` for compound rules

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
earlier ones holding). Then split the rule — say you have a rule with two asserts; when verifying the second assert, the first `assert` should be turned into an `assume`.

## 11. Conf hygiene

Start from the
[spec template's `run.conf`](https://github.com/Certora/solana-spec-template/blob/main/confs/run.conf)
and extend it per rule using `--override_base_config` rather than reinventing the prover-args set per rule. That is, write a `base.conf`:

```json
// base.conf
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
        "-solanaTACMathInt true"
    ]
}
```

and then the per-rule confs inherit and override:

```json
// deposit.conf
{
    "override_base_config": "base.conf",
    "rule":        ["rule_solvency_deposit", "rule_monotonicity_deposit"]
}
```

A few guidelines for tuning these defaults:

- **`loop_iter`** controls loop unrolling depth. The template defaults to
  `1`; bump only for loops that genuinely need more iterations. When your
  code uses an unbounded heap data structure such as `Vec<T>` (see {ref}`solana_nondet_vectors`), replace it with a bounded data structure for verification.
- **Multiple Z3 random seeds** are a low-cost robustness boost on flaky
  rules — append e.g.
  `"-s [z3:def{randomSeed=1},z3:def{randomSeed=2},z3:def{randomSeed=3}]"`
  to `prover_args`. Not in the template default; opt in when you need it.
- **`rule_sanity: basic`** runs the vacuity check on every rule (see
  {ref}`solana-sanity-vacuity`). Recommended for every conf.

## 12. Keep `package.metadata.certora` minimal

The `[package.metadata.certora]` block in your `Cargo.toml` controls what
`cargo certora-sbf` ships to verification. Every extra entry in `sources`
adds compile time, so list only the crates this verification job actually
touches; in a multi-crate workspace, do **not** glob the whole tree.

```{warning}
Files listed in `sources` are **uploaded to the Certora cloud** to power
*Jump to Source* in the rule report. If that report is shared _publicly_
via the "Copy Link" button in the web report, these sources are also
available publicly. See {ref}`solana_project_setup`
for the full discussion.
```

`cvlr_inlining.txt` and `cvlr_summaries.txt` are baseline annotations the
Prover needs to handle Rust / Solana stdlib correctly — they are required
scaffolding, not optional fine-tuning. Use the
[spec template's set](https://github.com/Certora/solana-spec-template/tree/main/envs)
unmodified for the stdlib parts, and add project-specific entries on top
when a particular rule demands it.

See {ref}`solana_project_setup` for the canonical block.

## 13. Layout convention

{ref}`solana_project_setup` shows the recommended source-tree layout. The
prove-it-works experience is much better when files have predictable
shapes:

- `nondet.rs` — only `Nondet` derives / impls, nothing else.
- `mocks/foo.rs` — only mock implementations, mirroring `src/foo.rs`.
- `specs/<topic>/<topic>.rs` — only `#[rule]` functions and the
  `cvlr_rules!` blocks that emit them.
- `specs/<topic>/preds.rs` — only `#[cvlr::predicate]` definitions and
  reusable predicate constructors.

Code that does not fit any of these buckets is a signal that the task
may have been misframed.

## 14. Iterate on rules incrementally

A practical workflow:

1. Write the property in English. Give it an ID.
2. Write a property struct + a `#[rule]` instantiating it.
3. Run on the cloud. Read the counterexample if any.
4. If the counterexample is real → fix the production code, **not** the
   spec.
5. If the counterexample is spurious → tighten it by adding an `assume`. Add a comment explaining why.
6. Re-run. Repeat.

```{tip}
Guideline: **never silence a counterexample without recording the
justification.**
```

## 15. Common antipatterns

- **A passing rule that asserts nothing meaningful.** Produces a
  "verified" spec with no actual coverage. Apply the sanity check to
  every rule.
- **A 200-line rule.** Split it — both the Prover and reviewers benefit
  from smaller units.
- **Mocks that hard-code success.** `Ok(())` mocks should be the exception;
  `Ok(nondet())` is the default.
- **Importing production state types into rules and mutating fields by
  hand.** Use `Nondet` to havoc the state and a `#[cvlr::predicate]`
  to constrain it instead — it's clearer and composes.
- **Catching production bugs by reading Prover output, not the code.** When
  a counterexample reveals a real bug, fix the code; don't add assumes to
  make the rule pass.

## 16. Where to find more

- The high-level CVLR reference: {ref}`speclanguage`.
- The Certora Solana spec template (recommended starting scaffold):
  [Certora/solana-spec-template](https://github.com/Certora/solana-spec-template).
- `cvlr` source / API: [github.com/Certora/cvlr](https://github.com/Certora/cvlr).
- `cvlr-solana` source / API:
  [github.com/Certora/cvlr-solana](https://github.com/Certora/cvlr-solana/).
- Worked examples: [Certora/SolanaExamples](https://github.com/Certora/SolanaExamples).
