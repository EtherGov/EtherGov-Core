// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interface/IMailbox.sol";
import "./interface/IInterchainGasPaymaster.sol";

contract Governance {
    struct Proposal {
        uint256 id;
        address proposedAddress;
        uint16 targetChain;
        address targetAddress;
        address tokenAddressSource;
        address tokenAddressDestination;
        uint256 sourceValue;
        uint256 destinationValue;
        uint256 votesNeeded;
        uint256 votes;
        bytes messageBody;
        bool executed;
        bool ended;
        uint256 duration;
    }

    struct ProposalInput {
        uint16 targetChain;
        address targetAddress;
        address tokenAddressSource;
        address tokenAddressDestination;
        uint256 sourceValue;
        uint256 destinationValue;
        uint256 duration;
        uint16 voteNeeded;
        bytes messageBody;
    }

    mapping(address => mapping(uint256 => uint256)) public balances;
    mapping(address => mapping(uint256 => bool)) public voted;
    mapping(address => uint256) public userStakes;
    mapping(address => bool) public isCouncil;

    uint256 public totalStaked;
    uint256 immutable minimumVotes;
    IMailbox public immutable mailbox;
    IInterchainGasPaymaster public immutable gasPaymaster;
    IERC20 public immutable stakingToken;
    uint256 public requiredStakeAmount = 100 * 10 ** 18;
    uint256 gasAmount = 100000;
    address[] public council;

    Proposal[] public proposals;

    event ProposalCreated(uint indexed id);
    event VoteCasted(
        uint indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(uint indexed proposalId);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    modifier onlyCouncil() {
        require(isCouncil[msg.sender], "Only councils can call this function");
        _;
    }

    constructor(
        uint256 _minimumVotes,
        address _gasPaymaster,
        address _mailboxAddress,
        IERC20 _stakingToken,
        address[] memory _council
    ) {
        minimumVotes = _minimumVotes;
        mailbox = IMailbox(_mailboxAddress);
        gasPaymaster = IInterchainGasPaymaster(_gasPaymaster);
        stakingToken = _stakingToken;

        council = _council; // Set the councils

        for (uint256 i = 0; i < _council.length; i++) {
            isCouncil[_council[i]] = true;
        }
    }

    function createProposal(ProposalInput memory input) public onlyCouncil {
        require(input.voteNeeded >= minimumVotes, "Vote needed too low");
        require(input.voteNeeded <= 100, "Vote needed too high");
        require(input.duration >= 10 minutes, "Duration too short");
        require(input.duration <= 30 days, "Duration too long");

        proposals.push(
            Proposal({
                id: proposals.length,
                proposedAddress: msg.sender,
                targetChain: input.targetChain,
                targetAddress: input.targetAddress,
                tokenAddressSource: input.tokenAddressSource,
                tokenAddressDestination: input.tokenAddressDestination,
                sourceValue: input.sourceValue,
                destinationValue: input.destinationValue,
                votesNeeded: input.voteNeeded,
                votes: 0,
                messageBody: input.messageBody,
                executed: false,
                ended: false,
                duration: input.duration
            })
        );

        emit ProposalCreated(proposals.length - 1);
    }

    function stakeAndVote(uint256 proposalId) external {
        // Transfer required stake amount from the user to the contract
        require(
            stakingToken.transferFrom(
                msg.sender,
                address(this),
                requiredStakeAmount
            ),
            "Staking failed"
        );

        // Update user's staked balance
        userStakes[msg.sender] += requiredStakeAmount;

        // Cast the vote (integrating the logic of the vote function)
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.ended, "Vote has ended.");
        require(!proposal.executed, "Proposal has already been executed.");
        require(!voted[msg.sender][proposalId], "You have already voted.");
        proposal.votes += 1;
    }

    function withdrawStake(uint256 amount) external {
        require(userStakes[msg.sender] >= amount, "Insufficient staked amount");

        // Update user's staked balance
        userStakes[msg.sender] -= amount;

        // Transfer stake back to the user
        require(stakingToken.transfer(msg.sender, amount), "Withdraw failed");
    }

    function execute(uint256 proposalId) public payable {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal has already been executed.");
        require(!proposal.ended, "Proposal has already ended.");

        proposal.executed = true;
        proposal.ended = true;

        bytes32 targetAddressBytes32 = bytes32(bytes20(proposal.targetAddress));

        bytes32 messageId = mailbox.dispatch(
            proposal.targetChain,
            targetAddressBytes32,
            proposal.messageBody
        );

        gasPaymaster.payForGas{value: msg.value}(
            messageId,
            proposal.targetChain,
            gasAmount,
            msg.sender
        );
    }

    function returnAllProposal() public view returns (Proposal[] memory) {
        return proposals;
    }

    function returnAllCouncil() public view returns (address[] memory) {
        return council;
    }
}
