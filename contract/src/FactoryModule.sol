// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "./MainModule.sol";

// contract ModuleFactory {
//     Module[] public modules;
//     event ModuleCreated(address module);

//     function createModule(
//         uint256 _minimumVotes,
//         address _mailboxAddress,
//         address _gasPaymaster
//     ) public returns (Module) {
//         Module module = new Module(
//             _minimumVotes,
//             _mailboxAddress,
//             _gasPaymaster
//         );
//         modules.push(module);
//         emit ModuleCreated(address(module));
//         return module;
//     }

//     function getModules(uint256 index) public view returns (Module) {
//         return modules[index];
//     }

//     function getModules() public view returns (Module[] memory) {
//         return modules;
//     }
// }
