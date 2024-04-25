.. index::
   single: sums

Tracking Sums
=============

This section deals with tracking sums of values. The quintessential example for
needing to track sums is from ERC-20 contracts, where :solidity:`totalSupply()`
must be the sum of all balances. This is the example we shall use here,
namely the :clink:`ERC20</DEFI/ERC20/contracts/ERC20.sol>` contract from the
:clink:`Examples</>` repository.


Trying to verify the sum of two balances
----------------------------------------
Often one needs a invariant like :cvl:`sumOfTwo` below:

.. code-block:: cvl

   invariant sumOfTwo(address a, address b)
       (a != b) => (balanceOf(a) + balanceOf(b) <= to_mathint(totalSupply()));

If we run this invariant, the Prover will find a violations.
An example of such a violation is summarized in the table below.
In this example the function called was :cvl:`tranferFrom(c, a, 2)`,
where :solidity:`c` is an address different from :solidity:`a` and :solidity:`b`.

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

We see that the Prover cannot verify :cvl:`sumOfTwo` invariant without us adding unsound
assumptions. So instead, we shall prove a stronger property, as explained next.


Equality of sum of balances and total supply
--------------------------------------------
The preferred solution to tracking sums is using a hook and a ghost, as shown below.

.. cvlinclude:: ../../../Examples/DEFI/ERC20/certora/specs/ERC20Fixed.spec
   :lines: 98-106, 115-116
   :caption: :clink:`Total supply is sum of balances</DEFI/ERC20/certora/specs/ERC20Fixed.spec>`

Once this invariant is proved, we can require properties like the one in
:cvl:`sumOfTwo` above.
