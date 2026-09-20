#!/usr/bin/env sh
# Downloads pinned goreleaser and syft binaries into tools/bin for the
# current platform. CI and local machines use the same script, so versions
# never drift. POSIX sh + curl/tar only.
set -eu

GORELEASER_VERSION="${GORELEASER_VERSION:-v2.18.2}"
SYFT_VERSION="${SYFT_VERSION:-1.52.0}"

BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/tools/bin"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM
mkdir -p "$BIN_DIR"

case "$(uname -s)" in
  Linux)
    GR_OS=Linux
    SYFT_OS=linux
    ;;
  Darwin)
    GR_OS=Darwin
    SYFT_OS=darwin
    ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64 | amd64)
    GR_ARCH=x86_64
    SYFT_ARCH=amd64
    ;;
  arm64 | aarch64)
    GR_ARCH=arm64
    SYFT_ARCH=arm64
    ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

download() {
  url=$1
  dest=$2
  echo "downloading $url"
  curl -fL --retry 3 -o "$dest" "$url"
}

GR_VERSION="${GORELEASER_VERSION#v}"
download "https://github.com/goreleaser/goreleaser/releases/download/${GORELEASER_VERSION}/goreleaser_${GR_OS}_${GR_ARCH}.tar.gz" "$TMP_DIR/goreleaser.tar.gz"
tar -xzf "$TMP_DIR/goreleaser.tar.gz" -C "$TMP_DIR" goreleaser
mv "$TMP_DIR/goreleaser" "$BIN_DIR/goreleaser"
chmod +x "$BIN_DIR/goreleaser"

download "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_${SYFT_OS}_${SYFT_ARCH}.tar.gz" "$TMP_DIR/syft.tar.gz"
tar -xzf "$TMP_DIR/syft.tar.gz" -C "$TMP_DIR" syft
mv "$TMP_DIR/syft" "$BIN_DIR/syft"
chmod +x "$BIN_DIR/syft"

echo "installed:"
"$BIN_DIR/goreleaser" --version | sed -n 's/^GitVersion:[[:space:]]*//p' || true
"$BIN_DIR/syft" version | grep -E '^Version:' || true
