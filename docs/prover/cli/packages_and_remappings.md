# Packages and Remappings

The Solidity compiler \(`solc`\) uses a virtual file system \(VFS\) to abstract how
files are accessed. Instead of reading directly from disk, `solc` interacts with a
file system interface that maps import paths to file contents. 
`solc` supports flags to indicate where to find imported files, and supports remappings to change 
how import paths are resolved.  

Example,
```shell
solc contracts/MyToken.sol \
  --base-path . \
  --include-path node_modules \
  @openzeppelin=node_modules/@openzeppelin

```
In this example paths to modules starts from current working directory, and some libraries will be stored under 
the `node_modules` directory. Paths to imports of the form `@openzeppelin/XXX` will be resolved to the path
 `node_modules/@openzeppelin/XXX`.

More information on path resolution in Solidity compiler can be found  [here](https://docs.soliditylang.org/en/latest/path-resolution.html).  

There are three methods for the prover client to pass remappings and import file location instructions 
to the `solc` compiler:   

\(1\) Using client flags/attributes  
\(2\) Following Hardhat's package support  
\(3\) Following Foundry's remappings support

## Using client flags/attributes

The attributes {ref}`--packages` holds a list of path remappings of the form 
```text
prefix=path
```
Format is identical to the Solidity compiler's remappings and will be passed as is to the compiler.
In the conf file it will look like this:

```json
{
  "packages": [
    "layerzero/=lib/layerzerolabs/lz-evm-oapp-v2/contracts",
    "openzeppelin/=lib/openzeppelin-contracts/"
  ]
}
```

## Using hardhat's package support
Hardhat is a popular development environment for Ethereum smart contracts, written in JavaScript and TypeScript.
For package, Hardhat uses the `Node.js` package manager (`npm`) to manage dependencies, which are typically stored in 
the `node_modules` directory.

The Certora Prover Client will check if  the file `package.json` in the current directory. 
If it is, packages will be retrieved from the JSON file and for each package, the client will generate a remapping
for the Solidity compiler. The remapping will map the package name to its default location in the `node_modules` directory.
The attributes {ref}--packages_path can be used to specify the root directory for packages in
case where they were installed in a different location than the default `node_modules` directory. 
Another way to specify the location of packages is by setting the `NODE_PATH` environment variable.


## Using foundry's remappings support
Foundry is another Rust-based Ethereum development framework for deploying smart 
contracts written in Solidity. 
Foundry handles dependencies in the `foundry.toml` configuration file. The dependencies in `foundry.toml` can be 
overridden by a `remappings.txt` file that contains import remappings, each line in the file has the format:  
```text
import_prefix=path/to/dependency/
```
The syntax is identical to the Solidity compiler's remappings and to the `packages` attribute in the Prover client.
`foundry.toml` and `remappings.txt` are expected to be in the project root directory.

## How does it work?

To find the location of packages and remappings, the Prover client follows these steps:
1. If the attribute {ref}`--packages` was set in the configuration file or as a flag `--packages` in the command line,
   the remappings are used when calling the solidity compiler. In this case remappings in `package.json` or `remappings.txt` are ignored.
2. If {ref}`--packages` was set, but `package.json` is found in the current directory, then for each package
   specified in the objects `dependencies` and `devDependencies` a mapping is generated (as described above).
3. If the current directory is inside a foundry project, i.e. `foundry.toml` is found in the current directory or in a parent directory, 
   then getting all the project remappings is done by simply calling the shell command:
   ```shell
   forge remappings
   ```
4. If the current directory is not inside a foundry project, but the Prover client finds a `remappings.txt` file in current working directory,
   it reads the remappings from this file and uses them to resolve import paths.

The Prover client checks there are no conflicts between remappings from `package.json` and remappings from a `remappings.txt` file.
If such conflicts are found, the Prover client will throw an error and exit.