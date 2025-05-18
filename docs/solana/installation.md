# Get started with the Solana Certora Prover

## Installing Solana Certora Prover

Begin by following the steps in the {ref}`Certora Prover installation guide <installation>`.

## Rust, Solana, and Certora Platform Tools Setup

1. We recommend installing Rust as on the
   official [Rust website](https://www.rust-lang.org/tools/install): 

   `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

   It is useful to have Rust versions 1.75, 1.79, and 1.81 or above installed.

   ```
   rustup toolchain install 1.79
   rustup toolchain install 1.75
   rustup toolchain install 1.81
   ```

2. Install `certora-sbf` cargo sub-command

   `cargo +1.81 install cargo-certora-sbf`

   Note that a minimal version of Rust required to install `certora-sbf` is
   v1.81.

3. Test the installation by using `certora-sbf` to download and install Certora
   Platform Tools

   `cargo certora-sbf --no-build`

4. It is strongly recommended to install VSCode and the rust-analyzer extension.

----

Congratulations! You have just completed Solana Certora Prover's installation and setup.

```{caution}
We strongly recommend trying the tool on basic examples to verify correct installation.
See {ref}`solana_usage` for a detailed walkthrough.
```

