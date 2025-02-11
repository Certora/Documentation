Soroban Types
=============

Sunbeam makes use of several Soroban-specific types for representing accounts, storage, and common data structures.

Env
---
The `Env` type represents the environment of a Soroban contract, including its storage, address, and other metadata. Many Sunbeam rules take an `Env` as a parameter to access the contract state.

For example:
   .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn certora_config_sanity(env: Env, admin: Address, token: Address, amount: i128, deposit_params: Map<BallotCategory, i128>, start_date: u64) {
            DAOContract::config(env, ContractConfig { admin, token, amount, deposit_params, start_date });
            satisfy!(true);
        }
        // ... existing code ...


Address
-------
The `Address` type represents an account address on the Soroban network. It's commonly used to represent token owners, contract admins, and other entities interacting with a contract.

Map
---
`Map` is Soroban's key-value store type, used for representing associative arrays in contract storage. Maps can be used with various key and value types.

An example of using a `Map` in a rule:
   .. code-block:: bash
        // ... existing code ...
        #[rule]
        pub fn certora_config_deposit_not_negative(env: Env, admin: Address, token: Address, amount: i128, deposit_params: Map<BallotCategory, i128>, start_date: u64, category: BallotCategory) {
            let initial: Option<i128> = env.storage().instance().get(&category);
            require!(initial.is_none(), "deposit initially unset");
            DAOContract::config(env.clone(), ContractConfig { admin, token, amount, deposit_params, start_date });
            assert!(env.get_deposit(category) >= 0);
        }
        // ... existing code ...

String and Vec
--------------
Soroban provides `String` and `Vec` types for representing text and sequences respectively. These are commonly used for metadata fields like token names, descriptions, etc.

Custom Enums
------------
Sunbeam specs often make use of custom enums to represent contract-specific types like token categories, proposal statuses, etc. 

For example:
   .. code-block:: bash
        // ... existing code ...
        pub enum BallotStatus {
            InProgress,
            Accepted, 
            Rejected,
            Retracted,
        }
        // ... existing code ...

These enums can then be used in rules:
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