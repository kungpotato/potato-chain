#!/usr/bin/env bash
# IBC round trip potato-1 <-> gaia-local over channel-0 (needs localnet, make ibc-up, make relayer running).
# 1 POTATO out (escrow on potato, voucher minted on gaia), then back (voucher burned, unescrowed).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH" ETH_RPC_URL="${RPC:-http://localhost:8545}"
assert() { local d="$1"; shift; if "$@"; then printf '  ok   %s\n' "$d"; else printf '  FAIL %s\n' "$d" >&2; exit 1; fi; }
gaiad() { docker exec potato-ibc-gaia-1 gaiad "$@" --home /root/.gaia; }
# wait_until "<shell condition>": re-evaluated every 2s (a plain arg would expand $(...) only once), max 60s
wait_until() { for _ in $(seq 1 30); do eval "$1" && return 0; sleep 2; done; return 1; }
ONE=1000000000000000000

dev0_hex=$(cast wallet address "$DEV0_PRIVKEY")
dev0=$("$BIN" debug addr "${dev0_hex#0x}" | awk '/Bech32 Acc/{print $3}')
user=$(gaiad keys show user -a --keyring-backend test)
voucher="ibc/$(printf '%s' "transfer/channel-0/$DENOM" | shasum -a 256 | cut -d' ' -f1 | tr a-f A-F)"
vbal() { gaiad q bank balance "$user" "$voucher" -o json | jq -r '.balance.amount'; }

v0=$(vbal)
"$BIN" tx ibc-transfer transfer transfer channel-0 "$user" "${ONE}$DENOM" --from dev0 --keyring-backend "$KEYRING" \
  --home "$ROOT/.localnet/node0" --chain-id "$CHAIN_ID" --node tcp://localhost:26657 --gas 300000 \
  --fees "3000000000000000$DENOM" -y >/dev/null
assert "potato -> gaia: voucher $voucher minted" wait_until '[ "$(vbal)" != "$v0" ]'
assert "  voucher amount +1 POTATO" test "$(python3 -c "print(int('$(vbal)')-int('$v0'))")" = "$ONE"

b0=$(cast balance "$dev0_hex")
gaiad tx ibc-transfer transfer transfer channel-0 "$dev0" "${ONE}$voucher" --from user --keyring-backend test \
  --chain-id gaia-local --gas 250000 --fees 2000uatom -y >/dev/null
assert "gaia -> potato: 1 POTATO unescrowed to dev0 (EVM balance)" \
  wait_until '[ "$(python3 -c "print(int(\"$(cast balance "$dev0_hex")\") - $b0)")" = "$ONE" ]'
assert "voucher burned back to previous amount" wait_until '[ "$(vbal)" = "$v0" ]'
# From the EVM: (A) EOA calls the ICS-20 precompile directly, (B) through PotatoBridge
ts=$(( ($(date +%s) + 600) * 1000000000 ))  # unix nanoseconds
v1=$(vbal)
cast send 0x0000000000000000000000000000000000000802 \
  'transfer(string,string,string,uint256,address,string,(uint64,uint64),uint64,string)' \
  transfer channel-0 "$DENOM" "$ONE" "$dev0_hex" "$user" '(0,0)' "$ts" smoke --private-key "$DEV0_PRIVKEY" >/dev/null
assert "EVM (A): EOA -> ICS-20 precompile 0x0802 -> gaia" wait_until '[ "$(python3 -c "print(int(\"$(vbal)\") - $v1)")" = "$ONE" ]'

bridge=$(jq -r '.PotatoBridge // empty' "$ROOT/deployments/${NETWORK:-localnet}.json")
if [[ -n "$bridge" ]]; then
  v2=$(vbal)
  cast send "$bridge" 'bridge(string)' "$user" --value "$ONE" --private-key "$DEV0_PRIVKEY" >/dev/null
  assert "EVM (B): PotatoBridge.bridge{value} -> gaia" wait_until '[ "$(python3 -c "print(int(\"$(vbal)\") - $v2)")" = "$ONE" ]'
  assert "  bridge keeps no balance (all escrowed)" test "$(cast balance "$bridge")" = 0
fi
echo "ibc smoke test passed"
