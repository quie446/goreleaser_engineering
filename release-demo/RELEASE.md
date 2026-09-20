# Release engineering

This directory is a self-contained, reproducible release setup for the tiny
`reltool` binary. It does not depend on anything in the parent repository.

## What gets built

`make release-snapshot` runs `goreleaser release --snapshot --clean` and
produces, under `dist/`:

| Artifact | Example |
| --- | --- |
| Archives (2 OS × 2 arch) | `reltool_1.0.0_linux_arm64.tar.gz` |
| Checksums (SHA-256) | `checksums.txt` |
| SBOM per archive (CycloneDX 1.7 JSON) | `reltool_1.0.0_linux_arm64.tar.gz.sbom.cdx.json` |

Targets: `linux/{amd64,arm64}`, `darwin/{amd64,arm64}`, all `CGO_ENABLED=0`.

## Commands

```console
make tools              # install pinned goreleaser/syft into tools/bin
make release-check      # goreleaser check; exits non-zero on bad config
make release-snapshot   # full local build into dist/, nothing uploaded
make release-repro      # build twice, fail unless archive hashes match
make build / make test  # plain go build / go test
```

`release-check` is the gate CI uses on PRs: a malformed `.goreleaser.yaml`
makes the command exit non-zero, so the check goes red. You can try it:

```console
echo "goos: [not-an-os]" >> .goreleaser.yaml && make release-check; echo $?
git checkout -- .goreleaser.yaml
```

## Version and commit injection

Versions come from git tags, never from a hard-coded string:

- On an exact tag (real release): `v1.2.3` → version `1.2.3`.
- Between tags (snapshot): `1.2.4-dev.<short-commit>`
  (or `0.0.1-dev.<short-commit>` before the first tag).

[`.goreleaser.yaml`](.goreleaser.yaml) passes these via `-ldflags -X` into
`internal/version`:

| Variable | Source template |
| --- | --- |
| `Version` | `{{ .Version }}` |
| `Commit` | `{{ .FullCommit }}` |
| `CommitDate` | `{{ .CommitDate }}` |
| `TreeState` | `{{ if .IsGitDirty }}dirty{{ else }}clean{{ end }}` |

`reltool --version` prints all four. A plain `go build` without ldflags
falls back to `runtime/debug.ReadBuildInfo()` (vcs.revision/vcs.time), so
the commit is still reported.

```console
$ reltool --version
reltool version 1.2.4-dev.9f2c1a3d4e5f
commit: 9f2c1a3d4e5f
commitDate: 2026-09-20T08:00:00Z
treeState: clean
```

## Environment variables

### Snapshot (local and tag CI) — no secrets

Snapshots pass `--snapshot`, which disables publishing. Requirements:

- git history available (`fetch-depth: 0` in CI) so tags/commits resolve;
- Go toolchain and the pinned `goreleaser` + `syft` (`make tools`);
- no `GITHUB_TOKEN`, no signing keys.

Optional overrides for `make tools`:

| Variable | Default | Purpose |
| --- | --- | --- |
| `GORELEASER_VERSION` | `v2.18.2` | goreleaser release to download |
| `SYFT_VERSION` | `1.52.0` | syft release to download |

If `goreleaser`/`syft` already exist on `PATH`, the Makefile uses them;
otherwise the pinned copies in `tools/bin/` are used.

### Real release — secret required, not used by CI here

To actually publish from a clean `v*` tag locally or in a release workflow:

| Variable | Purpose |
| --- | --- |
| `GITHUB_TOKEN` | create the GitHub Release and upload artifacts |
| (optional) `GPG_FINGERPRINT` / `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE` | checksum signature |

```console
export GITHUB_TOKEN=ghp_xxx        # never commit it
goreleaser release --clean
```

No token is stored in this repository. The shipped CI deliberately only
runs `--snapshot`, so tag pushes cannot publish by accident.

## Reproducibility check

Two snapshots of the **same commit** must yield byte-identical archives.
Automated:

```console
make release-repro
```

This runs `goreleaser release --snapshot --clean` twice, extracts the
`<sha256>  <archive>` rows for every `*.tar.gz` from `dist/checksums.txt`,
and `diff`s them; any difference exits non-zero.

Manual equivalent:

```console
goreleaser release --snapshot --clean
cp dist/checksums.txt /tmp/run1.txt
goreleaser release --snapshot --clean
cp dist/checksums.txt /tmp/run2.txt
grep '\.tar\.gz$' /tmp/run1.txt > /tmp/a
grep '\.tar\.gz$' /tmp/run2.txt > /tmp/b
diff -u /tmp/a /tmp/b && echo "second run matches the first"
```

Why archives are stable:

- `CGO_ENABLED=0` and `-trimpath` remove host paths;
- no build wall-clock time is injected via ldflags (`CommitDate` is the git
  commit date, identical for repeated builds);
- `mod_timestamp: {{ .CommitTimestamp }}` pins zip/timestamps from module
  data;
- GoReleaser writes archive entries deterministically (sorted names, fixed
  mtime/modes).

### Documented timestamp exception: SBOMs

The `*.sbom.cdx.json` files are **not** expected to hash identically across
runs and are excluded from the strict comparison. Syft stamps each CycloneDX
document with:

- `metadata.timestamp` — wall-clock generation time;
- a random `serialNumber` URN per document.

The SBOMs describe the same archive (same components/hashes), but those two
metadata fields change per run. If byte-reproducible SBOMs are required,
normalize with a dedicated tool (e.g. strip `metadata.timestamp` and
`serialNumber` before diffing); the archive hashes themselves are the
reproducible anchor.

## Clean-environment verification

From a fresh checkout, with only Go ≥ 1.24, `curl`, `tar`, and `make`:

```console
cd release-demo
make tools
make release-check
make release-snapshot
# artifacts:
ls dist/*.tar.gz dist/checksums.txt dist/*.sbom.cdx.json
# version smoke test (host arch is darwin/arm64 here):
mkdir -p /tmp/x && tar -xzf dist/reltool_*_darwin_arm64.tar.gz -C /tmp/x
/tmp/x/reltool --version
```
