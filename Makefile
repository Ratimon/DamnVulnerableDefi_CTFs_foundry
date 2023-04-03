# spin node
anvil-node:
	anvil --chain-id 1337

anvil-node-auto:
	anvil --chain-id 1337 --block-time 15

1-deploy-SideEntrance:
	forge script DeploySideEntranceScript --rpc-url $(call local_network,8545)  -vvvv --broadcast; \

1-unit:
	forge test --match-path test/1_SideEntrance.t.sol -vvv

define local_network
http://127.0.0.1:$1
endef