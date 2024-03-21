(memout-introduction)=
# Out of memory problems

In this section, we show how to diagnose and remedy out-of-memory problems.
Since the remediation of these problems is often similar to that of certain
kinds of  timeouts, this section is kept short and links to the corresponding
places in the documentation on timeout prevention.

(memout-indicators)=
## General indicators

When the free memory drops below a certain threshold, the Prover issues the
following warning to the "General Problems" panel: `Extremely low available
memory`.

This warning might occasionally not be conclusive: the JVM is sometimes able
to clean up enough memory on-demand to avert any crashes, or the memory might be
just enough. It might also not show up although the job fails due to
insufficient memory, e.g., if a single allocation that is greater than the
warning threshold fails. Both cases are expected to be rare.

(memout-scenarios)=
## Reducing memory usage

In most cases, high memory usage and long running times go hand in hand and
thus {ref}`timeouts-introduction` is applicable for out-of-memory issues as well.

There are a number of ways that can help avoiding memory exhaustion, either by
 - {ref}`checking fewer rules <timeout-single-rule>`,
 - {ref}`modularizing the verification <library_timeouts>`, or 
 - fine-tuning {ref}`which SMT solvers are run <memout-smt-portfolio>`.

Furthermore, there is a number of {ref}`heuristic options <timeout-cli-options>`
that sometimes help to in reducing memory usage in some way or another.


(memout-smt-portfolio)=
### High memory usage of SMT solvers

As discussed in {ref}`high-nonlinear-op-count`, using different SMT solvers or
changing their order is sometimes beneficial. It is important to keep in mind
for out-of-memory issues that simply removing some solvers rarely helps as the
maximum memory usage needs to be reduced.
Roughly speaking, this technique only helps if there are less calls to the SMT
solvers than there are CPU cores available or if a particular solver or solver
configuration uses much more memory than the other solvers in this case.
Otherwise, reducing the portfolio only enables the Prover to run more rules in
parallel while the number of solvers running - and competing for memory - at any
given point in time remains the same.

