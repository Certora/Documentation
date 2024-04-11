.. role:: bash(code)
   :language: bash

Running the Certora Prover
==========================

The :bash:`certoraRun` utility simplifies the verification process by invoking the
contract compiler (e.g., Solidity) and then sending the verification job to Certora’s
servers.

The most commonly used command is:

.. code-block:: bash

   certoraRun contractFile:contractName --verify contractName:specFile

If :bash:`contractFile` is named :bash:`contractName.sol`, the command can be further
simplified to:

.. code-block:: bash

   certoraRun contractFile --verify contractName:specFile


A concise summary of these options can be viewed by using:

.. code-block:: bash

   certoraRun --help


Usage Example with ERC20 Contract
---------------------------------

To demonstrate the usage, let's consider an ERC20 contract named
:clink:`ERC20Fixed </DEFI/ERC20/contracts/correct/ERC20Fixed.sol>` from the
:clink:`Certora Prover and CVL Examples Repository </>`.
The corresponding spec file is named
:clink:`ERC20Fixed.spec </DEFI/ERC20/certora/specs/ERC20Fixed.spec>`.
Here is a rule from this spec:

.. cvlinclude:: ../../Examples/DEFI/ERC20/certora/specs/ERC20Fixed.spec
   :cvlobject: transferSpec
   :caption: :clink:`from ERC20Fixed.spec </DEFI/ERC20/certora/specs/ERC20Fixed.spec>`

You can run the Certora Prover with the following command (from the
:clink:`/DEFI/ERC20/` folder in the repository):

.. code-block:: bash

   certoraRun contracts/correct/ERC20Fixed.sol --verify ERC20Fixed:certora/specs/ERC20Fixed.spec

This command triggers a verification run on the :solidity:`ERC20` contract from the
solidity file :file:`ERC20.sol`, checking all rules in the specification file
:file:`ERC20Fixed.spec`.

.. tip::

   You will need to use the correct version of the Solidity compiler.
   Either by

   * using ``solc-select`` or having the compiler executable in your path
     (see :ref:`selecting-solidity-compiler`),
   * or by directing the ``certoraRun`` to the correct path using the
     :ref:`--solc` argument.
   

Results
-------

While running, the Prover will print various information to the console about the run.
In the end, the output will look similar to this:

.. code-block:: text

   ...

   Job submitted to server

   Follow your job at https://prover.certora.com
   Once the job is completed, the results will be available at https://prover.certora.com/...

The output indicates that the Prover running the verification request, and it provides
a link to view the results on the Certora platform. 

Using Configuration (Conf) Files
--------------------------------

For larger projects, managing the command line for Certora Prover can become complex.
It is advisable to use configuration files (with a :file:`.conf` extension) that hold
the parameters and options for the Prover.
These JSON5 configuration files simplify the process and enhance manageability.
Refer to :ref:`conf-files` for more detailed information.
