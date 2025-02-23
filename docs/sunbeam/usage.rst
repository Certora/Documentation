User Guide For Sunbeam
======================

Before reading this, make sure you have followed the installation guide.

What is Sunbeam?
----------------

Sunbeam is a tool for formally verifying Soroban smart contracts written in Rust. It allows you to write specifications describing the behavior and invariants of your contract, then mathematically proves that your code adheres to those specifications. A recent `blog <https://certora.vercel.app/blog/formally-verifying-webassembly>`_ explains the core technology behind Sunbeam.

Writing Specs
-------------

Specifications for Sunbeam are written as Rust functions. We use Certora's `Cavalier spec library <https://github.com/Certora/cvlr>`_ which relies on Rust macros. You may also require some of the `Soroban specific macros <https://github.com/Certora/cvlr-soroban/>`_.


Rules and assertions
--------------------

A specification is simply a function annotated with the ``#[rule]`` attribute. These rules make assertions about your smart contract code using the ``cvlr_assert!``, ``cvlr_assume!`` and ``cvlr_satisfy!`` macros. For example:


.. code-block:: rust

    #[rule]
    fn transfer_is_correct(e: Env, to: Address, from: Address, amount: i64) {
        cvlr_assume!(
            e.storage().persistent().has(&from) && e.storage().persistent().has(&to) && to != from);
        let balance_from_before = Token::balance(&e, from.clone());
        let balance_to_before = Token::balance(&e, to.clone());
        Token::transfer(&e, from.clone(), to.clone(), amount);
        let balance_from_after = Token::balance(&e, from.clone());
        let balance_to_after = Token::balance(&e, to.clone());
        cvlr_assert!(
            (balance_to_after == balance_to_before + amount)
                && (balance_from_after == balance_from_before - amount)
        );
    }


Depending on the property you prove, it is possible that you may need to define "ghost variables" that are intended only for verification. A Ghost variable offers a way to annotate the program to track additional information that can be useful for verification. A simple example can be found `here <https://github.com/Certora/reflector-subscription-contract/blob/51944577dc4536e9cf9711db6e125fe1e2254054/src/lib.rs#L44>`_. We encourage you to look into its usage to understand how you may use a similar approach.

Nondet
------

When formally verifying real-world programs, it is not uncommon to encounter "solver timeouts". This means that the underlying SMT solver timed out and was not able to verify the property. One way to mitigate this is by "summarizing the code" --- this is often done by replacing some parts of the code (e.g., a function body) with something else that is easier for SMT solvers to handle while being a sound overapproximation of the original logic of the code.

A common summary that is often used is ``nondet``. This essentially allows the prover to use a nondeterministically chosen value instead of performing a more complex computation or function call. Sunbeams's spec language, Cavalier provides `nondet` implementations for various primitive types. Additional ones for Soroban are also provided in `cvlr-soroban <https://github.com/Certora/cvlr-soroban/blob/main/cvlr-soroban/src/nondet.rs>`_. More can be added to this repository as needed.

You can also implement ``nondet`` for user-defined types like so:

.. code-block:: rust

    // Example from the Blend protocol
    pub struct Q4W {
        pub amount: i128,
        pub exp: u64,
    }
    
    impl cvlr::nondet::Nondet for Q4W {
        fn nondet() -> Self {
            Self {
                amount: cvlr::nondet(),
                exp: cvlr::nondet()
            }
        }
    }

Examples
--------

We encourage users to check out the `Sunbeam Tutorials <https://certora-sunbeam-tutorials.readthedocs-hosted.com/en/latest/>`_ for learning more about how to use the tool.

Running Sunbeam
---------------
As the tutorial shows, the easiest way to run Sunbeam is via ``conf`` files which provide all the arguments and flags required for Sunbeam. We recommend making a directory for your project where you can save these files. Then you can run the tool like so:

.. code-block:: bash

    cd projects/path/to/conf/files
    certoraSorobanProver filename.conf


Typically a conf file looks like this:

.. code-block:: json

    {
        "build_script": "../certora_build.py",
        "process": "emv",
        "rule": [
            "init_balance",
            "transfer_is_correct",
            "transfer_no_effect_on_other",
            "transfer_fails_if_low_balance"
        ],
        "prover_version": "master",
        "server": "production"
    }

The ``rule`` field has the names the rust functions corresponding to the ``rules`` you wrote for verifying properties of the smart contract. During setup,  we encourage you to make a  ``certora_build.py`` script similar to the one in the `tutorial <https://github.com/Certora/sunbeam-tutorials/blob/main/projects/token/certora_build.py>`_. You will likely need to only adapt the global variables at the top of the script according to your project:

.. code-block:: python

    # Command to run for compiling the rust project.
    COMMAND = "just build"
    
    # JSON FIELDS
    PROJECT_DIR = (SCRIPT_DIR).resolve()
    SOURCES = ["src/path/to/rust/files/*.rs", "Cargo.toml"]
    EXECUTABLES = "target/wasm32-unknown-unknown/release/wasm_file_name.wasm"

``SOURCES`` lets the user control all the source files that they would like to see in the report. ``EXECUTABLES`` has the WASM binary file that is to be verified. ``COMMAND`` tells Sunbeam how to compile the project. In this example, we used ``just`` to compile the project, so it says ``just build`` but it could also be ``make`` or ``cargo build --release``, etc.

Alternatively, you can also compile the project on your own and provide a path to the binary directly in the ``conf`` file:

.. code-block:: json

    {
        "files": ["target/wasm32-unknown-unknown/release/wasm_file_name.wasm"],
        "process": "emv",
        "rule": [
            "init_balance",
            "transfer_is_correct",
            "transfer_no_effect_on_other",
            "transfer_fails_if_low_balance"
        ],
        "prover_version": "master",
        "server": "production"
    }


After running Sunbeam
---------------------

Once you run Sunbeam as described above, it will send a verification job to Certora's cloud. You will receive a link to a report page for example something like `this <https://prover.certora.com/output/33158/43d2f53488204780bcb004e91be562a9/?anonymousKey=21e6b9c505d1c3eecb004bcdf5778b53b8197a41>`_. The page shows the status of the rules, provides a call trace when there is a counter example, and also shows the rust source code.
