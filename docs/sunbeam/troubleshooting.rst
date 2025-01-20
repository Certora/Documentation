Troubleshooting
===============

Unable to run ``certoraSorobanProver``
----------------------------
If you are unable to run ``certoraSorobanProver``, we recommend trying it from within a ``venv``.

#. First, create a ``venv`` and make sure you are inside the ``venv`` by running the
   following:

   .. code-block:: bash

      cd projectDir
      python3 -m venv .venv
      source .venv/bin/activate

#. Then, install all required packages like so:

   .. code-block:: bash

      pip3 install -r requirements.txt

#. Finally, try running ``certoraRun`` again:

   .. code-block:: bash

      certoraSorobanProver path/to/prover_config.conf

----

Build step of ``certoraSorobanProver`` is failing
---------------------------------------

When you execute ``certoraSorobanProver``, the project is internally build using ``cargo build``.
This step requires a successful build. In case ``certoraSorobanProver`` fails on the build step,
first try to compile the project by running
``cargo build --release --target wasm32-unknown-unknown``
and resolve all compiler errors that you see.

----

Compiler Error: "error: linking with \`cc\` failed: exit status: 1" on Mac
--------------------------------------------------------------------------

If you are running on Mac and the build step of your project or ``certoraRun`` fails
with the warning:

.. code-block:: bash

   "error: linking with \`cc\` failed: exit status: 1"

then check out the following `StackOverflow post`_.

.. Links
   =====

.. _StackOverflow post:
   https://stackoverflow.com/questions/28124221/error-linking-with-cc-failed-exit-code-1
