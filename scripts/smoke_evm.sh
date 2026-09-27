#!/usr/bin/env bash
# End-to-end EVM smoke test against a running chain (see docs/04-evm-tx-lifecycle.png).
#   RPC=http://localhost:8545 scripts/smoke_evm.sh
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH"
export ETH_RPC_URL="${RPC:-http://localhost:8545}"
command -v cast >/dev/null || { echo "cast not found: install Foundry (foundryup)" >&2; exit 1; }

# assert <description> <test...>: print ok or fail the whole run
assert() { local d="$1"; shift; if "$@"; then printf '  ok   %s\n' "$d"; else printf '  FAIL %s\n' "$d" >&2; exit 1; fi; }

assert "chain-id 707070" test "$(cast chain-id)" = 707070
h1=$(cast block-number); sleep 2; h2=$(cast block-number)
assert "blocks advancing ($h1 -> $h2)" test "$h2" -gt "$h1"

to=$(cast wallet new --json | jq -r '.. | .address? // empty' | head -1)
receipt=$(cast send "$to" --value 1ether --private-key "$DEV0_PRIVKEY" --json)
assert "transfer 1 POTATO dev0 -> $to (block $(( $(jq -r .blockNumber <<<"$receipt") )))" \
  test "$(jq -r .status <<<"$receipt")" = 0x1

# same 20 bytes, bech32 view through the Cosmos REST API
bech=$("$BIN" debug addr "${to#0x}" | awk '/Bech32 Acc/{print $3}')
amt=$(curl -sf "${REST:-http://localhost:1317}/cosmos/bank/v1beta1/balances/$bech" | jq -r ".balances[] | select(.denom==\"$DENOM\") | .amount")
assert "cosmos bank sees $bech = 1 POTATO" test "$amt" = 1000000000000000000
echo "smoke test passed"
