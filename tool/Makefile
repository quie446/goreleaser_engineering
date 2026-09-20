SHELL := /bin/bash

.PHONY: help tools test release-check release-snapshot release-verify clean

help:
	@echo "make tools             install pinned goreleaser + syft into ./bin"
	@echo "make test              go test ./..."
	@echo "make release-check     validate .goreleaser.yaml (+ negative test)"
	@echo "make release-snapshot  build all archives + checksums + SBOMs into ./dist"
	@echo "make release-verify    two snapshot builds, checksums must match"
	@echo "make clean             remove ./dist"

tools:
	@./scripts/bootstrap-tools.sh

test:
	go test ./...

release-check: tools
	PATH="$(CURDIR)/bin:$$PATH" goreleaser check
	@./scripts/check-bad-config.sh

release-snapshot: tools
	PATH="$(CURDIR)/bin:$$PATH" goreleaser release --snapshot --clean

release-verify: tools
	@./scripts/verify-reproducible.sh

clean:
	rm -rf dist
