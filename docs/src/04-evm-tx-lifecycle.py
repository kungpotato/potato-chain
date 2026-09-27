from diagram import Diagram

d = Diagram("04-evm-tx-lifecycle", 480, "EVM transaction lifecycle on potato-chain",
            "A wallet sends a signed raw transaction to JSON-RPC, which runs CheckTx into the EVM mempool and "
            "returns the hash. CometBFT asks the app to prepare a proposal from the mempool, validators vote "
            "with two thirds, FinalizeBlock executes the EVM tx, and the wallet polls the receipt.")

cols = {"client": 90, "rpc": 220, "pool": 350, "comet": 480, "app": 600}
heads = [("client", "cast/MetaMask", "gray"), ("rpc", "JSON-RPC :8545", "gray"),
         ("pool", "EVM mempool", "teal"), ("comet", "CometBFT x4", "teal"), ("app", "App + EVM", "teal")]
for k, label, ramp in heads:
    d.box(cols[k] - 57, 20, 114, 40, label, ramp=ramp)
    d.line(cols[k], 60, cols[k], 455, color="#B4B2A9", dash="3 4", arrow=False)


def msg(y, a, b, label, dash=None, lx=None):
    x1, x2 = cols[a], cols[b]
    s = 1 if x2 > x1 else -1
    d.line(x1 + 3 * s, y, x2 - 5 * s, y, color="#5F5E5A", dash=dash)
    d.text(lx or (x1 + x2) / 2, y - 7, label, anchor="middle")


msg(100, "client", "rpc", "1 sendRawTx")
msg(140, "rpc", "pool", "2 CheckTx")
msg(180, "rpc", "client", "3 tx hash", dash="4 3")
msg(220, "comet", "pool", "4 PrepareProposal")
d.box(420, 245, 120, 36, "5 vote ≥ ⅔", ramp="teal", small=True)
msg(320, "comet", "app", "6 FinalizeBlock")
msg(360, "app", "comet", "7 app hash", dash="4 3")
msg(400, "client", "rpc", "8 getReceipt")
msg(440, "rpc", "client", "9 status 1", dash="4 3")

if __name__ == "__main__":
    d.main()
