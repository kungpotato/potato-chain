#!/usr/bin/env bash
# Morpho Blue on the REAL chain with the WPOTATO precompile as collateral (forge tests use a mock):
# fresh borrower: 100 POTATO collateral -> borrow 150 USDC -> price $2 -> $1.80 -> dev0 liquidates.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH" ETH_RPC_URL="${RPC:-http://localhost:8545}"
D="$ROOT/deployments/${NETWORK:-localnet}.json"
j() { jq -r ".$1" "$D"; }
morpho=$(j Morpho) usdc=$(j USDC) W=$(j WPOTATO) id=$(j Market_WPOTATO_USDC)
MP="($usdc,$W,$(j PotatoOracle),$(j LinearIrm),770000000000000000)"
MPT='(address,address,address,address,uint256)'
assert() { local d="$1"; shift; if "$@"; then printf '  ok   %s\n' "$d"; else printf '  FAIL %s\n' "$d" >&2; exit 1; fi; }
num() { awk '{print $1}'; }
trap '"$ROOT/scripts/oracle_push.sh" 2.0 >/dev/null' EXIT   # always restore the price

"$ROOT/scripts/oracle_push.sh" 2.0 >/dev/null
w=$(cast wallet new --json | jq -c '.data | if type=="array" then .[0] else . end')
b=$(jq -r .address <<<"$w"); bk=$(jq -r .private_key <<<"$w")
"$ROOT/scripts/faucet.sh" "$b" 100 >/dev/null && cast send "$b" --value 1ether --private-key "$DEV0_PRIVKEY" >/dev/null  # +1 for gas

# WPOTATO precompile as ERC-20: approve + Morpho.transferFrom move *native* POTATO
cast send "$W" 'approve(address,uint256)' "$morpho" 100ether --private-key "$bk" >/dev/null
cast send "$morpho" "supplyCollateral($MPT,uint256,address,bytes)" "$MP" 100ether "$b" 0x --private-key "$bk" >/dev/null
coll=$(cast call "$morpho" 'position(bytes32,address)(uint256,uint128,uint128)' "$id" "$b" | sed -n 3p | num)
assert "supplyCollateral 100 WPOTATO (precompile transferFrom)" test "$coll" = 100000000000000000000

if cast send "$morpho" "borrow($MPT,uint256,uint256,address,address)" "$MP" 160000000 0 "$b" "$b" --private-key "$bk" >/dev/null 2>&1; then
  assert "borrow 160 USDC (80% > LLTV) must revert" false
else
  assert "borrow 160 USDC (80% > LLTV) reverts" true
fi
cast send "$morpho" "borrow($MPT,uint256,uint256,address,address)" "$MP" 150000000 0 "$b" "$b" --private-key "$bk" >/dev/null
assert "borrow 150 USDC at 75% LTV" test "$(cast call "$usdc" 'balanceOf(address)(uint256)' "$b" | num)" = 150000000

"$ROOT/scripts/oracle_push.sh" 1.8 >/dev/null     # LTV 150/180 = 83% > 77%
cast send "$usdc" 'approve(address,uint256)' "$morpho" 100000000 --private-key "$DEV0_PRIVKEY" >/dev/null
before=$(cast balance "$(cast wallet address "$DEV0_PRIVKEY")")
cast send "$morpho" "liquidate($MPT,address,uint256,uint256,bytes)" "$MP" "$b" 10ether 0 0x --private-key "$DEV0_PRIVKEY" >/dev/null
after=$(cast balance "$(cast wallet address "$DEV0_PRIVKEY")")
coll2=$(cast call "$morpho" 'position(bytes32,address)(uint256,uint128,uint128)' "$id" "$b" | sed -n 3p | num)
assert "liquidate after drop to \$1.80: 10 POTATO seized" test "$coll2" = 90000000000000000000
assert "  liquidator received native POTATO (minus gas)" python3 -c "import sys; sys.exit(0 if int('$after') - int('$before') > 9 * 10**18 else 1)"
echo "lending smoke test passed"
