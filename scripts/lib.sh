# Shared helpers for potato-chain dev scripts. Source it: . "$(dirname "$0")/lib.sh"
# DEV ONLY: keyring "test" stores keys unencrypted.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${BIN:-$ROOT/build/potatod}"
CHAIN_ID="potato-1"      # keep in sync with config/chain.go
DENOM="apotato"
KEYRING="test"
KEYALGO="eth_secp256k1"

# Well-known cosmos/evm dev mnemonic (public, never use outside localnet).
DEV0_MNEMONIC="copper push brief egg scan entry inform record adjust fossil boss egg comic alien upon aspect dry avoid interest fury window hint race symptom" # 0xC6Fe5D33615a1C52c08018c47E8Bc53646A0E101
DEV0_PRIVKEY="0x88cbead91aee890d27bf06e003ade3d4e952427e88f88d31d61d3ef5e5d54305" # same dev0, public (gitleaks:allow)

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

# patch_genesis_denoms <genesis.json>: every module that holds a denom must use apotato.
patch_genesis_denoms() {
  local g="$1"
  jq ".app_state.staking.params.bond_denom=\"$DENOM\"
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
    | .app_state.gov.params.expedited_voting_period=\"15s\"" "$g" >"$g.tmp" && mv "$g.tmp" "$g"
}

# tune_node_config <home>: ~1s blocks, app-side mempool (required by EVM mempool), all APIs on.
tune_node_config() {
  local home="$1"
  sed -i.bak -e 's/timeout_commit = "5s"/timeout_commit = "1s"/' \
             -e 's/timeout_propose = "3s"/timeout_propose = "2s"/' \
             -e 's/type = "flood"/type = "app"/' "$home/config/config.toml"
  sed -i.bak 's/enable = false/enable = true/g' "$home/config/app.toml"
  rm -f "$home/config/"*.bak
}
