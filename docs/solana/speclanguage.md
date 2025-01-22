# Certora Verification Language for Rust (CVLR)

CVLR stands for Certora Verification Language for Rust. It is pronounced like "cavalier". 
CVLR provides the basic primitives for writing verification rules that specify
pre- and post-conditions for client code. Unlike CVL for Solidity, CVLR is
embedded in Rust. It is compiled by the Rust compiler and has simple operational
semantics.

## Assertions

The simplest feature of CVLR are assertions. An assertion is written as
`cvlr_assert!(cond)`, where `cond` is the condition being asserted.
The semantics is the same as traditional asserts in Rust -- an assertion is
violated if there is (a panic-free) execution that reaches `cvlr_assert!(cond)`
and in the current execution state `cond` is false.

For example, `cvlr_assert!(true)` is never violated, while `cvlr_assert!(false)`
is always violated when reached.

What makes `cvlr_assert!()` special is that it is verified symbolically by the
Certora Prover. That is, the Prover returns `Violated` if there is an input and
an execution of the program that reaches that assertion and violates it.

Often, the intended meaning of an assertion is to not be violated, i.e., to
hold on all possible executions. However, sometimes it is useful to check
whether some execution is possible. In that case, the specification intends for
the assertion to be reachable. For such cases, CVLR provides a satisfy
assertion, called `cvlr_satisfy!(cond)`. 

The semantics of `cvlr_satisfy!(cond)` is that it is `Violated` when it is
either not reached, or when every execution that reaches it, violates the
condition. For example, `cvlr_satisfy!(true)` is violated only if it is never
reachable (i.e., part of dead code), and `cvlr_satisfy!(false)` is always
violated.

## Assumptions

Assumptions provide a way to restrict input to reflect some pre-condition. CVLR
provides an assumption macro `cvlr_assume!(cond)`. If an execution reaches
`cvlr_assume!(cond)`, it continues only if `cond` is true in the current program
state. Otherwise, the execution aborts.

For example, `cvlr_assume!(true)` is a noop, while `cvlr_assume!(false)` blocks
all executions that reach it.

A typical use of `cvlr_assume!` is to restrict a range of a value beyond the
restriction afforded by its type. For example, restricting the maximum value of
a variable to `100` can be done as follows:
```rust
let fee_bps = get_some_fee();
cvlr_assume!(fee_bps <= 100)
// computation reaches here only if fee_bps is no greater than 100
```

## Nondeterministic Values

A specification must tell the Prover what are the (symbolic) inputs that the
Prover has to explore. Such values are called non-deterministic. The name comes
from the fact that the Prover chooses the values non-deterministically (i.e., not
following any specific pre-determined exploration scheme or probability
distribution). Nondet values are similar to *arbitrary* values in property-based
testing, except that they are not chosen randomly, but are explored
exhaustively via symbolic reasoning.

CVLR provides a generic function `nondet()` that can generate non-deterministic
values of all primitive integers. For example, `nondet::<u64>()` returns a
non-deterministic `u64`, and `nondet::<u16>()` returns a non-deterministic
`u16`.

## CVLR Rules

Specifications are written as pre- and post-conditions in rules. A rule is
similar to a unit test. However, instead of being executed for some specific
input, the rule is symbolically analyzed for all possible values of
non-deterministic values.

In CVLR, rules are regular Rust functions, annotated with `#[rule]`.

A complete example of a specification with several rules is shown below.
The function being verified is `compute_fee`. We have included it in the spec
file for simplicity.

```rust
use cvlr::{nondet, asserts::*, cvlr_rule as rule, clog};

pub fn compute_fee(amount: u64, fee_bps: u16) -> Option<u64> {
    if amount == 0 { return None; }
    let fee = amount.checked_mul(fee_bps).checked_div(10_000);
    Some(fee)
}

#[rule]
pub fn rule_fee_sanity() {
   compute_fee(nondet(), nondet()).unwrap();
   cvlr_satisfy!(true); 
}

#[rule]
pub fn rule_fee_assessed() {
    let amt: u64 = nondet();
    let fee_bps: u16 = nondet();
    cvlr_assume!(fee_bps <= 10_000);
    let fee = compute_fee(amt, fee_bps).unwrap();
    clog!(amt, fee_bps, fee);
    cvlr_assert!(fee <= amt);
    if fee_bps > 0 { cvlr_assert!(fee > 0); }
}

#[rule]
pub fn rule_fee_liveness() {
    let amt: u64 = nondet();
    let fee_bps: u16 = nondet();
    cvlr_assume!(fee_bps <= 10_000);
    let fee = compute_fee(amt, fee_bps);
    clog!(amt, fee_bps, fee);
    if fee.is_none() { cvlr_assert!(amt == 0); }
}
```

The rule `rule_fee_sanity` checks that the function under verification has at
least one panic-free execution. A rule like that is called a sanity rule. It is
a good practice to start a specification with such a rule.

The rule `rule_fee_assessed` checks that a fee can be computed for an arbitrary amount.
There are two assertions. The first checks that the fee is never greater than
the amount. The second checks that the fee is always assessed when required.
The first assertion is not violated. However, the second is. Can you spot the bug?
Note that we have also added calls to the log macro `clog!` that is similar to
`dbg!` macro in Rust. The `clog!` macro will instruct the Prover to produce the
values of the desired variables in any violating execution.

The rule `rule_fee_liveness` checks that the fee is always computed, except when
the fee rate is 0. This assertion is violated. Can you spot the bug?

