#!/usr/bin/env bash
# Push a POTATO/USD price to the mock feed (dev stand-in for a keeper / Pyth price pusher).
#   scripts/oracle_push.sh 2.15
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH"
export ETH_RPC_URL="${RPC:-http://localhost:8545}"
feed=$(jq -r '.Feed_POTATO_USD // empty' "$ROOT/deployments/${NETWORK:-localnet}.json")
[[ -n "$feed" ]] || { echo "no Feed_POTATO_USD: run make deploy-oracle" >&2; exit 1; }

usd="${1:?usage: oracle_push.sh <price-in-usd>}"
answer=$(python3 -c "from decimal import Decimal as D; import sys; v=D(sys.argv[1]); assert v>0; print(int(v*10**8))" "$usd" 2>/dev/null) \
  || { echo "price must be a positive number" >&2; exit 1; }

cast send "$feed" 'updateAnswer(int256)' "$answer" --private-key "$DEV0_PRIVKEY" >/dev/null
read -r round ans _ updated _ < <(cast call "$feed" 'latestRoundData()(uint80,int256,uint256,uint256,uint80)' | awk '{print $1}' | xargs)
echo "POTATO/USD = $(python3 -c "print($ans/1e8)") (round $round, updatedAt $updated)"
