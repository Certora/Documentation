(problems-memout)=
# Out of memory problems


In this chapter, we discuss a number of contributors to high memory usage, how
to figure out what actually happens, and possible remedies.


## General indicators

An out-of-memory issue can be hard to diagnose. When the free memory drops below
a certain threshold, we issue the following warning to the "General Problems"
panel, as well as the prover log:

> Extremely low available memory: ... out of a total of ... are left. The prover likely crashes soon and results will be incomplete.

This warning might occasionally be a false positive: the JVM is sometimes able
to clean up enough memory on-demand to avert any crashes, or the memory might be
just enough. It might also not show up although the job fails due to
insufficient memory, e.g., if a single allocation that is greater than the warning
threshold fails. Both cases are pretty rare, though.

We store statistics about resource usage in the `statsdata.json` file under the
`"resource-usage"` key. It can be helpful to check whether memory exhaustion is
plausible, as well as to start to work out who is using memory.
The `"vm-mem"` data series shows memory usage of the java process; high usage
indicates excessive memory usage in the static analysis or the generation of the
verification condition.
The `"system-mem"` data series shows total memory usage; high usage, while
`"vm-mem"` is low, indicates high memory usage of the SMT solvers used in the
backend.


## High number of rules

The Certora Prover works on the rules of the specification in parallel.
While the analysis done by the prover is not very memory intensive per se, doing
this in parallel for many rules can add up quickly and thereby exhaust the
available memory. Try running individual rules only via the {ref}`--rule`
option, or split the specification into separate files. Keep in mind that a
{term}`parametric rule`, as well as an {term}`invariant`, spawns a subrule for
every contract method. This can further be reduced via the {ref}`--method`
option.


