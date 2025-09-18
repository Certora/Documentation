```{role} cvl(code)
:language: cvl
```

# Listing Safe Assumptions

The "Listing Safe Assumptions" design pattern introduces a structured approach to document and validate essential assumptions. Let's delve into the importance of this design pattern using the provided example.

```{cvlinclude} /CVLByExample/Ecrecover/ecrecover.spec
:cvlobject: ecrecoverAxioms zeroValue ownerSignatureIsUnique
:caption: {clink}`ecrecover.spec</CVLByExample/Ecrecover/ecrecover.spec>`
:emphasize-lines: 4, 5
```

```{warning}
The _uniqueness of signature_ axiom is not sound. There are some rare cases where
{cvl}`ecrecover(h2, v, r, s)` will not return zero for the wrong hash. This is why
you must always check that the address returned by {cvl}`ecrecover` is the
correct one.
```

## Context:

In the example, we focus on the `ecrecover` function used for signature verification. The objective is to articulate and validate key assumptions associated with this function to bolster the security of smart contracts.

## Importance of Listing Safe Assumptions:

1. **Clarity and Documentation:**
   - The design pattern begins by explicitly listing assumptions related to the `ecrecover` function. This serves as clear documentation for developers, auditors, and anyone reviewing the spec. Clarity in assumptions enhances the understanding of expected behavior.

2. **Preventing Unexpected Behavior:**
   - The axioms established in the example, such as the zero message axiom and uniqueness of signature axiom, act as preventive measures against unexpected behavior. They set clear expectations for how the `ecrecover` function should behave under different circumstances, neglect all the counter-examples that are not relevant to the function intended behavior.

3. **Easy To Use:**
   - By encapsulating assumptions within the CVL function, this design pattern allow us to easily use those assumptions in any rule or invariant we desire.

In conclusion, the "Listing Safe Assumptions" design pattern, exemplified through the `ecrecover` function in the provided example, 
serves a broader purpose in specs writing. It systematically documents assumptions, prevents unexpected behaviors, 
and offers ease of use throughout the rules and invariants.
