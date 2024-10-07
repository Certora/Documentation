.. role:: bash(code)
   :language: bash

CI Configuration
================

Follow these steps to configure CI for GitHub Actions on your repository:

* Step 1:
   Add the Certora CLI key `as a secret`_ to your repository, the secret name is `CERTORAKEY`
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

        # It's recommended to pin the latest certora-cli version available in https://pypi.org/project/certora-cli/
        - name: Install certora cli
          run: pip install certora-cli==7.3.0

        - name: Install solc
          run: |
            pip install solc-select
            solc-select install 0.8.23
            solc-select use 0.8.23

            # If your project depends on compiling with multiple solc versions, you can install and differentiate them using these commands.
            # wget https://github.com/ethereum/solidity/releases/download/v0.8.23/solc-static-linux
            # chmod +x solc-static-linux
            # sudo mv solc-static-linux /usr/local/bin/solc8.23

        - name: Verify ${{ matrix.rule }}
          env:
            CERTORAKEY: ${{ secrets.CERTORAKEY }}
          run: certoraRun  ${{ matrix.rule }}

      strategy:
        fail-fast: false
        max-parallel: 16
        matrix:
          rule:
              - path-to-conf1.conf --rule rule1 # https://docs.certora.com/en/latest/docs/prover/cli/options.html#rule-rule-name
              - path-to-conf1.conf --exclude_rule rule2 # https://docs.certora.com/en/latest/docs/prover/cli/options.html#exclude-rule-rule-name-pattern
              - path-to-conf2.conf # run the entire conf

.. Links
   -----
.. _as a secret: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository