#!/usr/bin/env bash
# Indexer consistency: after a fresh swap, Ponder's pool row must equal on-chain getReserves().
# Needs: localnet + deployed DEX + indexer running (make indexer-dev).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH"
export ETH_RPC_URL="${RPC:-http://localhost:8545}"
API="${INDEXER_API:-http://localhost:42069}"
D="$ROOT/deployments/${NETWORK:-localnet}.json"
pair=$(jq -r .Pair_WPOTATO_USDC "$D"); usdc=$(jq -r .USDC "$D")
assert() { local d="$1"; shift; if "$@"; then printf '  ok   %s\n' "$d"; else printf '  FAIL %s\n' "$d" >&2; exit 1; fi; }
gql() { curl -sf "$API/graphql" -H 'content-type: application/json' -d "{\"query\":\"$1\"}"; }

count_before=$(gql '{ pools { items { swapCount } } }' | jq '.data.pools.items[0].swapCount')
"$ROOT/scripts/smoke_dex.sh" >/dev/null          # 2 swaps on-chain
target=$((count_before + 2))

for _ in $(seq 1 20); do                          # realtime lag should be ~1-2 blocks
  row=$(gql '{ pools { items { swapCount reservePotato reserveUsdc } } }' | jq -c '.data.pools.items[0]')
  [[ "$(jq .swapCount <<<"$row")" -ge "$target" ]] && break
  sleep 1
done
assert "indexer saw 2 new swaps (swapCount $count_before -> $(jq .swapCount <<<"$row"))" test "$(jq .swapCount <<<"$row")" -ge "$target"

res=$(cast call "$pair" 'getReserves()(uint112,uint112,uint32)' | awk '{print $1}')  # bash 3.2: no mapfile
r0=$(sed -n 1p <<<"$res"); r1=$(sed -n 2p <<<"$res")
if [[ "$(cast call "$pair" 'token0()(address)')" == "$(cast to-check-sum-address "$usdc")" ]]; then
  chain_usdc=$r0; chain_potato=$r1
else
  chain_usdc=$r1; chain_potato=$r0
fi
assert "reserve POTATO matches chain ($chain_potato)" test "$(jq -r .reservePotato <<<"$row")" = "$chain_potato"
assert "reserve USDC matches chain ($chain_usdc)" test "$(jq -r .reserveUsdc <<<"$row")" = "$chain_usdc"
echo "indexer smoke test passed"
