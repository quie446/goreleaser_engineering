#!/usr/bin/env bash
# Negative test: a broken config MUST make `goreleaser check` exit non-zero.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${DIR}/bin:${PATH}"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

cat > "${tmp}/broken.yaml" <<'YAML'
version: 2
builds:
  - id: tool
    goos:
      - plan9
    goarch:
      - amd64
    bogus_unknown_key: true
YAML

if goreleaser check --config "${tmp}/broken.yaml" >/dev/null 2>&1; then
  echo "FAIL: goreleaser check accepted a broken config" >&2
  exit 1
fi

echo "ok: broken config rejected"
