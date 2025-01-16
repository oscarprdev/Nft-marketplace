# Makefile for Smart Contract Testing, Deployment, and Client App Management

HARDHAT = npx hardhat
IGNITION_DEPLOY = $(HARDHAT) ignition deploy ./ignition/modules/NFTMarketplace.ts

# Smart Contract Commands
.PHONY: hardhat_test hardhat_test-gas hardhat_node hardhat_deploy

hardhat_test:
	$(HARDHAT) test

hardhat_test-gas:
	REPORT_GAS=true $(HARDHAT) test

hardhat_node:
	$(HARDHAT) node

hardhat_deploy:
	$(IGNITION_DEPLOY)

# Client App Commands
.PHONY: start build lint

start:
	npm run dev

build:
	npm run build

lint:
	npm run lint
