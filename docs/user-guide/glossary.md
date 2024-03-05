(glossary)=
Glossary
========

````{glossary}

axiom
  a statement accepted as true without proof.

call trace
  TODO

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
  In general (and in practice) the number of control flow paths grows 
  exponentially with the size of the CFG. This is known as the path explosion 
  problem.
  Further reading: 
  [Wikipedia: Control-flow graph](https://en.wikipedia.org/wiki/Control-flow_graph)
  [Wikipedia: Path explosion problem](https://en.wikipedia.org/wiki/Path_explosion)

  % TODO: ok to mention TAC here?

environment
  The environment of a method call refers to the global variables that solidity
  provides, including `msg`, `block`, and `tx`.  CVL represents these variables
  in a structure of type {ref}`env <env>`.  The environment does *not* include
  the contract state or the state of other contracts --- these are referred to
  as the {ref}`storage <storage-type>`.

EVM
Ethereum Virtual Machine
EVM bytecode
  EVM is short for Ethereum Virtual Machine.
  EVM bytecode is one of the source languages that the Certora Prover internally
  can take as input for verification. It is produced by the Solidity and Vyper 
  compilers, among others.
  For details on what the EVM is and how it works, the following links provide
  good entry points.
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
  In some cases, the Certora Prover should assume that some variables can change 
  in an unknown way.  For example, an external function on an unknown contract 
  may have an arbitrary effect on the state of a third contract.  In this case, 
  we say that the variable was "havoced".  See {ref}`havoc-summary` and
  {ref}`havoc-stmt` for more details.

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
  We use the terms "model" and "example" interchangeably.
  In the context of a CVL rule, they refer to an assignment of values to all of 
  the CVL variables and contract storage that either violates an `assert` 
  statement or fulfills a `satisfy` statement. 
  In the `assert` case, we also call the model a "counterexample". In the 
  `satisfy` case, we also call the model "witness example".
  See {ref}`rule-overview`.
  In the context of {term}`SMT solver`s, a model is a valuation of the logical 
  constants and uninterpreted functions in the input formula that makes the formula
  evaluate to `true`, also see {term}`SAT result`.

linear arithmetic
nonlinear arithmetic
  An arithmetic expression is called linear if it consists only of additions, 
  subtractions, and multiplications by constant. Division and modulo where the
  second parameter is a constant are also linear arithmetic.
  Examples for linear expressions are `x * 3`, `x / 3`, `5 * (x + 3 * y)`.
  Every arithmetic expression that is not linear is nonlinear.
  Examples for nonlinear expressions are `x * y`, `x * (1 + y)`, `x * x`, 
  `3 / x`, `3 ^ x`.

overapproximation
underapproximation
  Sometimes it is useful to replace a complex piece of code with something
  simpler that is easier to reason about.  If the approximation includes all of
  the possible behaviors of the original code (and possibly others), it is
  called an "overapproximation"; if it does not then it is called an
  "underapproximation".  
  
  Example: A {ref}`NONDET <view-summary>` summary is
  an overapproximation because every possible value that the original
  implementation could return is considered by the Certora Prover, while an
  {ref}`ALWAYS <view-summary>` summary is an underapproximation if the
  summarized method could return more than one value.

  Proofs on overapproximated programs are {term}`sound`, but there may be
  spurious {term}`counterexample`s caused by behavior that the original code
  did not exhibit.  Underapproximations are more dangerous because a property
  that is successfully verified on the underapproximation may not hold on the
  approximated code.

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

sanity
  ```{todo}
  This section is incomplete.  See {ref}`--rule_sanity` and {ref}`built-in-sanity` for partial information.
  ```

SAT
UNSAT
SAT result
UNSAT result
  *SAT* and *UNSAT* are the results that an {term}`SMT solver` returns on a 
  successful run (i.e. not a timeout). SAT means that the input formula is 
  satisfiable and a {term}`model` has been found. UNSAT means that the input 
  formula is unsatisfiable (and thus there is no model for it).
  Within the Certora Prover, what SAT means depends on the type of rule 
  being checked: For an `assert` rule, SAT means the rule is violated and the 
  SMT model corresponds to a counterexample.
  For a `satisfy` rule, SAT means the rule is not violated and the SMT model
  corresponds to a witness example.
  Conversely, UNSAT means that an `assert` is never violated or a `satisfy` never
  fulfilled respectively.
  See also {ref}`rule-overview`.

scene
  The *scene* refers to the set of contract instances that the Certora Prover 
  knows about.

SMT
SMT solver
  "SMT" is short for "Satisfiability Modulo Theories". An SMT solver takes as 
  input a formula in predicate logic and returns whether the formula is 
  satisfiable (short "SAT") or unsatisfiable (short: "UNSAT"). The "Modulo 
  Theory" part means that the solver assumes a meaning for certain symbols in 
  the formula. For instance the theory of integer arithmetic stipulates that the 
  symbols `+`, `-`, `*`, etc. have their regular everyday mathematical 
  meaning.
  When the formula is satisfiable, the SMT solver can also return a model for 
  the formula. I.e. an assignment of the formula's variables that makes the 
  formula evaluate to "true". For instance, on the formula "x > 5 /\ x = y * y", 
  a solver will return SAT, and produce any valuation where x is the square of
  an integer and larger than 5, and y is the root of x.
  Further reading: [Wikipedia](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories)

sound
unsound
  Soundness means that any rule violations in the code being verified are
  guaranteed to be reported by the Certora Prover.  Unsound approximations 
  such as loop unrolling or certain kinds of harnessing may cause real bugs 
  to be missed by the Prover, and should therefore be used with caution. See
  {doc}`/docs/prover/approx/index` for more details.

split
split leaf
split leaves
  Control flow splitting is a technique to speed up verification by splitting the
  program into smaller parts and verifying them separately. These smaller programs 
  are called splits. Splits that cannot be split further are called split leaves.
  See {ref}`control-flow-splitting`.
  

summary
summarize
  A method summary is a user-provided approximation of the behavior of a
  contract method.  Summaries are useful if the implementation of a method is
  not available or if the implementation is too complex for the Certora 
  Prover to analyze without timing out.  See {doc}`/docs/cvl/methods` for
  complete information on different types of method summaries.

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


