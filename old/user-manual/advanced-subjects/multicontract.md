# Multicontract

When we run the Certora Prover, we usually write the specification with a particular contract in mind. However, the checked contract may interact with other contracts, e.g., other contracts that belong to the same protocol, or 3rd party contracts such as ERC20.

The Certora Prover allows modeling the interaction between concrete instances of contracts. First, one has to include all relevant contracts in the verification context. For example, if we have `Protocol.sol` interacting with another contract `Auxiliary.sol`, we will run the tool as follows:

```text
certoraRun Protocol.sol Auxiliary.sol --verify Protocol:spec.spec
```

where `spec.spec` is our specification file.

We can now write rules that refer to functions of both `Protocol` and `Auxiliary` as follows:

```text
using Protocol as protocolInstance
using Auxiliary as auxInstance

rule example {
    assert protocolInstance.get1() == auxiliaryInstance.get2();
}
```

Note that `Protocol` and `Auxiliary` get a unique address. `get1()` is a method of `Protocol` and ```get2()``` is a method of `Auxiliary`.

If `Protocol` is calling `Auxiliary` within its code, then the call to `Auxiliary` should be either _inlined_ or _summarized_. We elaborate on that in the next section.

