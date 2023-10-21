// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IMailbox.sol";
import "./interface/IInterchainGasPaymaster.sol";
import "./NFTLock.sol";
import "./StakeERC20.sol";

contract Governance {
    struct Proposal {
        uint256 id;
        string description;
        address proposedAddress;
        uint16 targetChain;
        address targetAddress;
        address tokenAddressSource;
        uint256 sourceValue;
        uint256 votesNeeded;
        uint256 votes;
        bytes messageBody;
        LockedNFT lockedNFT;
        string groupId;
        bool executed;
        bool ended;
        uint256 duration;
    }

    struct ProposalInput {
        string description;
        uint16 targetChain;
        address targetAddress;
        address tokenAddressSource;
        uint256 sourceValue;
        uint256 duration;
        uint16 voteNeeded;
        LockedNFT lockedNFT;
        string groupId;
        bytes messageBody;
    }

    struct LockedNFT {
        address nftAddress;
    }

    struct GovernanceResources {
        IMailbox mailbox;
        IInterchainGasPaymaster paymaster;
        NFTLock nftLock;
        ERC20Staking stakingContract;
        address[] council;
        Proposal[] proposals;
    }

    mapping(address => mapping(uint256 => bool)) public voted;
    mapping(address => bool) public isCouncil;

    GovernanceResources public resources;

    event ProposalCreated(uint indexed id);
    event VoteCasted(
        uint indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(uint indexed proposalId);

    modifier onlyCouncil() {
        require(isCouncil[msg.sender], "Only councils can call this function");
        _;
    }

    constructor(
        address _mailboxAddress,
        address _paymaster,
        address[] memory _council,
        address _nftLock,
        address _stakingContract
    ) {
        resources.mailbox = IMailbox(_mailboxAddress);
        resources.paymaster = IInterchainGasPaymaster(_paymaster);
        setCouncil(_council);
        resources.nftLock = NFTLock(_nftLock);
        resources.stakingContract = ERC20Staking(_stakingContract);
    }

    function setCouncil(address[] memory _council) private {
        resources.council = _council;
        for (uint256 i = 0; i < _council.length; i++) {
            isCouncil[_council[i]] = true;
        }
    }

    function createProposal(
        ProposalInput memory input
    ) public onlyCouncil validateInput(input) {
        addProposal(input);
    }

    modifier validateInput(ProposalInput memory input) {
        require(input.voteNeeded >= 10, "Vote needed too low");
        require(input.voteNeeded <= 100, "Vote needed too high");
        require(input.duration >= 10 minutes, "Duration too short");
        require(input.duration <= 30 days, "Duration too long");
        _;
    }

    function addProposal(ProposalInput memory input) private {
        resources.proposals.push(
            Proposal({
                id: resources.proposals.length,
                description: input.description,
                proposedAddress: msg.sender,
                targetChain: input.targetChain,
                targetAddress: input.targetAddress,
                tokenAddressSource: input.tokenAddressSource,
                sourceValue: input.sourceValue,
                votesNeeded: input.voteNeeded,
                votes: 0,
                messageBody: input.messageBody,
                lockedNFT: input.lockedNFT,
                groupId: input.groupId,
                executed: false,
                ended: false,
                duration: input.duration
            })
        );
        emit ProposalCreated(resources.proposals.length - 1);
    }

    function stakeAndVote(
        uint256 proposalId,
        uint256 stakeAmount,
        uint256 tokenId
    ) external {
        resources.stakingContract.stake(stakeAmount);
        // Get the proposal
        Proposal storage proposal = resources.proposals[proposalId];

        // Lock the NFT
        lockProposalNFT(proposal, proposalId, tokenId);

        // Check requirements and cast vote
        castVote(proposal, proposalId);
    }

    function lockProposalNFT(
        Proposal storage proposal,
        uint256 proposalId,
        uint256 tokenId
    ) internal {
        resources.nftLock.lockNFT(
            proposalId,
            proposal.lockedNFT.nftAddress,
            tokenId
        );
    }

    function castVote(Proposal storage proposal, uint256 proposalId) internal {
        require(!proposal.ended, "Vote has ended.");
        require(!proposal.executed, "Proposal has already been executed.");
        require(!voted[msg.sender][proposalId], "You have already voted.");

        proposal.votes += 1;
        voted[msg.sender][proposalId] = true; // Marking that the user has voted for this proposal
    }

    function releaseLockedNFT(uint256 proposalId) external {
        resources.nftLock.releaseNFT(proposalId);
    }

    function executeProposal(uint256 proposalId) public payable {
        Proposal storage proposal = getValidProposalForExecution(proposalId);

        bytes32 targetAddressBytes32 = convertToBytes32(proposal.targetAddress);
        bytes32 messageId = resources.mailbox.dispatch(
            proposal.targetChain,
            targetAddressBytes32,
            proposal.messageBody
        );

        payForGas(messageId, proposal);
    }

    function getValidProposalForExecution(
        uint256 proposalId
    ) internal returns (Proposal storage) {
        Proposal storage proposal = resources.proposals[proposalId];
        require(!proposal.executed, "Proposal has already been executed.");
        require(!proposal.ended, "Proposal has already ended.");

        _setProposalToExecuted(proposal);

        return proposal;
    }

    function _setProposalToExecuted(Proposal storage proposal) private {
        proposal.executed = true;
        proposal.ended = true;
    }

    function convertToBytes32(address _address) private pure returns (bytes32) {
        return bytes32(bytes20(_address));
    }

    function payForGas(bytes32 messageId, Proposal storage proposal) private {
        resources.paymaster.payForGas{value: msg.value}(
            messageId,
            proposal.targetChain,
            10000,
            msg.sender
        );
    }

    function returnAllProposal() public view returns (Proposal[] memory) {
        return resources.proposals;
    }

    function returnAllCouncil() public view returns (address[] memory) {
        return resources.council;
    }
}
