// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Governance.sol";

contract GovernanceFactory {
    Governance[] public governances;
    mapping(address => string) public governanceNames;

    event GovernanceCreated(address governance, string name);

    function createGovernance(
        string memory name, // New parameter for the governance name
        uint256 _minimumVotes,
        address _mailboxAddress,
        address _gasPaymaster,
        IERC20 _stakingToken,
        address[] memory _council
    ) public returns (Governance) {
        Governance governance = new Governance(
            _minimumVotes,
            _mailboxAddress,
            _gasPaymaster,
            _stakingToken,
            _council
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
