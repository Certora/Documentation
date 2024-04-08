.. role:: bash(code)
   :language: bash

CI Configuration
================

Follow these steps to configure CI for GitHub Actions on your repository:

* Step 1:
   Add the Certora CLI key `as a secret`_ to your repository, the secret name is "CERTORAKEY"
   and the value is the key provided.

* Step 2:
   Create a :bash:`certora_verification.yml` file under :bash:`.github` directory and 
   use the following `.yaml` example as a template you can use to start running `certora-cli`.

.. code-block:: yaml

   name: certora-verification

   on:
   push:
      branches:
         - main
   pull_request:
      branches:
         - main

   workflow_dispatch:

   jobs:
   verify:
      runs-on: ubuntu-latest

      steps:
         - uses: actions/checkout@v4
         with:
            submodules: recursive

         - name: Install python
         uses: actions/setup-python@v2
         with: { python-version: 3.9 }

         - name: Install java
         uses: actions/setup-java@v1
         with: { java-version: "11", java-package: jre }

         - name: Install certora cli
         run: pip3 install certora-cli==7.0.7

         - name: Install solc
         run: |
            wget https://github.com/ethereum/solidity/releases/download/v0.8.23/solc-static-linux
            chmod +x solc-static-linux
            sudo mv solc-static-linux /usr/local/bin/solc8.23

         - name: Verify
         env:
            CERTORAKEY: ${{ secrets.CERTORAKEY }}
         run: |
            # Add your code here

.. Links
   -----
.. _as a secret: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository