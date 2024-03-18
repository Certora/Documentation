Overview
========

A specification file is made up of several parts, each of which serves some purpose to interact with a contract or refine specifications in some way. The following shows an overview of the different parts of a specification file.

```cvl
 ******************************************************************
 * IMPORTS/SETUP                                                  *
 ******************************************************************
methods {
	some_function_from_the_contract(address) returns (uint256)
}

 ******************************************************************
 * USEFUL CONSTRUCTS.                                             *
 ******************************************************************
// advanced use for SMT speedup with ghosts
sort MyUninterpretedSort;

// uninterpreted functions, useful for describing contract state
ghost myGhostFunction(uint256, address) returns bool {
  axiom forall uint256 n. myGhostFunction(n, 0x0) == false;
}

// a way to interact with state changes in the contract via storage
// reads and writes
hook Sstore my_storage_mapping[KEY address key] uint256 value {
  havoc myGhostFunction assuming myGhostFunction@new(value, key);
}

// encapsulation of some commonly reused computation
function myCVLFunction(uint256 x, uint256 y) returns uint256 {
  if (x > y) {
    return x - y;
  } else {
    return y - x;
  }
}

 ******************************************************************
 * MEAT AND POTATOES:                                             *
 ******************************************************************
// the basic unit of a spec: the rule is how we actually specify
// behavior, typically by
// 1. making some assumptions on "unconstrained" variables
// 2. invoking a contract function
// 3. making some assertion about the result of that function
rule my_rule(address a) {
  require a != owner();
  some_function_from_the_contract(a);
  assert lastReverted;
}

// like super-rules, these automatically generate a base-case
// and inductive case for inductive invariants (rules are only
// really equipped to handle the inductive case)
invariant address_zero_gets_nothing_ever() 
	some_function_from_the_contract(0) == 0
```
