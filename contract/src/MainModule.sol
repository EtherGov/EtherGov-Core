// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "./Enum.sol";
// import "../lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
// import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
// import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
// import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

// interface GnosisSafe {
//     /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
//     /// @param to Destination address of module transaction.
//     /// @param value Ether value of module transaction.
//     /// @param data Data payload of module transaction.
//     /// @param operation Operation type of module transaction.
//     function execTransactionFromModule(
//         address to,
//         uint256 value,
//         bytes calldata data,
//         Enum.Operation operation
//     ) external returns (bool success);
// }

// interface IMailbox {
//     function dispatch(
//         uint32 _destinationDomain,
//         bytes32 _recipientAddress,
//         bytes calldata _messageBody
//     ) external returns (bytes32);

//     function process(
//         bytes calldata _metadata,
//         bytes calldata _message
//     ) external;
// }

// interface IInterchainGasPaymaster {
//     /**
//      * @notice Emitted when a payment is made for a message's gas costs.
//      * @param messageId The ID of the message to pay for.
//      * @param gasAmount The amount of destination gas paid for.
//      * @param payment The amount of native tokens paid.
//      */
//     event GasPayment(
//         bytes32 indexed messageId,
//         uint256 gasAmount,
//         uint256 payment
//     );

//     /**
//      * @notice Deposits msg.value as a payment for the relaying of a message
//      * to its destination chain.
//      * @dev Overpayment will result in a refund of native tokens to the _refundAddress.
//      * Callers should be aware that this may present reentrancy issues.
//      * @param _messageId The ID of the message to pay for.
//      * @param _destinationDomain The domain of the message's destination chain.
//      * @param _gasAmount The amount of destination gas to pay for.
//      * @param _refundAddress The address to refund any overpayment to.
//      */
//     function payForGas(
//         bytes32 _messageId,
//         uint32 _destinationDomain,
//         uint256 _gasAmount,
//         address _refundAddress
//     ) external payable;

//     /**
//      * @notice Quotes the amount of native tokens to pay for interchain gas.
//      * @param _destinationDomain The domain of the message's destination chain.
//      * @param _gasAmount The amount of destination gas to pay for.
//      * @return The amount of native tokens required to pay for interchain gas.
//      */
//     function quoteGasPayment(
//         uint32 _destinationDomain,
//         uint256 _gasAmount
//     ) external view returns (uint256);
// }

// contract Module is EIP712, AccessControl {
//     IMailbox public immutable mailbox;
//     IInterchainGasPaymaster public immutable gasPaymaster;
//     bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
//     bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
//     bytes32 public constant TYPEHASH =
//         keccak256(
//             "MintRequest(address to,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
//         );
//     error SignatureExpired();
//     error InvalidSignature();
//     error InvalidUser();

//     uint256 gasAmount = 100000;

//     uint256 constant GAS_LIMIT = 50_000;
//     uint256 immutable minimumVotes;

//     using ECDSA for bytes32;

//     struct SignatureRequest {
//         address to;
//         uint128 validityStartTimestamp;
//         uint128 validityEndTimestamp;
//     }

//     struct Proposal {
//         uint256 id;
//         address proposedAddress;
//         string proposalDescription;
//         uint16 targetChain;
//         address targetAddress;
//         address tokenAddressSource;
//         address tokenAddressDestination;
//         uint256 sourceValue;
//         uint256 destinationValue;
//         uint256 votesNeeded;
//         uint256 votes;
//         bool executed;
//         bool ended;
//         uint256 duration;
//     }

//     Proposal[] public proposals;
//     mapping(address => mapping(uint256 => bool)) public voted;

//     event ProposalCreated(uint indexed id, string description);
//     event WormholeCalled(address indexed wormholeAddress, uint64 sequence);

//     modifier canVote(SignatureRequest calldata req, bytes calldata signature) {
//         address signer = getSigner(req, signature);

//         if (
//             req.validityStartTimestamp > block.timestamp ||
//             block.timestamp > req.validityEndTimestamp
//         ) {
//             revert SignatureExpired();
//         }
//         if (isSigner(signer) == false) revert InvalidSignature();
//         if (req.to != msg.sender) revert InvalidUser();

//         _;
//     }

//     constructor(
//         uint256 _minimumVotes,
//         address _mailboxAddress,
//         address _gasPaymaster
//     ) EIP712("Module", "1") {
//         mailbox = IMailbox(_mailboxAddress);
//         gasPaymaster = IInterchainGasPaymaster(_gasPaymaster);
//         minimumVotes = _minimumVotes;
//         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _grantRole(PAUSER_ROLE, msg.sender);
//     }

//     function createProposal(
//         string memory _proposalDescription,
//         uint16 _targetChain,
//         address _targetAddress,
//         address _tokenAddressSource,
//         address _tokenAddressDestination,
//         uint256 _sourceValue,
//         uint256 _destinationValue,
//         uint256 _duration,
//         uint16 voteNeeded
//     ) public {
//         require(voteNeeded >= minimumVotes, "Vote needed too low");
//         require(voteNeeded <= 100, "Vote needed too high");
//         require(_duration >= 10 minutes, "Duration too short");
//         require(_duration <= 30 days, "Duration too long");

//         proposals.push(
//             Proposal({
//                 id: proposals.length,
//                 proposedAddress: msg.sender,
//                 proposalDescription: _proposalDescription,
//                 targetChain: _targetChain,
//                 targetAddress: _targetAddress,
//                 tokenAddressSource: _tokenAddressSource,
//                 tokenAddressDestination: _tokenAddressDestination,
//                 sourceValue: _sourceValue,
//                 destinationValue: _destinationValue,
//                 votesNeeded: voteNeeded,
//                 votes: 0,
//                 executed: false,
//                 ended: false,
//                 duration: _duration
//             })
//         );

//         emit ProposalCreated(proposals.length - 1, _proposalDescription);
//     }

//     function execute(uint256 proposalId, bytes calldata messageBody) internal {
//         Proposal storage proposal = proposals[proposalId];
//         require(!proposal.executed, "Proposal has already been executed.");
//         require(!proposal.ended, "Proposal has already ended.");

//         proposal.executed = true;
//         proposal.ended = true;

//         bytes32 targetAddressBytes32 = bytes32(bytes20(proposal.targetAddress));

//         sendAndPayForMessage(
//             proposal.targetChain,
//             targetAddressBytes32,
//             messageBody
//         );
//     }

//     function vote(
//         uint256 proposalId,
//         // SignatureRequest calldata req,
//         // bytes calldata signature,
//         bytes calldata messageBody
//     ) public payable {
//         Proposal storage proposal = proposals[proposalId];
//         require(!proposal.ended, "Vote has ended.");
//         require(!proposal.executed, "Proposal has already been executed.");
//         require(!voted[msg.sender][proposalId], "You have already voted.");
//         (
//             address decodedTokenAddressSource,
//             address decodedTokenAddressDestination,
//             uint256 decodedSourceValue,
//             uint256 decodedDestinationValue
//         ) = abi.decode(messageBody, (address, address, uint256, uint256));
//         require(
//             decodedTokenAddressSource == proposal.tokenAddressSource,
//             "Token address source does not match"
//         );
//         require(
//             decodedTokenAddressDestination == proposal.tokenAddressDestination,
//             "Token address destination does not match"
//         );
//         require(
//             decodedSourceValue == proposal.sourceValue,
//             "Source value does not match"
//         );
//         require(
//             decodedDestinationValue == proposal.destinationValue,
//             "Destination value does not match"
//         );

//         proposal.votes += 1;

//         if (proposal.votesNeeded == proposal.votes) {
//             execute(proposalId, messageBody);
//         }
//     }

//     function sendAndPayForMessage(
//         uint32 destinationDomain,
//         bytes32 recipientAddress,
//         bytes calldata messageBody
//     ) public payable {
//         bytes32 messageId = mailbox.dispatch(
//             destinationDomain,
//             recipientAddress,
//             messageBody
//         );
//         gasPaymaster.payForGas{value: msg.value}(
//             messageId, // The ID of the message that was just dispatched
//             destinationDomain, // The destination domain of the message
//             gasAmount, // 100k gas to use in the recipient's handle function
//             msg.sender // refunds go to msg.sender, who paid the msg.value
//         );
//     }

//     // EIP712
//     function _recoverAddress(
//         SignatureRequest calldata _req,
//         bytes calldata _signature
//     ) internal view returns (address signer) {
//         signer = _hashTypedDataV4(
//             keccak256(
//                 abi.encode(
//                     TYPEHASH,
//                     _req.to,
//                     _req.validityStartTimestamp,
//                     _req.validityEndTimestamp
//                 )
//             )
//         ).recover(_signature);
//     }

//     function getSigner(
//         SignatureRequest calldata _req,
//         bytes calldata _signature
//     ) internal view returns (address signer) {
//         signer = _recoverAddress(_req, _signature);
//     }

//     function isSigner(address account) internal view returns (bool) {
//         return hasRole(SIGNER_ROLE, account);
//     }

//     function addSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
//         _grantRole(SIGNER_ROLE, _signer);
//     }

//     function returnAllProposal() public view returns (Proposal[] memory) {
//         return proposals;
//     }
// }
