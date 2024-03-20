% (problems-identification)=
% # Identifying problems
% 
% 
% A job that ran out of time is shown as "Halted". Figuring out what
% {ref}`caused the timeout <timeouts-introduction>` can be more difficult, but
% oftentimes necessary to {ref}`prevent it <timeout-prevention>`.
% 
% When a job runs {ref}`out of memory <problems-memout>`, this usually means that
% the SMT solvers used internally crash and eventually even the main Certora
% Prover process may crash.
% Before doing so, the prover usually proves a warning reading
% `Extremely low available memory` shortly before. This sometimes does not happen,
% and some other ways to identify out-of-memory issues are given in
% {ref}`problems-memout-indicators`.
% 
% Other warnings and errors can stem from failure to compile the contract code or
% {ref}`the specification code <cvl-language>`, code constructs that are not yet
% supported by the prover or software bugs.
% While some jobs are marked as "Problem", others may lack some results, have
% fishy counter examples or just "seem off".
% The following places should be consulted to identify problems with a particular
% job:
% 
% - The web report has two views called "Global Problems" and "Rule Problems".
% - The "Job Info" page provides the "Logs page", essentially the log file of the Certora Prover.
% - For experienced users, the "Status page" contains the download link for a zip archive that contains all the Certora Prover output, including further log files and dumps of intermediate code.
% 