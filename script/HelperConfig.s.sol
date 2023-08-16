// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    struct Config {
        bytes32 KEY_HASH;
        address VRF_COORDINATOR;
        uint64 SUBSCRIPTION_ID;
        uint32 GAS_LIMIT;
        uint32 NUM_WORDS;
        uint16 REQUEST_CONFIRMATIONS;
        uint256 ENTRANCE_FEE; //= 0.1 ether;
        uint256 INTERVAL; // 1 week
    }

    Config public s_activeConfig;

    constructor() {
        s_activeConfig = calculateActiveConfig();
    }

    function calculateActiveConfig() public returns (Config memory config) {
        if (block.chainid == 1) {
            // eth mainet
            config = getEthMainetConfig();
        } else if (block.chainid == 11155111) {
            // sepolia alchemy
            config = getSepoliaConfig();
        } else {
            config = getOrCreateAnvilConfig();
        }
    }

    function getOrCreateAnvilConfig() internal returns (Config memory config) {
        if (s_activeConfig.VRF_COORDINATOR != address(0)) {
            return config;
        }
        uint96 _baseFee = 0.25 ether; // 0.25 LINK
        uint96 _gasPriceLink = 1e9; // 1 gwei LINK

        vm.startBroadcast();
        VRFCoordinatorV2Mock mock = new VRFCoordinatorV2Mock(
            _baseFee,
            _gasPriceLink
        );
        vm.stopBroadcast();

        config
            .KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        config.VRF_COORDINATOR = address(mock);
        config.SUBSCRIPTION_ID = 0;
        config.GAS_LIMIT = 200000;
        config.NUM_WORDS = 1;
        config.REQUEST_CONFIRMATIONS = 3;
        config.ENTRANCE_FEE = 0.1 ether;
        config.INTERVAL = 60 * 60 * 24 * 7;
    }

    function getEthMainetConfig() internal pure returns (Config memory config) {
        config
            .KEY_HASH = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
        config.VRF_COORDINATOR = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
        config.SUBSCRIPTION_ID = 0;
        config.GAS_LIMIT = 200000;
        config.NUM_WORDS = 1;
        config.REQUEST_CONFIRMATIONS = 3;
        config.ENTRANCE_FEE = 0.1 ether;
        config.INTERVAL = 60 * 60 * 24 * 7;
    }

    function getSepoliaConfig() internal pure returns (Config memory config) {
        config
            .KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        config.VRF_COORDINATOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
        config.SUBSCRIPTION_ID = 4255;
        config.GAS_LIMIT = 200000;
        config.NUM_WORDS = 1;
        config.REQUEST_CONFIRMATIONS = 3;
        config.ENTRANCE_FEE = 0.1 ether;
        config.INTERVAL = 60 * 60 * 24 * 7;
    }
}
