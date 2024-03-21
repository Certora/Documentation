(managing-problems)=
Managing Timeouts and Out of Memory Problems
============================================

In this chapter, we describe how to diagnose and remedy when the Certora Prover
ran out of time or out of memory.

Out-of-memory problems are signified by an `Extremely low available memory`
message in the Global Problems tab of the Prover reports, see
{ref}`memout-introduction` for more details. Timeouts are signified either by a
`Global timeout reached` message in the Global Problems tab, if the whole Prover
job timed out, or by an orange clock symbol next to the rule, if that
particular rule timed out, see {ref}`timeouts-introduction` for more details.

% Unfortunately, the Certora Prover regularly encounters issues it can not resolve
% and fails in some way or another. A job may run out of time or memory, or hit a
% variety of further issues so that it is shown as "Problem". Even a job shown as
% successfully finished may have problems in the "Global Problems" view at the
% bottom of the web report.
% The "Job Info" page provides the "Logs page", essentially the log file of the
% Certora Prover.
% For experienced users, the "Status page" contains the download link for a zip
% archive that contains all the Certora Prover output, including further log files
% and dumps of intermediate code.


% problems-identification.md

```{toctree}
memout.md
timeout.md
timeout-theory.md
```




