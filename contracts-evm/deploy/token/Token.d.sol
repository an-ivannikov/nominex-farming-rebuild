// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../../src/token/Token.sol";

contract TokenDeploy is Script {
    Token public token;

    function setUp() public virtual {}

    function run() public virtual {
        vm.startBroadcast();

        token = new Token();

        vm.stopBroadcast();
    }
}
