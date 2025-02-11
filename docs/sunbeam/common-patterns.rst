Common Spec Patterns
====================

Sunbeam specs often employ certain common patterns for checking properties of smart contracts. Here are a few of the most common ones.

Authorization Checks
--------------------

Many rules check that certain actions can only be performed by authorized users, typically a contract admin or the initiator of a proposal.

The pattern is:
1. Get the address attempting the action from the environment
2. Check if it matches the authorized address
3. Perform the action
4. Assert that unauthorized addresses can't perform the action

For example:
    .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn certora_create_ballot_must_be_initiator(e: Env, initiator: Address, category: BallotCategory, title: String, description: String) {    
            let params = BallotInitParams { initiator, category, title, description };
            require!(!is_auth(params.initiator.clone()), "not authorized");
            DAOContract::create_ballot(e, params);
            // create_ballot should have failed because the initiator did not authorize
            assert!(false)
        }
        // ... existing code ...

"At Most Once" Semantics
------------------------

Some rules check that certain actions can only be performed once, such as initializing a contract or retracting a proposal.

The pattern is:
1. Check the initial state 
2. Perform the action once
3. Check the state has changed as expected
4. Attempt the action again
5. Assert that the second attempt fails or has no effect

For example:
    .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn certora_config_can_only_be_called_once(
            env: Env, 
            admin1: Address, token1: Address, amount1: i128, deposit_params1: Map<BallotCategory, i128>, start_date1: u64,
            admin2: Address, token2: Address, amount2: i128, deposit_params2: Map<BallotCategory, i128>, start_date2: u64
        ) {
            DAOContract::config(env.clone(), ContractConfig { admin: admin1, token: token1, amount: amount1, deposit_params: deposit_params1, start_date: start_date1 });
            // Second call should fail
            DAOContract::config(env.clone(), ContractConfig { admin: admin2, token: token2, amount: amount2, deposit_params: deposit_params2, start_date: start_date2 });
            // Check that the second call failed (i.e., we should not reach this point).
            assert!(false);
        }
        // ... existing code ...

Monotonically Increasing IDs
----------------------------

When contracts generate unique IDs, rules often check that these IDs are monotonically increasing and can't overflow.

The pattern is:
1. Get the current max ID
2. Generate a new ID
3. Assert the new ID is equal to the old max + 1
4. Assert the new ID hasn't overflowed the max possible value

For example:
    .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn certora_ballot_id_increasing(e: Env, initiator: Address, category: BallotCategory, title: String, description: String) {    
            let params = BallotInitParams { initiator, category, title, description };
            let before = e.get_last_ballot_id();
            require!(before < u64::MAX, "ballot_id can't overflow");
            let id = DAOContract::create_ballot(e.clone(), params.clone());
            let after = e.get_last_ballot_id();
            assert!(after == id);
            // Check that the ballot_id is increasing, and that it's increasing *slowly*, so it can't overflow the 64-bit int.
            assert!(after == before + 1);
        }
        // ... existing code ...

State Transition Checks
-----------------------

Many rules check that state transitions occur as expected, such as a proposal moving from pending to accepted/rejected status.

The pattern is:
1. Set up an initial state
2. Perform an action
3. Assert the new state is as expected
4. Often also assert that further actions either fail or don't change state

For example:
    .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn certora_retract_ballot_can_only_be_called_once(e: Env, ballot_id: u64) {
            let before = get_ballot(&e, ballot_id).status;
            DAOContract::retract_ballot(e.clone(), ballot_id);
            let after = get_ballot(&e, ballot_id).status;
            assert!(before != BallotStatus::Retracted);
            assert!(after == BallotStatus::Retracted);
        }
        // ... existing code ...

Invariant Checks
----------------

Some rules check that certain invariants always hold, such as a user's balance never going negative.

The common pattern is to wrap the invariant check around calls to the contract:
1. Check the invariant holds initially
2. Perform some action
3. Check the invariant still holds
4. Return the result of the action

For example:
    .. code-block:: bash
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

These are some of the most common patterns you'll see in Sunbeam specs. Understanding these patterns can help you read and write specs more effectively. 