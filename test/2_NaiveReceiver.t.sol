// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {NaiveReceiverLenderPool} from "@main/naive-receiver/NaiveReceiverLenderPool.sol";
import {FlashLoanReceiver} from "@main/naive-receiver/FlashLoanReceiver.sol";

import {FlashLoanReceiverAttacker} from "@main/naive-receiver/FlashLoanReceiverAttacker.sol";

interface IPool {
    function ETH() external view returns (address);
}

contract NaiveReceiverTest is Test {
    string mnemonic = "test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address public attacker = address(11);

    NaiveReceiverLenderPool pool;
    FlashLoanReceiver receiver;

    uint256 constant ETHER_IN_POOL = 1_000 ether;
    uint256 constant ETHER_IN_RECEIVER = 10 ether;

    FlashLoanReceiverAttacker flashloanreceiverAttacker;

    function setUp() public {
        vm.startPrank(deployer);
        vm.deal(deployer, 1_010 ether);
        vm.deal(attacker, 1 ether);

        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");

        pool = new NaiveReceiverLenderPool();

        (bool success,) = address(pool).call{value: ETHER_IN_POOL}("");
        require(success);

        receiver = new FlashLoanReceiver(address(pool));

        vm.stopPrank();
    }

    modifier beforeEach() {
        vm.startPrank(deployer);

        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(pool.maxFlashLoan(IPool(address(pool)).ETH()), ETHER_IN_POOL);
        assertEq(pool.flashFee(IPool(address(pool)).ETH(), 0), 1 ether);

        vm.expectRevert();
        (bool success,) = address(receiver).call{value: ETHER_IN_RECEIVER}("");
        // assertTrue(success);
        assertEq(success, false);
        assertEq(address(receiver).balance, ETHER_IN_RECEIVER);

        vm.stopPrank();
        _;
    }

    function test_isSolved() public beforeEach {
        vm.startPrank(attacker);

        flashloanreceiverAttacker = new FlashLoanReceiverAttacker(address(pool), address(receiver));
        flashloanreceiverAttacker.attack();

        assertEq(address(receiver).balance, 0 ether);
        assertEq(address(pool).balance, ETHER_IN_POOL + ETHER_IN_RECEIVER);

        vm.stopPrank();
    }
}
