// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {DeploySideEntranceScript} from "@script/4_DeploySideEntrance.s.sol";
import {SideEntranceLenderPool} from "@main/side-entrance/SideEntranceLenderPool.sol";
import {SideEntranceAttacker} from "@main/side-entrance/SideEntranceAttacker.sol";

contract SideEntranceTest is Test, DeploySideEntranceScript {

    string mnemonic ="test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address public attacker = address(11);

    SideEntranceAttacker sideentranceAttacker;

    function setUp() public {
        vm.deal(deployer, 1001 ether);
        vm.deal(attacker, 1 ether);
        
        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");

        DeploySideEntranceScript.run();

        vm.startPrank(deployer);
        sideentranceChallenge.deposit{value: 1000 ether}();
        vm.stopPrank(  );
    }

    function test_isSolved() public {
        vm.startPrank(attacker);

        assertEq( address(sideentranceChallenge).balance , 1000 ether);
        assertEq( address(attacker).balance , 1 ether);
        sideentranceAttacker = new SideEntranceAttacker(address(sideentranceChallenge));
        sideentranceAttacker.attack();
        assertEq( address(sideentranceChallenge).balance , 0 ether);
        assertEq( address(attacker).balance , 1001 ether);
       
        vm.stopPrank(  );
    }


}