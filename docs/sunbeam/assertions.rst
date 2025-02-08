satisfy!
--------

In addition to `assert!` and `require!`, Sunbeam provides a `satisfy!` macro for checking satisfiability of conditions.

`satisfy!(expr)` asserts that the expression `expr` is satisfiable, i.e., there exists some input for which `expr` evaluates to true. If `expr` is unsatisfiable (always false), the rule will fail.

For example:
#[rule]
pub fn certora_config_sanity(env: Env, admin: Address, token: Address, amount: i128, deposit_params: Map<BallotCategory, i128>, start_date: u64) {
    DAOContract::config(env, ContractConfig { admin, token, amount, deposit_params, start_date });
    satisfy!(true);
}

In this case, `satisfy!(true)` is always satisfiable, so the rule will pass as long as the `DAOContract::config` call doesn't revert.

`satisfy!` can be useful for checking that certain desirable conditions are possible, without asserting that they always hold. For example, you might use `satisfy!` to check that it's possible for a user to earn a reward, without requiring that all users always earn rewards.

However, in many cases `assert!` is more appropriate than `satisfy!`. Only use `satisfy!` if you specifically want to check for satisfiability rather than asserting that a condition always holds. 