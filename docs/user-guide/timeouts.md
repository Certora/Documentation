Managing Timeouts
=================

```{todo}
This chapter is incomplete.  The old documentation has a section on
{doc}`troubleshooting </docs/confluence/perplexed>` that addresses timeouts.  There
is also some helpful information in the section on
{ref}`summarization <old-summary-example>`.
Some of the information in these references is out of date.
```

What causes timeouts?
---------------------

The complexity check
--------------------

Summarizing complex functions
-----------------------------

Modular verification
--------------------

Flags for tuning the Prover
---------------------------

Introduction
------------

Probably the hardest practical problem with using the Certora prover is time-outs: the case where the SMT solver is unable to provide a solution (verify or provide a counter-example) for the rule we have written in our spec. The tool either doesn’t have enough time (resources) to solve the underlying problem, or it is too hard for the solver to simplify the generated SMT formula and converge to a solution, i.e. verification (UNSAT) or providing a counter-example (a model).
That is not surprising, as generally the SAT problem is hard (NP-hard or even more maybe?). The more complex our code is, and the wider the scope our rule/specifications encapsulate, the longer the SMT formula that will be generated, hence the problem becomes more difficult to solve.

Our mission in formally verifying a contract/protocol is not simple, but can be easily formulated: think of correct and as broad as possible specifications for the program, implement them using CVL, and let the prover assert those for you.
The most important mission on our behalf is thinking of good properties, but it is usually not the hardest one. If you understand your contract well and how it is supposed to function generally, expressing those properties in words shouldn’t be a difficult task. Translating them to code by implementing them in CVL requires some experience (or at least the basic knowledge of CVL syntax), but is not insurmountable. 
Getting a result for each of the rules you’ve written is the main challenge, since the solver has its own limitations.

If you are handling small projects, consisting only of a few contracts, and hopefully without any complex mathematical calculations (we will define ‘complex’ in a later section), you shouldn’t encounter any time-outs. Yet as the number of contracts increases, and the function call trace becomes deeper, with many logical branching along the way, the likelihood of timeouts increases accordingly. These timeouts are ubiquitous in today’s blockchain protocols we are verifying for the Cerotra customers. This is not just because the code is complex, but it is also affected by the quality of our properties. Good properties cover a large portion of the underlying code, together with a broad range of the possible states of the system.
**The chance of getting a timeout is a function of both the code complexity and the scope of the specifications.**

In this guide we will try to give heuristics, rules of thumb and practical methodologies of handling these timeouts, based on our overall experience with a variety of different protocols. Hopefully we will cover as many examples and cases as possible, so you should be able to identify at least one of them in your own problem, and apply the relevant solution.
But before going into practice, you should first ask yourself what your strategy is when approaching the formal verification problem. 

The Strategy (what do we actually want)
---------------------------------------

Ideally, one would want to verify his/her code entirely, taking into account every possible scenario and every possible transition of the state of the system, performed by the contract’s methods. It is therefore natural that the rule writer will think of as many rules as he/she can, covering the entire functionality of the system and considering the most general case, meaning for every state of the system.

But there are no free meals: as the complexity of the code increases, so does the number of properties one has to think about and verify in order to be certain of its correctness. These properties would also need to be more broad in the sense that they test more functions/a larger part of the code. Practically speaking, the prover will not be able to verify all properties and at the same time test the entire system.
So essentially, one has to choose between two objectives: testing good properties or testing the entire code. By ‘to choose’ we don’t mean a dichotomous choice, but rather a compromise between the two that one has to prioritize eventually based on his/her needs.

Therefore you should ask yourself first what do you really care about. Do you wish to test a specific piece of code? Are you concerned about a specific function(s) that you suspect is the most critical to the safety of your protocol? Or do you care about a certain property of the system that should hold after any state transition, even at the cost of testing it for a limited scope?
We believe that these questions are the key to choosing the correct strategy for handling the time-outs, as along the way we will be forced to make compromises with respect to the code we are testing, in order to “simplify” the problem we are tackling.

Identifying Timeouts
--------------------

Most of the time, when starting to work on a project, one does not identify the causes for timeouts a-priori. It’s unexpected to examine the code beforehand and discover the patterns or the code characteristics that may lead to timeouts in the future.
It’s advised to first discover the difficult/complex parts of the code via the prover using an elementary check called the sanity check/sanity rule (add link to docs, if present),

This simple rule takes any public or external method of the main verified contract (it is a parametric rule), and asserts for each method whether it is reachable, i.e., does it have at least one non-reverting path. The prover, then, if such a path exists, will find it by assigning random variables of the storage and follow the function execution path until its exit point.

The results of the sanity rule provide us a crude estimate of the complexity of the code in general, and of each function in particular. If the prover managed to find a counterexample for each of them, without timing out, or hard-stopping after the maximum time limit, then it’s a good start and we can see how long it took for the prover to find such a path.
The time it takes for each method to “ be executed” by the prover depends on the scope of contracts defined for the tool, the internal function call resolutions, linked contracts and some settings such as loop unrolling. Therefore one should expect larger execution times when the scope becomes broader and the call trace deeper.

Let’s begin with a very rare case where the sanity rule yields a hard-stop time-out, where we won’t be able to see the results of all functions. If that happens, we advise running the sanity rule on a specific method by applying the setting `--method “[method signature]”`. Try to figure out what the heavy functions are by looking at the code and see which functions have the deepest call trace.

Now suppose that we didn’t get a hard stop. If, after having your different contracts linked, having resolved all call resolutions and applied all summaries, one gets a timeout in any of the tested functions, or relatively large execution times, one can identify the more problematic parts of the code. Note that the sanity rule is usually lenient in running times with respect to more meaningful rules that will be implemented in the future. So if you experience long running times for several functions, it is advised to simplify them in advance in order to decrease the probability for timeouts for future rules.

Another cause for long running times might be static/pre-running analysis failures. This is a broad term of many pre-processing analysis done before building the SMT formula, that includes pointer and storage analysis, built in the tool. While we usually have no control on the way these things are done, we can at least see where failures of such processes have occurred by looking at the logs page or at the statsdata.json file.

If you managed to solve the static analysis problems by applying the different techniques suggested by the Certora team, but still unsatisfied by the results, there are still a few things you can do. You can (in any run script) enhance the SMT timeout settings, `-t`, `-mediumTimeout`, and `-depth`:

Setting `-depth=x` in the run settings will make the SMT split the SMT formula tree up to x levels (the deepest leaf in the SMT branching will be at most at the x-th level).

Setting `-mediumTimeout=x` in the run settings will allocate up to x seconds for any SMT sub-program to be solved before being splitted again.

Setting `-t=x` in the run settings will allocate up to x seconds for solving the sub-programs at the bottom of the splitting tree (the deepest ‘depth’). This is the maximum solving time assigned to a subprogram, which is not split anymore.

Increasing the numbers of these settings will most surely increase the running time of the prover, but the chance of resolving the timeout (getting a verification or violation) will increase.
It’s important to note that increasing these settings indefinitely doesn’t guarantee convergence to a result, as the SMT ability to solve the problem is saturated eventually, if the problem is hard enough.

Common Causes for Timeouts
--------------------------

Timeouts are principally affected by two things: massive code and complex rules. Together they are translated into long SMT formulas whose solution is difficult and hence the timeout. It should also be noted that the time it takes the prover to run isn’t determined only by the SMT solver, but also by the time it takes to generate the formula. This is a long process which involves all the decompilation of the bytecode, pointer analysis (and all the magic John does under the hood :) ).

A massive code is the principal cause for these timeouts, but is actually a general term for a family of sub-patterns that produce a large program, with many lines of code, that result in many SMT variables and high formula complexity.
The ‘massive code’ cause can take form in several patterns:

1. Long functions (or deep call trace) - calling a function within CVL in any rule involves simulating the entire call trace of that function from its main entry point all the way to the bottom. As one might expect, as there is more code to handle, the problem becomes harder, as that “bottom” becomes deeper and deeper. This difficulty isn’t measured solely by the number of lines of code. The complexity also depends on the number of contracts involved during this call trace, as multi-contracts calls could be involved, jumping from one contract to another. Additionally, the number of storage variables being accessed is also a factor. All of these jumps and accesses involve pointer and storage analysis. While these are not related to the actual solution of the SMT formula, they are a part of the preprocessing of the SAT problem, and require some time.



2. Wide branching - basically many if-else statements inside the code. N if-else statements inside a single function call-trace yield up to 2N different sub-programs, or branches, to be handled by the solver (see footnote). Essentially the branching is translated into a boolean statement and an additional formula representing the program branch constructed from all if-else paths. The SMT solver does automatically handle all these branches pretty well, but sometimes their number is big enough so that each branch is a difficult problem to solve on its own. Remember that it takes only one branch to find a counterexample, but it requires testing all of them to make sure the assertion is true. So if your program involves many non-trivial branching, and you expect to verify your rule, timeout is indeed a probable outcome.

   (footnote: The extreme case of completely independent if-else blocks is highly rare. Usually those if-statements will be nested inside the program so on average one encounters significantly less branches in total.)



3. Complex math calculations - nonlinear mathematical calculations are quite common in Defi protocols as they are usually needed for calculating the value of an asset, converting between two different assets based on some price curve defined in some DEX, or for any other algorithm that requires multiple operations in order to extract some value. The term ‘nonlinear’ might be vague depending on your background, but here we simply mean an operation between two non-constant numbers (usually unsigned integers) that involves multiplication, division (or God forbid, exponentiation). Any number is considered as non-constant (variable) as long as its value isn’t already fixed in the code or in the spec. The latter could be done by adding a simple require statement which forces that variable involved in the operation to always have the same value. Unfortunately, nonlinear operations are notoriously difficult for most SMT solvers, mostly because the solver has to assert some properties about functions of variables on the domain of integers, which is by itself a difficult mathematical problem. 



4. Multiple dispatchers - method dispatchers (add link to docs) are used whenever we want to replace unresolved calls inside our contracts with any given implementation of that same function signature included in our list of contracts. An unresolved function call is the default status of the prover and it is modeled by havocing the state variables of some contracts. Keeping the methods unresolved has two big advantages: they are the most sound thing we can do, and they are the best solution in terms of code complexity, as they don’t add another piece of code to be analyzed, opposed to dispatching. 

   But usually we want to be more specific with respect to the outcome of the function call, hence we use dispatchers for actual implementations. When dispatching any function call, the prover searches for all the matching implementations of that function signature in the scope of available contracts, and potentially creates different full branches of the same problem, where for each branch a single instance of the implementation is fetched. It is not guaranteed, however, that every branch, or every implementation will be solved completely, as there might be contradictions between certain `require` statements inside the rule, or previous linking, and the chosen implementation. 

   The most common example for multiple dispatchers is ERC20 token implementations. They mostly appear in DEX-like or liquidity pool protocols. So, in order to correctly simulate the DeFi tokenomics, we require at least two, or three, different instances of ERC20 tokens in our verification environment. But not all rules require the same amount of instances for correct verification. Some of our rules could merely check the integrity of the ERC20 interface, completely oblivious to the presence of any other tokens in the scope. Now, if we happen to duplicate these token implementations, we end up checking exactly the same rules for essentially the same code more than once, and therefore too much. 
   While this particular example won’t be very costly in terms of running time, more complex functions and certain rules will unnecessarily check similar implementations without any logical gain to the verification. The prover might time-out as there are too many branches to handle in a limited amount of time. One therefore should think whether there are more than necessary implementations for the scope of verification.



5. Loops - for, while, or implicit copy loops are unrolled by the prover, and the number of unrolled iterations is controlled by the user (link to loop_iter / loop unrolling). Essentially the body of the loop iteration is copied, and the code inside the loop is bloated as the number of unrolled iterations increases. Loops are common whenever arrays are involved (usually ‘for’ loops), but can also appear as iterative algorithms that require an unknown number of iterations to converge (‘while’ loops). Depending on, of course, the character of the code for every iteration, it might be that only a few iterations suffice to cause timeouts of the prover. Needless to say, this is another example of ‘long functions’ or massive code we have mentioned earlier.



6. Analysis failures - Ask John/Shelly to elaborate?



7. Complex rules - parametric rules, many assertions, long rules …


It follows from the variety of reasons for timeouts we listed above that there isn’t a magic solution that can solve them all. As we’ve mentioned before, the strategy you should take in dealing with them depends on your verification goals. A certain strategy might focus on a specific piece of code (or more abstractly, some functionality of the program), hence less flexible in changing it to your aid, while the other, focused on verifying some property, will involve some changes to the underlying code, hopefully that won’t compromise the accuracy of it.

In the rest of this guide we dive deeper into all the main reasons we listed above, and suggest certain techniques that should solve time-outs, under certain circumstances. We also provide examples that implement these techniques so one could ‘exercise’ them on simple cases, and adapt to any given project. We’ll relate to any of these issues independently, but one can combine the techniques and solutions we provide, if one encounters two or more of them in some cases.

Before analyzing each case separately, it’s important to first give some basic principles for dealing with these timeouts.

One thing to bear in mind is that not all rules require the same preconditions/assumptions in order to be verified or violated. Some properties are more specific, or more precise than others, so they are ‘more susceptible’ to the characteristics of the code, more dependent on the exact implementation. The weaker rule requires only a very specific behavior to hold by the underlying code, in comparison to the more general, stronger rule. In that case, a function being tested could be modified in a manner that preserves the desired property, but at the same time performs different operations essentially, or even introduces a bug. Thus for any method we are testing in some rule, we can simply describe it by picking the desirable property for our need, as long as it actually holds. This methodology is also known as function summarization.

Summarization
-------------

Method summarization is a functionality enabled in CVL by which one can replace actual code, explicit or implicit of resolved and unresolved function calls, respectively, by a custom-made functions/behavior implemented in CVL. The main value of using a summarization over the actual code is to reduce code complexity, together with truncating deep, elaborate call-trace, by replacing it with a more brief, “summarized” behavior of the original code.
As we’ve stated above, code complexity is a common and major cause for timeouts, thus it is advised to replace such code (if possible) with summarizing functions. 
It’s important to note that not any code is summarizable, or could be appropriately replaced by a CVL implementation, as currently it is not possible to express storage/state variables changing (non view) by CVL functions. Summarizations are mostly used to replace view, and better, pure, functions by specific behavior.

A good example (and also real) would be a mathematical calculation that makes use of a set of input numbers and returns a deterministic value based on some algorithm. For demonstration, let us consider the calculation of the nearest integer square root of a number, which by nature is a pure function. We know that the function **should**, for any input x, return the nearest integer y, such that `y2 <=x` . Now let us suppose that the function is correctly calculating this value for any x. Is it really necessary for the prover to follow the calculation and yield that result? Do we care about the implementation? Probably not. We are only concerned about the relation between the input and the output, i.e. that:
`y*y <= x && (y + 1)*(y + 1) > x`.

Hence, we can replace the original implementation with our own CVL function that returns an arbitrary value, but forces this statement on the output value.
The bottomline here is that one should, when possible, replace implementation with properties, or functionality with behavior. Thus it remains to explain how to summarize a function. There are a few common tips and tricks, depending on the proving methodology. Let us first give the main points to remember about any summary:

The golden rule of summarizing a function is:
***A good summary of a function is one that extracts from it the same property which is sufficient for proving/violating a rule***.
Correct summarization goes in two directions: over-approximative and under-approximative. The first means we are describing the function in a more general way than it actually is, or we ignore some more specific properties of it. In other words, for every pair of input-output of the original function, the summarizing function could always, in principle, return the same output, but in general can return different output values for the same input. This means that the over-approximation includes the behavior of the original, but also includes other possibilities.
 
 Underapproximation means the opposite, that we narrow down the possible outcomes of the function. Most times it means that the possible branches, or inputs, of the original function are limited, or filtered to a narrower range, but the result is identical to the original one.
An example would be a function that calculates the product of two integers. The underapproximation would also return the same product, but will restrict itself only to prime inputs, or that the output is also divisible by 10. So the value of the underapproximation is still valid, and identical to the original function given the same input, but the possibilities are just limited with respect to the actual code. A summary that narrows down the range but also returns wrong values for some input, **is not an underapproximation, but rather wrong summary**. The outcome of an underapproximation must always be included in that of the original function, and never deviate from it.