// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/safe-contracts/contracts/Safe.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract SmartMultisig is Safe, AccessControl {
    enum OwnerType {
        NONE,
        ADMIN,
        USER
    }

    Safe safe;

    mapping(address => OwnerType) public ownerTypes;

    uint256 public transferLimit;

    constructor(uint256 _limit) Safe() {
        transferLimit = _limit;
    }

    function setupAccount(
        address[] calldata admins,
        address[] calldata users,
        uint256 _threshold,
        uint256 initialLimit
    ) external {
        require(transferLimit == 1 ether, "Already initialized");
        transferLimit = initialLimit;

        for (uint i = 0; i < admins.length; i++) {
            ownerTypes[admins[i]] = OwnerType.ADMIN;
        }
        for (uint i = 0; i < users.length; i++) {
            ownerTypes[users[i]] = OwnerType.USER;
        }

        // Combine admins and users into a single owner list
        address[] memory combinedOwners = new address[](
            admins.length + users.length
        );
        for (uint i = 0; i < admins.length; i++) {
            combinedOwners[i] = admins[i];
        }
        for (uint i = 0; i < users.length; i++) {
            combinedOwners[admins.length + i] = users[i];
        }

        // Call Safe's setup
        safe.setup(
            combinedOwners,
            _threshold,
            address(0),
            "",
            address(0),
            address(0),
            0,
            payable(address(0))
        );
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable override returns (bool success) {
        if (ownerTypes[msg.sender] == OwnerType.USER) {
            require(value <= transferLimit, "Transfer exceeds limit");
        }
        return
            safe.execTransaction(
                to,
                value,
                data,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                signatures
            );
    }

    // function increaseLimit(uint256 newLimit) external onlyAdmin {
    //     require(newLimit > transferLimit, "New limit should be higher");
    //     transferLimit = newLimit;
    // }

    // modifier onlyAdmin() {
    //     require(ownerTypes[msg.sender] == OwnerType.ADMIN, "Not an admin");
    //     _;
    // }
}
