(problems-triaging)=
# Triaging problems


The first step to addressing problems is to realize that a specific run is
problematic in the first place. While some jobs are marked as "Problem", others
may lack some results, have fishy counter examples or just "seem off".
The following places should be consulted to identify problems with a particular
job:

- The web report has two views called "Global Problems" and "Rule Problems".
- The "Job Info" page provides the "Logs page", essentially the log file of the Certora Prover.
- For experienced users, the "Status page" contains the download link for a zip archive that contains all the Certora Prover output, including further log files and dumps of intermediate code.


## Common problems

Many problems show as warnings or errors in the "Global Problems" of the log
file. Here are some of the more common ones:

> Extremely low available memory: ... out of a total of ... are left. The prover likely crashes soon and results will be incomplete.

The run likely exhausts the available memory, consult {ref}`problems-memout`.
