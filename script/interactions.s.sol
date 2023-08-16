// SPDX-LICENSE-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address vrfCoordinator,
        uint64 subId
    ) external {
        vm.startBroadcast();
        VRFCoordinatorV2Mock mock = VRFCoordinatorV2Mock(vrfCoordinator);
        mock.addConsumer(subId, raffle);

        vm.stopBroadcast();
    }
}

contract CreateSubscription is Script {
    function createSubscription(
        address vrfCoordinator
    ) external returns (uint64 subId) {
        vm.startBroadcast();
        VRFCoordinatorV2Mock mock = VRFCoordinatorV2Mock(vrfCoordinator);
        subId = mock.createSubscription();
        console.log(
            "subId: [%s] Update your Config file for this blockChain %s",
            subId,
            block.chainid
        );
        vm.stopBroadcast();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscription(address vrfCoordinatorr, uint64 subId) external {
        vm.startBroadcast();
        VRFCoordinatorV2Mock mock = VRFCoordinatorV2Mock(vrfCoordinatorr);
        mock.fundSubscription(subId, FUND_AMOUNT);

        vm.stopBroadcast();
    }
}
