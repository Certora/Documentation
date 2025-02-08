Helper Functions
================

Sunbeam specs often make use of helper functions to encapsulate common logic that is used across multiple rules. This can make specs more readable and maintainable.

Defining Helpers
----------------

Helper functions in Sunbeam are just regular Rust functions. They can take parameters, perform computations, and return values just like any other function.

The key difference is that helper functions are not annotated with `#[rule]`, so they are not directly checked by the Sunbeam prover. Instead, they are called from within rules.

Here's an example helper function that converts token quantities between the pool and user scales:

// ... existing code ...
pub(crate) fn certora_convert_to_tokens(pool_shares: i64, pool_tokens: i64, shares: i64) -> i64 {
    if pool_shares == 0 {
        return shares;
    }
    shares * pool_shares / pool_tokens
}
// ... existing code ...

Using Helpers in Rules
----------------------

To use a helper function in a rule, simply call it like you would any other Rust function.

For example, here's a rule that uses the `certora_convert_to_tokens` helper:

// ... existing code ...
#[rule]
pub fn simple_token_roundtrip_correct(pool_shares: i64, pool_tokens: i64, tokens: i64) {
    require!(
        tokens >= 0 && pool_shares > 0 && pool_tokens > 0,
        "quantity of tokens cannot be negative"
    );
    let tokens_res = certora_convert_to_tokens(
        pool_shares,
        pool_tokens,
        certora_convert_to_shares(pool_shares, pool_tokens, tokens),
    );
    assert!(tokens >= tokens_res);
}
// ... existing code ...

Common Uses
-----------

Some common uses for helper functions in Sunbeam specs include:

- Performing conversions or computations
- Querying contract state
- Checking preconditions or invariants
- Wrapping contract calls for invariant checks

For example, here's a helper that wraps a contract call to check that an invariant holds before and after:

// ... existing code ...
pub fn get_balance_wrapped(e: &Env, user: Address) -> i128 {
    let before = e.get_balance(user);
    // Perform some operation that should maintain the invariant
    // ...
    let after = e.get_balance(user);
    assert!(before == after, "Balance should not change");
    after
}
// ... existing code ...

This pattern of wrapping contract calls to check invariants is quite common in Sunbeam specs. 