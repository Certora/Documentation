(managing-problems)=
Managing Problems
=================

Sometimes, the Certora Prover encounters issues it can not resolve and fails in
some way or another. A job status may show as "Problem", but also a job shown as
successfully finished may show possibly problems in the "Global Problems" view
at the bottom of the web report. The underlying causes of these issues are
manifold, e.g.
subtle errors in the input not caught during type checking;
incorrect usage of command line options;
not yet supported features of specific solidity compiler version;
plain regular software bugs;
issues in the cloud environment;
insufficient system memory.


```{toctree}
problems-triaging.md
problems-memout.md
```




