(install_evm_compiler)=
Installing an EVM compiler
============

A working local installation of a compiler is required for verification of EVM code.

TODO: add here the table of contents.

(selecting-solidity-compiler)=
Installing the relevant Solidity compiler versions
---------------------------------------------------------------------------

There are two ways to install the Solidity compiler (`solc`): via [solc-select](https://github.com/crytic/solc-select) or downloading the binary directly and adding its folder to your `PATH`.

```{index} single: solc; solc-select
```

### Using `solc-select`

<details>

  <summary>solc-select instructions</summary>

  * Open a terminal and install `solc-select` via `pip`:

    ```bash
    pip install solc-select
    ```

  * Download the required compiler version. For example,
    if you want to install version 0.8.0, run:

    ```bash
    solc-select install 0.8.0
    ```

  * Set `solc` to point to the required compiler version. For example:

    ```bash
    solc-select use 0.8.0
    ```
</details>


```{index} single: solc; solc executables
```

### Download binaries

You can download the `solc` binaries directly from
[Solidity's release page on GitHub](https://github.com/ethereum/solidity/releases).

To run the Prover, you may find it useful to add the
`solc` executables folder to your `PATH`. This way
you will not need to provide the Prover with the
full path to the `solc` executables folder every time.

```{eval-rst}
.. dropdown:: Downloading binaries

   .. tab-set::
   
      .. tab-item:: macOS
         :sync: macos
   
         * Open a terminal and move to the :file:`etc/paths.d` directory from root:
   
           .. code-block:: bash
    
              cd /etc/paths.d
   
         * Use root privileges to create a file with an informative
           name such as ``SolidityCertoraProver``, and open it with your favorite text editor:
   
           .. code-block:: bash
    
              sudo nano SolidityCertoraProver
   
         * Write the full path to the directory that contains the ``solc`` executables:
   
           .. code-block:: bash
    
              /full/path/to/solc/executable/folder
   
           * If needed, more than one path can be added on a single file,
             just separate the path with colon a (``:``).
   
         * Quit the terminal to load the new addition to ``$PATH``,
           and reopen to check that the ``$PATH`` was updated correctly:
   
           .. code-block:: bash
    
              echo $PATH
   
      .. tab-item:: Linux
         :sync: linux
         
         * Open a terminal and make sure you're in the home directory:
       
           .. code-block:: bash
    
              cd ~
       
         * open the .profile file with your favorite text editor:
       
           .. code-block:: bash
    
              nano .profile
       
         * At the bottom of the file, add to ``PATH="..."`` the full
           path to the directory that contains the `solc` executables.
           To add an additional path just separate with a colon (``:``) :
       
           .. code-block:: bash
    
              PATH="$PATH:/full/path/to/solc/executable/folder"
       
         * You can make sure that the file was modified correctly by opening
           it again with the text editor:
       
           .. code-block:: bash
    
              nano .profile
       
         * Make sure to apply the changes to the ``$PATH`` by executing the script:
       
           .. code-block:: bash
    
              source .profile
```

```{index} single: install; vyper
```

Install the Vyper compiler (`vyper`)
--------------------------------------------------------------------------------
[Vyper](https://github.com/vyperlang/vyper) is an EVM compatible Pythonic smart contract language.
Since the Certora Prover operates on the bytecode, it can be applied to any source-level language
that compiles to EVM bytecode.
We recommend to install Vyper either from PyPi (i.e., `pip install vyper`) or to get a 
binary executable for the desired version.