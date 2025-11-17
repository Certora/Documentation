SuiProver Setup and Specification Guide
=======================================

This guide explains how to set up Move specifications ("specs"), write rules,
summaries, and advanced constructs for verifying Sui Move contracts with the
Certora SuiProver.

Setup
-----

Move “specs” (rules and `summaries <https://docs.certora.com/en/latest/docs/user-guide/glossary.html#term-summary>`_) are written in Move. Typically these live in
their own Move package, often named ``spec``. This package will depend on:

- The Move code being verified
- Certora’s ``cvlm`` specification library
- Platform-specific summary packages (e.g., for Sui)

Below is an example ``Move.toml`` for a spec package for the
`Review Rating <https://docs.sui.io/guides/developer/app-examples/reviews-rating>`_
example from Sui’s documentation:

.. code-block:: toml

    [package]
    name = "spec"
    edition = "2024.beta"

    [dependencies]
    reviews_rating = { local = "../sui/examples/move/reviews_rating" }
    cvlm = { git = "https://github.com/Certora/cvl-move-proto.git", subdir = "cvlm", rev = "main" }
    certora_sui_summaries = { git = "https://github.com/Certora/cvl-move-proto.git", subdir = "certora_sui_summaries",  rev = "main" }

    [addresses]
    spec = "0x0"

The three dependencies are:

* ``reviews_rating`` – the code being verified  
* ``cvlm`` – the Move specification language providing rules, summaries, etc.  
* ``certora_sui_summaries`` – common summaries for Sui (storage, events, types, etc.)

Writing a Rule
--------------

Rules are Move functions. A module declares its rules in a special function
called ``cvlm_manifest``. For example:

.. code-block:: rust

    module spec::rules;

    use reviews_rating::service::{ Service, ProofOfExperience };
    use sui::clock::Clock;
    use std::string::String;

    use cvlm::asserts::cvlm_satisfy;
    use cvlm::manifest::rule;

    public fun cvlm_manifest() {
        rule(b"write_new_review_sanity");
    }

    public fun write_new_review_sanity(
        service: &mut Service,
        owner: address,
        content: String,
        overall_rate: u8,
        clock: &Clock,
        poe: ProofOfExperience,
        ctx: &mut TxContext,
    ) {
        service.write_new_review(owner, content, overall_rate, clock, poe, ctx);
        cvlm_satisfy_msg(true, b"Reached end of function");
    }

Key points:

* ``cvlm_manifest`` registers rules in the module.  
* When the SuiProver runs a rule, **all parameters are nondeterministically instantiated**.  
* ``cvlm_satisfy`` creates a *satisfy rule*: it asks the SuiProver to explore whether a state satisfying the condition exists.
* ``cvlm_assert`` and other CVLM constructs may also be used.

The SuiProver can also automatically generate sanity rules using
``module_sanity``.  
See `the CVLM sources <https://github.com/Certora/cvl-move-proto/tree/main/cvlm/sources>`_
for additional details.

Checking the Spec
-----------------

To check a spec, run the following from the directory containing ``Move.toml``:

.. code-block:: bash

    certoraSuiProver.py --server production --prover_version "master"

To enable verbose setup logging (recommended initially):

.. code-block:: bash

    certoraSuiProver.py --java_args "-Dverbose.setup.helpers" ...

This logs missing summaries, unsupported features, and other setup hints.

To restrict which rules will be checked, use:

* ``--rule``_  
* ``--excludeRule``_ 
* ``--method``
* ``--excludeMethod``_ 

Sanity Rules
------------

The SuiProver can automatically generate “sanity” rules for selected functions
via ``target`` and ``target_sanity``:

.. code-block:: rust

    public fun cvlm_manifest() {
        target(@reviews_rating, b"dashboard", b"create_dashboard");
        target(@reviews_rating, b"dashboard", b"register_service");
        target(@reviews_rating, b"moderator", b"add_moderator");
        target(@reviews_rating, b"moderator", b"delete_moderator");
        target(@reviews_rating, b"review", b"upvote");
        target(@reviews_rating, b"service", b"create_service");
        target(@reviews_rating, b"service", b"write_new_review");
        target(@reviews_rating, b"service", b"write_new_review_without_poe");
        target(@reviews_rating, b"service", b"distribute_reward");
        target(@reviews_rating, b"service", b"top_up_reward");
        target(@reviews_rating, b"service", b"generate_proof_of_experience");
        target(@reviews_rating, b"service", b"remove_review");
        target(@reviews_rating, b"service", b"upvote");

        target_sanity();
    }

The SuiProver generates two rules per target:

* A **satisfy-true** rule (execution reaches the end)  
* An **assert-true** rule (all assertions hold)

For more on sanity rules, see the
`EVM Prover documentation <https://docs.certora.com/en/latest/docs/cvl/builtin.html#how-sanity-is-checked>`_.

Parametric Rules
----------------

Rules can accept *target functions* as parameters, enabling generic correctness
properties. Example: asserting that a review’s score never decreases.

.. code-block:: rust

    public fun cvlm_manifest() {
        target(@reviews_rating, b"service", b"create_service");
        target(@reviews_rating, b"service", b"write_new_review");
        target(@reviews_rating, b"service", b"write_new_review_without_poe");
        target(@reviews_rating, b"service", b"distribute_reward");
        target(@reviews_rating, b"service", b"top_up_reward");
        target(@reviews_rating, b"service", b"generate_proof_of_experience");
        target(@reviews_rating, b"service", b"remove_review");
        target(@reviews_rating, b"service", b"upvote");

        invoker(b"invoke");
        rule(b"score_only_increases");
    }

    native fun invoke(target: Function, id: ID);

    public fun score_only_increases(
        service: &mut Service,
        review_id: ID,
        target: Function
    ) {
        let initial_score = service.get_total_score(review_id);
        invoke(target, review_id);
        let final_score = service.get_total_score(review_id);
        cvlm_assert(final_score >= initial_score);
    }

Explanation:

* ``target`` registers callable functions from the contract.  
* ``invoker`` names the entry point used to call them.  
* The SuiProver generates **one sub-rule per (rule × target) combination**.

Summaries
---------

Complex logic (e.g., loops) can be replaced with *summaries* that are easier for
the SuiProver to reason about.  
Consider this loop:

.. code-block:: rust

    fun find_idx(service: &Service, total_score: u64): u64 {
        let mut i = service.top_reviews.length();
        while (0 < i) {
            let review_id = service.top_reviews[i - 1];
            if (service.get_total_score(review_id) > total_score) {
                break
            };
            i = i - 1;
        };
        i
    }

To summarize it, we must first expose relevant fields using ``#[test_only]``:

.. code-block:: rust

    #[test_only]
    public fun top_reviews(service: &Service): vector<ID> {
        service.top_reviews
    }

    #[test_only]
    public fun get_total_score_(service: &Service, review_id: ID): u64 {
        service.get_total_score(review_id)
    }

Then write the summary in ``spec::summaries``:

.. code-block:: rust

    module spec::summaries;

    use reviews_rating::service::Service;

    use cvlm::manifest::summary;
    use cvlm::nondet::nondet;
    use cvlm::asserts::cvlm_assume;

    public fun cvlm_manifest() {
        summary(b"find_idx_summary", @reviews_rating, b"service", b"find_idx");
    }

    #[test_only]
    public fun find_idx_summary(service: &Service, total_score: u64): u64 {
        if (service.top_reviews().length() == 0) {
            return 0
        };
        let i = nondet<u64>();
        cvlm_assume(
            (i == 0 || service.get_total_score_(service.top_reviews()[i - 1]) > total_score) &&
            service.get_total_score_(service.top_reviews()[i]) <= total_score
        );
        i
    }

This replaces the loop with logical assumptions that capture its intended effect.

Ghost State, Shadow Mappings, and Hash Functions
------------------------------------------------

CVLM provides additional advanced features:

* **Ghost state** – global variables and mappings for rules and summaries  
* **Shadow mappings** – alternative internal representations for structs  
* **Hash functions** – unique ``u256`` values computed from arguments  

Documentation is available in the
`manifest module <https://github.com/Certora/cvl-move-proto/blob/main/cvlm/sources/manifest.move>`_,
and examples appear in the
`Sui platform summaries <https://github.com/Certora/cvl-move-proto/tree/main/certora_sui_summaries/sources>`_.

.. _--rule: https://docs.certora.com/en/latest/docs/prover/cli/options.html#rule
.. _--excludeRule: https://docs.certora.com/en/latest/docs/prover/cli/options.html#exclude-rule
.. _--method: https://docs.certora.com/en/latest/docs/prover/cli/options.html#method
.. _--excludeMethod: https://docs.certora.com/en/latest/docs/prover/cli/options.html#exclude-method