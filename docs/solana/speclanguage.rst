Certora Verification Language for Rust (CVLR)
=============================================

CVLR stands for Certora Verification Language for Rust. It is pronounced like "cavalier". 
CVLR provides the basic primitives for writing verification rules that specify
pre- and post-conditions for client code. Unlike CVL for Solidity, CVLR is
embedded in Rust. It is compiled by the Rust compiler and has simple operational
semanitcs.

Assertions
----------

The simplest feature of CVLR are assertions. An assertion is written as
`cvlr_assert!(cond)`, where `cond` is the condition being asserted.
The semantics is the same as traditional asserts in Rust -- an assertion is
violated if there is (a panic-free) execution that reaches `cvlr_assert!(cond)`
and in the current execution state `cond` is false.

For example, `cvlr_assert!(true)` is never violated, while `cvlr_assert!(false)`
is always violated when reached.

What makes `cvlr_assert!()` special is that it is verified symbolically by the
Certora Prover. That is, the Procer returns `Violated` if there is an input and
an execution of the program that reachaes that assertion and violates it.

Often, the intended meaning of an assertion is to not be violoated, i.e., to
hold on all possible executions. However, sometimes it is useful to check
whether some execution is possible. In that case, the specification itends for
the assertion to be reachable. For such cases, CVLR provides a satisfy
assertion, called `cvlr_satisfy!(cond)`. 

The semantics of `cvlr_satisfy!(cond)` is that it is `Violated` when it is
either not reached, or when every execution that reaches it, violates the
condition. For example, `cvlr_satisfy!(true)` is violated only if it is never
reachalbe (i.e., part of dead code), and `cvlr_satisfy!(false)` is always
violated.

Assumptions
-----------

Used to specify pre-conditions. `cvlr_assume!`. Semantically, same as `cvlr_assert!`, 
but panics if the condition is false. Do an example with bps

```rust
let fee_bps = get_some_fee();
cvlr_assume!(fee_bps <= 10_000)
// computation reaches here only if fee_bps is no greater than 10_000 
```

Nondeterministic Values
-----------------------

Similar to arbitrary values in property-based testing. Evaluated symbolically by
the prover. The prover checks that for every value of non-deterministic values,
every execution that satisfies all the assumptions, does not violate any of the
assertions.

CVLR Rules
----------

Specifications are written as pre- and post-conditions in rules. A rule is
similar to a unit test. However, instead of being executed for some specific
input, the rule is symbolically analyzed for all possible values of
non-detemrinistc values.

A complete example of a specification.

```rust
use cvlr::{nondet, asserts::*, cvlr_rule as rule, clog};

pub fn compute_fee(amount: u64, fee_bps: u16) -> Option<u64> {
    if amount == 0 { return None; }
    let fee = amount.checked_mul(fee_bps).checked_div(10_000);
    Some(fee)
}

#[rule]
pub fn rule_fee_assesed() {
    let amt: u64 = nondet();
    let fee_bps: u16 = nondet();
    cvlr_assume!(fee_bps <= 10_000);
    let fee = compute_fee(amt, fee_bps).unwrap();
    clog!(amt, fee_bps, fee);
    cvlr_assert!(fee <= amt);
    if fee_bps > 0 { cvlr_assert!(fee > 0); }
}

#[rule]
pub fn rule_fee_sanity() {
   compute_fee(nondet(), nondet()).unwrap();
   cvlr_satisfy!(true); 
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

First assertion succeeds, the second fails because rounding is toward 0. 
Code also has overflow which means it will reject fee for large values.

* What is CVLR?
* How to use CVLR?
* Overview of all important macros (assert, assume, cex_print...)