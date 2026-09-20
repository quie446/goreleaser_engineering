#!/usr/bin/env bash
# Builds two snapshots from the same commit and compares the archive
# hashes recorded in checksums.txt.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${DIR}/bin:${PATH}"

cd "${DIR}"

goreleaser release --snapshot --clean
cp dist/checksums.txt /tmp/tool-checksums-1.txt

goreleaser release --snapshot --clean
cp dist/checksums.txt /tmp/tool-checksums-2.txt

echo "--- run 1 ---"
cat /tmp/tool-checksums-1.txt
echo "--- run 2 ---"
cat /tmp/tool-checksums-2.txt

if ! diff -u /tmp/tool-checksums-1.txt /tmp/tool-checksums-2.txt; then
  echo "FAIL: archive checksums differ between two builds of the same commit" >&2
  exit 1
fi

echo "PASS: checksums identical across two snapshot builds"
