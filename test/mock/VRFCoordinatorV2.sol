// SPDX-License- Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

contract VRFCoordinatorV2 {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId) {
        requestId = 1;
    }
}
