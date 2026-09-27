#!/usr/bin/env bash
# Generate homes for an N-validator localnet (default 4) under .localnet/node{0..N-1}.
# Run on the host; docker-compose.yml mounts each home into its container.
# See docs/03-localnet-docker.png.
#
#   scripts/localnet_init.sh        # wipes .localnet and regenerates
set -euo pipefail

. "$(dirname "$0")/lib.sh"
N="${VALIDATORS:-4}"
OUT="$ROOT/.localnet"
STAKE="1000000000000000000000$DENOM"          # 1000 potato self-delegation each -> equal power
BALANCE="100000000000000000000000$DENOM"      # 100k potato per validator account

make -C "$ROOT" build >/dev/null
rm -rf "$OUT"

home() { echo "$OUT/node$1"; }
pd() { local i="$1"; shift; "$BIN" "$@" --home "$(home "$i")"; }

# 1. each node gets its own consensus key (priv_validator_key.json), node key and operator key
for ((i = 0; i < N; i++)); do
  pd "$i" init "potato-val$i" --chain-id "$CHAIN_ID" >/dev/null 2>&1
  pd "$i" keys add "val$i" --keyring-backend "$KEYRING" --algo "$KEYALGO" >/dev/null 2>&1
done

# 2. node0 owns the draft genesis: denoms + all funded accounts
G0="$(home 0)/config/genesis.json"
patch_genesis_denoms "$G0"
for ((i = 0; i < N; i++)); do
  addr="$(pd "$i" keys show "val$i" -a --keyring-backend "$KEYRING")"
  pd 0 genesis add-genesis-account "$addr" "$BALANCE"
done
echo "$DEV0_MNEMONIC" | pd 0 keys add dev0 --recover --keyring-backend "$KEYRING" --algo "$KEYALGO" >/dev/null 2>&1
pd 0 genesis add-genesis-account dev0 "1000000000000000000000$DENOM" --keyring-backend "$KEYRING"

# 3. every validator signs a gentx against the same draft genesis; node0 collects them
mkdir -p "$(home 0)/config/gentx"
for ((i = 0; i < N; i++)); do
  [[ $i -gt 0 ]] && cp "$G0" "$(home "$i")/config/genesis.json"
  pd "$i" genesis gentx "val$i" "$STAKE" --gas-prices "10000000$DENOM" \
    --keyring-backend "$KEYRING" --chain-id "$CHAIN_ID" \
    --output-document "$(home 0)/config/gentx/val$i.json" >/dev/null 2>&1
done
pd 0 genesis collect-gentxs >/dev/null 2>&1
pd 0 genesis validate-genesis

# 4. same final genesis everywhere + full-mesh peers by docker hostname (nodeX:26656)
peers=()
for ((i = 0; i < N; i++)); do
  peers+=("$(pd "$i" comet show-node-id)@node$i:26656")
done
for ((i = 0; i < N; i++)); do
  h="$(home "$i")"
  [[ $i -gt 0 ]] && cp "$G0" "$h/config/genesis.json"
  mine=()
  for ((j = 0; j < N; j++)); do [[ $j -ne $i ]] && mine+=("${peers[j]}"); done
  tune_node_config "$h"
  # listen on all interfaces inside the container; private docker IPs are fine for dev
  sed -i.bak -e "s|^persistent_peers = .*|persistent_peers = \"$(IFS=,; echo "${mine[*]}")\"|" \
             -e 's|^laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' \
             -e 's|^addr_book_strict = true|addr_book_strict = false|' \
             -e 's|^allow_duplicate_ip = false|allow_duplicate_ip = true|' "$h/config/config.toml"
  sed -i.bak -e 's|address = "127.0.0.1:8545"|address = "0.0.0.0:8545"|' \
             -e 's|ws-address = "127.0.0.1:8546"|ws-address = "0.0.0.0:8546"|' \
             -e 's|address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|' \
             -e 's|address = "localhost:9090"|address = "0.0.0.0:9090"|' "$h/config/app.toml"
  rm -f "$h/config/"*.bak
done

echo "localnet ready: $N validators in $OUT (chain-id $CHAIN_ID)"
