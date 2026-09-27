# Known issues

## eth_getLogs with `fromBlock: 0` duplicates the latest block's logs (cosmos/evm v0.7.3)

**Symptom**: for ~1 block after a tx, `eth_getLogs({fromBlock: "0x0", toBlock: "latest"})`
returns the newest log twice. `fromBlock: "0x1"` is always correct.

**Root cause** (upstream, not our code):
- `rpc/namespaces/ethereum/eth/filters/filters.go` `Filter.Logs` maps `"earliest"` to 1 but lets a
  numeric `0` through, so the loop starts at height 0.
- `rpc/backend/comet.go` `CometBlockResultByNumber` turns height `0` into `nil`, which CometBFT
  treats as **latest** -> the tip block is scanned twice.

**Repro**: send a tx that emits an event, then immediately compare `fromBlock` `0x0` vs `0x1`.

**Workaround**: clients/indexers start at block 1 (or the contract's deploy block).
**Fix (upstream)**: in `Filter.Logs`, clamp `from` to 1 after resolving it.

## eth_fillTransaction estimates gas against block 0 (cosmos/evm v0.7.3)

**Symptom**: txs sent by viem with a *local* account (burner/private-key wallets) run out of gas:
`approve` gets gas limit 22490 (= intrinsic + calldata floor) and reverts with
`ReentrancySentryOOG`. MetaMask and `cast` are unaffected (they call `eth_estimateGas` at latest).

**Root cause** (upstream): recent viem prepares txs via `eth_fillTransaction`; cosmos/evm's
`rpc/backend/call_tx.go` `SetTxDefaults` estimates with `NewBlockNumber(big.NewInt(0))`, i.e. against
genesis state where the target contract has no code, so only intrinsic gas is counted.
viem's `estimateGas({ account: localAccount })` goes through the same path.

**Repro**: `eth_fillTransaction` vs `eth_estimateGas` for USDC `approve` -> 22490 vs 46330.

**Workaround**: pass an explicit `gas` from a raw `eth_estimateGas` call (web/src/burner.ts).
**Fix (upstream)**: estimate at the latest block (`rpc.LatestBlockNumber`) like go-ethereum.
