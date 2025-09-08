// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MintSchedule} from "../../src/supply/MintSchedule.sol";

contract MintScheduleDeploy is Script {
    MintSchedule public mintSchedule;

    function setUp() public virtual {}

    function run() public virtual {
        vm.startBroadcast();

        mintSchedule = new MintSchedule();

        vm.stopBroadcast();
    }
}
