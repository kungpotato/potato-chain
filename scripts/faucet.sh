#!/usr/bin/env bash
# Dev faucet: send POTATO from dev0 to an address (0x... or potato1...).
#   scripts/faucet.sh <address> [amount-in-potato, default 10]
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH"
export ETH_RPC_URL="${RPC:-http://localhost:8545}"

to="${1:?usage: faucet.sh <0x... | potato1...> [amount]}"
amount="${2:-10}"
MAX=100  # keep dev0 from being drained by a typo

[[ "$amount" =~ ^[0-9]+$ ]] && (( amount > 0 && amount <= MAX )) || { echo "amount must be 1..$MAX POTATO" >&2; exit 1; }
if [[ "$to" == potato1* ]]; then  # bech32 -> same 20 bytes as 0x
  to="$("$BIN" debug addr "$to" | awk '/Address hex/{print $3}')"
fi
[[ "$to" =~ ^0x[0-9a-fA-F]{40}$ ]] || { echo "invalid address: $to" >&2; exit 1; }

tx=$(cast send "$to" --value "${amount}ether" --private-key "$DEV0_PRIVKEY" --json)
[[ "$(jq -r .status <<<"$tx")" == 0x1 ]] || { echo "tx failed: $tx" >&2; exit 1; }
echo "sent $amount POTATO -> $to"
echo "tx:      $(jq -r .transactionHash <<<"$tx")"
echo "balance: $(cast balance "$to" --ether) POTATO"
