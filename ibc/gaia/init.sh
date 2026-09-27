#!/bin/sh
# Runs INSIDE the gaia container. Creates a single-validator gaia-local on first start, then starts it.
# DEV ONLY: keyring "test", mnemonics written in plain text to $HOME/mnemonics for Hermes.
set -eu
H=/root/.gaia
CHAIN_ID=gaia-local
DENOM=uatom

# Marker is written last: a half-finished init (e.g. a failed gentx) is wiped and redone.
if [ ! -f "$H/.initialized" ]; then
  rm -rf "$H"/* "$H"/.[!.]* 2>/dev/null || true
  gaiad init gaia-val --chain-id "$CHAIN_ID" --home "$H" >/dev/null 2>&1
  mkdir -p "$H/mnemonics"
  for k in val relayer user; do
    gaiad keys add "$k" --keyring-backend test --home "$H" --output json 2>/dev/null | sed -n 's/.*"mnemonic":"\([^"]*\)".*/\1/p' > "$H/mnemonics/$k.txt"
    gaiad genesis add-genesis-account "$k" 1000000000000$DENOM --keyring-backend test --home "$H"
  done

  G="$H/config/genesis.json"
  sed -i "s/\"stake\"/\"$DENOM\"/g" "$G"                                      # every denom field
  sed -i 's/"min_base_gas_price": "1.000000000000000000"/"min_base_gas_price": "0.001000000000000000"/' "$G"
  # gov requires expedited < regular voting period
  sed -i -e 's/"voting_period": "[^"]*"/"voting_period": "30s"/' \
         -e 's/"expedited_voting_period": "[^"]*"/"expedited_voting_period": "15s"/' "$G"

  gaiad genesis gentx val 100000000000$DENOM --chain-id "$CHAIN_ID" --keyring-backend test --home "$H"
  gaiad genesis collect-gentxs --home "$H" >/dev/null
  gaiad genesis validate-genesis --home "$H"

  sed -i -e 's/timeout_commit = "5s"/timeout_commit = "1s"/' \
         -e 's#laddr = "tcp://127.0.0.1:26657"#laddr = "tcp://0.0.0.0:26657"#' "$H/config/config.toml"
  sed -i -e 's#address = "localhost:9090"#address = "0.0.0.0:9090"#' \
         -e "s/minimum-gas-prices = \"\"/minimum-gas-prices = \"0.001$DENOM\"/" "$H/config/app.toml"
  touch "$H/.initialized"
fi

exec gaiad start --home "$H"
