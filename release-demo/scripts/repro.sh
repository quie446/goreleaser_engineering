#!/usr/bin/env sh
# Builds the snapshot twice from the same checkout and verifies that the
# SHA-256 of every archive in dist/checksums.txt is identical across runs.
# Exits non-zero on any mismatch.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

goreleaser_bin="${GORELEASER:-goreleaser}"

run_snapshot() {
  out=$1
  "$goreleaser_bin" release --snapshot --clean
  # checksums.txt contains both archives and SBOMs; compare archive rows
  # ("<sha256>  <name>") only, since SBOM documents carry timestamps.
  awk '/[.]tar[.]gz$/ { print $1, $2 }' dist/checksums.txt | sort > "$out"
}

echo "== snapshot run 1 =="
run_snapshot /tmp/reltool-hashes-1

echo "== snapshot run 2 =="
run_snapshot /tmp/reltool-hashes-2

echo
echo "== archive hashes (both runs) =="
cat /tmp/reltool-hashes-1

if diff -u /tmp/reltool-hashes-1 /tmp/reltool-hashes-2; then
  echo "REPRODUCIBLE: identical archive hashes in both snapshots"
else
  echo "FAILED: archive hashes differ between snapshots" >&2
  exit 1
fi
