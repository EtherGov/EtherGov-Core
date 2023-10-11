// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {SmartMultisig} from "src/SmartMultisig.sol";

contract SmartMultisigTest is Test {
    SmartMultisig multisig;

    function setUp() public {
        multisig = new SmartMultisig(1 ether);
    }

    // function test_setup() public {
    //     address[] memory admins = new address[](1);
    //     address[] memory users = new address[](1);
    //     admins[0] = address(0x1);
    //     users[0] = address(0x2);
    //     multisig.setupAccount(admins, users, 1, 1 ether);
    //     assertTrue(
    //         multisig.ownerTypes(address(0x1)) == SmartMultisig.OwnerType.ADMIN
    //     );
    //     assertTrue(
    //         multisig.ownerTypes(address(0x2)) == SmartMultisig.OwnerType.USER
    //     );
    //     assertTrue(multisig.transferLimit() == 1 ether);
    // }
}
