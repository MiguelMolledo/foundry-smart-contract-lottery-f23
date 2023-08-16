// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
// third party imports
import {Test, console} from "forge-std/Test.sol";

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 constant ANVIL_ID = 31337;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleStatus.OPEN);
    }

    function testEnterRaffle() external {}

    function testPickWinnerNotEnoughTimePassed() external {
        uint256 lastRequestedId = raffle.s_lastRequestedId();

        uint256 contractBalance;
        uint256 numPlayers;
        Raffle.RaffleStatus contractStatus;

        // vm.expectRevert(Raffle.Raffle_NotReadyToCalculateWinner.selector);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_NotReadyToCalculateWinner.selector,
                contractBalance,
                numPlayers,
                contractStatus
            )
        );
        raffle.pickWinner();
    }

    function testGetEntranceFee() external {
        uint256 entranceFee = raffle.getEntranceFee();
        assertEq(entranceFee, 0.1 ether, "Entrance fee should be 0.1 ether");
    }

    modifier enterRaffleAndEnoughTimePassed() {
        // arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.1 ether}();

        vm.warp(block.timestamp + raffle.getInterval() + 1);
        _;
    }

    function testCantEnterWhenNotEnoughFounds() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_NotEnoughEthToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testCantEnterWhenRaffleIsNotOpen()
        public
        enterRaffleAndEnoughTimePassed
    {
        // arrange
        raffle.pickWinner();

        // act
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_RaffleYetNotOpen.selector);
        raffle.enterRaffle{value: 0.1 ether}();
    }

    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        assertEq(raffle.getBalance(), 0, "Initial Balance should be 0");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false, "Upkeep should not be needed");
    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen()
        public
        enterRaffleAndEnoughTimePassed
    {
        raffle.pickWinner();
        assert(raffle.getRaffleState() == Raffle.RaffleStatus.CLOSED);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false, "Upkeep should not be needed");
    }

    function testPerformUpKeepCanOnlyRunIfcheckUpKeepIsTrue()
        public
        enterRaffleAndEnoughTimePassed
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, true);
        raffle.performUpkeep("");
    }

    // 4. tetPerformUpKeepCanOnlyRunIfCheckUpkeepIsTrue

    function testPerformUpKeeprevertIfCheckUpKeepIsFalse() public {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false);
        vm.expectRevert(Raffle.Raffle_NotReadyToCalculateWinner.selector);
        raffle.performUpkeep("");
    }

    // 5. testPerformUpKeepRevertIfCheckUpKeepIsfalse

    function testPerformUpkeepUpdateRaffleStateAndEmitsRequestId()
        public
        enterRaffleAndEnoughTimePassed
    {
        // arange
        // struct Log {
        //     bytes32[] topics;
        //     bytes data;
        //     address emitter;

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[0].topics[1];
        assert(uint256(requestId) > 0);
        assert(uint256(raffle.getRaffleState()) == 1);
        console.log(uint256(requestId));
        console.log(uint256(entries[0].topics[2]));
    }

    // 6. testPerformUpkeepUpdateRaffleStateandEmitsRequestId
    // 7. testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep

    modifier skipIfNotAnvil() {
        if (block.chainid != ANVIL_ID) {
            return;
        }
        _;
    }

    function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep_anvil()
        public
        skipIfNotAnvil
        enterRaffleAndEnoughTimePassed
    {
        // try to get the event that executes fulfillrandomWords
        // to get this we ned to execute getRandomWords

        uint256 requestId = 0;
        address consumer = address(raffle);
        VRFCoordinatorV2Mock mock = VRFCoordinatorV2Mock(
            raffle.getVrfCoordinator()
        );
        vm.expectRevert("nonexistent request");
        mock.fulfillRandomWords(requestId, consumer);
        // raffle.getVrfCoordinator()
    }

    function testFulfillRandomWordsPickaswinnerResetsAndSendsMoney_anvil()
        public
        skipIfNotAnvil
    {
        // arrange
        //player 1
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.1 ether}();

        // // player 2
        // address player_2 = makeAddr("player2");
        // vm.prank(player_2);
        // vm.deal(player_2, 5 ether);
        // raffle.enterRaffle{value:0.1 ether}();

        vm.warp(block.timestamp + raffle.getInterval() + 1);

        uint256 userInitialBalanace = address(PLAYER).balance;
        uint256 contractInitialBalance = raffle.getBalance();

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[0];

        console.log(uint256(requestId));
        VRFCoordinatorV2Mock mock = VRFCoordinatorV2Mock(
            raffle.getVrfCoordinator()
        );

        mock.fulfillRandomWords(uint256(1), address(raffle));
        address winner = raffle.getLatestWinner();

        // assert(winner.balance == userInitialBalanace + userInitialBalanace);
        assert(raffle.getParticipants().length == 0);
        assert(raffle.getLatestRequestId() == uint(1));

        // assert(raffle.getRaffleState() == Raffle.RaffleStatus.OPEN);
        assert(raffle.getBalance() == 0);

        // act
    }

    // 8. testFulfillRandomWordsPicksAsWinnerResetsAndSendsMoney
}
