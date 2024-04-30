.. index::
   single: parametric rule
   single: rule; parametric

Parametric rules
================

General
-------
A :term:`parametric rule` is a rule that uses a :cvl:`method f` parameter.
Such a rule will be tested against all possible methods :cvl:`f`, including methods from
other contracts in the :term:`scene`.
It is possible to limit the methods tested, see :ref:`parametric-rules`.

Parametric rules can be used to verify properties of the changes in storage values.
The template for such checks is:

.. code-block:: cvl
   :caption: Parametric rule template

   rule parametricExample(method f) {
       // Get storage values before
       uint before = ...;
       ...

       // Function call
       env e;
       calldataarg args;
       f(e, args)

       // Get storage values after
       uint after = ...;
       ...

       // Assert property of the change, e.g.:
       assert after - before == ...;
   }

The main differences between parametric rules and invariants are:

#. Invariants are also tested after the constructor.
#. Invariants are used to assert properties of the storage (between function calls),
   while parametric rules are used to assert properties of *changes* in the storage
   (caused by function calls).


ERC20 example
-------------
Here is a parametric rule example from the spec file
:clink:`ERC20Full.spec</DEFI/ERC20/certora/specs/ERC20Full.spec>` -- a spec
for an ERC20 implementation.
The parametric rule :cvl:`onlyAllowedMethodsMayChangeBalance` asserts two things:

#. A user's balance can increase only by calls to :solidity:`mint`,
   :solidity:`transfer`, and :solidity:`transferFrom`.
#. A user's balance can decrease only by calls to :solidity:`burn`,
   :solidity:`transfer`, and :solidity:`transferFrom`.

It follows that all other functions do not change balances.
The rule is shown below, with the lines for getting the storage value before and after
the function call highlighted.
The two helper functions used in the rule are explained below the rule.

.. cvlinclude:: ../../Examples/DEFI/ERC20/certora/specs/ERC20Full.spec
   :cvlobject: onlyAllowedMethodsMayChangeBalance
   :emphasize-lines: 8, 10
   :caption: :clink:`onlyAllowedMethodsMayChangeBalance</DEFI/ERC20/certora/specs/ERC20Full.spec>`

* The function :cvl:`canIncreaseBalance(f)` returns true if
  :cvl:`f` is one of the functions :solidity:`mint`, :solidity:`transfer`, or
  :solidity:`transferFrom`.
* Similarly, :cvl:`canDecreaseBalance(f)` returns true
  if :cvl:`f` is one of :solidity:`burn`, :solidity:`transfer`, or
  :solidity:`transferFrom`.

.. dropdown:: The helper functions :cvl:`canIncreaseBalance` and :cvl:`canDecreaseBalance`

   .. cvlinclude:: ../../Examples/DEFI/ERC20/certora/specs/ERC20Full.spec
      :lines: 50-58

.. seealso::

   There is more information about parametric rules in :ref:`parametric-rules`.
