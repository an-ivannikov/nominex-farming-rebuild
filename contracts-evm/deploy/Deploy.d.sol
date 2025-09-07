// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenDeploy} from "./token/Token.d.sol";

contract Deploy is Script, TokenDeploy {
    function setUp() public virtual override {
        super.setUp();
    }

    function run() public virtual override {
        super.run();
    }
}
