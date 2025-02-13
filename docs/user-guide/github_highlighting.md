```{index} single: GitHub
```

(github_highlighting)=
Syntax Highlighting on GitHub
============
This page explains how improve GitHub sytax highlighting in your repository for Certora prover [configuration](conf-files) and [specification](cvl-language) files.

**show old pic and new pic**

Steps
-----

1. Create a `.gitattributes` file in the root directory of the repository if it doesn't exist.

2. Append to the end of the `.gitattributes` file the following:

```
*.spec linguist-language=Solidity
*.conf linguist-detectable
*.conf linguist-language=JSON5
```

3. Commit and push the changes

4. Wait for GitHub to process the changes (can take a few hours to 24 hours).

Explanation
-----------
The file `.gitattributes` tells GitHub to associate files with the suffixes `.spec` and `.conf` as specific languages. While `.conf` files are just [JSON5](https://json5.org/) files with a different suffix, CVL highlighting is not yet supported on GitHub. Since CVL is so similar to Solidity, the highlighter still gives far better results than GitHub's default highlighter. For example, see:

**Show examples of .spec highlighting diff**


Troubleshooting
---------------

### Step 1 - Check local language detection
- Check that `.gitattributes` was updated correctly by running inside your git repository:
```
git check-attr linguist-language -- **/*.spec **/*.conf
```

You should see that the files are associated correctly, and get this output:
```
path/to/file.spec: linguist-language: Solidity
...
path/to/file.conf: linguist-language: JSON5
```

If you get the language as undefined, as seen below, it means that `.gitattributes` is not at the root of the repo or was not updated correctly:
```
CLIFlags/solc_via_ir.conf: linguist-language: unspecified
```

### Step 2 - Verify GitHub server update
Run the following API query to confirm GitHub's Linguist has updated the classification:
`https://api.github.com/repos/YOUR-ORG/YOUR-REPO/languages`
You should see an output similar to this:
```
{
  "Solidity": 21038,
  "JSON5": 443
  ...
}
```

If you get an empty JSON, check that the change was pushed and that there are no file suffix clashes with previous contents of `.gitattributes`.

