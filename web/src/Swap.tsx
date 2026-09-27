import { useState } from "react";
import { formatUnits, parseUnits } from "viem";
import { useConnection, useReadContract } from "wagmi";
import { useQuery } from "@tanstack/react-query";
import { addr, INDEXER_URL } from "./chain";
import { erc20Abi, routerAbi } from "./abis";
import { useTx } from "./useTx";

const SLIPPAGE_BPS = 50n; // 0.5%
const deadline = () => BigInt(Math.floor(Date.now() / 1000) + 600);

type Dir = "sell" | "buy"; // sell = POTATO -> USDC, buy = USDC -> POTATO

export function Swap() {
  const { address } = useConnection();
  const [dir, setDir] = useState<Dir>("sell");
  const [amount, setAmount] = useState("1");
  const tx = useTx();

  const inDec = dir === "sell" ? 18 : 6;
  const outDec = dir === "sell" ? 6 : 18;
  const path = dir === "sell" ? [addr.WPOTATO, addr.USDC] : [addr.USDC, addr.WPOTATO];
  let amountIn = 0n;
  try { amountIn = parseUnits(amount || "0", inDec); } catch { /* invalid input -> no quote */ }

  const quote = useReadContract({
    address: addr.UniswapV2Router02, abi: routerAbi, functionName: "getAmountsOut",
    args: [amountIn, path], query: { enabled: amountIn > 0n, refetchInterval: 3000 },
  });
  const out = quote.data?.[1];
  const minOut = out ? out - (out * SLIPPAGE_BPS) / 10_000n : 0n;

  const allowance = useReadContract({
    address: addr.USDC, abi: erc20Abi, functionName: "allowance",
    args: address ? [address, addr.UniswapV2Router02] : undefined,
    query: { enabled: !!address && dir === "buy", refetchInterval: 2000 },
  });
  const needsApprove = dir === "buy" && (allowance.data ?? 0n) < amountIn;

  function submit() {
    if (!address || !out) return;
    if (dir === "sell") {
      tx.writeContract({ address: addr.UniswapV2Router02, abi: routerAbi, functionName: "swapExactETHForTokens",
        args: [minOut, path, address, deadline()], value: amountIn });
    } else if (needsApprove) {
      tx.writeContract({ address: addr.USDC, abi: erc20Abi, functionName: "approve", args: [addr.UniswapV2Router02, amountIn] });
    } else {
      tx.writeContract({ address: addr.UniswapV2Router02, abi: routerAbi, functionName: "swapExactTokensForETH",
        args: [amountIn, minOut, path, address, deadline()] });
    }
  }

  return (
    <section className="card">
      <h2>Swap</h2>
      <div className="row">
        <input aria-label="amount in" value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" />
        <span>{dir === "sell" ? "POTATO" : "USDC"}</span>
        <button className="ghost" onClick={() => setDir(dir === "sell" ? "buy" : "sell")} aria-label="flip direction">⇄</button>
        <span data-testid="swap-quote">≈ {out ? Number(formatUnits(out, outDec)).toFixed(dir === "sell" ? 4 : 6) : "–"} {dir === "sell" ? "USDC" : "POTATO"}</span>
      </div>
      <div className="row" style={{ marginTop: 8 }}>
        <button onClick={submit} disabled={!address || !out || tx.busy}>
          {needsApprove ? "Approve USDC" : dir === "sell" ? "Sell POTATO" : "Buy POTATO"}
        </button>
        <span className="muted">slippage 0.5%</span>
        {tx.status && <span className="muted" data-testid="swap-status">{tx.status}</span>}
      </div>
    </section>
  );
}

type Row = { side: string; amountPotato: string; amountUsdc: string; priceUsdc: number; txHash: string; timestamp: string };
const QUERY = `{ pools { items { priceUsdc reservePotato reserveUsdc swapCount } }
  swaps(orderBy: "timestamp", orderDirection: "desc", limit: 5) { items { side amountPotato amountUsdc priceUsdc txHash timestamp } } }`;

export function Market() {
  const q = useQuery({
    queryKey: ["ponder-market"],
    refetchInterval: 3000,
    queryFn: async () => {
      const r = await fetch(`${INDEXER_URL}/graphql`, {
        method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ query: QUERY }),
      });
      if (!r.ok) throw new Error(`indexer ${r.status}`);
      return (await r.json()).data as { pools: { items: { priceUsdc: number; reservePotato: string; reserveUsdc: string; swapCount: number }[] }; swaps: { items: Row[] } };
    },
  });
  const pool = q.data?.pools.items[0];
  return (
    <section className="card">
      <h2>Market (from Ponder indexer)</h2>
      {q.error && <p className="err">indexer offline: {(q.error as Error).message} (make indexer-dev)</p>}
      {pool && (
        <p data-testid="pool-price">
          1 POTATO = <b>{pool.priceUsdc.toFixed(4)}</b> USDC · liquidity {Number(formatUnits(BigInt(pool.reservePotato), 18)).toFixed(2)} POTATO /{" "}
          {Number(formatUnits(BigInt(pool.reserveUsdc), 6)).toFixed(2)} USDC · {pool.swapCount} swaps
        </p>
      )}
      <table>
        <tbody>
          {q.data?.swaps.items.map((s) => (
            <tr key={s.txHash + s.side}>
              <td>{s.side === "buy" ? "🟢 buy" : "🔴 sell"}</td>
              <td>{Number(formatUnits(BigInt(s.amountPotato), 18)).toFixed(4)} POTATO</td>
              <td>@ {s.priceUsdc.toFixed(4)}</td>
              <td className="muted">{new Date(Number(s.timestamp) * 1000).toLocaleTimeString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
