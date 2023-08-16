// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();

        (
            bytes32 keyHash,
            address vrfCoordinator,
            uint64 subscriptionId,
            uint32 gasLimit,
            uint32 numWords,
            uint16 requestConfirmations,
            uint256 entranceFee,
            uint256 interval
        ) = helperConfig.s_activeConfig();

        // addConsumer

        if (subscriptionId == 0) {
            // create new Subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                address(vrfCoordinator)
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                address(vrfCoordinator),
                subscriptionId
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            keyHash,
            vrfCoordinator,
            subscriptionId,
            gasLimit,
            numWords,
            requestConfirmations
        );
        vm.stopBroadcast();

        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            subscriptionId
        );

        return (raffle, helperConfig);
    }
}
