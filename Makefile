# Makefile for Moby (Docker Engine)
# Provides common development targets for building, testing, and linting

.PHONY: all binary build clean default help test test-unit test-integration lint validate

# Default target
default: binary

# Build variables
GO ?= go
GOFLAGS ?= -trimpath
BUILD_DIR ?= ./cmd/dockerd
BINARY_NAME ?= dockerd
OUTPUT_DIR ?= ./bundles

# Version information
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

LDFLAGS := -ldflags "-X github.com/docker/docker/dockerversion.Version=$(VERSION) \
	-X github.com/docker/docker/dockerversion.GitCommit=$(GIT_COMMIT) \
	-X github.com/docker/docker/dockerversion.BuildTime=$(BUILD_DATE)"

## help: Display this help message
help:
	@echo "Moby (Docker Engine) Makefile"
	@echo ""
	@echo "Usage:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'

## all: Build all binaries
all: binary

## binary: Build the dockerd binary
binary:
	@echo "==> Building $(BINARY_NAME)..."
	@mkdir -p $(OUTPUT_DIR)
	$(GO) build $(GOFLAGS) $(LDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME) $(BUILD_DIR)
	@echo "==> Binary available at $(OUTPUT_DIR)/$(BINARY_NAME)"

## build: Alias for binary
build: binary

## clean: Remove build artifacts
clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)
	@$(GO) clean -cache

## test: Run all tests
test: test-unit

## test-unit: Run unit tests
test-unit:
	@echo "==> Running unit tests..."
	$(GO) test $(GOFLAGS) -v -count=1 ./...

## test-integration: Run integration tests (requires root/privileged)
test-integration:
	@echo "==> Running integration tests..."
	$(GO) test $(GOFLAGS) -v -count=1 -tags=integration ./integration/...

## test-race: Run tests with race detector
test-race:
	@echo "==> Running tests with race detector..."
	$(GO) test -race $(GOFLAGS) -count=1 ./...

## lint: Run golangci-lint
lint:
	@echo "==> Running linter..."
	@which golangci-lint > /dev/null || (echo "golangci-lint not found, install from https://golangci-lint.run" && exit 1)
	golangci-lint run ./...

## validate: Run go vet and staticcheck
validate:
	@echo "==> Running go vet..."
	$(GO) vet ./...
	@echo "==> Running go mod tidy check..."
	$(GO) mod tidy
	@git diff --exit-code go.mod go.sum || (echo "go.mod or go.sum is out of date, run 'go mod tidy'" && exit 1)

## fmt: Format Go source files
fmt:
	@echo "==> Formatting source files..."
	$(GO) fmt ./...

## vendor: Update vendor directory
vendor:
	@echo "==> Updating vendor directory..."
	$(GO) mod vendor

## tidy: Tidy go modules
tidy:
	@echo "==> Tidying go modules..."
	$(GO) mod tidy

## version: Print version information
version:
	@echo "Version:    $(VERSION)"
	@echo "Git Commit: $(GIT_COMMIT)"
	@echo "Build Date: $(BUILD_DATE)"
