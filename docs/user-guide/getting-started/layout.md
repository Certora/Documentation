Project Layout
==============

Repo Setup
----------

### New Project

For a new project, create a fork of the customer's repository in the Certora GitHub.

Create and switch to a new branch for the project, naming the branch to indicate the scope of the project with the scheme `certora/projectscope`, e.g. `certora/governance` or `certora/erc1155`. This is the branch where most of the verification work will take place.

If the project is the beginning of a planned multipart project with the same customer repository, it may make more sense to use the branch name to indicate the project start month, e.g. `certora/march2022`. This branch naming scheme may also be helpful if the scope of the project isn't easy to label succinctly.

### Existing Project

Some projects may be continuations of previous verifications undertaken by Certora staff or by customers themselves. If needed following a customer-led project, fork the appropriate repository in the Certora GitHub. Previous work by Certora will already have a fork in the Certora GitHub. 

In either case, create a new branch for the project using the most recent project branch as a base. As with a new project, the branch name should reflect the scope of the new project or the start month of the new verification work.

Directory Layout
----------------

All projects should have the following directories in the base directory of the project repository:

### `certora/`

This directory is where most of the verification work will take place. An example of the recommended layout is available in [this repository](https://github.com/Certora/CustomersCode/tree/master/templates/certora).

The `certora/` directory should house the following:

#### Directories

##### `.vscode/`

TODO: This directory is in the templates directory for the certora folder. Should we remove it and this section?

##### `harnesses/`

Houses solidity files which serve as an interface between the Certora Prover and copies of the customer solidity files in the `munged/` directory. It is generally preferable to alter files through a harness rather than via munging, discussed below. A guide to harnessing best-practices is available [here](). TODO: link to harnessing guide

##### `helpers/`

Houses helper files. A guide to helper best-practices is available [here](). TODO: link to helper guide. Improve this section.

##### `munged/`

Houses automatically-generated copies of customer solidity files. The Certora Prover accesses these files directly (not recommended) or via harnesses in the `harnesses/` directory. If a needed change cannot happen using a harness, these files can be munged, i.e. changed directly. The `certora/applyHarness.patch` file keeps a record of changes in these files from the customer originals and applies them automatically when the `munged/` directory is populated by running the appropriate command defined in `certora/Makefile`. A guide to munging best-practices is available [here](). TODO: link to munging guide. Clarify population of munged directory.

##### `reports/`

Houses a static .pdf copy of a project's final verification report as well as the verification reports from any previous work. May also contain links to dynamic web versions of verification reports. A guide to report generation best-practices is available [here](). TODO: link to report generation guide.

##### `scripts/`

Houses shell scripts that run the Certora Prover during a verification. There will often be one or more scripts for each contract under verification. A guide to shell script best-practices is available [here](). TODO: link to report generation guide. 

May also contain a subdirectory of scripts for use in continuous integration (CI). A guide to continuous integration best-practices is available [here](). TODO: link to continuous integration guide.

##### `specs/`

Houses specification files written in the [Certora Verification Language](), or CVL. There is generally a single `.spec` file per contract under verification, although some files may verify multiple contracts. A tutorial on how to write specification files and run the Certora Prover is available [here](). TODO: link to tutorial. link to CVL documentation.

#### Files

##### `applyHarness.patch`

Records changes from original customer files. Used to create munged versions in `certora/munged`. Generated automatically by running the appropriate command defined in `certora/Makefile`. TODO: correct this section. Actually generated automatically?

##### `Makefile`

Defines a number of automated actions to correctly populate and update directories and files in the `certora` directory. A example `Makefile` and explanations are available [here](). TODO: link to Makefile example and explanation.

##### `README.md`

Contains basic instructions for running the Certora Prover. An example is available [here](https://github.com/Certora/CustomersCode/blob/master/templates/certora/README.md).

### `ComplexityCheck/`

This directory houses files used in a preliminary complexity check. An example of the recommended contents is available in [this repository](https://github.com/Certora/CustomersCode/tree/master/templates/ComplexityCheck).

TODO: create description of complexity check directory.
