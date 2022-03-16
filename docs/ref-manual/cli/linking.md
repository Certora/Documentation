Linking
=======

Troubleshooting
---------------

* `Failed to perform link in contract ...  Solidity compiler version may be too old.` - linking introduces a constraint that the storage slot holding the address linked is equal to the contract we link to. But if there are packed variables within the same storage slots, and we lack information about the layout of the storage, the linking may fail. One may try to override the entire slot (regardless of packing) using the option `fullWordLinkingWhenNoStorageAnalysis`. By default, it is set to false. Note that setting this option may affect other variables that are packed with the linked address and set them to 0, which may affect correctness.