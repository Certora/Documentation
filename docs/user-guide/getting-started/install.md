(installation)=
Installation
============

Step 1: prerequisites
---------------------

<details>
  <summary>Linux or MacOS</summary>
  Windows users should use [WSL][wsl].

  % TODO: more information?
  </details>

[wsl]: https://learn.microsoft.com/en-us/windows/wsl/install

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

<details>
  <summary>Solidity compiler (ideally v0.5 and up)</summary>

  * If you use a specific version of Solidity in your contract, download the
    needed Solidity compiler from the [official Solidity repository](https://github.com/ethereum/solidity/releases)
    on GitHub. Make sure to place all the compilers that you download in the same
    path.

  * Certora employees can clone the `CVT_Executables` repository suitable for
    their OS from [GitHub](https://github.com/orgs/Certora/repositories).
</details>

Step 2: Install the Certora Prover package
------------------------------------------

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

<details>
  <summary>macOS</summary>

  ```{caution}
  The script `certoraRun` is installed in
  '/Users/user\_name/Library/Python/3.8/bin' which is not on PATH. Consider
  adding this directory to PATH
  ```

  * Open a terminal and move to the `etc/paths.d` directory from root:

    ```bash
    cd /etc/paths.d
    ```

  * Use root privileges to create a file with an informative name such as `PythonForProver`, and open it with your favorite text editor:

    ```bash
    sudo nano PythonForProver
    ```

  * Write the specified path from the warning:

    ```bash
    /specified/path/in/warning
    ```

  * If needed, more than one path can be added on a single file, just separate the path with a colon (`:`).

  * Quit the terminal to load the new addition to `$PATH`, and reopen to check that the `$PATH` was updated correctly:

    ```bash
    echo $PATH
    ```
</details>

<details>
  <summary>Linux</summary>

  ```{caution}
  Known warning - “The script `certoraRun` is installed in '`/home/user_name/.local/bin`' which is not on PATH. Consider adding this directory to PATH"
  ```

  * Open a terminal and make sure you're in the home directory:

    ```bash
    cd ~
    ```

  * open the .profile file with your favorite text editor:

    ```bash
    nano .profile
    ```

  * At the bottom of the file, add to `PATH="..."` the specified path from the warning. To add an additional path just separate with a colon (`:`) :

    ```bash
    PATH="$PATH:/specified/path/in/warning"
    ```

  * You can make sure that the file was modified correctly by opening it again with the text editor:

    ```bash
    nano .profile
    ```

  * Make sure to apply the changes to the `$PATH` by executing the script:

    ```bash
    source .profile
    ```
</details>

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
You can get a personal access key by registering on the 
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

<details>
  <summary>macOS</summary>

  * Open a terminal and make sure you're in the home directory:

    ```bash
    cd ~
    ```

  * Create a file with the name `.zshenv` and open it with your favorite text editor:

    ```bash
    nano .zshenv
    ```

  * Write the export command from the beginning of step 3, save and quit (`ctrl+x` on `nano`).

  * You can make sure that the file was created correctly by seeing it listed on the directory or by opening it again with the text editor:

    ```bash
    ls -a
    ```

    OR

    ```bash
    nano .zshenv
    ```

  * Make sure to apply the environment variable you've just created by executing the script:

    ```bash
    source .zshenv
    ```

</details>

<details>
  <summary>Linux</summary>

  * Open a terminal and make sure you're in the home directory:

    ```bash
    cd ~
    ```

  * open the .profile file with your favorite text editor:

    ```bash
    nano .profile
    ```

  * At the bottom of the file, under the `PATH="..."` insert the export command from the beginning of step 3, save and quit (`ctrl+x` on `nano`).

  * You can make sure that the file was modified correctly by opening it again with the text editor:

    ```bash
    nano .profile
    ```

  * Make sure to apply the environment variable you've just created by executing the script:

    ```bash
    source .profile
    ```
</details>

Step 4: Add the Solidity compiler (`solc`) executable's folder to your `PATH`
---------------------------------------------------------------------------

<details>
  <summary>macOS</summary>

  * Open a terminal and move to the `etc/paths.d` directory from root:

    ```bash
    cd /etc/paths.d
    ```

  * Use root privileges to create a file with an informative name such as `SolidityCertoraProver`, and open it with your favorite text editor:

    ```bash
    sudo nano SolidityCertoraProver
    ```

  * Write the full path to the directory that contains the `solc` executables:

    ```bash
    /full/path/to/solc/executable/folder
    ```

    * If needed, more than one path can be added on a single file, just separate the path with colon a (`:`).

  * Quit the terminal to load the new addition to `$PATH`, and reopen to check that the `$PATH` was updated correctly:

    ```bash
    echo $PATH
    ```
</details>

<details>
  <summary>Linux</summary>

  * Open a terminal and make sure you're in the home directory:

    ```bash
    cd ~
    ```

  * open the .profile file with your favorite text editor:

    ```bash
    nano .profile
    ```

  * At the bottom of the file, add to `PATH="..."` the full path to the directory that contains the `solc` executables. To add an additional path just separate with a colon (`:`) :

    ```bash
    PATH="$PATH:/full/path/to/solc/executable/folder"
    ```

  * You can make sure that the file was modified correctly by opening it again with the text editor:

    ```bash
    nano .profile
    ```

  * Make sure to apply the changes to the `$PATH` by executing the script:

    ```bash
    source .profile
    ```
</details>

Step 5 (for VS Code users): Install the Certora IDE Extension
--------------------------------------------------------------------------------

All users of the Certora Prover can access the tool using the command line 
interface, or [CLI](https://docs.certora.com/en/latest/docs/prover/cli/index.html). 
Those who use Microsoft's Visual Studio Code editor (VS Code) also have the 
option of using the Certora IDE Extension for that program.

To install VS Code, follow the platform specific instructions found on the 
[Visual Studio Code website](https://code.visualstudio.com/).

Once VS Code is installed, search for "Certora IDE" in VS Code's extension pane 
or [navigate there directly](https://marketplace.visualstudio.com/items?itemName=Certora.vscode-certora-prover) 
and follow the prompts to install the extension.

Instructions on how to use the Certora IDE extension are available directly from 
the extension's marketplace page.

Congratulations! You have just completed Certora Prover's installation and setup.

```{caution}
We strongly recommend trying the tool on basic examples to verify correct installation.  See {doc}`running` for a detailed walkthrough.
```
