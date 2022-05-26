
While CVL has many builtin types which largely reflect the type system of Solidity, it is possible to define new types in within a solidity file. Specifically it is possible to define the following:

- Enum Types
- User Defined Value Types (similar to aliases but not quite)
- Structs

It is impossible to declare _new_ such types in a spec file, but it is possible to use such a type by importing the contract which contains it. For example, suppose we have the contract:

```solidity 
MyContract.sol:
contract MyContract {
    enum MyEnum {
        element_one,
        element_two
    }

    type MyUDT is uint256;

    struct MyStruct {
        uint256 field1;
        uint32  field2;
    }
}
```

The following are examples of what is possible in a rule:

```cvl
test.spec:

// you must import the contract which contains the type
using MyContract as c

rule myRule {
    // declare a variable of type MyEnum and assign to it
    c.MyEnum e = c.MyEnum.element_one;

    // declare a variable of type MyUDT and assign to it
    uint256 x;
    c.MyUDT v = x;

    // declare a variable of type MyStruct and assign to its members
    // (struct literals are not supported)
    uint256 a;
    uint32 b;
    c.MyStruct s;
    s.field1 = a;
    s.field2 = b;
}

```