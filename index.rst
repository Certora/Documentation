Certora Prover Documentation
============================

Contents
--------

* :doc:`docs/user-guide/index` -- explains how to use the Prover to verify smart
  contracts. Organized by topic and focuses on the most useful features.
* :doc:`docs/cvl/index` -- a reference manual for CVL.
* :doc:`docs/prover/index` -- a reference manual for the Certora Prover.
* :doc:`docs/sunbeam/index` -- instructions for installing and using *Certora Sunbeam*
  for formal verification of `Soroban`_ contracts.
* :doc:`docs/solana/index` -- instructions for installing and using *Certora Solana Prover*
* :doc:`docs/gambit/index` -- use mutation testing to improve you specifications.

.. toctree::
   :maxdepth: 1
   :caption: Contents
   :hidden:

   docs/user-guide/index.md
   docs/cvl/index.md
   docs/prover/index.md
   docs/sunbeam/index.rst
   docs/solana/index.rst
   docs/move/index.rst
   docs/gambit/index.md


Learning resources
------------------

Certora Prover
^^^^^^^^^^^^^^

* :doc:`docs/user-guide/index` (in this Documentation).
* `Certora Prover Tutorials`_ -- learning to use the Prover and CVL through exercises.
* `Certora Prover and CVL Examples Repository`_ -- learn CVL from examples.
* :doc:`docs/user-guide/tutorials` -- lists workshops and tutorials that
  cover basic Prover usage.

Certora Sunbeam
^^^^^^^^^^^^^^^
* `Certora Sunbeam Tutorials`_ -- a set of exercises using Soroban contracts in Rust.


.. Advanced topics

.. toctree::
   :maxdepth: 1
   :caption: Additional information

   docs/equiv-check/index.md
   docs/whitepaper/index.md

.. Hidden stuff that will only appear in the sidebar.
   E.g. the index.

.. toctree::
   :hidden:

   genindex

.. _contact:

Contacting Certora
------------------

If you have questions about Certora's products, the best ways to contact us is
on our `Help Desk channel on Discord`_.

For sales, please use the `contact form on our website`_.

.. Adding TODO list visible only in dev-build.
   To create a dev-build locally run:
   sphinx-build -b html . build/html -t is_dev_build

.. only:: is_dev_build

   To do list
   ----------

   .. todolist::


.. Links
   -----
.. _Certora Prover Tutorials: https://docs.certora.com/projects/tutorials
.. _Certora Prover and CVL Examples Repository: https://github.com/Certora/Examples/
.. _Certora Sunbeam Tutorials:
   https://certora-sunbeam-tutorials.readthedocs-hosted.com/en/latest/

.. _Help Desk channel on Discord:
   https://discord.com/channels/795999272293236746/1104825071450718338

.. _contact form on our website: https://www.certora.com/#Request_Early_Access

.. _Soroban: https://stellar.org/soroban
