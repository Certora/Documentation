.. index::
   single: sums

Tracking Sums
=============

This section deals with tracking sums of values. The quintessential example for
needing to track sums is from ERC-20 contracts, where :solidity:`totalSupply()`
must be the sum of all balances. This is the example we shall use here,
namely the :clink:`ERC20</DEFI/ERC20/contracts/ERC20.sol>` contract from the
:clink:`Examples</>` repository.


Motivating rule
---------------
The motivating example is the following rule, asserting that the transfer recipient's
balance is updated correctly.

.. _transferIntegrity_bad_rule:

.. cvlinclude:: ../../../Examples/DEFI/ERC20/certora/specs/ERC20SumsBad.spec
   :cvlobject: transferIntegrity
   :caption: :clink:`transferIntegrity rule</DEFI/ERC20/certora/specs/ERC20SumsBad.spec>`

The Prover will find a counter-example for this rule, in which the recipient's balance
overflows. This overflow can occur, because the recipient's balance update is inside
an :solidity:`unchecked` clause, as shown below in :ref:`erc20_transfer_func`.
In practice this violation cannot occur, since the balance of :cvl:`recipient` is
limited by :solidity:`totalSupply`. The Prover, however, is not aware of this fact.

Hence, to verify the :cvl:`transferIntegrity` rule we must make the Prover aware that
the :solidity:`totalSupply()` is the sum of all balances.

.. _erc20_transfer_func:

.. literalinclude:: ../../../Examples/DEFI/ERC20/contracts/ERC20.sol
   :language: solidity
   :start-at: function transfer
   :end-before: function transferFrom
   :emphasize-lines: 6-8
   :caption: :clink:`transfer function</DEFI/ERC20/contracts/ERC20.sol>`


Trying to verify the sum of two balances
----------------------------------------
The naive solution is to prove the following :cvl:`sumOfTwo` invariant, and
add :cvl:`requireInvariant sumOfTwo(e.msg.sender, recipient)` to
:ref:`transferIntegrity_bad_rule`.

.. cvlinclude:: ../../../Examples/DEFI/ERC20/certora/specs/ERC20SumsBad.spec
   :cvlobject: sumOfTwo
   :caption: :clink:`sumOfTwo invariant</DEFI/ERC20/certora/specs/ERC20SumsBad.spec>`

This solution fails however, since the Prover finds counter-examples for this invariant.
Here is one possible counter-example, where the function called is
:cvl:`tranferFrom(c, a, 2)`. The states before and after the function call
are summarized in the table below, where :solidity:`c` is an address different
from :solidity:`a` and :solidity:`b`.

.. list-table:: Counter example
   :header-rows: 1
   :align: center

   * -
     - Before :cvl:`tranferFrom`
     - After

   * - :cvl:`balanceOf(a)`
     - 1
     - 3

   * - :cvl:`balanceOf(b)`
     - 2
     - 2

   * - :cvl:`balanceOf(c)`
     - 3
     - 1

   * - :cvl:`totalSupply()`
     - 3
     - 3

   * - :cvl:`sumOfTwo(a, b)`
     - **true** (3 >= 1+2)
     - **false** (3 < 3+2)

Hence, the Prover cannot verify :cvl:`sumOfTwo` invariant without additional assumptions.
So instead, we shall prove a stronger property, as explained next.


Equality of sum of balances and total supply
--------------------------------------------
The preferred solution to tracking sums is using a hook and a ghost, as shown below.

.. literalinclude:: ../../../Examples/DEFI/ERC20/certora/specs/ERC20SumsGood.spec
   :language: cvl
   :start-at: A ghost variable to track the sum of all balances
   :end-before: Partial transfer integrity rule
   :caption: :clink:`Sum of balances</DEFI/ERC20/certora/specs/ERC20SumsGood.spec>`

Once this invariant is proved, we can require this invariant. For example,
we can add such a requirement to fix :ref:`transferIntegrity_bad_rule` from before,
as shown below.

.. cvlinclude:: ../../../Examples/DEFI/ERC20/certora/specs/ERC20SumsGood.spec
   :cvlobject: transferIntegrity
   :emphasize-lines: 3
   :caption: :clink:`transferIntegrity rule corrected</DEFI/ERC20/certora/specs/ERC20SumsGood.spec>`

.. warning::

   Note that the :cvl:`Sload` hook adds a require statement for every balance read.
   One should always be cautious with such require statements, as they can be unsound.

.. todo::

   * Explain that the :cvl:`require` statement in the hook is equivalent to a forall
     statement.
   * Show this might be unsound - for example if we added balances in the constructor
     not through minting.
   * A sound approach is proving an invariant that forall addresses :cvl:`totalSupply()`
     is greater than  :cvl:`balanceOf(address)`.
