Installation of Certora Prover
==============================

Step 1: Prerequisites
---------------------

### Python3.5 or newer

* Check your Python3 version by executing the following command on the
  terminal:
  
  ```bash
  python3 --version
  ```
  
* If the version is < 3.5 an installation of a newer version is needed.
  * You can follow the installation guide on the
  [python.org wiki](https://wiki.python.org/moin/BeginnersGuide/Download).

### Java Development Kit (JDK) 11 or newer

* Check your Java version by executing the following command on the terminal:
  ```bash
  java --version
  ```

* If the version is < 11, you must install a newer version.
  * Download the appropriate Java installer from
  [Oracle.com](https://www.oracle.com/java/technologies/downloads/)
  according to your OS and system’s specification.

### Solidity compiler (ideally v0.5 and up)

* If you use a specific version of Solidity in your contract, download the
  needed Solidity compiler from the [official Solidity repository](https://github.com/ethereum/solidity/releases)
  on Github. Make sure to place all the compilers that you download in the same
  path.
  
* Certora employees can clone the `CVT_Executables` repository suitable for
  their OS from [Github](https://github.com/orgs/Certora/repositories).

Step 2: Install the Certora Prover package
------------------------------------------

On Terminal execute:

```bash
pip3 install certora-cli
```

Note that the terminal may prompt you with a warning that some files, e.g.
python3.x, are not included in the PATH, and should be added. Add these files
to PATH to avoid errors.

The following section presents some, but maybe not all, possible warnings that
can arise during installation and how to deal with them:

### Windows

So far we haven’t encountered any warnings at installation that's needed to be
resolved to use the tool freely, however it doesn’t mean that you won’t
encounter one.

If you do encounter a warning try the following solutions in descending order:

* Follow the warning’s instructions.
  
* If you do not understand the warning and don’t know how to fix it, try to
  compare it to the warning of the other OS and follow their instructions.
 * The warnings in the other OS suggest to add the installation folder to the PATH.

 * To get the location of the certora-cli installation re-execute on cmd:

   ```bash
   pip install certora-cli
   ```

* Contact the Certora team.

Please also share the warning with us so we could write a walkthrough for fixing it.

### macOS

WARNING: The script certoraRun is installed in
'/Users/user\_name/Library/Python/3.8/bin' which is not on PATH. Consider
adding this directory to PATH

* Open a terminal and move to the `etc/paths.d` directory from root:

  ```bash
  cd /etc/paths.d
  ```
  
* Use root privileges to create a file with an informative name such as “PythonForProver”, and open it with your favorite text editor:
  
  ```bash
  sudo nano PythonForProver
  ```
  
* Write the specified path from the warning:
  
  ```bash
  /specified/path/in/warning
  ```
  
  * If needed, more than one path can be added on a single file, just separate the path with colon a (`:`).
    
* Quit the terminal to load the new addition to $PATH, and reopen to check that the $PATH was updated correctly:
  
  ```java
  echo $PATH
  ```
  

### Linux

Known warning - “The script certoraRun is installed in '`/home/user_name/.local/bin`' which is not on PATH. Consider adding this directory to PATH"

* Open a terminal and make sure you’re in the home directory:
  
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
  
* Make sure to apply the changes to the $PATH by executing the script:
  
  ```bash
  source .profile
  ```

Step 3: Set the premium access key as an environment variable
-------------------------------------------------------------

The Certora Prover is available for all to use in a free trial version. The
Prover's processing power and storage capacity are limited in the trial
version. If you are using the tool in this way, you can skip to the next step.

Otherwise, you should have received a personal _premium key_ from the Certora
team. Before running the Prover in the premium version, you should register the
premium key as a system variable.

To do so on macOS or Linux machines, execute the following command on the terminal:

```bash
export CERTORAKEY=<premium_key>
```

This command sets a temporary variable that will be unset once the terminal is
closed. We recommended storing the premium key in an environment variable named
`CERTORAKEY`. This way, you will no longer need to execute the above command
whenever you open a terminal. To set an environment variable permanently,
follow the next steps:

### Windows

* Open the cmd terminal and execute:
  
  ```bash
  setx CERTORAKEY <premium_key>
  ```
  

### macOS

* Open a terminal and make sure you’re in the home directory:
  
  ```bash
  cd ~
  ```
  
* Create a file with the name `.zshenv` and open it with your favorite text editor:
  
  ```java
  nano .zshenv
  ```
  
* Write the export command from the beginning of step 3, save and quit (`ctrl+x` on nano).
  
* You can make sure that the file was created correctly by seeing it listed on the directory or by opening it again with the text editor:
  
  ```java
  ls -a
  ```
  
  OR
  
  ```java
  nano .zshenv
  ```
  
* Make sure to apply the environment variable you’ve just created by executing the script:
  
  ```bash
  source .zshenv
  ```
  

### Linux

* Open a terminal and make sure you’re in the home directory:
  
  ```bash
  cd ~
  ```
  
* open the .profile file with your favorite text editor:
  
  ```bash
  nano .profile
  ```
  
* At the bottom of the file, under the `PATH="..."` insert the export command from the beginning of step 3, save and quit (`ctrl+x` on nano).
  
* You can make sure that the file was modified correctly by opening it again with the text editor:
  
  ```bash
  nano .profile
  ```
  
* Make sure to apply the environment variable you’ve just created by executing the script:
  
  ```bash
  source .profile
  ```
  

Step 4: Add the Solidity compiler (solc) executable's folder to your PATH
-------------------------------------------------------------------------

### Windows

The following instructions are for Windows 11; for other versions of Windows the instructions might slightly differ.

* Press `"Windows key" + x` to access the Power User Task Menu.
  
* In the Power User Task Menu, select the System option.
  
* In the System window, scroll to the bottom and click the About option.
  
* In the System > About window, click the Advanced system settings link at the bottom of the Device specifications section.
  
* In the System Properties window, click the Advanced tab, then click the Environment Variables button near the bottom of that tab.
  
* In the Environment Variables window, highlight the Path variable in the System variables section and click the Edit button.
  
* Add the full path to the directory that contains the solc executables, e.g.:
  
  ```bash
  C:\full\path\to\solc\executable\folder
  ```
  
* Quit and reopen all opened terminals for the change to take effect in the terminals.
  
* You can check that the variable was set correctly by running the following in the cmd terminal:
  
  ```bash
  echo %PATH%
  ```
  

### macOS

* Open a terminal and move to the `etc/paths.d` directory from root:
  
  ```bash
  cd /etc/paths.d
  ```
  
* Use root privileges to create a file with an informative name such as “SolidityCertoraProver”, and open it with your favorite text editor:
  
  ```bash
  sudo nano SolidityCertoraProver
  ```
  
* Write the full path to the directory that contains the `solc` executables:
  
  ```bash
  /full/path/to/solc/executable/folder
  ```
  
  * If needed, more than one path can be added on a single file, just separate the path with colon a (`:`).
    
* Quit the terminal to load the new addition to $PATH, and reopen to check that the $PATH was updated correctly:
  
  ```java
  echo $PATH
  ```
  

### Linux

* Open a terminal and make sure you’re in the home directory:
  
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
  

Congratulations! You have just completed Certora Prover’s installation and setup.

**It's highly recommended to first try out the tool on basic examples to verify correct installation. You can follow the page** [**Running The Certora Prover**](Running-The-Certora-Prover_284360712.html) **for that purpose.**
