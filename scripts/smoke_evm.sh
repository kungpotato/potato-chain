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
# contract: deploy -> write -> read -> event (docs/known-issues.md: never query logs from block 0)
(cd "$ROOT/contracts" && forge build -q)
dep=$(cd "$ROOT/contracts" && forge create src/Counter.sol:Counter --private-key "$DEV0_PRIVKEY" --broadcast --json)
counter=$(jq -r .deployedTo <<<"$dep")
assert "deploy Counter at $counter" test "$(cast code "$counter")" != 0x
inc=$(cast send "$counter" 'increment()' --private-key "$DEV0_PRIVKEY" --json)
assert "increment() -> number() == 1" test "$(cast call "$counter" 'number()(uint256)')" = 1
blk=$(jq -r .blockNumber <<<"$inc")
logs=$(cast rpc eth_getLogs "{\"address\":\"$counter\",\"fromBlock\":\"$blk\",\"toBlock\":\"latest\"}" | jq length)
assert "eth_getLogs sees exactly 1 Incremented event" test "$logs" = 1
echo "smoke test passed"
