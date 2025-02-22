User Guide For Sunbeam
============================

Before reading this, make sure you have followed the installation guide.

What is Sunbeam?
----------------

Sunbeam is a tool for formally verifying Soroban smart contracts written in Rust. It allows you to write specifications describing the behavior and invariants of your contract, then mathematically proves that your code adheres to those specifications.

Writing Specs
-------------

Specifications for Sunbeam are written as Rust functions. We use Certora's `Cavalier spec library <https://github.com/Certora/cvlr>`_ which relies on Rust macros. You may also require some of the `Soroban specific macros <https://github.com/Certora/cvlr-soroban/>`_.

A specification is simply a function annotated with the `#[rule]` attribute. These rules make assertions about your smart contract code using the `cvlr_assert!`, `cvlr_assume!` and `cvlr_satisfy!` macros.
