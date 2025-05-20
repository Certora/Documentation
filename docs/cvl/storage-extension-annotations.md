(storage-extension-annotations)=
Automatic Storage-Extension Harnesses
=====================================

[Solidity and EIP-7201 namespace](https://eips.ethereum.org/EIPS/eip-7201)
-----------------------------

Upgradeable contracts frequently tuck new state variables into
namespace “bookshelves” in storage:

```solidity
/** @custom:storage-location erc7201:my.project.book1 */
struct Book1 { /* ... */ }
```

Manually replicating the slot calculation for storage extensions in CVL rules or harnesses can be tedious and error-prone. Certora Prover now supports automatic generation of these storage extensions, reducing manual effort and minimizing mistakes.

## Table of Contents

- [Feature Flags](#storage-extension-flags)
- [How it works (high level)](#storage-extension-how)
- [Quick example](#storage-extension-example)
- [Troubleshooting](#storage-extension-troubleshooting)

---

(storage-extension-flags)=
## Storage Extension Flags

To enable automatic storage extension, add one or both of the following flags to your `.conf` JSON:

| Flag                             | Appearance in `.conf` file                | Pass directly to CLI option                   | Purpose                                                                                                                                |
| -------------------------------- | ----------------------------------------- | --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| storage_extension_annotation     | `"storage_extension_annotation": true`    | `--storage_extension_annotation`              | Detects `@custom:storage-location erc7201:…` annotations and **automatically extends the storage layout** during compilation.           |
| extract_storage_extension_annotation | `"extract_storage_extension_annotation": true` | `--extract_storage_extension_annotation`      | Dumps the generated harness Solidity file(s) to `<build_dir>/…` for inspection.                                                        |

**Example:**

```json
{
  // ...
    "storage_extension_annotation": true,
    "extract_storage_extension_annotation": true
  // ...
}
```

(storage-extension-how)=
## How it works (high level)

1. **Scan ASTs** – while compiling each `.sol` file, the Prover looks for
   struct definitions with a preceding comment 
   `@custom:storage-location erc7201:<namespace>`.

2. **Generate a minimal harness** – for every unique namespace the tool
   emits an *extra* contract containing **only**:

   * Import statements for the original file,
   * one dummy state variable per namespace with the prefix
     `ext_<namespace>_` and the original struct name.

     ```solidity
     // auto-generated
     import "./OriginalFile.sol";
     contract _Auto_BookHarness_ {
         Book1 ext_my_project_book1;  // slot = keccak256("erc7201:my.project.book1")-1 & ~0xff
     }
     ```

3. **Compile the harness** with *exactly* the same `solc` flags that the main file is using.

4. **Splice the fields** – the storage layout extracted from the harness
   is merged into the layout of every contract that *inherits* the
   annotated struct’s declaring contract.

5. **(optional) Dump the harness** into
   `.<build_dir>/` if
   `extract_storage_extension_annotation` is on.

(storage-extension-example)=
## Quick example

```solidity
contract VaultBridgeToken {
    /** @custom:storage-location erc7201:agglayer.vault-bridge.VaultBridgeToken.storage */
    struct VaultBridgeTokenStorage {
        IERC20 underlyingToken;
        uint256 reservedAssets;
        // ...
    }
}
```

With

```json
{
  // ...
  "storage_extension_annotation": true
  // ...
}
```

you can immediately assert over `currentContract.ext_agglayer_vault_bridge_VaultBridgeToken_storage.underlyingToken`
in CVL:

```cvl
rule no_reserved_assets_leak(env e) {
    require currentContract._reservedAssets() == 0;
    deposit(e, 100);
    assert currentContract.ext_agglayer_vault_bridge_VaultBridgeToken_storage.reservedAssets >= 100;
}
```

(storage-extension-troubleshooting)=
## Troubleshooting

* **“Slot already declared”**
  Two different annotations resolved to the same slot. Double-check the
  namespace strings and inheritance chain.
