(storage-extension-annotations)=
Automatic Storage-Extension Harnesses
=====================================

Solidity ≋ EIP-7201 namespace
-----------------------------

Upgradeable contracts frequently tuck new state variables into
namespace “bookshelves” in storage:

```solidity
/** @custom:storage-location erc7201:my.project.book1 */
struct Book1 { /* ... */ }
```

Manually replicating the *slot math* in Certora rules or harnesses is
tedious and error-prone.
Lucky for you, now you can let the tool
*auto-generate* those storage extensions.

## Table of Contents

- [Feature Flags](#feature-flags)
- [How it works (high level)](#how-it-works-high-level)
- [Quick example](#quick-example)
- [Tips & limitations](#tips--limitations)
- [Troubleshooting](#troubleshooting)

---

(feature-flags)=
## Feature Flags

To enable automatic storage extension, add one or both of the following flags to your **conf JSON**:

| Flag                                           | Purpose                                                                                                                                | Default |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `"storage_extension_annotation": true         `| Detects `@custom:storage-location erc7201:…` annotations and **automatically extends the storage layout** during compilation.           | `false` |
| `"extract_storage_extension_annotation": true` | Dumps the generated harness Solidity file(s) to `<build_dir>/…` for inspection.                            | `false` |

**Example:**

```json
{
    "storage_extension_annotation": true,
    "extract_storage_extension_annotation": true
}
```

(how-it-works-high-level)=
## How it works (high level)

1. **Scan ASTs** – while compiling each `.sol` file the Prover looks for
   `StructDefinition` nodes that contain
   `@custom:storage-location erc7201:<namespace>`.

2. **Generate a minimal harness** – for every unique namespace the tool
   emits an *extra* contract containing **only**

   * Import statements for the original file,
   * one **dummy state variable** per namespace with the prefix
     `ext_<namespace>_` and the original struct name.

     ```solidity
     // auto-generated
     import "./OriginalFile.sol";
     contract _Auto_BookHarness_ {
         Book1 ext_my_project_book1;  // slot = keccak256("erc7201:my.project.book1")-1 & ~0xff
     }
     ```

3. **Compile the harness** with *exactly* the same `solc` flags
   (optimizer, via-IR, remappings, --overwrite, etc.) that the main run
   is using.

4. **Splice the fields** – the storage layout extracted from the harness
   is merged into the layout of every contract that *inherits* the
   annotated struct’s declaring contract.

5. **(optional) Dump the harness** into
   `.<build_dir>/` if
   `extract_storage_extension_annotation` is on.

(quick-example)=
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
  "storage_extension_annotation": true
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

(tips--limitations)=
## Tips & limitations

* Only **ERC-7201** strings (`erc7201:<namespace>`) are recognized.
* The hash function for slots follows the final EIP-7201 spec:
  `slot = keccak256(bytes(namespace)) - 1 & ~0xff`.
* The harness contains *zero* logic → no re-compilation surprises.
* If two structs claim the **same namespace**, a compilation-time error
  is raised with a helpful message pointing to the duplicate
  declaration.

(troubleshooting)=
## Troubleshooting

* **“Slot already declared”**
  Two different annotations resolved to the same slot. Double-check the
  namespace strings and inheritance chain.
