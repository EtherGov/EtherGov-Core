// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Governance.sol";
import "./NFTLock.sol";
import "./StakeERC20.sol";

contract GovernanceFactory {
    Governance[] public governances;
    NFTLock[] public nftLocks;
    mapping(address => string) public governanceNames;

    event GovernanceCreated(address governance, string name);

    function createGovernance(
        string memory name, // New parameter for the governance name
        address _mailboxAddress,
        address _paymaster,
        address[] memory _council
    ) public returns (Governance) {
        NFTLock lock = new NFTLock(); // Deploy an instance of the NFTLock
        nftLocks.push(lock);
        Governance governance = new Governance(
            _mailboxAddress,
            _paymaster,
            _council,
            address(lock)
        );
        governances.push(governance);
        governanceNames[address(governance)] = name; // Storing the name
        emit GovernanceCreated(address(governance), name);
        return governance;
    }

    function getGovernance(
        uint256 index
    ) public view returns (address, string memory) {
        Governance governance = governances[index];
        return (address(governance), governanceNames[address(governance)]);
    }

    function getGovernances()
        public
        view
        returns (address[] memory, string[] memory)
    {
        uint256 length = governances.length;

        address[] memory addresses = new address[](length);
        string[] memory names = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = address(governances[i]);
            names[i] = governanceNames[addresses[i]];
        }

        return (addresses, names);
    }
}
