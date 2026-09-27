import { useState } from "react";
import { parseEther } from "viem";
import { useConnection, useReadContract } from "wagmi";
import { addr } from "./chain";
import { bridgeAbi } from "./abis";
import { useTx } from "./useTx";

// Cosmos bech32 account on the counterparty (gaia-local uses the "cosmos" prefix).
const COSMOS_ADDR = /^cosmos1[02-9ac-hj-np-z]{38}$/;

export function Bridge() {
  const { address } = useConnection();
  const [to, setTo] = useState("");
  const [amount, setAmount] = useState("1");
  const tx = useTx();
  const channel = useReadContract({ address: addr.PotatoBridge, abi: bridgeAbi, functionName: "channel" });

  let value = 0n;
  try { value = parseEther(amount || "0"); } catch { /* invalid -> disabled */ }
  const validTo = COSMOS_ADDR.test(to.trim());

  return (
    <section className="card">
      <h2>Bridge → gaia-local (IBC {channel.data ?? "…"})</h2>
      <p className="muted">PotatoBridge escrows POTATO via the ICS-20 precompile; Hermes relays it (make relayer).</p>
      <div className="row">
        <input aria-label="cosmos receiver" placeholder="cosmos1…" value={to} onChange={(e) => setTo(e.target.value)} style={{ flex: 1 }} />
        <input aria-label="bridge amount" value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" style={{ width: 90 }} />
        <span>POTATO</span>
      </div>
      {to && !validTo && <p className="err">receiver must be a cosmos1… address</p>}
      <div className="row" style={{ marginTop: 8 }}>
        <button
          disabled={!address || !validTo || value === 0n || tx.busy}
          onClick={() => tx.writeContract({ address: addr.PotatoBridge, abi: bridgeAbi, functionName: "bridge", args: [to.trim()], value })}
        >
          Bridge
        </button>
        {tx.status && <span className="muted" data-testid="bridge-status">{tx.status}</span>}
      </div>
    </section>
  );
}
