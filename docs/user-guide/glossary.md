(glossary)=
Glossary
========

````{glossary}

axiom
  A statement accepted as true without proof.

call trace
  A call trace is the Prover's visualization of either a
  {term}`counterexample` or a {term}`witness example`.

  A call trace illustrates a rule execution that leads to the violation
  of an `assert` statement or the fulfillment of a `satisfy` statement. The
  trace is a sequence of commands in the rule (or in the contracts the rule
  was calling into), starting at the beginning of the rule and ending with the
  violated `assert` or fulfilled `satisfy` statement.
  In addition to the commands, the call trace also makes the best effort to
  show information about the program state at each point in the execution.
  It contains information about the state of global variables at crucial points
  as well as the values of call parameters, return values, and more.

  If a call trace exists, it can be found in the "Call Trace" tab in the report
  after selecting the corresponding (sub-)rule.

CFG
control flow graph
control flow path
  Control flow graphs (short: CFGs) are a program representation that
  illustrates in which order the program's instructions are processed during
  program execution.
  The nodes in a control flow graph represent single non-branching sequences
  of commands. The edges in a control flow graph represent the possibility of
  control passing from the last command of the source node to the first
  command of the target node. For instance, an `if`-statement in the program
  will lead to a branching, i.e., a node with two outgoing edges, in the
  control flow graph.
  A CVL rule can be seen as a program with some extra "assert" commands, thus
  a rule has a CFG like regular programs.
  The Certora Prover's [TAC reports](tac-reports) contain a control flow graph
  of the {term}`TAC` intermediate representation of each given CVL rule.
  The control flow paths are the paths from source to sink in a given CFG.
  In general (and in practice), the number of control flow paths grows
  exponentially with the size of the CFG. This is known as the path explosion
  problem.
  Further reading:
  [Wikipedia: Control-flow graph](https://en.wikipedia.org/wiki/Control-flow_graph)
  [Wikipedia: Path explosion problem](https://en.wikipedia.org/wiki/Path_explosion)

  % TODO: ok to mention TAC here?

environment
  The environment of a method call refers to the global variables that Solidity
  provides, including `msg`, `block`, and `tx`.  CVL represents these variables
  in a structure of type {ref}`env <env>`.  The environment does *not* include
  the contract state or the state of other contracts --- these are referred to
  as the {ref}`storage <storage-type>`.

EVM
Ethereum Virtual Machine
EVM bytecode
  EVM is short for Ethereum Virtual Machine.
  EVM bytecode is one of the source languages the Certora Prover
  can take as input for verification. 
  It is produced by the Solidity and Vyper compilers, among others.
  The following links provide good entry points for details on what the EVM is and how it works:
  [Official documentation](https://ethereum.org/en/developers/docs/evm/),
  [Wikipedia](https://en.wikipedia.org/wiki/Ethereum#Virtual_machine)

EVM memory
EVM storage
  The {term}`EVM` has two major concepts of memory, called *memory* and
  *storage*. In brief, memory variables keep data only for the duration of a
  single EVM transaction, while storage variables are stored persistently in
  the Ethereum blockchain.
  [Official documentation](https://ethereum.org/en/developers/docs/smart-contracts/anatomy)

havoc
  Havoc refers to assigning variables arbitrary, non-deterministic values. 
  This occurs in two main cases:
  1. At the beginning of a rule, all variables are havoced to model an unknown initial state.
  2. During rule execution, certain events may cause specific variables to be havoced.
    For example, when calling an external function on an unknown contract, 
    the Prover assumes it could arbitrarily affect the state of a third contract.
  
  For more information, see {ref}`havoc-summary` and {ref}`havoc-stmt`.

hyperproperty
  A hyperproperty describes a relationship between two hypothetical sequences
  of operations starting from the same initial state.  For example, a statement
  like "two small deposits will have the same effect as one large deposit" is a
  hyperproperty.  See {ref}`storage-type` for more details.

invariant
  An invariant (or representation invariant) is a property of the contract
  state that is expected to hold between invocations of contract methods.  See
  {ref}`invariants`.

model
example
counterexample
witness example
  We use the terms “model” and “example” interchangeably. 
  In the context of a CVL rule, they refer to an assignment of values to all CVL variables and contract storage that either:
  - violates an `assert` statement, in which case the model is also called a **counterexample**, or
  - satisfies a `satisfy` statement, in which case it is also called a **witness example**.

  See {ref}`rule-overview` for more on how these are used.

  In the context of SMT solvers, a _model_ refers to a valuation of the logical constants and uninterpreted functions in the input formula that makes the formula evaluate to `true`. 
  See {term}`SAT result` for more details.

linear arithmetic
nonlinear arithmetic
  An arithmetic expression is called linear if it consists only of additions,
  subtractions, and multiplications by constants. Division and modulo where the
  second parameter is a constant are also linear arithmetic.
  Examples for linear expressions are `x * 3`, `x / 3`, `5 * (x + 3 * y)`.
  Every arithmetic expression that is not linear is nonlinear.
  Examples for nonlinear expressions are `x * y`, `x * (1 + y)`, `x * x`,
  `3 / x`, `3 ^ x`.

overapproximation
underapproximation
  Sometimes, it is useful to replace a complex piece of code with something
  simpler that is easier to reason about.
  If the approximation includes all of the possible behaviors of the original code (and possibly others), it is called an "overapproximation"; 
  if it does not, it is called an "underapproximation".

  Example: A {ref}`NONDET <view-summary>` summary is
  an overapproximation because the Certora Prover considers every possible value 
  that the original implementation could return, 
  while an {ref}`ALWAYS <view-summary>` summary is an underapproximation if the
  summarized method could return more than one value.

  Proofs on overapproximated programs are {term}`sound`, but
  spurious {term}`counterexample`s may be caused by behavior that the original code
  did not exhibit. 
  Underapproximations are more dangerous because a property
  that is successfully verified on the underapproximation may not hold on the
  approximated code.

optimistic assumptions
pessimistic assertions
  Some input programs include constructs that the Prover cannot handle precisely and must instead approximate. 
  This means the Prover may ignore certain program behaviors, 
  such as what happens when a loop executes more times than a fixed unrolling limit.

  The Prover provides options that let you choose between 
  pessimistic and optimistic handling for each approximation. (See the end of this section for examples.)

  In pessimistic mode (the default), the Prover inserts pessimistic assertions 
  that check whether the program includes behavior that requires approximation, 
  such as a loop exceeding the bound set by {ref}`--loop_iter`. 
  If such behavior is detected, the rule fails with an explanatory message.

  In optimistic mode, the Prover instead inserts optimistic assumptions 
  at each point where approximation would occur. 
  These assumptions explicitly exclude the relevant behavior from verification, for example, assuming that no loop exceeds the iteration bound.

  For a list of all available optimistic options, see {ref}`prover-cli-options`. 
  Examples include {ref}`--optimistic_hashing`, {ref}`--optimistic_loop`, and
  {ref}`--optimistic_summary_recursion`. For more background on these approximations, refer to {ref}`prover-approximations`.


parametric rule
  A parametric rule is a rule that calls an ambiguous method, either using a
  method variable, or using an overloaded function name. The Certora Prover
  will generate a separate report for each possible instantiation of the method.
  See {ref}`parametric-rules` for more information.

quantifier
quantified expression
  The symbols `forall` and `exist` are sometimes referred to as *quantifiers*,
  and expressions of the form `forall type v . e` and `exist type v . e` are
  referred to as *quantified expressions*.  See {ref}`logic-exprs` for
  details about quantifiers in CVL.

receiveOrFallback
  A special function automatically added to every contract to model how Solidity handles calls that either have no `calldata` or do not match any existing function signature.
  1. If the call has no data and a `receive` function is present, `receive` is invoked.
  2. Otherwise, the `fallback` function is called.

  This behavior is modeled in CVL using the synthetic function `receiveOrFallback`, 
  which may appear in parametric rules, invariants, or call traces as `<receiveOrFallback>()`.

  For more details, see the [Solidity Documentation](https://docs.soliditylang.org/en/latest/contracts.html#fallback-function) on fallback functions.

rule name pattern
  Rule names, like all CVL identifiers, have the same format as Solidity identifiers: 
  they consist of a combination of letters, digits, dollar signs, and underscores, 
  but cannot start with a digit 
  (see [here](https://docs.soliditylang.org/en/v0.8.16/path-resolution.html#allowed-paths)).
  When used in client options (like {ref}`--rule`), 
  rule name patterns can also include the wildcard `*` that can replace any sequence of valid identifier characters.
  For example, the rule pattern `withdraw_*` can be used instead of listing all rules that start with the string `withdraw_`.
  This wildcard functionality is part of the client interface and does not apply within CVL spec files.

sanity
  ```{todo}
  This section is incomplete.  See {ref}`--rule_sanity` and {ref}`built-in-sanity` for partial information.
  ```

SAT
UNSAT
SAT result
UNSAT result
  `SAT` and `UNSAT` are the two possible results returned by an {term}`SMT solver` if it does not time out.
  - `SAT` (satisfiable) means that the input formula can be satisfied, and a corresponding {term}`model` has been found.
  - `UNSAT` (unsatisfiable) means that no such {term}`model` exists, as the formula cannot be satisfied.

  In the context of the Certora Prover, the interpretation of `SAT` depends on the type of rule being checked:
  - For an `assert` rule, `SAT` means the rule is violated; the {term}`model` returned serves as a counterexample.
  - For a `satisfy` rule, `SAT` means the rule is fulfilled; the {term}`model` is a witness example.

  Conversely, `UNSAT` indicates:
  - An `assert` rule is never violated.
  - A `satisfy` rule is never fulfilled.

  See also the {ref}`rule-overview` for more background.

scene
  The set of contract instances that the Certora Prover
  knows about.

SMT
SMT solver
  SMT stands for Satisfiability Modulo Theories. 
  An SMT solver takes as input a formula written in predicate logic and determines 
  whether it is satisfiable ({term}`SAT`) or unsatisfiable ({term}`UNSAT`).

  The “Modulo Theories” part refers to the solver’s ability to reason about specific background theories,
  such as integer arithmetic, arrays, or bitvectors. 
  For example, under the theory of integer arithmetic, 
  symbols like `+`, `-`, and `*` are interpreted according to their standard mathematical meaning.

  When a formula is satisfiable, the solver may also return a {term}`model`: an assignment of values to variables that makes the formula evaluate to `true`.
  For instance, given the formula `x > 5 ∧ x = y * y`, the solver might return `x = 9, y = 3` as a valid model.

  For more background, see Wikipedia](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories).

sound
unsound
  Soundness means that the Certora Prover is guaranteed to report any rule violations in the code being verified. 
  Unsound approximations, such as loop unrolling or certain kinds of harnessing, 
  may cause the Prover to miss real bugs, and should, therefore, be used with caution. 
  See {doc}`/docs/prover/approx/index` for more details.

split
split leaf
split leaves
  Control flow splitting is a technique to speed up verification by splitting the
  program into smaller parts and verifying them separately. These smaller programs
  are called splits. Splits that cannot be split further are called split leaves.
  See {ref}`control-flow-splitting`.


summary
summarize
summarization
Summaries
  A method summary is a user-provided approximation of the behavior of a
  contract method.  
  Summaries are useful if the implementation of a method is
  not available or if the implementation is too complex for the Certora
  Prover to analyze without timing out.  
  See {ref}`summaries` for complete information on different types of method summaries.


TAC
  TAC (originally short for "three address code") is an intermediate
  representation
  ([Wikipedia](https://en.wikipedia.org/wiki/Intermediate_representation))
  used by the Certora Prover. TAC code is kept invisible to the
  user most of the time, so its details are not in the scope of this
  documentation. We provide a working understanding, which is helpful for some
  advanced proving tasks, in the {ref}`tac-reports` section.

tautology
  A tautology is a logical statement that is always true.

vacuous
vacuity
  A logical statement is *vacuous* if it is technically true but only because
  it doesn't say anything.  For example, "every integer that is both greater
  than 5 and less than 3 is a perfect square" is technically true, but only
  because there are no numbers that are both greater than 5 and less than 3.

  Similarly, a rule or assertion can pass, but only because the `require`
  statements rule out all of the {term}`model`s.  In this case, the rule
  doesn't say anything about the program being verified.
  The {doc}`../prover/checking/sanity` help detect vacuous rules.

verification condition
  The Certora Prover works by translating a program an a specification into
  a single logical formula that is satisfiable if and only if the program
  violates the specification. This formula is called a
  *verification condition*.
  Usually, a run of the Certora Prover generates many verification conditions.
  For instance a verification condition is generated for every
  {term}`parametric rule`, and also for each of the sanity checks triggered by
  {ref}`--rule_sanity`.
  See also {ref}`white-paper`, {ref}`user-guide`.

wildcard
exact
  A methods block entry that explicitly uses `_` as a receiver is a *wildcard
  entry*; all other entries are called *exact entries*.  See
  {doc}`/docs/cvl/methods`.

````


