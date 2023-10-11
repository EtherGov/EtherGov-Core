// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "../lib/wormhole-solidity-sdk/src/interfaces/IWormholeReceiver.sol";
import "../lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";

contract ChainModule is IWormholeReceiver {
    address multisig;
    address[] owners;
    IWormholeRelayer public immutable wormholeRelayer;

    mapping(bytes32 => bool) public seenDeliveryVaaHashes;

    constructor(
        address _addressMultiSig,
        address[] memory _owners,
        address _wormholeRelayer
    ) {
        multisig = _addressMultiSig;
        owners = _owners;
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");
        address sender = abi.decode(payload, (address));
    }
}
