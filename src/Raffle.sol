// SPDX-License- Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

/**
 * @title A Sample Raffle contract
 * @author Miguel Molledo
 * @notice This contract is for creating a sample Raffle
 * @dev Implements Chainlin VRFv2
 */

// Pragma statements

// Import statements
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {console} from "lib/forge-std/src/Console.sol";

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Interfaces

// Libraries

// Contracts

// HARD CODED SEPOLIA, MOVE TO ENV VARIABLES
// address VRF_COORDINATOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
// address consKEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c; //  30gewi

contract Raffle is
    VRFConsumerBaseV2,
    ConfirmedOwner,
    AutomationCompatibleInterface
{
    // Type declarations
    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_gasLimit;
    uint32 private immutable i_numWords;
    uint16 private immutable i_requestConfirmations;
    uint64 private immutable i_subscriptionId;

    uint256 public immutable i_interval;
    uint256 public s_lastRequestedId;
    // interval in seconds for the pick winner to be executed
    uint256 private s_lastTimeStamp;
    address payable[] private s_participants;
    address payable public s_recentWinner;
    enum RaffleStatus {
        OPEN,
        CLOSED
    }
    RaffleStatus private s_raffleStatus;

    // State variables

    // Events
    event EnteredRaffle(address indexed participant);
    event PickedWinner(address indexed participant);
    event Raffle_CalculatingWinner(uint256 lastRequestedId);

    // Errors
    error Raffle_NotEnoughEthToEnterRaffle();
    error Raffle_RaffleYetNotOpen();
    error Raffle_FaillingTransferToWinner();
    error Raffle_NotReadyToCalculateWinner(
        uint256 currentBalanace,
        uint256 playersLenght,
        RaffleStatus raffleStatus
    );

    // Modifiers

    // Functions

    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 keyHash,
        address vrfCoordinator,
        uint64 subscroptionId,
        uint32 gasLimit,
        uint32 numWords,
        uint16 requestConfirmations
    ) VRFConsumerBaseV2(vrfCoordinator) ConfirmedOwner(msg.sender) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = keyHash;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscroptionId;
        i_gasLimit = gasLimit;
        i_numWords = numWords;
        i_requestConfirmations = requestConfirmations;
        s_raffleStatus = RaffleStatus.OPEN;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        // time is ok
        // status is closed
        // participants > 0
        upkeepNeeded = isReadyToPickWinner();
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        pickWinner();

        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function isReadyToPickWinner() public view returns (bool isReady) {
        isReady =
            (block.timestamp - s_lastTimeStamp) > i_interval &&
            s_raffleStatus == RaffleStatus.OPEN &&
            s_participants.length > 0 &&
            address(this).balance > 0;
    }

    function enterRaffle() external payable {
        // require(msg.value < i_entranceFee, "Not enough ETH to enter Raffle");
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthToEnterRaffle();
        } else if (s_raffleStatus == RaffleStatus.CLOSED) {
            revert Raffle_RaffleYetNotOpen();
        }
        s_participants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        if (!isReadyToPickWinner()) {
            revert Raffle_NotReadyToCalculateWinner(
                address(this).balance,
                s_participants.length,
                s_raffleStatus
            );
        }
        s_raffleStatus = RaffleStatus.CLOSED;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_gasLimit,
            i_numWords
        );

        s_lastRequestedId = requestId;
        emit Raffle_CalculatingWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(RaffleStatus.CLOSED == s_raffleStatus, "Raffle is not closed");
        uint256 indexWinner = randomWords[0] % s_participants.length;

        address payable winner = s_participants[indexWinner];
        s_recentWinner = winner;
        emit PickedWinner(winner);
        // winner.transfer(address(this).balance); or bellow
        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Raffle_FaillingTransferToWinner();
        }

        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffleStatus = RaffleStatus.OPEN;
        s_lastRequestedId = requestId;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleStatus) {
        return s_raffleStatus;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getVrfCoordinator() external view returns (address) {
        return address(i_vrfCoordinator);
    }

    function getParticipants()
        external
        view
        returns (address payable[] memory)
    {
        return s_participants;
    }

    function getLatestRequestId() public returns (uint256) {
        return s_lastRequestedId;
    }

    function getLatestWinner() public returns (address) {
        return s_recentWinner;
    }
}
