// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Enum.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    GnosisSafe public immutable gnosisSafe;

    constructor(address _account, address _gnosisSafe) {
        account = _account;
        gnosisSafe = GnosisSafe(_gnosisSafe);
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external virtual override {
        emit Received(_origin, address(bytes20(_sender)), _body);
        (
            uint256 targetChain,
            address tokenAddressSource,
            uint256 sourceValue,
            string memory payloadFunction,
            string memory transactionType,
            address from,
            address to
        ) = abi.decode(
                _body,
                (uint256, address, uint256, string, string, address, address)
            );

        gnosisSafe.execTransactionFromModule(
            tokenAddressSource,
            sourceValue,
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from, // This might be a bridge contract address
                to,
                sourceValue
            ),
            Enum.Operation.Call
        );
    }
}
