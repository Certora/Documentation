# Checking Specifications

Effective formal verification relies on accurate specifications. A flaw in the specification could lead to critical bugs slipping through undetected. Certora offers a set of tools to enhance the accuracy of specifications and identify potential issues. This chapter outlines these tools and demonstrates their application.

## Detecting Vacuous Specifications

A vacuous statement is one that is technically true but lacks meaningful content. Consider the following example:

**Contract:**
```solidity
function balanceOf(address account, uint256 id) public view override returns (uint256) {
    require(account != address(0), "account is zero");
    return _balances[id][account];
}
```

**Specification:**
```cvl
rule held_token_should_exist{
    address user;
    uint256 token;
    require balanceOf(0, token) == 0;

    require balanceOf(user, token) <= totalSupplyOf(token);
    assert balanceOf(user, token) > 0 => token_exists(token);
}
```

The specification contains a flaw; the statement `balanceOf(0, token) == 0;` will always revert due to the `require` in the contract, resulting in an empty starting state. To address such issues, Certora allows to run [Vacuity checks](https://docs.certora.com/en/latest/docs/prover/checking/sanity.html?highlight=rule%20sanity#sanity-vacuity). These checks append `assert false` to each rule, exposing vacuously proven assumptions. This ensures that every rule in the specification has at least one input that reaches all the assertions. It is a useful check, but nevertheless, it is not a good measure for coverage.
for more information on coverage measure checkout [mutation testing](https://docs.certora.com/en/latest/docs/prover/checking/mutation.html?highlight=rule%20mutation#mutation-testing).

*Note: Vacuity in real-world examples often arises from combinations of requirements, not just isolated statements.*

## Identifying Tautology Specifications

Tautology, a special case of vacuity known as the "vacuous assertion," occurs when a statement is always true regardless of the system's state. An example is provided below:

```cvl
rule something_is_always_transferred{
    address receiver;
    uint256 balance_before_transfer = balanceOf(receiver);
    require balanceOf(receiver) == 0;

    uint256 amount;
    require amount > 0;

    transfer(receiver, amount);
    uint256 balance_after_transfer = balanceOf(receiver);
    assert balanceOf(receiver) <= balance_after_transfer;
}
```

In this case, the `assert` statement is always true since it compares equal values, neglecting any meaningful checks related to the transfer behavior. Certora allows to run [Assert tautology checks](https://docs.certora.com/en/latest/docs/prover/checking/sanity.html?highlight=rule%20sanity#assert-tautology-checks) to address such instances. By removing preconditions and operations, these checks focus solely on the `assert` statement, revealing whether it is always true regardless of the process being examined.

## Conclusion

For more comprehensive examples and solutions, please refer to our [documentation](https://docs.certora.com/en/latest/docs/prover/checking/index.html). Certora's suite of verification tools empowers developers to enhance the precision of their specifications, ensuring robust and reliable smart contract development.