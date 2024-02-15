(managing-problems)=
Timeouts, memouts and other problems
====================================


Unfortunately, the Certora Prover regularly encounters issues it can not resolve
and fails in some way or another. A job may run out of time or memory, or hit a
variety of further issues so that it is shown as "Problem". Even a job shown as
successfully finished may have problems in the "Global Problems" view at the
bottom of the web report.
The "Job Info" page provides the "Logs page", essentially the log file of the
Certora Prover.
For experienced users, the "Status page" contains the download link for a zip
archive that contains all the Certora Prover output, including further log files
and dumps of intermediate code.


```{toctree}
problems-identification.md
problems-timeout.md
problems-timeout-theory.md
problems-memout.md
```




