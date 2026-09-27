import { useState } from "react";
import { formatUnits } from "viem";
import { useBalance, useConnect, useConnection, useConnectors, useDisconnect, useReadContract, useSwitchChain } from "wagmi";
import { addr, potato } from "./chain";
import { erc20Abi } from "./abis";
import { Market, Swap } from "./Swap";

function short(a: string) {
  return `${a.slice(0, 6)}…${a.slice(-4)}`;
}

function Wallet() {
  const { address, chainId, status } = useConnection();
  const connectors = useConnectors();
  const { connect, error } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain } = useSwitchChain();

  if (status !== "connected" || !address) {
    return (
      <div className="row">
        {connectors.map((c) => (
          <button key={c.uid} onClick={() => connect({ connector: c, chainId: potato.id })}>
            Connect {c.name}
          </button>
        ))}
        {error && <p className="err">{error.message}</p>}
      </div>
    );
  }
  return (
    <div className="row">
      <code title={address}>{short(address)}</code>
      {chainId !== potato.id && <button onClick={() => switchChain({ chainId: potato.id })}>Switch to Potato</button>}
      <button className="ghost" onClick={() => disconnect()}>Disconnect</button>
    </div>
  );
}

function Balances() {
  const { address } = useConnection();
  const potatoBal = useBalance({ address, query: { enabled: !!address, refetchInterval: 2000 } });
  const usdc = useReadContract({
    address: addr.USDC, abi: erc20Abi, functionName: "balanceOf", args: address ? [address] : undefined,
    query: { enabled: !!address, refetchInterval: 2000 },
  });
  if (!address) return null;
  return (
    <section className="card">
      <h2>Balances</h2>
      <p data-testid="bal-potato">{potatoBal.data ? formatUnits(potatoBal.data.value, 18) : "…"} POTATO</p>
      <p data-testid="bal-usdc">{usdc.data !== undefined ? formatUnits(usdc.data, 6) : "…"} USDC</p>
    </section>
  );
}

function Faucet() {
  const { address } = useConnection();
  const [msg, setMsg] = useState<string>();
  const [busy, setBusy] = useState(false);
  if (!address) return null;
  async function drip() {
    setBusy(true);
    try {
      const r = await fetch("/api/faucet", { method: "POST", body: JSON.stringify({ address }) });
      const j = await r.json();
      setMsg(r.ok ? `sent ${j.amount} POTATO (${j.hash.slice(0, 10)}…)` : j.error);
    } catch {
      setMsg("faucet unavailable (only in make web-dev)");
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="card">
      <h2>Faucet</h2>
      <div className="row">
        <button onClick={drip} disabled={busy}>{busy ? "sending…" : "Get 10 POTATO"}</button>
        {msg && <span className="muted" data-testid="faucet-msg">{msg}</span>}
      </div>
    </section>
  );
}

export default function App() {
  return (
    <main>
      <header>
        <h1>🥔 Potato Localnet</h1>
        <Wallet />
      </header>
      <Balances />
      <Faucet />
      <Market />
      <Swap />
    </main>
  );
}
