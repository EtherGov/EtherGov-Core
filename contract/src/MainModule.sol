// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Enum.sol";
import "../lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";

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
    IWormholeRelayer public immutable wormholeRelayer;

    uint256 constant GAS_LIMIT = 50_000;
    uint256 immutable minimumVotes;

    struct SignatureRequest {
        address to;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
    }

    struct Proposal {
        uint256 id;
        address proposedAddress;
        string proposalDescription;
        uint16 targetChain;
        address targetAddress;
        uint16 votesNeeded;
        uint256 votes;
        bool executed;
        bool ended;
        uint256 duration;
    }

    Proposal[] public proposals;

    event ProposalCreated(uint indexed id, string description);
    event WormholeCalled(address indexed wormholeAddress, uint64 sequence);

    constructor(address _wormholeRelayer, uint256 _minimumVotes) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        minimumVotes = _minimumVotes;
    }

    function createProposal(
        string memory _proposalDescription,
        uint16 _targetChain,
        address _targetAddress,
        uint256 _duration,
        uint16 voteNeeded
    ) public {
        require(voteNeeded >= minimumVotes, "Vote needed too low");
        require(voteNeeded <= 100, "Vote needed too high");
        require(_duration >= 10 minutes, "Duration too short");
        require(_duration <= 30 days, "Duration too long");

        proposals.push(
            Proposal({
                id: proposals.length,
                proposedAddress: msg.sender,
                proposalDescription: _proposalDescription,
                targetChain: _targetChain,
                targetAddress: _targetAddress,
                votesNeeded: voteNeeded,
                votes: 0,
                executed: false,
                ended: false,
                duration: _duration
            })
        );

        emit ProposalCreated(proposals.length - 1, _proposalDescription);
    }

    function quoteCrossChainGreeting(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    function sendCrossChainMessage(
        uint16 targetChain,
        address targetAddress
    ) external payable {
        uint256 cost = quoteCrossChainGreeting(targetChain);
        require(msg.value == cost);
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(msg.sender), // payload
            0, // no receiver value needed since we're just passing a message
            GAS_LIMIT
        );
    }
}
