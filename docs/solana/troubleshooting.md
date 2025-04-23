# Troubleshooting

This section describes resolution of common issues when using the Solana Prover.

## Unable to run `certoraSolanaProver`

The `certoraSolanaProver` command has been introduced in version `7.22.0` of
the Certora Prover package.
Run `certoraRun --version` to verify that you are using a version greater or
equal to `7.22.0`.
It is possible to upgrade the Certora Prover package with the following command:
`pip3 install --upgrade certora-cli`.
For information about how to install the Certora Prover package, refer to
[Installation](./installation.md).

## Jump to Source (JTS) feature not working

Observe that the Jump to Source feature does not work if the source files are
not
uploaded to the cloud.
For more information about how to use the Certora Prover for Solana and
correctly upload the source files to the cloud, refer to
[Installation](./installation.md).

By default, JTS works for assertions, and for calls to `clog!()` macro (i.e., calls without any additional arguments). In additional, source location is inferred automatically from debug information. However, the reliability of the automatic JTS depends on the optimizations performed by the compiler.

## Prover Errors

The Solana Prover is currently under development, and some features are not
supported yet.  The most common source of errors from the Prover are
stack-allocated arrays.  Accessing an element in an array that has been
allocated on the stack can result in an error.  For instance, the following rule
triggers a Prover error.

```rust
#[rule]
fn access_stack_element() {
    let ints = [0, 1, 2];
    let index: usize = nondet_with(|x| *x < 3);
    cvlr_assert!(ints[index] < 3);
}
```

The Prover will display the following error message:
![Stack Access Error](./img/stack_access_error.png)

To solve this, modify the source code to move the array to the heap.
For instance, in the previous example it is sufficient to modify the type of
`ints` from `[i32; 3]` to `Vec<i32>`:

```rust
#[rule]
fn access_stack_element() {
    let ints = vec![0, 1, 2];
    let index: usize = nondet_with(|x| *x < 3);
    cvlr_assert!(ints[index] < 3);
}
```