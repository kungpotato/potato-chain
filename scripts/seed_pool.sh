#!/usr/bin/env bash
# Seed the WPOTATO/USDC pool with first liquidity against the REAL chain
# (forge script can't simulate the WPOTATO precompile). Initial price: 1 POTATO = 2 USDC.
#   scripts/seed_pool.sh [potato-amount, default 100]
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH"
export ETH_RPC_URL="${RPC:-http://localhost:8545}"
D="$ROOT/deployments/${NETWORK:-localnet}.json"
[[ -f "$D" ]] || { echo "missing $D: run make deploy first" >&2; exit 1; }

POTATO="${1:-100}"
USDC_AMT=$((POTATO * 2 * 1000000))   # 6 decimals
usdc=$(jq -r .USDC "$D"); router=$(jq -r .UniswapV2Router02 "$D"); pair=$(jq -r .Pair_WPOTATO_USDC "$D")
me=$(cast wallet address "$DEV0_PRIVKEY")
send() { cast send --private-key "$DEV0_PRIVKEY" --json "$@" | jq -e '.status == "0x1"' >/dev/null; }

send "$usdc" 'approve(address,uint256)' "$router" "$USDC_AMT"
# Router: WPOTATO.deposit{value}() then WPOTATO.transfer(pair) -> precompile moves native POTATO
send "$router" 'addLiquidityETH(address,uint256,uint256,uint256,address,uint256)' \
  "$usdc" "$USDC_AMT" 0 0 "$me" $(( $(date +%s) + 600 )) --value "${POTATO}ether"

read -r r0 r1 _ < <(cast call "$pair" 'getReserves()(uint112,uint112,uint32)' | awk '{print $1}' | xargs)
echo "pool $pair reserves: $r0 / $r1 (token0/token1 raw units)"
echo "LP tokens: $(cast call "$pair" 'balanceOf(address)(uint256)' "$me")"
