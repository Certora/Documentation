# Get started with the Solana Certora Prover


## Installing Solana Certora Prover

1. First, we will need to install the Solana Certora Prover.
   For that, please visit [Certora.com](https://www.certora.com/) and sign up for a
   free account at [Certora sign-up page](https://www.certora.com/signup).

2. You will receive an email with a temporary password and a *Certora Key*.
   Use the password to login to Certora following the link in the email.

3. Next, install Python3.8.16 or newer on your machine.
   If you already have Python3 installed, you can check the version: `python3 --version`.
   If you need to upgrade, follow these instructions in the
   [Python Beginners Guide](https://wiki.python.org/moin/BeginnersGuide/Download).

4. Next, install Java. Check your Java version: `java -version`.
   If the version is < 11, download and install Java version 11 or later from
   [Oracle](https://www.oracle.com/java/technologies/downloads/).

5. Then, install the Certora Prover: `pip3 install certora-cli-beta`.

   Tip: Always use a Python virtual environment when installing packages.

6. Recall that you received a *Certora Key* in your email (Step 2).
   Use the key to set a temporary environment variable like so
   `export CERTORAKEY=<personal_access_key>`.


## Rust and Solana Setup

1. We recommend installing Rust as on the
   official [Rust website](https://www.rust-lang.org/tools/install): 

   `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

2. Next, install the Solana CLI:

   `sh -c "$(curl -sSfL https://release.solana.com/v1.18.16/install)`

	Currently, the Solana Prover only supports version `1.18.16` so make sure that you install that specific version.

3. Install Certora's version of platform-tools 1.41 as shown [here](https://github.com/Certora/certora-solana-platform-tools?tab=readme-ov-file#installation-of-executables).

4. Finally, install `rustfilt` like so: `cargo install rustfilt`.



