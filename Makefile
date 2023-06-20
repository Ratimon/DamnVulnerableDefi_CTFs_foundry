# spin node
anvil-node:
	anvil --chain-id 1337

anvil-node-auto:
	anvil --chain-id 1337 --block-time 15

1-unit:
	forge test --match-path test/1_UnstoppableVault.t.sol -vvv

2-unit:
	forge test --match-path test/2_NaiveReceiver.t.sol -vvv

3-unit:
	forge test --match-path test/3_Truster.t.sol -vvv

4-deploy-SideEntrance:
	forge script DeploySideEntranceScript --rpc-url $(call local_network,8545)  -vvvv --broadcast; \

4-solve-SideEntrance:
	forge script SolveSideEntranceScript --rpc-url $(call local_network,8545)  -vvvv --broadcast; \

4-unit:
	forge test --match-path test/4_SideEntrance.t.sol -vvv

5-unit:
	forge test --match-path test/5_Rewarder.t.sol -vvv

6-unit:
	forge test --match-path test/6_Selfie.t.sol -vvv

12-unit:
	forge test --match-path test/12_Climber.t.sol -vvv

cast-balance:
	cast balance 0x8464135c8f25da09e49bc8782676a84730c318bc \

cast-signature:
	cast sig "transfer(address,uint256)" \

define local_network
http://127.0.0.1:$1
endef