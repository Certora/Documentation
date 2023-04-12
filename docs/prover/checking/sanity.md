Rule Sanity Checks
==================

The {ref}`--rule_sanity` option enables some automatic checks that can warn you
about certain classes of mistakes in specifications. The `—rule_sanity` options 
may be followed by one of `none`, `basic`, or `advanced` options to control which sanity checks should be executed.
 * With `--rule_sanity none` or without passing `--rule_sanity`, no sanity checks are performed.
 * With `--rule_sanity basic` or just `--rule_sanity` without a mode, the reachability check is performed for all rules and invariants, and the assert-vacuity check is performed for invariants.
 * With `--rule_sanity advanced`, all the sanity checks will be performed for all invariants and rules.

There are 3 kinds of sanity checks:

1. **Reachability** checks that even when ignoring all the user-provided
   assertions, the end of the rule is reachable. This check ensures that that
   the combination of `require` statements does not rule out all possible
   counterexamples.

   For example, the following rule would be flagged by the reachability check:
   ```cvl
   rule vacuous {
     uint x;
     require x > 2;
     require x < 1;
     assert f(x) == 2, "f must return 2";
   }
   ```
   Since there are no models satisfying both `x > 2` and `x < 1`, this rule
   will always pass, regardless of the behavior of the contract.  This is an
   example of a *vacuous* rule - one that passes only because the preconditions
   are contradictory.

   ```{caution}
   The reachability check will *pass* on vacuous rules and *fail* on correct
   rules.  A passing reachability check indicates a potential error in the rule.
   
   The exception is when a {term}`parametric rule` is checked on the default
   fallback function: The default fallback function should always revert, so
   there are no examples that can reach the end of the rule.
   ```
   
2. **Assert-Vacuity** checks that individual `assert` statements are not
   tautologies.  A tautology is a statement that is true on all examples, even
   if all the `require` and `if` conditions are removed.

   For example, the following rule would be flagged by the assert-vacuity check:
   
   ```cvl
   rule tautology {
     uint x; uint y;
     require x != y;
     ...
     assert x < 2 || x >= 2,
      "x must be smaller than 2 or greater than or equal to 2";
   }
   ```
  
  
   Since every `uint` satisfies the assertion, the assertion is tautological,
   which is likely to be an error in the specification.
   
   **Checking vacuity for invariants**
   
   For invariants, vacuity is checked by converting it into a rule that asserts the invariant expression without any require statements. Since a rule would check the assertion for all arbitrary starting states, if the rule passes, it means that the expression being asserted is a tautology. The invariant, which checks the expression for a smaller set of states, would also be a tautology.
   
   The `sanityCheck` contract below has two state variables `address root` and `uint a`. Due to the zero address checks in the `constructor` and the `changeRoot` function, the root address can never be zero. The `rootNonZero` invariant asserts that the root address is never zero. When we run this invariant with the `--rule_sanity` `advanced` or `basic` options, the prover creates a rule similar to the `rootNonZeroRule` below. This rule would fail since the tool could assume a starting state where the `root` is 0. This means that the invariant expression is not a tautology and the invariant passes. On the other hand the `aGE0` invariant, when run without the `--rule_sanity` option, will pass [view report](https://vaas-stg.certora.com/output/11775/871cf37193c75d27542b/?anonymousKey=dde443c4a806021716e863a454561a6ad1543d2e) but when we run it with the `--rule_sanity` `advanced` or `basic` options, the prover creates a rule similar to the `aGE0Rule` below. This rule passes, indicating that the invariant expression is a tautology. The verification report shows that the invariant failed vacuity check [view report](https://vaas-stg.certora.com/output/11775/4c4cb65f65c75f013c63/?anonymousKey=0b6a843857e6ead8e1bb1f11b984fb6e3e9fb6a8). 

    ```solidity
     contract sanityCheck{
     address root;
     uint a;
     constructor(address _root){
         require(_root != address(0));
         root = _root;
     }
     function changeRoot (address root_) public{
         require(root_ != address(0));
         root = root_;
     }
     }
     ```
   
   
    ```cvl
    
      // Not a tautology
      invariant rootNonZero()
         root() != 0

      rule rootNonZero(){
         assert root() != 0;
      }

      // Tautology
      invariant aGE0()
         a() >= 0

      rule aGE0Rule{
         assert a() >= 0;
      }

    ```
    
    **Checking vacuity for rules**
    
    For rules, checking for tautology requires checking each assertion to see if 
    it’s meaningful. In order to do this, we employ few different checks depending
    on the syntax of the assertion expression.
    
      *Case 1: Implication*
    
      Given a rule with an `assert p => q` we perform two checks:
    
      1. Implication hypothesis: `assert(!p)`
       
      If the hypothesis part is always false then the assertion is a tautology.
      
      ```cvl
              rule testSanity{
              uint a;
              uint b;
              assert a<0 => b<10;
              }
      ```
         
        
      Error message
        
      ```cvl
            assert-vacuity check FAILED: sanity.spec:11:5
            assert-tautology check FAILED: sanity.spec:11:5'a < 0 => b < 10' is a vacuous 
            implication. It could be rewritten to !a < 0 because a < 0 is always false
            
      ```
      
        
    2. Implication conclusion: `assert(q)`
       
       If the conclusion part is always true regardless of the hypothesis then the
       assertion is a tautology
       
        ```cvl
          rule testSanity{
          uint a;
          uint b;
          assert a>10 => b>=0;
          }
        ```
        
      Error Message
        
      ```cvl
              assert-tautology check FAILED: sanity.spec:21:5conclusion `b >= 0` is always true 
              regardless of the hypothesis
      ```
        
   *Case 2: Double Implication*
     
     Given a rule with an assert p <=> q we perform two checks:
     
     1. Double implication, both false: `assert(!p && !q)`
         If this passes then the assertion is a tautology since both conditions are always false.

           ```cvl
             rule sanityDoubleImplication1{
             uint a;
             uint b;
             assert a<0 <=> b<0;
             }
           ```
          
      Error message
           
      ```cvl
           assert-tautology check FAILED: sanity.spec:26:5'a < 0 <=> b < 0' could be rewritten 
           to !a < 0 && !b < 0 because both a < 0 and b < 0 are always false
      ```
           
      2. Double implication, both true: `assert(p && q)`
      
          If this passes then the is a tautology since both conditions are always true.
      
            ```cvl
              rule sanityDoubleImplication2{
              uint a;
              uint b;
              assert a>=0 <=> b>=0;
              }
            ```
           
     Error message
            
     ```cvl
            assert-tautology check FAILED: sanity.spec:33:5'a >= 0 <=> b >= 0' could be rewritten
            to a >= 0 && b >= 0 because both a >= 0 and b >= 0 are always true
     ```
            
   *Case 3: Disjunction*
   
      Given a rule with an assert p || q we perform two checks:
      
      1. Disjunction always true: `assert(p)`
          If this passes then the assertion is a tautology since the first expression is always true.

            ```cvl
              rule sanityDisjunction1{
              uint a;
              uint b;
              assert a>=0 || b>10;
              }
            ```
           
      Error message
            
      ```cvl
            assert-tautology check FAILED: sanity.spec:41:5the expression `a >= 0` is always true
      ```
            
      2. Disjunction always true: `assert(q)`
          
          If this passes then the assertion is a tautology since the second expression is always true.
          
            ```cvl
              rule sanityDisjunction2{
              uint a;
              uint b;
              assert a>10 || b>=0;
              }
            ```
            
      Error message
            
      ```cvl
            assert-tautology check FAILED: sanity.spec:47:5the expression `b >= 0` is always true
      ```

      
       

     
        
        
        
  


