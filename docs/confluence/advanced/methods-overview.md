Overview
========

A specification may have a `methods` block that consists of _method declarations_. Each declares a function signature either in the contract being verified or in [other contracts in the verification context](multicontract.md).

Use Cases
---------

In general, we can reference contract functions without declaring them in the specification. Still, however, we may opt to declare an `external` or `public` contract function in the following use cases:

1.  **Making the specification more self-contained and readable.**
    
    *   We can use the `methods` block to
        
        *   list all the contract functions that are expected to exist in verification context;
            
        *   specify the contracts' interface against which the specification is written (e.g., ERC20).
            
2.  **Reusing the specification against contracts that implement subsets of an interface (e.g., ERC20).**
    
    *   Without a corresponding method declaration, a rule that refers to a contract function whose implementation is not found in the verification context would not pass the syntax check.
        
    *   Method declarations enable us to ignore rules that refer to functions not found in the current verification context and run the tool using only the relevant rules in the specification.
        
3.  **Declaring that the function is** `envfree`**, i.e., that it does not access the** [**execution environment of the EVM**](/docs/ref-manual/cvl/types.md)**, and, in particular, it is non-payable.**
    
    *   An `envfree` declaration allows the function to be referenced in either invoke commands or invoke expressions without giving an `env` type instance as the first input argument.
        
    *   If an implementation of the function exists in the contract, the tool would automatically generate rules to check that this implementation is indeed `envfree`.
        

Syntax
------

We demonstrate the syntax of method declarations through the example `methods` block shown below.

```cvl
using B as b

methods {
    foo02(uint, uint) returns (uint)
    
    b.foo03(uint) returns (uint) envfree

    foo01(uint x, uint y) returns (uint) envfree
}
```

*   Line 4 declares that a function whose signature is `foo02(uint, uint)` and whose return type is `uint` should exist in `currentContract`, i.e., the contract being verified.
    
*   Line 6 declares that a function whose signature is `foo03(uint)` should exist in the [imported contract](multicontract.md) `B` and have `uint` as its return type. Note that, in contrast to Line 4, it uses [multi-contract](multicontract.md) and, in addition, declares `b.foo03(uint)` as [envfree](#envfree).
    
*   Line 8 is similar to Line 6; the notable difference is that it declares a function in `currentContract`.
    

Summary Declarations
--------------------

A _summary declaration_ is a special case of a method declaration. It declares that a function signature should be summarized using the specified summary. For more details about summaries, see [Function Summarization](summaries.md).

As opposed to the declarations which we have considered thus far, summary declarations always implicitly apply to functions' signatures in “any contract”. That is, the summary applies to _any_ call, either external or internal, in the contracts being verified, such that (1) it calls to the declared signature (or [sighash](https://docs.soliditylang.org/en/v0.8.6/abi-spec.html#function-selector)); and (2) satisfies the [summary application policy](summaries.md) (i.e., either `ALL` or `UNRESOLVED`).

The example `methods` block shown below demonstrates the syntax of summary declarations.

```cvl
methods {
    foo03(uint) => ALWAYS(3) ALL
    
    foo02(uint, uint) => ALWAYS(2) UNRESOLVED
     
    0xd634d50a => ALWAYS(3) ALL // The sighash of foo3(uint)
    
    foo01(uint x, uint y) returns (uint) envfree => ALWAYS(1)
}
```

*   Line 2 declares that any call to a function whose signature is `foo03(uint)` should be summarized as `ALWAYS(3)` and according to an `ALL` policy.
    
*   Line 4 declares that any call to a function whose signature is `foo02(uint, uint)` should be summarized as `ALWAYS(2)`and according to an `UNRESOLVED` policy.
    
*   Line 6 is similar to Lines 2 and 4. The notable difference is that it uses the sighash of the function rather than its signature.
    
*   Line 8 combines a summary declaration with an `envfree` declaration. It declares an `ALWAYS(1)` summary for the signature `foo01(uint x, uint y)` in _any_ contract, whereas it declares that the function `foo01(uint x, uint y)` should exist in `currentContract` and its return type is `uint`.
    

```{note}
As shown in Line 8, we can omit the summary application policy (i.e., either `ALL` or `UNRESOLVED`). In this case, the default policy would be used. See [Function Summarization](summaries.md) for more details.
```

Method Declarations and Multi-Contract
--------------------------------------

Finally, notice that the use of [multi-contract](multicontract.md) in method declarations has the following restrictions:

1.  Multi-contract must not be used in summary declarations. Recall that summaries always implicitly apply to "any contract".
    
2.  Multi-contract should only be used in declarations that are _not_ summary declarations.
    
3.  When a valid `envfree` declaration is also a summary declaration (and therefore does not use multi-contract), the summary applies to "any contract" whereas the `envfree` declaration applies to `currentContract`.
