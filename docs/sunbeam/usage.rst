User Guide For Sunbeam
======================

Before reading this, make sure you have followed the installation guide.

What is Sunbeam?
----------------

Sunbeam is a tool for formally verifying Soroban smart contracts written in Rust. It allows you to write specifications describing the behavior and invariants of your contract, then mathematically proves that your code adheres to those specifications.

Writing Specs
-------------

Specifications for Sunbeam are written as Rust functions. We use Certora's `Cavalier spec library <https://github.com/Certora/cvlr>`_ which relies on Rust macros. You may also require some of the `Soroban specific macros <https://github.com/Certora/cvlr-soroban/>`_.


Rules and assertions
--------------------

A specification is simply a function annotated with the `#[rule]` attribute. These rules make assertions about your smart contract code using the `cvlr_assert!`, `cvlr_assume!` and `cvlr_satisfy!` macros. For example:


.. code-block:: bash

    #[rule]
    fn transfer_is_correct(e: Env, to: Address, from: Address, amount: i64) {
        cvlr_assume!(
            e.storage().persistent().has(&from) && e.storage().persistent().has(&to) && to != from,
            "addresses exist and different"
        );
        let balance_from_before = Token::balance(&e, from.clone());
        let balance_to_before = Token::balance(&e, to.clone());
        Token::transfer(&e, from.clone(), to.clone(), amount);
        let balance_from_after = Token::balance(&e, from.clone());
        let balance_to_after = Token::balance(&e, to.clone());
        cvlr_assert!(
            (balance_to_after == balance_to_before + amount)
                && (balance_from_after == balance_from_before - amount)
        );
    }


Depending on the property you prove, it is possible that you may need to define "ghost variables" that are intended only for verification. A simple example can be found `here <https://github.com/Certora/reflector-subscription-contract/blob/51944577dc4536e9cf9711db6e125fe1e2254054/src/lib.rs#L44>`_. We encourage you to look into its usage to understand how you may use a similar approach.

Nondet
------

When formally verifying real-world programs, it is not uncommon to encounter "solver timeouts". This means that the underlying SMT solver timed out and was not able to verify the property. One way to mitigate this is by summarizing the code.

A common summary that is often used is `nondet`. This essentially allows the prover to use a nondeterministically chosen value for that variable. Sunbeams's spec language, Cavalier provides `nondet` implementations for various primitive types. Additional ones for Soroban are also provided `here <https://github.com/Certora/cvlr-soroban/blob/main/cvlr-soroban/src/nondet.rs>`_. More can be added to this repository as needed.

You can also implement `nondet` for user defined types like so:

.. code-block:: bash
    // Example from the Blend protocol's codebase
    pub struct Q4W {
        pub amount: i128, // the amount of shares queued for withdrawal
        pub exp: u64,     // the expiration of the withdrawal
    }
    
    impl cvlr::nondet::Nondet for Q4W {
        fn nondet() -> Self {
            Self {
                amount: cvlr::nondet(),
                exp: cvlr::nondet()
            }
        }
    }

Examples
--------

We encourage users to check out the `Sunbeam Tutorials <https://certora-sunbeam-tutorials.readthedocs-hosted.com/en/latest/>`_ for learning more about how to use the tool.
