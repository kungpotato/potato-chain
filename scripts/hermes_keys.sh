#!/usr/bin/env bash
# Import Hermes relayer keys for potato-1 and gaia-local, then fund the potato-1 relayer.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$ROOT/tools/bin:$HOME/.foundry/bin:$PATH"
CFG="$ROOT/ibc/hermes/config.toml"
M="$ROOT/.localnet/hermes/potato-relayer.txt"
mkdir -p "$(dirname "$M")"
[[ -s "$M" ]] || cast wallet new-mnemonic --json | jq -r '.. | .mnemonic? // empty' | head -1 > "$M"

# cosmos/evm = Ethereum HD path (coin type 60); a 118 path would give a different, unfunded address
hermes --config "$CFG" keys add --chain potato-1 --key-name relayer --mnemonic-file "$M" --hd-path "m/44'/60'/0'/0/0" --overwrite
hermes --config "$CFG" keys add --chain gaia-local --key-name relayer --mnemonic-file "$ROOT/.localnet/gaia/mnemonics/relayer.txt" --overwrite

addr=$(cast wallet address --mnemonic "$(cat "$M")" --mnemonic-derivation-path "m/44'/60'/0'/0/0")
"$ROOT/scripts/faucet.sh" "$addr" 100
