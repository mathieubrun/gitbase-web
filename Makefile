# Package configuration
PROJECT := gitbase-playground
COMMANDS := cmd/gitbase-playground
DEPENDENCIES := \
	github.com/golang/dep/cmd/dep \
	github.com/jteeuwen/go-bindata \
	github.com/golang/lint/golint

GO_LINTABLE_PACKAGES := $(shell go list ./... | grep -v '/vendor/')
GO_BUILD_ENV := CGO_ENABLED=0
FRONTEND_PATH := ./frontend
FRONTEND_BUILD_PATH := $(FRONTEND_PATH)/build

# Tools
GODEP := dep
GOLINT := golint
GOVET := go vet
BINDATA := go-bindata
DIFF := diff
YARN := yarn --cwd $(FRONTEND_PATH)
REMOVE := rm -rf
MOVE := mv
MKDIR := mkdir -p

# Default rule
all:

# Including ci Makefile
CI_REPOSITORY ?= https://github.com/src-d/ci.git
CI_BRANCH ?= v1
CI_PATH ?= $(shell pwd)/.ci
MAKEFILE := $(CI_PATH)/Makefile.main
$(MAKEFILE):
	@git clone --quiet --depth 1 -b $(CI_BRANCH) $(CI_REPOSITORY) $(CI_PATH);
-include $(MAKEFILE)

# Makefile.main::dependencies -> Makefile.main::$(DEPENDENCIES) -> this::dependencies
# The `exit` is needed to prevent running `Makefile.main::dependencies` commands.
dependencies: | front-dependencies back-dependencies exit

# Makefile.main::test -> this::test
test: front-test

# this::build -> Makefile.main::build -> Makefile.main::$(COMMANDS)
# The @echo forces this prerequisites to be run before `Makefile.main::build` ones.
build: front-build back-build
	@echo

coverage: | test-coverage codecov

lint: back-lint front-lint

validate-commit: | \
	back-dependencies \
	back-ensure-assets-proxy \
	front-fix-lint-errors \
	no-changes-in-commit

exit:
	exit 0;

clean: front-clean

build-path:
	$(MKDIR) $(BUILD_PATH)

## Compiles the assets, and serve the tool through its API

serve: | front-build back-start


# Backend

assets := ./server/assets/asset.go
assets_back := $(assets).bak

back-dependencies:
	$(GODEP) ensure

back-build: back-bindata

back-bindata:
	$(BINDATA) \
		-pkg assets \
		-o $(assets) \
		build/public/...

back-lint: $(GO_LINTABLE_PACKAGES)
$(GO_LINTABLE_PACKAGES):
	$(GOLINT) $@
	$(GOVET) $@

back-start:
	GITBASEPG_ENV=dev go run cmd/gitbase-playground/main.go

back-ensure-assets-proxy:
	$(DIFF) $(assets) $(assets_back) || exit 1

go-test-integration-packages := ./server/handler
go-test-integration-flags := -v -args -test.integration.gitbase -test.integration.bblfshd
back-test-integration:
	go test $(go-test-integration-packages) $(go-test-integration-flags)


# Frontend

front-dependencies:
	$(YARN) install

front-test:
	$(YARN) test

front-lint:
	$(YARN) lint

front-build: build-path
	$(YARN) build
	$(MOVE) $(FRONTEND_BUILD_PATH) $(BUILD_PATH)/public

front-fix-lint-errors:
	$(YARN) format

front-clean:
	$(REMOVE) $(FRONTEND_PATH)/node_modules
	$(REMOVE) $(FRONTEND_BUILD_PATH)
