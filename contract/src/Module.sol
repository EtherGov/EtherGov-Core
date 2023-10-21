// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

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

interface IMessageRecipient {
    /**
     * @notice Handle an interchain message
     * @param _origin Domain ID of the chain from which the message came
     * @param _sender Address of the message sender on the origin chain as bytes32
     * @param _body Raw bytes content of message body
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external;
}

contract Module is IMessageRecipient {
    event Received(uint32 origin, address sender, bytes body);
    address public immutable account;
    uint16 public targetChained;

    // GnosisSafe public immutable gnosisSafe;

    constructor(address _account) {
        account = _account;
        // gnosisSafe = GnosisSafe(_gnosisSafe);
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external virtual override {
        emit Received(_origin, address(bytes20(_sender)), _body);
        uint16 targetChain = abi.decode(_body, (uint16));
        targetChained = targetChain;
        // if (
        //     keccak256(abi.encodePacked(transactionType)) == keccak256("DEPOSIT")
        // ) {
        // Handle the deposit logic here
        // gnosisSafe.execTransactionFromModule(
        //     tokenAddressSource,
        //     sourceValue,
        //     abi.encodeWithSignature(
        //         "transferFrom(address,address,uint256)",
        //         targetAddress, // This might be a bridge contract address
        //         sourceValue
        //     ),
        //     Enum.Operation.Call
        // );

        // }
    }
}
