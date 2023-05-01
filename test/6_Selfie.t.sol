// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {DamnValuableTokenSnapshot} from "@main/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "@main/selfie/SimpleGovernance.sol";
import {SelfiePool} from "@main/selfie/SelfiePool.sol";


contract SelfieTest is Test {

    string mnemonic ="test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);

    address public attacker = address(11);

    DamnValuableTokenSnapshot token;
    SimpleGovernance governance;
    SelfiePool pool;

    uint256 constant TOKEN_INITIAL_SUPPLY = 2_000_000 ether;
    uint256 constant TOKENS_IN_POOL = 1_500_000 ether;

    function setUp() public {
        vm.startPrank(deployer);

        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");

        token = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        governance = new SimpleGovernance(address(token));
        assertEq( governance.getActionCounter() ,1);

        pool = new SelfiePool(address(token), address(governance) );
        assertEq( address(pool.token()) , address(token));
        assertEq( address(pool.governance()) , address(governance));

        vm.stopPrank(  );
    }


    modifier beforeEach() {
        vm.startPrank(deployer);

        token.transfer(address(pool), TOKENS_IN_POOL);
        token.snapshot();

        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(pool.maxFlashLoan(address(token)), TOKENS_IN_POOL);
        assertEq(pool.flashFee(address(token),0), 0);

        vm.stopPrank(  );
        _;
    }

    function test_isSolved( ) public beforeEach() {
        vm.startPrank(attacker);

        // assertEq(token.balanceOf(attacker), TOKENS_IN_POOL);
        // assertEq(token.balanceOf(address(pool)), 0);
       
        vm.stopPrank( );
    }

}