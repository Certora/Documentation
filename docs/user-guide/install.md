```{index} single: install
```

(installation)=
Installation
============

```{attention}
These instructions are for Linux and macOS systems.
Windows users should use [WSL][wsl] and follow the
Linux installation instructions.
```

[wsl]: https://learn.microsoft.com/en-us/windows/wsl/install

Step 1: prerequisites
---------------------

<details>
  <summary>Python3.8.16 or newer</summary>

  Check your Python3 version by executing the following command on the
  terminal:

  ```bash
  python3 --version
  ```

  If the version is < 3.8.16, follow the [Python installation guide][pythonInstall] to upgrade.

  [pythonInstall]: https://wiki.python.org/moin/BeginnersGuide/Download
</details>

<details>
  <summary>Java Development Kit (JDK) 11 or newer</summary>

  Check your Java version by executing the following command on the terminal:
  ```bash
  java -version
  ```

  If the version is < 11, download and install Java version 11 or later from
  [Oracle](https://www.oracle.com/java/technologies/downloads/).
</details>

```{index} single: solc
```
<details>
  <summary>Solidity compiler (ideally v0.5 and up)</summary>

  * We recommend using [solc-select](https://github.com/crytic/solc-select)
    to download and switch between Solidity compiler versions.

  * You can also download the Solidity compiler binaries from the
    [official Solidity repository](https://github.com/ethereum/solidity/releases) on GitHub. 
    It is best to place all the `solc` binaries in the same path.

  * Certora employees can clone the `CVT_Executables` repository suitable for
    their OS from [GitHub](https://github.com/orgs/Certora/repositories).
</details>

Step 2: Install the Certora Prover package
------------------------------------------

```{tip}
It is always recommended to use a Python virtual environment,
such as [venv][venv] or [virtualenv][virtualenv],
when installing a Python package.
```

[venv]: https://docs.python.org/3.10/library/venv.html

Execute the following command at the terminal to install the Prover:

```bash
pip3 install certora-cli
```

```{caution}
Note that the terminal may prompt you with a warning that some files, e.g.
python3.x, are not included in the `PATH`, and should be added. Add these files
to `PATH` to avoid errors.
```

The following section presents some, but maybe not all, possible warnings that
can arise during installation and how to deal with them:

```{eval-rst}
.. dropdown:: Troubleshooting warnings

   .. tab-set::
   
      .. tab-item:: macOS
         :sync: macos
   
         .. code-block:: text
            :caption: The warning
         
            The script certoraRun is installed in /Users/<user name>/Library/Python/3.8/bin
            which is not on PATH. Consider adding this directory to PATH.
       
         * Open a terminal and move to the :file:`etc/paths.d` directory from root:
       
           .. code-block:: bash
        
              cd /etc/paths.d
       
         * Use root privileges to create a file with an informative name such as
           ``PythonForProver``, and open it with your favorite text editor:
       
           .. code-block:: bash
        
              sudo nano PythonForProver
       
         * Write the specified path from the warning:
       
           .. code-block:: bash
        
              /specified/path/in/warning
       
         * If needed, more than one path can be added on a single file,
           just separate the path with a colon (``:``).
       
         * Quit the terminal to load the new addition to ``$PATH``,
           and reopen to check that the ``$PATH`` was updated correctly:
       
           .. code-block:: bash
   
              echo $PATH
   
      .. tab-item:: Linux
         :sync: linux
   
         .. code-block:: text
            :caption: The warning
         
            The script certoraRun is installed in /home/<user name>/.local/bin
            which is not on PATH. Consider adding this directory to PATH.
       
         * Open a terminal and make sure you're in the home directory:
       
           .. code-block:: bash
   
              cd ~
       
         * open the .profile file with your favorite text editor:
       
           .. code-block:: bash
   
              nano .profile
       
         * At the bottom of the file, add to ``PATH="..."`` the specified path
           from the warning. To add an additional path just separate with a colon (`:`) :
       
           .. code-block:: bash
   
              PATH="$PATH:/specified/path/in/warning"
       
         * You can make sure that the file was modified correctly by opening it again
           with the text editor:
       
           .. code-block:: bash
   
              nano .profile
       
         * Make sure to apply the changes to the ``$PATH`` by executing the script:
       
           .. code-block:: bash
   
              source .profile
   
```

```{eval-rst}
.. index::
   single: install; beta version
   single: beta version
```

(beta-install)=
## Installing the beta version (optional)

If you wish to install a pre-release version, you can do so by installing
`certora-cli-beta` instead of `certora-cli`.  We do not recommend having both
packages installed simultaneously, so you should remove the `certora-cli`
package before installing `certora-cli-beta`:

```sh
pip uninstall certora-cli
pip install certora-cli-beta
```

If you wish to easily switch between the beta and the production versions, you
can use a [python virtual environment][virtualenv]:

[virtualenv]: https://virtualenv.pypa.io/en/latest/

```sh
pip install virtualenv
virtualenv certora-beta
source certora-beta/bin/activate
pip3 install certora-cli-beta
```

You can then switch to the standard CVL release by running `deactivate`, and
back to the beta release using `certora-beta/bin/activate`.

Step 3: Set the personal access key as an environment variable
-------------------------------------------------------------

The Certora Prover requires a personal access key. 
You can get a free personal access key by registering on the 
[Certora website](https://www.certora.com/signup?plan=prover).

Before running the Prover, 
you should register your access key as a system variable.
To do so on macOS or Linux machines, 
execute the following command on the terminal:

```bash
export CERTORAKEY=<personal_access_key>
```

This command sets a temporary variable that will be unset once the terminal is
closed. We recommended storing the access key in an environment variable named
`CERTORAKEY`. This way, you will no longer need to execute the above command
whenever you open a terminal. To set an environment variable permanently,
follow the next steps:

```{eval-rst}
.. tab-set::

   .. tab-item:: macOS
      :sync: macos

      * Open a terminal and make sure you're in the home directory:

        .. code-block:: bash

           cd ~
   
      * Create a file with the name ``.zshenv`` and open it with your favorite text editor:
    
        .. code-block:: bash
 
           nano .zshenv
    
      * Write the export command from the beginning of step 3,
        save and quit (``ctrl+x`` on ``nano``).
    
      * You can make sure that the file was created correctly by
        seeing it listed on the directory or by opening it again with the text editor:
    
        .. code-block:: bash
 
           ls -a
    
        OR
    
        .. code-block:: bash
 
           nano .zshenv
    
      * Make sure to apply the environment variable you've just created by executing the script:
    
        .. code-block:: bash
 
           source .zshenv

      When running the Certora Prover in the Visual Studio Code Extension, you may need
      to restart VSCode or your computer.

   .. tab-item:: Linux
      :sync: linux
      
      * Open a terminal and make sure you're in the home directory:

        .. code-block:: bash
 
           cd ~

      * open the .profile file with your favorite text editor:

        .. code-block:: bash
 
           nano .profile

      * At the bottom of the file, under the ``PATH="..."`` insert 
        the export command from the beginning of step 3, save and quit (``ctrl+x`` on ``nano``).

      * You can make sure that the file was modified correctly by
        opening it again with the text editor:

        .. code-block:: bash
 
           nano .profile

      * Make sure to apply the environment variable you've just created by executing the script:

        .. code-block:: bash
 
           source .profile
```

(selecting-solidity-compiler)=
Step 4: Install the relevant Solidity compiler versions
---------------------------------------------------------------------------

The Solidity compiler (`solc`) is a verification requirement.
There are two ways to install it: via [solc-select](https://github.com/crytic/solc-select) or downloading the binary directly and adding its folder to your `PATH`.

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

```{index} single: VS code; extension
```

Step 5 (for VS Code users): Install the Certora Verification Language LSP
-------------------------------------------------------------------------

All users of the Certora Prover can access the tool using the command line 
interface, or [CLI](https://docs.certora.com/en/latest/docs/prover/cli/index.html). 
Those who use Microsoft's Visual Studio Code editor (VS Code) also have the 
option of using the
[Certora Verification Language LSP](https://marketplace.visualstudio.com/items?itemName=Certora.evmspec-lsp).
This will provide both syntax checking and syntax highlighting for CVL.

----

Congratulations! You have just completed Certora Prover's installation and setup.

```{caution}
We strongly recommend trying the tool on basic examples to verify correct installation.
See {doc}`running` for a detailed walkthrough.
```
