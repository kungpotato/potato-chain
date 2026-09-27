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
