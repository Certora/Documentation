Sunbeam Spec Syntax
===================

Sunbeam specs are written as Rust functions annotated with the `#[rule]` attribute. Within a rule, you can make assertions about your smart contract using the Sunbeam assertion macros.

Rules
-----

Rules are the basic building block of Sunbeam specs. A rule is a Rust function annotated with `#[rule]` that describes a property that should always hold for your smart contract. 

For example:
<<<<<<< HEAD
   .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn add_liabilities_increases_liabilities(env: &Env) {
            // rule body
        }
        // ... existing code ...

=======

// ... existing code ...
#[rule]
pub fn add_liabilities_increases_liabilities(env: &Env) {
    // rule body
}
// ... existing code ...
>>>>>>> 97d38f9c40df1d224720a47b9100ae071db5e618

Within a rule you'll typically:
1. Set up some initial state, often using `nondet` values
2. Capture values before performing an operation 
3. Perform the operation you want to test
4. Assert properties that should hold after the operation

Assertions
----------

Within rules, you make assertions using the `assert!`, `require!` and `satisfy!` macros:

- `require!(expr, "msg")`: Asserts that the expression `expr` must hold at this point in the rule, like a precondition. Fails the rule if `expr` is false.
- `assert!(expr)`: Asserts that `expr` must hold at this point, like a postcondition. Fails the rule if `expr` is false.  
- `satisfy!(expr)`: Asserts that `expr` is satisfiable. Fails if there is no possible way for `expr` to be true.

Nondet
------

The `nondet` module provides functions for generating arbitrary values of a given type. This is useful for setting up test states that explore many possible inputs.

For example, `i128::nondet()` generates an arbitrary `i128` value. 

There are `nondet` functions for all the primitive Rust types, as well as some Soroban-specific types like `Address::nondet()`.

You can also define `nondet` functions for your own types:

<<<<<<< HEAD
   .. code-block:: bash
        // ... existing code ...
        impl User {
            pub fn nondet() -> Self {
                User {
                    liabilities: i128::nondet(),
                    collateral: i128::nondet(),
                    supply: i128::nondet(),
                }
            }
        }
        // ... existing code ...
=======
// ... existing code ...
impl User {
    pub fn nondet() -> Self {
        User {
            liabilities: i128::nondet(),
            collateral: i128::nondet(),
            supply: i128::nondet(),
        }
    }
}
// ... existing code ...
>>>>>>> 97d38f9c40df1d224720a47b9100ae071db5e618

See the :doc:`soroban-types` section for more on the types commonly used in Sunbeam specs. 