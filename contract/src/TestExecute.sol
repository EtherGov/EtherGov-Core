// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/IMailbox.sol";
import "./interface/IInterchainGasPaymaster.sol";

contract TestExecute {
    IMailbox public immutable mailbox;
    IInterchainGasPaymaster public immutable paymaster;
    uint256 gasAmount = 100000;

    constructor(address _IMailbox, address _IInterchainGasPaymaster) {
        mailbox = IMailbox(_IMailbox);
        paymaster = IInterchainGasPaymaster(_IInterchainGasPaymaster);
    }

    function execute(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) public payable {
        bytes32 messageId = mailbox.dispatch(
            _destinationDomain,
            _recipientAddress,
            _messageBody
        );
        paymaster.payForGas{value: msg.value}(
            messageId,
            _destinationDomain,
            gasAmount,
            msg.sender
        );
    }
}
