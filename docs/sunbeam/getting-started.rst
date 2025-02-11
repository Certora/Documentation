Getting Started with Sunbeam
============================

What is Sunbeam?
----------------

Sunbeam is a tool for formally verifying Soroban smart contracts written in Rust. It allows you to write specifications describing the behavior and invariants of your contract, then mathematically proves that your code adheres to those specifications.

Installing Sunbeam
------------------

Sunbeam can be installed as a Rust library by adding the following to your `Cargo.toml`:

    .. code-block:: bash
        // ... existing code ...
        [dependencies]
        certora-soroban-macros = "0.1"
        certora = "0.1"
        nondet = "0.1"
        // ... existing code ...

You'll also need to install the Sunbeam CLI to run the prover. Instructions for this can be found in the Sunbeam repository.

Writing Specs
-------------

Specifications in Sunbeam are written as Rust functions annotated with the `#[rule]` attribute. These rules make assertions about your smart contract code using the `assert!`, `require!` and `satisfy!` macros.

For example, here is a spec asserting that adding liabilities to a user increases their total liabilities:

    .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn add_liabilities_increases_liabilities(env: &Env) {
            let mut user = User::nondet();
            let mut reserve = Reserve::nondet();
            let amount = i128::nondet();
            require!(amount > 0, "liabilities to add > 0");

            let pool_liabilities_before = user.get_liabilities(reserve.config.index);

            user.add_liabilities(env, &mut reserve, amount);

            let pool_liabilities_after = user.get_liabilities(reserve.config.index);
            assert!(pool_liabilities_after >= pool_liabilities_before + amount);
        }
        // ... existing code ...

See the Spec Syntax section for more details on the Sunbeam rule language. 