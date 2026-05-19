# Get started with the Solana Certora Prover

## Installing Solana Certora Prover

Begin by following the steps in the {ref}`Certora Prover installation guide <installation>`.

## Rust, Solana, and Certora Platform Tools Setup

1. We recommend installing Rust as on the
   official [Rust website](https://www.rust-lang.org/tools/install): 

   `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

Rust 1.85 or above is recommended to be able to build cargo-certora-sbf and when using cvlr-solana ≥ 0.5. Version 1.75 can be used when analyzing programs that use older cvlr-solana versions (below or equal to 0.4) and programs that are bundled with Solana v1.18 (1.79 matches the one bundled with Solana v2.1). Install whichever versions correspond to the Solana releases you target:


   ```
   rustup toolchain install 1.85   # (recommended) if the program under analysis uses Solana v2.3
   rustup toolchain install 1.79   # (alternatively) if the program under analysis uses Solana v2.1
   rustup toolchain install 1.75   # (alternatively) if the program under analysis uses Solana v1.18
   ```

2. Install [`certora-sbf`](https://github.com/Certora/cargo-certora-sbf) cargo sub-command

   ```
   cargo install cargo-certora-sbf
   ```

4. Test the installation by using `certora-sbf` to download and install Certora
   Platform Tools

   ```
   cargo certora-sbf --no-build
   ```

6. Install [llvm](https://releases.llvm.org/), you can typically install it also via apt or brew.

7. Install [rustfilt](https://github.com/luser/rustfilt)
   ```
   cargo install rustfilt
   ```

8. It is strongly recommended to install VSCode and the rust-analyzer extension.

----

Congratulations! You have just completed Solana Certora Prover's installation and setup.

```{caution}
We strongly recommend trying the tool on basic examples to verify correct installation.
See {ref}`solana_usage` for a detailed walkthrough.
```

