// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Module.sol";

contract ModuleFactory {
    Module[] public modules;
    event ModuleCreated(address module);

    function createModule(
        address _account,
        address _gnosisSafe
    ) public returns (Module) {
        Module module = new Module(_account, _gnosisSafe);
        modules.push(module);
        emit ModuleCreated(address(module));
        return module;
    }

    function getModules(uint256 index) public view returns (Module) {
        return modules[index];
    }

    function getModules() public view returns (Module[] memory) {
        return modules;
    }
}
