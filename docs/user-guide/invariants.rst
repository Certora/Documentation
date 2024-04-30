.. index::
   single: invariant

Invariants
==========

An :term:`invariant` is a property of the contract's storage state that should
hold between calls to the contract. For example, in some ERC20 contracts the balance
of :solidity:`address(0)` is always zero.

Below, we provide examples of using invariants. You can read more about invariants
in :ref:`Invariants (from The Certora Verification Language)<invariants>`.


Teams example
-------------
The :clink:`ITeams</CVLByExample/Teams/ITeams.sol>` interface, shown below,
is an interface for managing teams consisting of two players and a team leader.

.. dropdown:: :clink:`ITeams interface</CVLByExample/Teams/ITeams.sol>`

   .. literalinclude:: ../../Examples/CVLByExample/Teams/ITeams.sol
      :language: solidity
      :lines: 13-

A contract implementing this interface should satisfy the following properties:

#. Each team has three *different* players, one of which is the team leader.
#. Each player can belong only to one team.
#. A team is identified by a unique id between 1 and 255.
#. A player having team-id 0 indicates this player has no assigned team.
#. Address zero cannot be part of a team.
#. If a team has not been created yet, it will have :solidity:`address(0)` as a team
   leader.

Next we translate these properties to CVL invariants. You can find the entire
spec in :clink:`The team of zero is zero</CVLByExample/Teams/Teams.spec>`. 

* To run the spec on a correct implementation of :solidity:`ITeams` use
  :clink:`correct.conf</CVLByExample/Teams/correct.conf>`, which will use the
  implementation in :clink:`Teams.sol</CVLByExample/Teams/Teams.sol>`.
* To see the spec discover bugs, use
  :clink:`buggy.conf</CVLByExample/Teams/buggy.conf>`. This will run the spec
  against the buggy implementation in
  :clink:`TeamsBugs.sol</CVLByExample/Teams/TeamsBugs.sol>`.


Simple invariants
-----------------

.. _no_team_for_address_zero:

No team for address zero
^^^^^^^^^^^^^^^^^^^^^^^^
We can readily deduce from the properties that :solidity:`teamOf(address(0))` must be
zero. Here it is written as an invariant:

.. cvlinclude:: ../../Examples/CVLByExample/Teams/Teams.spec
   :cvlobject: methods addressZeroNotPlayer
   :caption: :clink:`The team of zero is zero</CVLByExample/Teams/Teams.spec>`

We declared the functions :solidity:`teamOf` and :solidity:`leaderOf` as :cvl:`envfree`
to remove the need for an :cvl:`env` type argument.

The leader is part of the team
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Another invariant property is that the team-id of the leader of team :math:`x` is
:math:`x`. This only holds if :math:`x` is not zero and the leader is not
:solidity:`address(0)`. Here is the property written as an invariant:

.. cvlinclude:: ../../Examples/CVLByExample/Teams/Teams.spec
   :cvlobject: leaderBelongsToTeam
   :caption: :clink:`The team's leader is part of the team</CVLByExample/Teams/Teams.spec>`


.. index::
   single: preserved block
   single: invariant; preserved block

Using preserved blocks inside invariants
----------------------------------------
Sometimes additional conditions are needed to prove invariants. These additional
conditions are given using preserved blocks, see :ref:`preserved`. Here are two
examples using preserved blocks.

A team not created has no players
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Before team :solidity:`i` is created, :solidity:`leaderOf(i)` must be
:solidity:`address(0)`. In such a case, there should be no players in team :solidity:`i`.
We can write this condition as:

.. cvlinclude:: ../../Examples/CVLByExample/Teams/NoPreserved.spec
   :cvlobject: nonExistTeamHasNoPlayers
   :caption: :clink:`nonExistTeamHasNoPlayers without preserved block</CVLByExample/Teams/NoPreserved.spec>`

Running this rule, the Prover will find the following violation,
which you can see in this rule report `nonExistTeamHasNoPlayers violation report`_.
The function called is :solidity:`changeLeader(address(0))`, changing the leader
from address :solidity:`a` (where :solidity:`a` is not zero) to zero.
Before the call :solidity:`address(0)` is a member of team :solidity:`i`, where
:solidity:`i > 0`. After the call the left hand side of the invariant condition
holds true: :cvl:`i != 0 && leaderOf(i) == 0`. But the right hand side
is false for :cvl:`player = a`, since :cvl:`teamOf(a) = i`. The violation is expressed
in the following table, showing the change in state.

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * -
     - Pre call state
     - Post call state

   * - :solidity:`leaderOf(i)`
     - :solidity:`a`
     - :solidity:`0`

   * - :solidity:`teamOf(a)`
     - :solidity:`i`
     - :solidity:`i`
 
   * - :solidity:`teamOf(0)`
     - :solidity:`i`
     - :solidity:`i`

In order for the invariant to be proved, we need to require that the team of
:solidity:`address(0)` is zero. We'll do that using a preserved block. Since
we already proved this in :ref:`no_team_for_address_zero`, we can simply
:index:`require that the invariant<single: requireInvariant>`
:cvl:`addressZeroNotPlayer` holds, like so:

.. cvlinclude:: ../../Examples/CVLByExample/Teams/Teams.spec
   :cvlobject: nonExistTeamHasNoPlayers
   :caption: :clink:`Non created team has no players</CVLByExample/Teams/Teams.spec>`

.. seealso::

   To read more on :cvl:`requireInvariant` and its soundness, see
   :ref:`invariant-induction`.

A team has at most three players
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Here is how we phrase this property:

   Let :cvl:`a`, :cvl:`b`, :cvl:`c` and :cvl:`d` be four different addresses, and suppose
   that :cvl:`a`, :cvl:`b` and :cvl:`c` are all on the same non-zero team :cvl:`i`.
   Then :cvl:`d` does not belong to team :cvl:`i`.

Helper functions
""""""""""""""""
To enhance readability we'll define two helper functions:

#. A function checking that four addresses are different,
   called :cvl:`fourDifferentAddresses`.
#. A function checking that three addresses are on the same team, called :cvl:`sameTeam`.

Their definitions are given below.

.. dropdown:: :clink:`fourDifferentAddresses</CVLByExample/Teams/Teams.spec>`

   .. cvlinclude:: ../../Examples/CVLByExample/Teams/Teams.spec
      :cvlobject: fourDifferentAddresses

.. dropdown:: :clink:`sameTeam</CVLByExample/Teams/Teams.spec>`

   .. cvlinclude:: ../../Examples/CVLByExample/Teams/Teams.spec
      :cvlobject: sameTeam

The rule
""""""""
Here is the complete rule.

.. cvlinclude:: ../../Examples/CVLByExample/Teams/Teams.spec
   :cvlobject: teamHasMaxThreePlayers
   :caption: :clink:`A team has at most three players</CVLByExample/Teams/Teams.spec>`

As you can see, we used a different preserved block here. This preserved block adds
a pre-condition only when verifying the invariant on the function :cvl:`createTeam`
using environment :cvl:`env e`. Without this preserved block, the Prover may assume
that the team had players *before it was created*.

.. seealso::

   You can find out more about preserved blocks in :ref:`preserved` section.


.. Links
   -----

.. _nonExistTeamHasNoPlayers violation report:
   https://prover.certora.com/output/98279/65d0cd795ba640d6bdd7877074fca175?anonymousKey=55ad7f5a7130e367993082addf32fc7898494db3
