Special Portal URLs
===================

When you run the Certora CLI, the tool outputs a link to the generated
verification report.  By modifying this link, you can access additional files
that the tool generates.  These are primarily intended for the tool developers,
but they can be useful for users too in some cases.  This page lists these
outputs and explains how to read them.


Job Status
----------

The job status page contains information about the job, including the arguments
that were passed to the command line, the job message, and the exact certora
prover version.  It is created as soon as the job is submitted, and also shows
the current status (whether the job has started or finished processing).

To access the job status page, change the `output`  component of the URL to
`jobStatus`.  For example,

```
https://vaas-stg.certora.com/output/65540/270dce9623d492937d82/?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                             ──────
```

becomes

```
https://vaas-stg.certora.com/jobStatus/65540/270dce9623d492937d82/?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                             ─────────
```

FinalResults.html and Results.txt
---------------------------------

The `FinalResults.html` is an older version of the verification report, but
occasionally contains more information than the newer report format, especially
in cases where the tool encountered an internal error.  In certain cases, it
may be generated even when the main verification report is not.

If the main verification report shows an error and you want to find more
information, try checking `FinalResults.html`.  To access it, add `FinalResults.html`
Just before the `?` in the URL.  For example,

```
https://vaas-stg.certora.com/output/65540/270dce9623d492937d82/?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                                                              ──
```

becomes

```
https://vaas-stg.certora.com/output/65540/270dce9623d492937d82/FinalResults.html?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                                                              ───────────────────
```

Another potential source of information is the file `Results.txt`, which
captures the command line output of the tool.  It can be accessed by putting
`Results.txt` before the `?`:

```
https://vaas-stg.certora.com/output/65540/270dce9623d492937d82/Results.txt?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                                                              ─────────────
```

Statsdata.json
--------------

The Certora Prover performs several different kinds of bytecode analysis to
improve the running time of verifications.  Occasionally, some of these
analyses fail, which can lead to timeouts.

The `statsdata.json` file contains a section called `ANALYSIS` that lists all
of the analyses that are attempted, and whether they succeed or fail.  If you
see that a particular method consistently causes timeouts, you can check the
ANALYSIS section to see if that method was correctly analyzed.  The analysis
section should have a `true` for each successful analysis, and a `false` for
each unsuccessful analysis.

For example, the following shows that the `UNPACKING` analysis is failing on
several fields:

![example statsdata.json showing several unpacking failures][statsdata.png]

If an analysis is failing and causing you timeouts, contact the Certora team.

These analyses only depend on the bytecode being verified (not the rules), so
you should only need to recheck them if your contracts changes.

To access the `statsdata.json` file, add `statsdata.json` before the `?` in the
URL:

```
https://vaas-stg.certora.com/output/65540/270dce9623d492937d82/?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                                                              ──
```

becomes

```
https://vaas-stg.certora.com/output/65540/270dce9623d492937d82/statsdata.json?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                                                              ────────────────
```

Zip Ouptut
----------

When a job is submitted, all of the input and output are stored.  You can
retrieve these files by replacing `output` with `zipOutput` in the URL:

```
https://vaas-stg.certora.com/output/65540/270dce9623d492937d82/?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                            ────────
```

becomes

```
https://vaas-stg.certora.com/zipOutput/65540/270dce9623d492937d82/?anonymousKey=6edb93d7abae7871f1c3be3b10863d64d2d72fef
                            ───────────
```

This link will allow you to download a tar file.  The submitted specs are
contained in the `TarName` directory, and the original contracts can be found
in the `TarName/input/.certora_config` directory (the file names will be
changed).


Other information
-----------------

Certora developers can access additional links; see [the internal documentation](https://certora.atlassian.net/wiki/spaces/CER/pages/278593893/Useful+Links+Certora+API)

