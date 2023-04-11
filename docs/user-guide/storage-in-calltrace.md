Storage in CallTrace
============
The CallTrace should show the values in the storage of each contract during the execution of the counter example.  

How can the storage change?
---------------------------
While specific storage slots/fields can be assigned new values,
it is possible for the storage of the whole contract to revert to the previous state.  
This is as a result of either a Solidity require statement failing, explicit Solidity revert statement,
storage being restored to a previously saved state in CVL (e.g., `func() at init)`,
reset (`reset_storage currentContract` or `reset_storage allContracts`), or havoc’d (due to havoc’d functions’ calls).  

When do we show the storage state?
----------------------------------
At the beginning of the execution, right after the failed assert and internal function calls.  

What do we show?
----------------
For each contract in the spec, we show all storage access paths instantiated with concrete indices
(as determined by the counterexample), used (read / write) during the counter-example.  
These access paths are lexicography ordered.  
For each access path, we show its source-code name, value (if known), “computational type”,
and whether it was changed since the previous time we showed the storage.  

What are the “computational types”?
-----------------------------------
### There are currently four types:  
Concrete - the value of this variable in the counterexample is explicitly set to this value in the spec or contract,
so it must be similar in all counter examples.  
Don’t care - the value of this variable is not used before it is written, so its initial value is not relevant.  
Havoc - the SMT chooses a random value.  
Havoc dependent - the value is a result of some computation involving another havoc or havoc dependent variable.
We distinguish it from havoc’d variables, because if we know the values of all havoc’d variables,
this value can be calculated as well (unlike havoc’d variables which are completely random).  

Limitations of the current “computational type” resolution:
-----------------------------------------------------------
We currently only consider assignments and storage changes (store, havoc, reset, restore (`func() at init` and revert).  
However, we don’t consider requires or values that cause revert so in
```
uint256 a;
require a == 10
```
we consider `a` as havoc instead of concrete.
Additionally, in the following example
Solidity:
```
function foo(address sender) {
    require(sender == OWNER);
}
```
CVL:
```
address addr;
foo(addr);
```
we consider `addr` as havoc instead of concrete.

We don’t support showing strings / bytes keys of maps, so if `balances` is map with such keys,
they will be shown as `balances[*]` or `balances[hash_X]`.  
As a result, distinct keys may collide with each other when shown in the CallTrace.
