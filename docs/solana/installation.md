# Get started with the Solana Certora Prover

## Installing Solana Certora Prover

Begin by following the steps in {ref}`installation`.

## Rust and Solana Setup

1. We recommend installing Rust as on the
   official [Rust website](https://www.rust-lang.org/tools/install): 

   `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

2. Next, install the Solana CLI:

   `sh -c "$(curl -sSfL https://release.solana.com/v1.18.16/install)"`

	Currently, the Solana Prover only supports version `1.18.16` so make sure that you install that specific version.

3. Install Certora's version of platform-tools 1.41 as shown [here](https://github.com/Certora/certora-solana-platform-tools?tab=readme-ov-file#installation-of-executables).

4. Finally, install `rustfilt` like so: `cargo install rustfilt`.

----

Congratulations! You have just completed Certora Prover's installation and setup.

```{caution}
We strongly recommend trying the tool on basic examples to verify correct installation.
See {ref}`solana_usage` for a detailed walkthrough.
```

