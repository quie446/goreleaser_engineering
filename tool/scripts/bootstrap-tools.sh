#!/usr/bin/env bash
# Downloads pinned goreleaser + syft binaries into tool/bin.
# No network use after the binaries are cached there.
set -euo pipefail

GORELEASER_VERSION="v2.12.0"
SYFT_VERSION="v1.42.4"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${DIR}/bin"
mkdir -p "${BIN_DIR}"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "${os}" in
  darwin) os="Darwin" ;;
  linux)  os="Linux" ;;
  *) echo "unsupported os: ${os}" >&2; exit 1 ;;
esac

arch="$(uname -m)"
case "${arch}" in
  x86_64 | amd64) arch="x86_64" ;;
  arm64 | aarch64) arch="arm64" ;;
  *) echo "unsupported arch: ${arch}" >&2; exit 1 ;;
esac

if [[ ! -x "${BIN_DIR}/goreleaser" ]] || ! "${BIN_DIR}/goreleaser" --version | grep -q "${GORELEASER_VERSION#v}"; then
  url="https://github.com/goreleaser/goreleaser/releases/download/${GORELEASER_VERSION}/goreleaser_${os}_${arch}.tar.gz"
  echo "downloading goreleaser ${GORELEASER_VERSION} (${os}/${arch})"
  curl -fsSL "${url}" | tar -xz -C "${BIN_DIR}" goreleaser
fi

if [[ ! -x "${BIN_DIR}/syft" ]] || ! "${BIN_DIR}/syft" version | grep -q "Version:.*${SYFT_VERSION#v}"; then
  url="https://github.com/anchore/syft/releases/download/${SYFT_VERSION}/syft_${SYFT_VERSION#v}_${os}_${arch}.tar.gz"
  echo "downloading syft ${SYFT_VERSION} (${os}/${arch})"
  curl -fsSL "${url}" | tar -xz -C "${BIN_DIR}" syft
fi

echo "tools ready in ${BIN_DIR}"
