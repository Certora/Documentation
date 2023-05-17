// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { MinFirstAllocationStrategy } from "./MinFirstAllocationStrategy.sol";
import { SigningKeys } from "./SigningKeys.sol";
import { Math256 } from "./Math256.sol";

contract main {
    using Math256 for uint256;
    // Node operator => index => signature
    mapping(uint256 => mapping(uint256 => SigningKeys.Signature)) private signatures;
    // Node operator => index => public key
    mapping(uint256 => mapping(uint256 => SigningKeys.PublicKey)) private publicKeys;
    
    /// Total number of registered node operators
    uint256 _nodeOperatorsCount;
    /// Total number of active node operators
    uint256 _activeNodeOperatorsCount;

    /// 
    mapping(uint256 => uint256) exitedKeys;
    mapping(uint256 => uint256) depositedKeys;
    mapping(uint256 => uint256) maxValidators;

    /// Total number of exited keys from all node operators
    uint256 exitedKeysSummary;
    /// Total number of deposited keys from all node operators
    uint256 depositedKeysSummary;
    /// Total number of max validators from all node operators
    uint256 maxValidatorsSummary;

    function getNodeOperatorsCount() public view returns (uint256) {
        return _nodeOperatorsCount;
    }

    function getActiveNodeOperatorsCount() public view returns (uint256) {
        return _activeNodeOperatorsCount;
    }

    /// @notice Obtains deposit data to be used by StakingRouter to deposit to the Ethereum Deposit
    ///     contract
    /// @param depositsCount Number of deposits to be done
    /// @return _publicKeys Batch of the concatenated public validators keys
    /// @return _signatures Batch of the concatenated deposit signatures for returned public keys
    function obtainDepositData(uint256 depositsCount) external returns (bytes memory _publicKeys, bytes memory _signatures) {
        if (depositsCount == 0) return (new bytes(0), new bytes(0));

        (
            uint256 allocatedKeysCount,
            uint256[] memory nodeOperatorIds,
            uint256[] memory activeKeysCountAfterAllocation
        ) = _getSigningKeysAllocationData(depositsCount);

        require(allocatedKeysCount == depositsCount, "INVALID_ALLOCATED_KEYS_COUNT");

        (_publicKeys, _signatures) = _loadAllocatedSigningKeys(
            allocatedKeysCount,
            nodeOperatorIds,
            activeKeysCountAfterAllocation
        );
    }

    function _getSigningKeysAllocationData(uint256 _keysCount)
        internal
        view
        returns (uint256 allocatedKeysCount, uint256[] memory nodeOperatorIds, uint256[] memory activeKeyCountsAfterAllocation)
    {
        uint256 activeNodeOperatorsCount = getActiveNodeOperatorsCount();
        nodeOperatorIds = new uint256[](activeNodeOperatorsCount);
        activeKeyCountsAfterAllocation = new uint256[](activeNodeOperatorsCount);
        uint256[] memory activeKeysCapacities = new uint256[](activeNodeOperatorsCount);

        uint256 activeNodeOperatorIndex;
        uint256 nodeOperatorsCount = getNodeOperatorsCount();
        uint256 maxSigningKeysCount;
        uint256 depositedSigningKeysCount;
        uint256 exitedSigningKeysCount;

        for (uint256 nodeOperatorId; nodeOperatorId < nodeOperatorsCount; ++nodeOperatorId) {
            (exitedSigningKeysCount, depositedSigningKeysCount, maxSigningKeysCount)
                = _getNodeOperator(nodeOperatorId);

            // the node operator has no available signing keys
            if (depositedSigningKeysCount == maxSigningKeysCount) continue;

            nodeOperatorIds[activeNodeOperatorIndex] = nodeOperatorId;
            activeKeyCountsAfterAllocation[activeNodeOperatorIndex] = depositedSigningKeysCount - exitedSigningKeysCount;
            activeKeysCapacities[activeNodeOperatorIndex] = maxSigningKeysCount - exitedSigningKeysCount;
            ++activeNodeOperatorIndex;
        }

        if (activeNodeOperatorIndex == 0) return (0, new uint256[](0), new uint256[](0));

        /// @dev shrink the length of the resulting arrays if some active node operators have no available keys to be deposited
        if (activeNodeOperatorIndex < activeNodeOperatorsCount) {
            assembly {
                mstore(nodeOperatorIds, activeNodeOperatorIndex)
                mstore(activeKeyCountsAfterAllocation, activeNodeOperatorIndex)
                mstore(activeKeysCapacities, activeNodeOperatorIndex)
            }
        }

        allocatedKeysCount =
            MinFirstAllocationStrategy.allocate(activeKeyCountsAfterAllocation, activeKeysCapacities, _keysCount);

        /// @dev method NEVER allocates more keys than was requested
        assert(_keysCount >= allocatedKeysCount);
    }

    function _loadAllocatedSigningKeys(
        uint256 _keysCountToLoad,
        uint256[] memory _nodeOperatorIds,
        uint256[] memory _activeKeyCountsAfterAllocation
    ) internal returns (bytes memory _pubkeys, bytes memory _signatures) {
        (_pubkeys, _signatures) = _initKeysSigsBuf(_keysCountToLoad);

        uint256 loadedKeysCount = 0;
        uint256 depositedSigningKeysCountBefore;
        uint256 depositedSigningKeysCountAfter;
        uint256 keysCount;
        for (uint256 i; i < _nodeOperatorIds.length; ++i) {
            depositedSigningKeysCountBefore = depositedKeys[_nodeOperatorIds[i]];
            depositedSigningKeysCountAfter = exitedKeys[_nodeOperatorIds[i]] + _activeKeyCountsAfterAllocation[i];

            if (depositedSigningKeysCountAfter == depositedSigningKeysCountBefore) continue;

            assert(depositedSigningKeysCountAfter > depositedSigningKeysCountBefore);

            keysCount = depositedSigningKeysCountAfter - depositedSigningKeysCountBefore;
            _loadNodeOperatorKeys(_nodeOperatorIds[i], depositedSigningKeysCountBefore, keysCount);
        
            loadedKeysCount += keysCount;

            depositedKeys[_nodeOperatorIds[i]] = depositedSigningKeysCountAfter;
        }

        assert(loadedKeysCount == _keysCountToLoad);

        depositedKeysSummary += loadedKeysCount;
    }

    function _initKeysSigsBuf(uint256 _count) internal pure returns (bytes memory, bytes memory) {
        return (new bytes(_count*(SigningKeys.PUBKEY_LENGTH)), new bytes(_count*(SigningKeys.SIGNATURE_LENGTH)));
    }

    function _getNodeOperator(uint256 nodeOperatorId) internal view returns (uint256, uint256, uint256) {
        uint256 exited = exitedKeys[nodeOperatorId];
        uint256 deposited = depositedKeys[nodeOperatorId];
        uint256 maxKeys = maxValidators[nodeOperatorId];
        return (exited, deposited, maxKeys);
    }

    function _loadNodeOperatorKeys(uint256 nodeOperatorId, uint256 index, uint256 keyCount) internal view returns (bytes memory pubkeys, bytes memory sigs) {
        pubkeys = new bytes(0);
        sigs = new bytes (0);
        bytes memory pubkey;
        bytes memory sig;
        for (uint256 i; i < keyCount; ++i) {
            pubkey = SigningKeys.constructPublicKey(publicKeys[nodeOperatorId][index]);
            sig = SigningKeys.constructSignature(signatures[nodeOperatorId][index]);
            pubkeys = abi.encodePacked(pubkeys, pubkey);
            sigs = abi.encodePacked(sigs, sig);
        }
    }
}
    