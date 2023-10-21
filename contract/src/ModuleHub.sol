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

contract ModuleHub {
    address public immutable account;

    constructor(address _deployer) {
        account = _deployer;
    }

    function execTransactionFromModule(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation
    ) external returns (bool success) {
        require(msg.sender == account, "ModuleHub: sender must be account");
        (success, ) = _to.call{value: _value}(_data);
    }
}
