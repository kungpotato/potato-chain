#!/usr/bin/env bash
# Single-validator potato-chain for local development.
# Steps match docs/02-single-node-bootstrap.png.
#
#   scripts/local_node.sh          # fresh chain (wipes $CHAINDIR)
#   scripts/local_node.sh --keep   # restart existing chain data
#
# DEV ONLY: keyring "test" stores keys unencrypted and the mnemonics below are public.
set -euo pipefail

. "$(dirname "$0")/lib.sh"
CHAINDIR="${CHAINDIR:-$HOME/.potatod}"

# Well-known cosmos/evm validator mnemonic (public, never use outside localnet).
VAL_MNEMONIC="gesture inject test cycle original hollow east ridge hen combine junk child bacon zero hope comfort vacuum milk pitch cage oppose unhappy lunar seat"

# 1. build binary (identity is compiled in: bech32 potato, home, evm-chain-id)
make -C "$ROOT" build >/dev/null

pd() { "$BIN" "$@" --home "$CHAINDIR"; }

if [[ "${1:-}" != "--keep" ]]; then
  rm -rf "$CHAINDIR"
  pd config set client chain-id "$CHAIN_ID" >/dev/null
  pd config set client keyring-backend "$KEYRING" >/dev/null

  # 2. init: writes config.toml, app.toml, default genesis.json + validator consensus key
  echo "$VAL_MNEMONIC" | pd init potato-val0 --chain-id "$CHAIN_ID" --recover >/dev/null 2>&1

  # 3. genesis: every module that holds a denom must use apotato
  patch_genesis_denoms "$CHAINDIR/config/genesis.json"

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

  tune_node_config "$CHAINDIR"
fi

# 6. start: CometBFT loads genesis -> InitChain -> FinalizeBlock loop
exec "$BIN" start --home "$CHAINDIR" \
  --chain-id "$CHAIN_ID" \
  --minimum-gas-prices "0$DENOM" \
  --evm.min-tip 0 \
  --json-rpc.api eth,txpool,net,web3,debug \
  --log_level info
