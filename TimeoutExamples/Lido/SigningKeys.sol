// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.9.0;

library SigningKeys {
    uint64 internal constant PUBKEY_LENGTH = 48;
    uint64 internal constant SIGNATURE_LENGTH = 96;
    uint256 internal constant UINT64_MAX = 0xFFFFFFFFFFFFFFFF;

    struct Signature {
        bytes32 a;
        bytes32 b;
        bytes32 c;
    }

    struct PublicKey {
        bytes32 a;
        bytes16 b;
    }

    function constructSignature(Signature storage sig) internal pure returns (bytes memory) {
        return abi.encode(sig);
    }

    function constructPublicKey(PublicKey storage key) internal pure returns (bytes memory) {
        return abi.encode(key);
    }
}
