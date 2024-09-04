(transient-storage)=
Transient Storage
=================

[Transient storage in EVM contracts](https://eips.ethereum.org/EIPS/eip-1153) is a contract-specific key-value
mapping that persists throughout a single EVM transaction.
Therefore, a contract being invoked several times during a single
transaction (like in reentrancy), will share the same transient storage.
When a transaction completes, transient storage is nullified.

The Certora Prover currently models the transient storage as follows:
- Each rule is assumed to run in an already active transaction,
and does not assume the contracts' transient storage is nullified at
the beginning of the rule.
- Different calls made from CVL to different contracts do
not assume a new transaction starts. Similar to regular (persistent)
storage, the previous transient storage saved by the previous contract 
call is used for the next call.
- Reverts and havoc impact the transient storage in the same way they impact the regular storage.
- In {ref}`invariants <invariants>`, only the constructor check (base-step) of the invariant assumes a nullified transient storage for the contract.
- The usage of `at` {ref}`syntax <storage-type>` also resets the transient storage to the values
represented by the mentioned `storage` variable.
- Different environment variables passed to calls have no effect on the transient storage. In particular, one may wish to use different starting `storage` states for calls that receive environment variables with different values of `tx.origin`.