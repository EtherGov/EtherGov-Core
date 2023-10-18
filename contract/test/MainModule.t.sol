// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test} from "forge-std/Test.sol";
// import {Module} from "../src/MainModule.sol";
// import {ChainModule} from "../src/ChainModule.sol";
// import "../lib/wormhole-solidity-sdk/src/testing/WormholeRelayerTest.sol";

// contract MainModuleTest is WormholeRelayerBasicTest {
//     Module public mainModule;
//     ChainModule public chainTarget;

//     function setUpSource() public override {
//         mainModule = new Module(address(relayerSource), 10);
//     }

//     function setUpTarget() public override {
//         chainTarget = new ChainModule(address(relayerTarget), address(0));
//     }

//     function testSendPayloadEVM() public {
//         uint256 cost = mainModule.quoteCrossChainGreeting(targetChain);

//         vm.recordLogs();

//         mainModule.sendCrossChainMessage{value: cost}(
//             targetChain,
//             address(chainTarget)
//         );

//         performDelivery();

//         vm.selectFork(targetFork);
//         assertEq(chainTarget.sender(), address(relayerSource));
//     }
// }
