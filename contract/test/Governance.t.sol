// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {Test} from "forge-std/Test.sol";
// import "forge-std/console.sol";
// import {Governance} from "../src/Governance.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

// contract GovernanceTest is Test {
//     Governance public governance;

//     function setUpSource() public {
//         governance = new Governance(
//             10,
//             address(0),
//             address(0),
//             IERC20(address(0)),
//             address(1337)
//         );
//     }

//     function test_return_council() public {
//         address councils = governance.returnCouncil();
//         assertEq(councils, address(1337));
//     }
// }
