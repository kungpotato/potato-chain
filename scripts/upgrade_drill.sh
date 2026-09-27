#!/usr/bin/env bash
# Governance-driven software upgrade drill on the 4-validator docker localnet (docs/12-gov-upgrade.png):
#   propose potato-v2 @ H -> 4x vote yes -> passed -> all nodes halt at H -> swap to :v2 image -> resume.
# Pre-req: `docker build -t potato-chain/potatod:v2 .` from a commit that has the potato-v2 handler,
# while the running containers are still on the old image (without it).
# One-shot per chain: after it passes the chain runs v2 (gasLimit 30M); re-run on a fresh
# `make localnet-init` started from a pre-potato-v2 image.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export PATH="$HOME/.foundry/bin:$PATH" ETH_RPC_URL="${RPC:-http://localhost:8545}"
PLAN=potato-v2
NODE=tcp://localhost:26657
N=4
step() { printf '\n== %s\n' "$*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
height() { curl -sf localhost:26657/status | jq -r .result.sync_info.latest_block_height; }
pd() { local i="$1"; shift; "$BIN" "$@" --home "$ROOT/.localnet/node$i" --keyring-backend "$KEYRING" --chain-id "$CHAIN_ID" --node "$NODE"; }
# poll <max-seconds> <shell condition>
poll() { local max="$1" cond="$2" t=0; until eval "$cond"; do (( t >= max )) && return 1; sleep 2; t=$((t + 2)); done; }

docker image inspect potato-chain/potatod:v2 >/dev/null 2>&1 || fail "build the v2 image first"
[[ "$(cast block latest --field gasLimit)" == 10000000 ]] || fail "expected pre-upgrade gasLimit 10M"

step "1. propose $PLAN"
H=$(( $(height) + 70 ))   # 30s voting + margin at ~1s blocks
pd 0 tx upgrade software-upgrade "$PLAN" --upgrade-height "$H" --title "potato-v2" \
  --summary "raise block max gas to 30M" --deposit "10000000$DENOM" --no-validate \
  --from val0 --gas 400000 --fees "4000000000000000$DENOM" -y >/dev/null
poll 20 '[ -n "$(pd 0 q gov proposals --output json 2>/dev/null | jq -r ".proposals[-1].id // empty")" ]' || fail "proposal not found"
PID=$(pd 0 q gov proposals --output json | jq -r '.proposals[-1].id')
echo "proposal #$PID, upgrade height $H (now $(height))"

step "2. vote yes from $N validators"
for ((i = 0; i < N; i++)); do
  pd "$i" tx gov vote "$PID" yes --from "val$i" --gas 200000 --fees "2000000000000000$DENOM" -y >/dev/null
done

step "3. wait for voting period (30s)"
poll 60 '[ "$(pd 0 q gov proposal "$PID" --output json | jq -r .proposal.status)" = PROPOSAL_STATUS_PASSED ]' \
  || fail "proposal did not pass: $(pd 0 q gov proposal "$PID" --output json | jq -c '.proposal | {status, final_tally_result}')"
echo "passed; scheduled plan: $(pd 0 q upgrade plan --output json | jq -c '{name: .plan.name, height: .plan.height}')"

step "4. wait for the chain to halt at $H"
poll 120 '[ "$(docker logs potato-node0 2>&1 | grep -c "UPGRADE \"$PLAN\" NEEDED")" -gt 0 ]' || fail "no UPGRADE NEEDED at $H (height $(height))"
halted=$(height || echo "?")
echo "halted: last committed block $halted; every node logs UPGRADE \"$PLAN\" NEEDED:"
for ((i = 0; i < N; i++)); do printf '  node%s %s\n' "$i" "$(docker logs "potato-node$i" 2>&1 | grep -c "UPGRADE \"$PLAN\" NEEDED") times"; done

step "5. swap binary: recreate containers on potato-chain/potatod:v2"
POTATOD_TAG=v2 docker-compose -f "$ROOT/docker-compose.yml" up -d 2>&1 | tail -1
poll 90 '[ "$(height 2>/dev/null || echo 0)" -gt "$H" ]' || fail "chain did not resume past $H"

step "6. verify"
applied=$(pd 0 q upgrade applied "$PLAN" --output json | jq -r '.height // .header.height // empty')
gas=$(cast block latest --field gasLimit)
echo "resumed at $(height); applied $PLAN at height $applied; block gasLimit $gas"
[[ "$gas" == 30000000 ]] || fail "gasLimit not raised"
# `|| true`: grep -m1 closes the pipe early -> docker logs gets SIGPIPE (141) under pipefail
docker logs potato-node0 2>&1 | grep -m1 'potato-v2: raised block max gas' | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-160 || true
# make :dev follow the upgraded binary so a plain `make localnet-up` never restarts the old one
docker tag potato-chain/potatod:v2 potato-chain/potatod:dev
echo "upgrade drill passed"
