// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Enum.sol";

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);
}

interface IWormhole {
    function publishMessage(
        uint32 nonce,
        bytes calldata payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);
}

contract Module {
    event WormholeCalled(address indexed wormholeAddress, uint64 sequence);

    function callWormhole(
        address payable wormholeAddress,
        uint32 nonce,
        bytes calldata payload, a daw 
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence) {
        // Call the publishMessage function of the Wormhole contract
        sequence = IWormhole(wormholeAddress).publishMessage(
            nonce,
            payload,
            consistencyLevel
        );
        emit WormholeCalled(wormholeAddress, sequence);
    }

    function recieveVAA() external {}
}
