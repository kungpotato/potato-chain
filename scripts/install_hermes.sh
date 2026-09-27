#!/usr/bin/env bash
# Install Hermes (IBC relayer) into tools/bin, pinned + checksum-verified.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=v1.13.3
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)  T=aarch64-apple-darwin;       SHA=aba0db17827f3646c86247292e24f12e98325cbc604e4ee034b9cac62be16588 ;;
  Darwin-x86_64) T=x86_64-apple-darwin;        SHA=8e90939527bf8d22b02945d5d0b309d2b998bffeb965219358486e2446889762 ;;
  Linux-aarch64) T=aarch64-unknown-linux-gnu;  SHA=c586ac5e8d6bbeffff271e0f28b356488f5b44c58d5b25386c0051ddcf84af4d ;;
  Linux-x86_64)  T=x86_64-unknown-linux-gnu;   SHA=3582136824ac1984c8884b310c63940a1489f091fa45faca38ed80e5dfe7d51b ;;
  *) echo "unsupported platform" >&2; exit 1 ;;
esac
BIN="$ROOT/tools/bin/hermes"
STAMP="$ROOT/tools/bin/.hermes-sha256"
# Note: the v1.13.3 release binary self-reports "1.13.2+bab3b80", so pin by artifact checksum, not by `hermes version`.
if [[ -x "$BIN" && "$(cat "$STAMP" 2>/dev/null)" == "$SHA" ]]; then echo "hermes $VERSION already installed"; exit 0; fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
url="https://github.com/informalsystems/hermes/releases/download/$VERSION/hermes-$VERSION-$T.tar.gz"
curl -fsSL "$url" -o "$tmp/h.tgz"
echo "$SHA  $tmp/h.tgz" | shasum -a 256 -c - >/dev/null || { echo "checksum mismatch for $url" >&2; exit 1; }
tar -xzf "$tmp/h.tgz" -C "$tmp"
mkdir -p "$(dirname "$BIN")" && install -m 0755 "$tmp/hermes" "$BIN" && echo "$SHA" > "$STAMP"
"$BIN" version
