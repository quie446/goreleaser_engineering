# Pinned tool versions used by scripts/tools.sh and CI.
GORELEASER_VERSION ?= v2.18.2
SYFT_VERSION ?= 1.52.0
export GORELEASER_VERSION SYFT_VERSION

# Prefer tools already on PATH (CI installs them the same pinned way);
# fall back to the project-local copy managed by `make tools`.
GORELEASER ?= $(shell command -v goreleaser 2>/dev/null || echo tools/bin/goreleaser)
SYFT ?= $(shell command -v syft 2>/dev/null || echo tools/bin/syft)
export PATH := $(abspath tools/bin):$(PATH)

.PHONY: all build test fmt vet
all: build

build:
	go build -o bin/reltool .

test:
	go test ./...

fmt:
	gofmt -s -w .

vet:
	go vet ./...

# Download the pinned release tooling into tools/bin/ (git-ignored).
.PHONY: tools
tools:
	scripts/tools.sh

# Validate the GoReleaser config. Exit code is non-zero on bad config.
.PHONY: release-check
release-check:
	$(GORELEASER) check -f .goreleaser.yaml

# Local snapshot: cross-compiles every target and produces archives,
# checksums and SBOMs under dist/. Nothing is uploaded; no secrets needed.
.PHONY: release-snapshot
release-snapshot:
	$(GORELEASER) release --snapshot --clean

# Reproducibility check: build twice, archive hashes must be identical.
.PHONY: release-repro
release-repro:
	GORELEASER="$(GORELEASER)" scripts/repro.sh

.PHONY: clean
clean:
	rm -rf bin dist
