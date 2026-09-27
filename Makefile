BINARY   ?= evmd
MAIN_PKG := ./cmd/evmd
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
