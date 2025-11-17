Installation
============

.. attention::

   These instructions are for Linux and macOS systems.
   Windows users should use `WSL`_ and follow the
   Linux installation instructions.

.. _WSL: https://learn.microsoft.com//install

   
Installing the SuiProver
-------------------------

#. First, we will need to install the Certora SuiProver.
   For that, please visit `Certora.com <https://www.certora.com/>`_ and sign up for a
   free account at `Certora sign-up page <https://www.certora.com/signup>`_.
#. You will receive an email with a temporary password and a *Certora Key*.
   Use the password to login to Certora following the link in the email.
#. Next, install Python3.9 or newer on your machine.
   If you already have Python3 installed, you can check the version: ``python3 --version``.
   If you need to upgrade, follow these instructions in the
   `Python Beginners Guide <https://wiki.python.org/moin/BeginnersGuide/Download>`_.
#. Next, install Java. Check your Java version: ``java -version``.
   If the version is < 11, download and install Java version 11 or later from
   `Oracle <https://www.oracle.com/java/technologies/downloads/>`_.
#. Then, install the Certora Prover: ``pip3 install certora-cli``.

   .. tip:: Always use a Python virtual environment when installing packages.

#. Recall that you received a *Certora Key* in your email (Step 2).
   Use the key to set a temporary environment variable like so
   ``export CERTORAKEY=<personal_access_key>``.
   Alternatively, to store the key in your profile see
   :ref:`Step 3 of the Prover installation <installation-step-3>`.


Move and Sui Setup
------------------

#. `Install the Sui CLI <https://docs.sui.io/guides/developer/getting-started/sui-install>`


----

With that, you should be all set for using Certora SuiProver. Congratulations!

