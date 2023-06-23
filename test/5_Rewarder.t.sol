// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DamnValuableToken} from "@main/DamnValuableToken.sol";
import {FlashLoanerPool} from "@main/the-rewarder/FlashLoanerPool.sol";
import {TheRewarderPool} from "@main/the-rewarder/TheRewarderPool.sol";
import {RewardToken} from "@main/the-rewarder/RewardToken.sol";
import {AccountingToken} from "@main/the-rewarder/AccountingToken.sol";

import {TheRewarderPoolAttacker} from "@main/the-rewarder/TheRewarderPoolAttacker.sol";

contract RewarderTest is Test {
    string mnemonic = "test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address attacker;

    address alice;
    address bob;
    address charlie;
    address david;

    uint256 public staticTime;

    DamnValuableToken liquidityToken;
    FlashLoanerPool flashLoanPool;
    TheRewarderPool rewarderPool;
    RewardToken rewardToken;
    AccountingToken accountingToken;

    uint256 constant TOKENS_IN_LENDER_POOL = 1_000_000 ether;

    TheRewarderPoolAttacker therewarderAttacker;

    function setUp() public {
        vm.startPrank(deployer);

        attacker = makeAddr("Attacker");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        david = makeAddr("david");

        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");
        vm.label(alice, "Alice");

        staticTime = block.timestamp;

        liquidityToken = new DamnValuableToken();
        flashLoanPool = new FlashLoanerPool(address(liquidityToken));

        // Set initial token balance of the pool offering flash loans
        liquidityToken.transfer(address(flashLoanPool), TOKENS_IN_LENDER_POOL);
        rewarderPool = new TheRewarderPool(address(liquidityToken));
        rewardToken = RewardToken(rewarderPool.rewardToken());
        accountingToken = AccountingToken(rewarderPool.accountingToken());

        vm.stopPrank();
    }

    modifier beforeEach() {
        vm.startPrank(deployer);

        assertEq(accountingToken.owner(), address(rewarderPool));

        uint256 minterRole = accountingToken.MINTER_ROLE();
        uint256 snapshotRole = accountingToken.SNAPSHOT_ROLE();
        uint256 burnerRole = accountingToken.BURNER_ROLE();

        assertEq(accountingToken.hasAllRoles(address(rewarderPool), minterRole | snapshotRole | burnerRole), true);

        vm.stopPrank();

        address[] memory users = new address[](4);
        users[0] = alice;
        users[1] = bob;
        users[2] = charlie;
        users[3] = david;

        uint256 depositAmount = 100 ether;

        for (uint8 i = 0; i < users.length; i++) {
            vm.startPrank(deployer);

            liquidityToken.transfer(users[i], depositAmount);
            vm.stopPrank();
            vm.startPrank(users[i]);
            liquidityToken.approve(address(rewarderPool), depositAmount);
            rewarderPool.deposit(depositAmount);

            assertEq(accountingToken.balanceOf(users[i]), depositAmount);
            vm.stopPrank();
        }

        assertEq(accountingToken.totalSupply(), (users.length) * depositAmount);
        assertEq(rewardToken.totalSupply(), 0);

        vm.warp({newTimestamp: staticTime + 5 days});

        uint256 rewardsInRound = rewarderPool.REWARDS();

        for (uint8 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            rewarderPool.distributeRewards();

            assertEq(rewardToken.balanceOf(users[i]), rewardsInRound / users.length);
            vm.stopPrank();
        }

        assertEq(rewardToken.totalSupply(), rewardsInRound);
        assertEq(liquidityToken.balanceOf(attacker), 0, " Player starts with zero DVT tokens in balance");
        assertEq(rewarderPool.roundNumber(), 2, "Two rounds must have occurred so far");
        _;
    }

    function test_isSolved() public beforeEach {
        vm.startPrank(attacker);

        vm.warp({newTimestamp: staticTime + 10 days});

        therewarderAttacker = new TheRewarderPoolAttacker(
            address(rewardToken),
            address(flashLoanPool),
            address(rewarderPool),
            address(liquidityToken),
            attacker
        );

        therewarderAttacker.attack();

        vm.stopPrank();

        assertEq(rewarderPool.roundNumber(), 3, "Only one round must have taken place");

        address[] memory users = new address[](4);
        users[0] = alice;
        users[1] = bob;
        users[2] = charlie;
        users[3] = david;

        for (uint8 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            rewarderPool.distributeRewards();

            uint256 userRewards = rewardToken.balanceOf(users[i]);
            uint256 delta = userRewards - (rewarderPool.REWARDS() / users.length);

            assertLt(delta, 0.01 ether, "Users should get neglegible rewards this round");
            vm.stopPrank();
        }

        assertGt(rewardToken.totalSupply(), rewarderPool.REWARDS());
        uint256 playerRewards = rewardToken.balanceOf(attacker);
        assertGt(playerRewards, 0);

        uint256 delta = rewarderPool.REWARDS() - playerRewards;
        assertLt(delta, 0.1 ether, "The amount of rewards earned should be close to total available amount");
        assertEq(
            liquidityToken.balanceOf(attacker), 0, "Balance of DVT tokens in player and lending pool hasn't changed"
        );
        assertEq(
            liquidityToken.balanceOf(address(flashLoanPool)),
            TOKENS_IN_LENDER_POOL,
            "Balance of DVT tokens in player and lending pool hasn't changed"
        );
    }
}
