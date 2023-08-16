# Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract ltotery

## What we want it to do

1. Users can Enter by Paying for a ticket
   1. The ticket ffees are going to go to the winner during the draw
2. After X period of Time, the lottery will automatically draw a winner
   1. and this will be don eprogramatically
3. Using chainlink vrf and ChainLink automation
   1. Chainlink brf -> Randomness
   2. chainlink automation -> Time based Trigger

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Notes

vm.wrap, to fake timestamps
vm.roll

vm.recordLogs

> execute code with events emits
> Vm.Log[] memory entries = vm.getRecrorddLogs()
> import {Vm} from

logs are recorded in bytes 32
ejem
bytes32 requestId = entries[1].topics[1]

cheatcode
hoax(playerr, 1 ether) > prank + deal

vm.startBroadCast(DeployerKey) we ccan use private keys here
vm.envUint("PRIVATE_KEY");

for anvil we can use a default key

vm.expectRevert(
abi.encodeWithSelector( event.selector, variable1, variable2, v3, v4..)
)

# TODOS

## Add tests

1. testCanEnterWhenRaffleIsCalculating
2. testCheckUpKeepReturnsFalseIfItHasNoBalanace
3. testCheckUpKeepReturnsFalseIfRaffleNotOpen
4. tetPerformUpKeepCanOnlyRunIfCheckUpkeepIsTrue
5. testPerformUpKeepRevertIfCheckUpKeepIsfalse
6. testPerformUpkeepUpdateRaffleStateandEmitsRequestId
7. testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep
8. testFulfillRandomWordsPicksAsWinnerResetsAndSendsMoney

Fuzz Testing

Create modifier if needed

## Add Interactions

1. Manage subscription

## Mock Contracts

1. Link Contract
2. vrfCoordinator contract
3. Add subscriber
4. Create Subscription
5. Fund Subscriptions
6. Add Consumer
