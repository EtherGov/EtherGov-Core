pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTLock {
    struct LockedNFT {
        address nftAddress;
        uint256 nftTokenId;
    }
    struct GovernanceReference {
        address governanceAddress;
        uint256 proposalId;
    }

    mapping(address => GovernanceReference) public governanceReference;

    mapping(uint256 => mapping(address => LockedNFT)) public lockedNFTs;

    event NFTLocked(
        uint indexed proposalId,
        address indexed locker,
        address nftAddress,
        uint256 nftTokenId
    );
    event NFTReleased(uint indexed proposalId, address indexed locker);

    function lockNFT(
        uint256 proposalId,
        address nftAddress,
        uint256 nftTokenId
    ) external {
        IERC721(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nftTokenId
        );
        lockedNFTs[proposalId][msg.sender] = LockedNFT(nftAddress, nftTokenId);
        emit NFTLocked(proposalId, msg.sender, nftAddress, nftTokenId);
    }

    function releaseNFT(uint256 proposalId) external {
        LockedNFT memory userLockedNFT = lockedNFTs[proposalId][msg.sender];
        require(
            userLockedNFT.nftAddress != address(0),
            "No NFT locked for this proposal."
        );

        IERC721(userLockedNFT.nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            userLockedNFT.nftTokenId
        );
        delete lockedNFTs[proposalId][msg.sender];
        emit NFTReleased(proposalId, msg.sender);
    }

    function setGovernanceReference(
        address user,
        address governanceAddress,
        uint256 proposalId
    ) external {
        governanceReference[user] = GovernanceReference(
            governanceAddress,
            proposalId
        );
    }
}
