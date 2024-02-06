# Require Invariants: Proving inter-dependent invariants

The`requireInvariant` statements can be used to establish 
crucial conditions that must persist throughout the execution of a smart contract. Let's explore the 
usefulness of the `requireInvariant` statement and illustrate its application using the provided example.

```cvl
invariant totalSharesLessThanDepositedAmount()
    totalSupply() <= depositedAmount();

invariant totalSharesLessThanUnderlyingBalance()
    totalSupply() <= underlying.balanceOf(currentContract)
    {
        preserved with(env e) {
            require e.msg.sender != currentContract;
            requireInvariant totalSharesLessThanDepositedAmount();
            requireInvariant depositedAmountLessThanContractUnderlyingAsset();
        }
    }

rule sharesRoundingTripFavoursContract(env e) {
    uint256 clientSharesBefore = balanceOf(e.msg.sender);
    uint256 contractSharesBefore = balanceOf(currentContract);

    requireInvariant totalSharesLessThanDepositedAmount();
    require e.msg.sender != currentContract;

    uint256 depositedAmount = depositedAmount();

    uint256 clientAmount = withdraw(e, clientSharesBefore);
    uint256 clientSharesAfter = deposit(e, clientAmount);
    uint256 contractSharesAfter = balanceOf(currentContract);
    assert (clientAmount == depositedAmount) => clientSharesBefore <= clientSharesAfter; 
    
    // all other states
    assert (clientAmount < depositedAmount) => clientSharesBefore >= clientSharesAfter;
    assert contractSharesBefore <= contractSharesAfter;
}
```

## Importance of Require Invariants:

1. **Ensuring Invariant Consistency:**
   - The `totalSharesLessThanUnderlyingBalance` invariant expands the validation scope to include the 
   underlying balance of the current contract. By utilizing the previously established 
   `totalSharesLessThanDepositedAmount` invariant as a prerequisite, the specification writer ensures that the 
   total shares in the contract remain within the limits of the underlying asset balance. This 
   `requireInvariant` approach effectively eliminates counterexamples in states that have already been proven 
   to be unattainable.

2. **Validation Through Rules:**
    - The `sharesRoundingTripFavoursContract` rule showcases the application of require invariants to verify 
    the behavior of share transactions. Similarly to the invariant example, the `requireInvariant` statements 
    enable the specification writer to disregard counterexamples in states that are not relevant to the 
    intended behavior.

```{todo}
show example run links where we try to remove one of the `requireInvariant` and get a false violation, and explain it.
```

In conclusion, the "Require Invariants" design pattern, as demonstrated through the provided example, offers a 
systematic methodology to define, validate, and uphold critical conditions within smart contract 
specifications.
for more information, please visit the [documentation](../../cvl/statements.md).