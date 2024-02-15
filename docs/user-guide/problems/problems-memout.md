(problems-memout)=
# Out of memory problems


(problems-memout-indicators)=
## General indicators

An out-of-memory issue can be hard to diagnose. When the free memory drops below
a certain threshold, we usually  issue the following warning to the
"General Problems" panel, as well as the prover log:
`Extremely low available memory`.

This warning might occasionally be a false positive: the JVM is sometimes able
to clean up enough memory on-demand to avert any crashes, or the memory might be
just enough. It might also not show up although the job fails due to
insufficient memory, e.g., if a single allocation that is greater than the warning
threshold fails. Both cases are pretty rare, though.

The prover log oftentimes contains other warnings that point to an out-of-memory
issue.


### SMT solvers dying

A common indication for insufficient is when SMT solvers terminate unexpectedly,
which can be seen in the log file as `solver process died`.
If the solver could not even be started, an explanation like
`Cannot run program ... Cannot allocate memory` is given.
If the solver was already started, it is usually followed by a message like
`solver process did not respond to ... command`.
Both variants usually point to an out-of-memory issue.


### Memory statistics

We store statistics about resource usage in the `statsdata.json` file under the
`"resource-usage"` key. It can be helpful to check whether memory exhaustion is
plausible, as well as to start to work out who is using memory.
The `"vm-mem"` data series shows memory usage of the java process; high usage
indicates excessive memory usage in the static analysis or the generation of the
verification condition.
The `"system-mem"` data series shows total memory usage; high usage, while
`"vm-mem"` is low, indicates high memory usage of the SMT solvers used in the
backend.


### Specific exceptions

Oftentimes, running out of memory produces exceptions that are written to the
log file. Below is a list of exceptions or error messages that almost certainly
indicate an out-of-memory issue, even if some seem completely unrelated at first
glance:

- `java.io.IOException: ... Cannot allocate memory`
- `java.lang.NoClassDefFoundError`


(memout-scenarios)=
## Reducing memory usage

In most cases, high memory usage and long running times go hand in hand and
thus {ref}`timeouts-introduction` is applicable for out-of-memory issues as well.

There are a number of ways that can help avoiding memory exhaustion, either by
{ref}`checking less rules <timeout-single-rule>`,
{ref}`modularizes the verification <library_timeouts>` or fine-tuning
{ref}`which SMT solvers are run <memout-smt-portfolio>`.
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
Otherwise, reducing the portfolio only enables the prover to run more rules in
parallel while the number of solvers running - and competing for memory - at any
given point in time remains the same.

