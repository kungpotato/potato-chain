#!/usr/bin/env bash
# DEX round trip on the REAL chain (exercises the WPOTATO precompile, which forge tests can't):
# fresh trader swaps 1 POTATO -> USDC -> POTATO through UniswapV2Router02.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH"
export ETH_RPC_URL="${RPC:-http://localhost:8545}"
D="$ROOT/deployments/${NETWORK:-localnet}.json"
usdc=$(jq -r .USDC "$D"); router=$(jq -r .UniswapV2Router02 "$D"); pair=$(jq -r .Pair_WPOTATO_USDC "$D"); W=$(jq -r .WPOTATO "$D")
assert() { local d="$1"; shift; if "$@"; then printf '  ok   %s\n' "$d"; else printf '  FAIL %s\n' "$d" >&2; exit 1; fi; }
num() { awk '{print $1}'; }
gt() { python3 -c "import sys; sys.exit(0 if int(sys.argv[1]) > int(sys.argv[2]) else 1)" "$1" "$2"; }  # uint256-safe

w=$(cast wallet new --json | jq -c '.data | if type=="array" then .[0] else . end')
t=$(jq -r .address <<<"$w"); tk=$(jq -r .private_key <<<"$w")
"$ROOT/scripts/faucet.sh" "$t" 10 >/dev/null
dl=$(( $(date +%s) + 600 ))

quote=$(cast call "$router" 'getAmountsOut(uint256,address[])(uint256[])' 1ether "[$W,$usdc]" | tr -d '[]' | cut -d, -f2 | num)
cast send "$router" 'swapExactETHForTokens(uint256,address[],address,uint256)' "$quote" "[$W,$usdc]" "$t" "$dl" \
  --value 1ether --private-key "$tk" >/dev/null
got=$(cast call "$usdc" 'balanceOf(address)(uint256)' "$t" | num)
assert "swap 1 POTATO -> $got USDC-units (quoted $quote)" test "$got" = "$quote"

cast send "$usdc" 'approve(address,uint256)' "$router" "$got" --private-key "$tk" >/dev/null
before=$(cast balance "$t")
cast send "$router" 'swapExactTokensForETH(uint256,uint256,address[],address,uint256)' "$got" 0 "[$usdc,$W]" "$t" "$dl" \
  --private-key "$tk" >/dev/null
assert "swap USDC back -> native POTATO received" gt "$(cast balance "$t")" "$before"

# Uniswap sorts tokens by address: find which reserve slot is WPOTATO
slot=2; [[ "$(cast call "$pair" 'token0()(address)')" == "$(cast to-check-sum-address "$W")" ]] && slot=1
reserve=$(cast call "$pair" 'getReserves()(uint112,uint112,uint32)' | sed -n "${slot}p" | num)
assert "pair native balance == WPOTATO reserve ($reserve)" test "$(cast balance "$pair")" = "$reserve"
assert "router holds no native dust" test "$(cast balance "$router")" = 0
echo "dex smoke test passed"
