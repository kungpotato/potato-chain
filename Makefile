BINARY   ?= potatod
MAIN_PKG := ./cmd/potatod
BUILDDIR ?= $(CURDIR)/build

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
COMMIT  := $(shell git rev-parse HEAD 2>/dev/null)

ldflags := -X github.com/cosmos/cosmos-sdk/version.Name=potato \
           -X github.com/cosmos/cosmos-sdk/version.AppName=$(BINARY) \
           -X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
           -X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT)

.PHONY: build install clean

build:
	go build -ldflags '$(ldflags)' -o $(BUILDDIR)/$(BINARY) $(MAIN_PKG)

install:
	go install -ldflags '$(ldflags)' $(MAIN_PKG)

clean:
	rm -rf $(BUILDDIR)

# ---- 4-validator docker localnet ----
.PHONY: localnet-init localnet-up localnet-down localnet-logs

localnet-init:
	scripts/localnet_init.sh

localnet-up:
	docker-compose up -d --build

localnet-down:
	docker-compose down

localnet-logs:
	docker-compose logs -f --tail=50

.PHONY: smoke
smoke:  ## EVM end-to-end check against a running chain
	scripts/smoke_evm.sh

# ---- Blockscout explorer (needs localnet running) ----
.PHONY: explorer-up explorer-down explorer-reset

explorer/.env:
	@printf 'POSTGRES_PASSWORD=%s\nSECRET_KEY_BASE=%s\n' "$$(openssl rand -hex 16)" "$$(openssl rand -base64 48 | tr -d '\n')" > $@
	@echo "generated $@ (local secrets, gitignored)"

explorer-up: explorer/.env
	docker-compose -f explorer/docker-compose.yml up -d

explorer-down:
	docker-compose -f explorer/docker-compose.yml down

explorer-reset:  ## wipe indexed data (needed after localnet-init)
	docker-compose -f explorer/docker-compose.yml down -v

# ---- Week 3: money + DEX (needs localnet) ----
.PHONY: contracts-test deploy seed-pool smoke-dex

contracts-test:
	cd contracts && forge test

deploy:  ## MockUSDC + Uniswap v2 -> deployments/localnet.json
	. scripts/lib.sh && cd contracts && forge script script/Deploy.s.sol --rpc-url potato_local --private-key $$DEV0_PRIVKEY --broadcast

seed-pool:
	scripts/seed_pool.sh

smoke-dex:
	scripts/smoke_dex.sh

# ---- Indexer (Ponder; needs localnet + deployed DEX) ----
.PHONY: indexer-install indexer-dev smoke-indexer

indexer-install:
	cd indexer && npm ci

indexer-dev:  ## GraphQL at http://localhost:42069/graphql
	cd indexer && npx ponder dev --disable-ui

smoke-indexer:
	scripts/smoke_indexer.sh

# ---- Oracle (mock Chainlink feed; needs localnet) ----
.PHONY: deploy-oracle

deploy-oracle:  ## POTATO/USD feed -> deployments json (Feed_POTATO_USD)
	. scripts/lib.sh && cd contracts && forge script script/DeployOracle.s.sol --rpc-url potato_local --private-key $$DEV0_PRIVKEY --broadcast

# ---- IBC: gaia-local + Hermes (needs localnet) ----
.PHONY: ibc-up ibc-down hermes-keys ibc-channel relayer

ibc-up:
	scripts/install_hermes.sh
	mkdir -p .localnet/gaia && docker-compose -f ibc/docker-compose.yml up -d

ibc-down:
	docker-compose -f ibc/docker-compose.yml down

hermes-keys:  ## relayer keys for both chains (potato: eth HD path, funded by faucet)
	scripts/hermes_keys.sh

ibc-channel:  ## one-time: clients + connection + transfer channel-0
	tools/bin/hermes --config ibc/hermes/config.toml create channel --a-chain potato-1 --b-chain gaia-local \
	  --a-port transfer --b-port transfer --new-client-connection --yes

relayer:
	tools/bin/hermes --config ibc/hermes/config.toml start

.PHONY: smoke-ibc
smoke-ibc:  ## needs make relayer running
	scripts/smoke_ibc.sh

.PHONY: deploy-bridge
deploy-bridge:  ## PotatoBridge on channel-0 -> deployments json
	. scripts/lib.sh && cd contracts && forge script script/DeployBridge.s.sol --rpc-url potato_local --private-key $$DEV0_PRIVKEY --broadcast

# ---- Lending (Morpho Blue; needs deploy + deploy-oracle) ----
.PHONY: deploy-lending smoke-lending

deploy-lending:  ## Morpho + WPOTATO/USDC market (LLTV 77%) + 10k USDC supply
	. scripts/lib.sh && cd contracts && forge script script/DeployLending.s.sol --rpc-url potato_local --private-key $$DEV0_PRIVKEY --broadcast

smoke-lending:
	scripts/smoke_lending.sh

# ---- Chain upgrade drill (x/gov + x/upgrade; one-shot per chain) ----
.PHONY: upgrade-image upgrade-drill

upgrade-image:  ## pre-stage the next binary as potato-chain/potatod:v2
	docker build -t potato-chain/potatod:v2 --build-arg VERSION=$(VERSION) --build-arg COMMIT=$(COMMIT) .

upgrade-drill:
	scripts/upgrade_drill.sh

# ---- Frontend (Vite + wagmi; needs localnet + deployments) ----
.PHONY: web-install web-dev web-build

web-install:
	cd web && npm ci

web-dev:  ## http://localhost:5173 (burner wallet + dev faucet enabled)
	. scripts/lib.sh && cd web && VITE_DEV_BURNER=1 POTATO_FAUCET_KEY=$$DEV0_PRIVKEY npx vite --port 5173 --strictPort

web-build:
	cd web && npm run build
