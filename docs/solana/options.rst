Solana-Specific Options / CLI Flags
===================================

This page documents Solana-specific Certora Prover options, which include CLI flags or `prover_args` flags.

The `certoraSolanaProver` utility invokes the Rust compiler and then sends the job to Certora's servers.

The most commonly used command is:

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script>

If a precompiled execution is desired, the run command can skip the compilation step by executing:

.. code-block:: bash

    certoraSolanaProver <path_to_binary_file>

A short summary of these options can be seen by invoking:

.. code-block:: bash

    certoraSolanaProver --help

Using Configuration (Conf) Files
--------------------------------

For larger projects, the command line for running the Certora Prover can become large and cumbersome. It is therefore recommended to use configuration files instead.

These files are in [JSON5](https://json5.org/) format and use a `.conf` extension. They hold the parameters and options for the Prover.

For more details, see `Conf File <https://docs.certora.com/en/latest/docs/prover/cli/conf-file-api.html#conf-files>`.


.. contents:: Overview
   :depth: 2
   :local:

Modes of Operation
------------------

The Certora Solana Prover has two modes of operation. These modes are mutually exclusive - you cannot run the tool with more than one mode at a time.

.. _build_script:
--build_script
~~~~~~~~~~~~~~~

**What does it do?**

Runs formal verification of specified properties while providing an automatic method to compile a Rust project.

The build script must output the following:

- `project_directory`: Path to the project root directory.
- `sources`: List of files or directories used or imported in the program.
- `executables`: List of compiled binary files, which are the target of the Rust program.
- `success`: Boolean flag indicating if the build phase passed successfully.

**When to use it?**

Use this mode to prove properties on source code while providing an automatic compilation method. This is especially useful during development when files are modified frequently.

**Example**

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script>

precompiled binary
~~~~~~~~~~~~~~~~~~~

**What does it do?**

Runs formal verification of specified properties on a precompiled Rust project by providing a path to the binary target file.

**When to use it?**

Use this mode to prove properties on source code without recompiling the project for every execution. Ideal when files are stable and unchanged.

**Example**

.. code-block:: bash

    certoraSolanaProver <path_to_binary_file>

Most Frequently Used Options
----------------------------
.. _solana_inlining:
--solana_inlining
~~~~~~~~~~~~~~~~~~

**What does it do?**

Provides the prover with a list of paths to inlining files for Solana contracts. These files are parsed and used to prove properties.

**When to use it?**

TODO: @Jorge please advise.

**Example**

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script> --solana_inlining <path_to_inlining_file>

.. _solana_summaries:
--solana_summaries
~~~~~~~~~~~~~~~~~~~

**What does it do?**

Provides the prover with a list of paths to summary files for Solana contracts. These files are parsed and used to prove properties.

**When to use it?**

TODO: @Jorge please advise.

**Example**

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script> --solana_summaries <path_to_summaries_file>

.. _cargo_features:
--cargo_features
~~~~~~~~~~~~~~~~~

**What does it do?**

Provides the prover with a whitespace-separated list of extra features passed to the build script.

**When to use it?**

TODO: @Jorge please advise.

**Example**

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script> --cargo_features <feature_1> <feature_2>

.. _msg:
--msg
~~~~~

**What does it do?**

Adds a description message to your run, similar to a commit message. This message appears in the title of the completion email.
Note that you need to wrap your message in quotes if it contains spaces.

**When to use it?**

Adding a message makes it easier to track several runs. It is very useful if you are running many verifications simultaneously.
It is also helpful to keep track of a single file verification status over time, so we recommend always providing an informative message.

**Example**

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script> --msg 'Removed an assertion'

.. _rule:
--rule
~~~~~~

**What does it do?**

Formally verifies one or more specified properties instead of the whole specification file. Can also verify an invariant.

**When to use it?**

This option saves a lot of run time. Use it whenever you care about only a
specific subset of a specification's properties. The most common case is when
This option saves runtime and is useful for verifying specific subsets of a specification. Common cases include testing new rules or investigating specific failures.
you add a new rule to an existing specification. The other is when code changes
cause a specific rule to fail; in the process of fixing the code, updating the
rule, and understanding counterexamples, you likely want to verify only that
specific rule.

**Example**

If `Bank.rs` includes the following:

.. code-block:: text

    invariant address_zero_cannot_become_an_account()
    rule withdraw_succeeds()
    rule withdraw_fails()

To verify only `withdraw_succeeds`, run:

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script> --rule withdraw_succeeds

To verify both `withdraw_succeeds` and `withdraw_fails`, run:

.. code-block:: bash

    certoraSolanaProver --build_script <path_to_build_script> --rule withdraw_succeeds withdraw_fails
