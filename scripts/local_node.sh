#!/usr/bin/env bash
# Single-validator potato-chain for local development.
# Steps match docs/02-single-node-bootstrap.png.
#
#   scripts/local_node.sh          # fresh chain (wipes $CHAINDIR)
#   scripts/local_node.sh --keep   # restart existing chain data
#
# DEV ONLY: keyring "test" stores keys unencrypted and the mnemonics below are public.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build/potatod"
CHAINDIR="${CHAINDIR:-$HOME/.potatod}"
CHAIN_ID="potato-1"      # keep in sync with config/chain.go
DENOM="apotato"
KEYRING="test"
KEYALGO="eth_secp256k1"
GENESIS="$CHAINDIR/config/genesis.json"
CONFIG_TOML="$CHAINDIR/config/config.toml"
APP_TOML="$CHAINDIR/config/app.toml"

# Well-known cosmos/evm dev mnemonics (public, never use outside localnet).
VAL_MNEMONIC="gesture inject test cycle original hollow east ridge hen combine junk child bacon zero hope comfort vacuum milk pitch cage oppose unhappy lunar seat"
DEV0_MNEMONIC="copper push brief egg scan entry inform record adjust fossil boss egg comic alien upon aspect dry avoid interest fury window hint race symptom" # 0xC6Fe5D33615a1C52c08018c47E8Bc53646A0E101

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

# 1. build binary (identity is compiled in: bech32 potato, home, evm-chain-id)
make -C "$ROOT" build >/dev/null

pd() { "$BIN" "$@" --home "$CHAINDIR"; }
patch_genesis() { jq "$1" "$GENESIS" >"$GENESIS.tmp" && mv "$GENESIS.tmp" "$GENESIS"; }

if [[ "${1:-}" != "--keep" ]]; then
  rm -rf "$CHAINDIR"
  pd config set client chain-id "$CHAIN_ID" >/dev/null
  pd config set client keyring-backend "$KEYRING" >/dev/null

  # 2. init: writes config.toml, app.toml, default genesis.json + validator consensus key
  echo "$VAL_MNEMONIC" | pd init potato-val0 --chain-id "$CHAIN_ID" --recover >/dev/null 2>&1

  # 3. genesis: every module that holds a denom must use apotato
  patch_genesis ".app_state.staking.params.bond_denom=\"$DENOM\"
    | .app_state.mint.params.mint_denom=\"$DENOM\"
    | .app_state.gov.params.min_deposit[0].denom=\"$DENOM\"
    | .app_state.gov.params.expedited_min_deposit[0].denom=\"$DENOM\"
    | .app_state.evm.params.evm_denom=\"$DENOM\"
    | .app_state.bank.denom_metadata=[{
        description: \"Native token of potato-chain\",
        denom_units: [{denom: \"$DENOM\", exponent: 0}, {denom: \"potato\", exponent: 18}],
        base: \"$DENOM\", display: \"potato\", name: \"Potato\", symbol: \"POTATO\"}]
    | .app_state.evm.params.active_static_precompiles=[
        \"0x0000000000000000000000000000000000000100\", \"0x0000000000000000000000000000000000000400\",
        \"0x0000000000000000000000000000000000000800\", \"0x0000000000000000000000000000000000000801\",
        \"0x0000000000000000000000000000000000000802\", \"0x0000000000000000000000000000000000000803\",
        \"0x0000000000000000000000000000000000000804\", \"0x0000000000000000000000000000000000000805\",
        \"0x0000000000000000000000000000000000000806\", \"0x0000000000000000000000000000000000000807\"]
    | .app_state.erc20.native_precompiles=[\"0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE\"]
    | .app_state.erc20.token_pairs=[{contract_owner: 1, erc20_address: \"0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE\", denom: \"$DENOM\", enabled: true}]
    | .consensus.params.block.max_gas=\"10000000\"
    | .app_state.gov.params.max_deposit_period=\"30s\"
    | .app_state.gov.params.voting_period=\"30s\"
    | .app_state.gov.params.expedited_voting_period=\"15s\""

  # 4. genesis accounts: validator + one dev account for MetaMask later
  echo "$VAL_MNEMONIC" | pd keys add val0 --recover --algo "$KEYALGO" >/dev/null 2>&1
  echo "$DEV0_MNEMONIC" | pd keys add dev0 --recover --algo "$KEYALGO" >/dev/null 2>&1
  pd genesis add-genesis-account val0 "100000000000000000000000000$DENOM" --keyring-backend "$KEYRING"
  pd genesis add-genesis-account dev0 "1000000000000000000000$DENOM" --keyring-backend "$KEYRING"

  # 5. gentx: val0 self-delegates 1000 potato -> becomes the only validator
  pd genesis gentx val0 "1000000000000000000000$DENOM" --gas-prices "10000000$DENOM" \
    --keyring-backend "$KEYRING" --chain-id "$CHAIN_ID" >/dev/null 2>&1
  pd genesis collect-gentxs >/dev/null 2>&1
  pd genesis validate-genesis

  # faster blocks for dev (~1s) + enable REST/gRPC/JSON-RPC
  sed -i.bak -e 's/timeout_commit = "5s"/timeout_commit = "1s"/' \
             -e 's/timeout_propose = "3s"/timeout_propose = "2s"/' \
             -e 's/type = "flood"/type = "app"/' "$CONFIG_TOML"  # EVM mempool needs app-side mempool
  sed -i.bak 's/enable = false/enable = true/g' "$APP_TOML"
fi

# 6. start: CometBFT loads genesis -> InitChain -> FinalizeBlock loop
exec "$BIN" start --home "$CHAINDIR" \
  --chain-id "$CHAIN_ID" \
  --minimum-gas-prices "0$DENOM" \
  --evm.min-tip 0 \
  --json-rpc.api eth,txpool,net,web3,debug \
  --log_level info
