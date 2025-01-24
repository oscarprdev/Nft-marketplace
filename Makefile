# Makefile for Smart Contract Testing, Deployment, and Client App Management

HARDHAT = npx hardhat

# Smart Contract Commands
.PHONY: hardhat_test hardhat_test-gas hardhat_node hardhat_deploy

hardhat_test:
	$(HARDHAT) test

hardhat_test-gas:
	REPORT_GAS=true $(HARDHAT) test

hardhat_node:
	$(HARDHAT) node

hardhat_deploy:
	rm -rf ./artifacts
	rm -rf ./cache
	rm -rf ./contracts/NFTCollection.json
	rm -rf ./ignition/deployments
	npx hardhat ignition deploy ./ignition/modules/NFTCollection.ts --network $(network)
	mv ./artifacts/contracts/NFTCollection.sol/NFTCollection.json ./contracts

hardhat_test:
	$(HARDHAT) test

# Foundry
foundry_build:
	forge build

foundry_test:
	forge test

foundry_doc:
	forge doc

# Client App Commands
.PHONY: start build lint

start:
	npm run dev

build:
	npm run build

lint:
	npm run lint
