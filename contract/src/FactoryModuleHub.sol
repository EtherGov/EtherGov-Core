// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ModuleHub.sol";

contract FactoryModuleHub {
    ModuleHub[] public modules;
    address public immutable owner;

    event ModuleCreated(address module);

    constructor() {
        owner = msg.sender;
    }

    function createModule() public returns (ModuleHub) {
        require(msg.sender == owner, "ModuleHub: sender must be owner");
        ModuleHub module = new ModuleHub(msg.sender);
        modules.push(module);
        emit ModuleCreated(address(module));
        return module;
    }

    function getModules(uint256 index) public view returns (ModuleHub) {
        return modules[index];
    }

    function getModules() public view returns (ModuleHub[] memory) {
        return modules;
    }
}
