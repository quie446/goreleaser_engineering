# reltool

`reltool` is a deliberately tiny Go CLI used to demonstrate reproducible,
multi-architecture release engineering with [GoReleaser](https://goreleaser.com).

It ships `linux`/`darwin` × `amd64`/`arm64` archives, a `checksums.txt`,
and a CycloneDX SBOM per archive.

## Build metadata

```console
$ reltool --version
reltool version 1.0.0
commit: 9f2c1a3d4e5f...
commitDate: 2026-09-20T08:00:00Z
treeState: clean
```

The fields are injected with `-ldflags` by GoReleaser (see
[`.goreleaser.yaml`](.goreleaser.yaml)). A plain `go build` falls back to
metadata from `debug.ReadBuildInfo`, so the commit is never a hard-coded
string.

## Common tasks

All commands run from this directory (`release-demo/`):

```console
make tools              # install pinned goreleaser + syft into tools/bin
make release-check      # validate .goreleaser.yaml (bad config fails red)
make release-snapshot   # build all archives + checksums + SBOMs into dist/
make release-repro      # run two snapshots and diff the archives' hashes
make build              # plain local go build
make test               # go test ./...
```

Pinned tool versions are variables in the `Makefile` (`GORELEASER_VERSION`,
`SYFT_VERSION`). If `goreleaser`/`syft` are already on `PATH`, they win;
otherwise `make tools` downloads the pinned binaries for the current
platform into `tools/bin/`.

## Release environment

Snapshots never upload anything and need **no secrets**:

```console
make release-snapshot
# equivalent to: goreleaser release --snapshot --clean
```

A real, tag-driven release needs:

- a git tag reachable from the checkout (e.g. `v1.0.0`);
- `GITHUB_TOKEN` (or `GITHUB_TOKEN` with `repo`/`contents: write`) so
  GoReleaser can create the GitHub Release and upload artifacts;
  run it with `goreleaser release --clean` (the CI workflow gates this
  behind tag pushes).

No tokens are stored in the repository.

## Reproducibility

See [`RELEASE.md`](RELEASE.md) for the full rationale and the exact steps
to reproduce:

```console
make release-repro
```

Two snapshots of the same commit must produce identical hashes for each
`*.tar.gz` in `dist/checksums.txt`. The SBOM files (`*.sbom.cdx.json`) are
excluded from that strict comparison because Syft stamps documents with
generation metadata; see the documented exception in `RELEASE.md`.
