.. _solana_index:

The Certora Solana Prover
=========================

The *Certora Solana Prover* allows formal verification of Solana smart contracts written in Rust.

Verification rules are written in **CVLR** (Certora Verification Language for
Rust), an embedded DSL that lives in two crates:

* `cvlr <https://github.com/Certora/cvlr>`_ — core verification primitives
  (``#[rule]``, ``cvlr_assert!``, ``cvlr_assume!``, ``nondet``, ``clog!``, the
  ``Nondet`` and ``CvlrLog`` derives, ``CvlrFormula`` / ``cvlr_lemma!`` /
  ``cvlr_spec!`` / ``cvlr_rules!`` for the spec layer, ``mock_fn``,
  ``cvlr_hook_on_exit``, …).
* `cvlr-solana <https://github.com/Certora/cvlr-solana>`_ — Solana-specific
  helpers (nondeterministic ``AccountInfo``, ``Pubkey``, anchor account
  wrappers, clock helpers).

The recommended starting scaffold for new projects is the
`Certora Solana spec template <https://github.com/Certora/solana-spec-template>`_
— it ships the canonical ``run.conf``, the baseline inlining / summaries
files, and a setup script that wires everything into your ``Cargo.toml``.
The pages below assume the layout that template produces.

The pages below are organised so that you can read top-to-bottom for a full
walkthrough, or jump directly to the topic you need.

.. toctree::
   :maxdepth: 1
   :caption: Setup and tooling

   installation
   usage
   options
   output
   sanity
   troubleshooting

.. toctree::
   :maxdepth: 1
   :caption: Writing specifications

   speclanguage
   nondet
   spec
   mocks
   accounts
   anchor
   parametric-rules
   methodology


.. Links
   =====

.. _Solana Documentation: https://solana.com/docs
