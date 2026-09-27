import { useState } from "react";
import { formatUnits, parseUnits } from "viem";
import { useConnection, useReadContract } from "wagmi";
import { addr } from "./chain";
import { erc20Abi, morphoAbi, oracleAbi } from "./abis";
import { useTx } from "./useTx";

const LLTV = 770000000000000000n; // must match the deployed market (DeployLending.s.sol)
const marketParams = {
  loanToken: addr.USDC, collateralToken: addr.WPOTATO, oracle: addr.PotatoOracle, irm: addr.LinearIrm, lltv: LLTV,
} as const;
const live = { refetchInterval: 2000 } as const;

type Action = "deposit" | "borrow" | "repay";

export function Lend() {
  const { address } = useConnection();
  const [amount, setAmount] = useState("10");
  const [action, setAction] = useState<Action>("deposit");
  const tx = useTx();

  const pos = useReadContract({ address: addr.Morpho, abi: morphoAbi, functionName: "position",
    args: address ? [addr.Market_WPOTATO_USDC, address] : undefined, query: { enabled: !!address, ...live } });
  const mkt = useReadContract({ address: addr.Morpho, abi: morphoAbi, functionName: "market", args: [addr.Market_WPOTATO_USDC], query: live });
  const price = useReadContract({ address: addr.PotatoOracle, abi: oracleAbi, functionName: "price", query: live });
  const token = action === "deposit" ? addr.WPOTATO : addr.USDC;
  const allowance = useReadContract({ address: token, abi: erc20Abi, functionName: "allowance",
    args: address ? [address, addr.Morpho] : undefined, query: { enabled: !!address && action !== "borrow", ...live } });

  const collateral = pos.data?.[2] ?? 0n;
  const borrowShares = pos.data?.[1] ?? 0n;
  // Morpho virtual shares: assets = shares * (totalAssets + 1) / (totalShares + 1e6), rounded up for debt
  const [, , totBorrowAssets = 0n, totBorrowShares = 0n] = mkt.data ?? [];
  const debt = borrowShares === 0n ? 0n : (borrowShares * (totBorrowAssets + 1n) + totBorrowShares + 1_000_000n - 1n) / (totBorrowShares + 1_000_000n);
  const collateralValue = price.data ? (collateral * price.data) / 10n ** 36n : 0n; // in USDC units
  const ltvBps = collateralValue > 0n ? (debt * 10_000n) / collateralValue : 0n;
  const maxBorrow = (collateralValue * LLTV) / 10n ** 18n;

  const dec = action === "deposit" ? 18 : 6;
  let amt = 0n;
  try { amt = parseUnits(amount || "0", dec); } catch { /* invalid */ }
  const needsApprove = action !== "borrow" && (allowance.data ?? 0n) < amt;

  function submit() {
    if (!address || amt === 0n) return;
    if (needsApprove) return tx.writeContract({ address: token, abi: erc20Abi, functionName: "approve", args: [addr.Morpho, amt] });
    if (action === "deposit")
      return tx.writeContract({ address: addr.Morpho, abi: morphoAbi, functionName: "supplyCollateral", args: [marketParams, amt, address, "0x"] });
    if (action === "borrow")
      return tx.writeContract({ address: addr.Morpho, abi: morphoAbi, functionName: "borrow", args: [marketParams, amt, 0n, address, address] });
    return tx.writeContract({ address: addr.Morpho, abi: morphoAbi, functionName: "repay", args: [marketParams, amt, 0n, address, "0x"] });
  }

  const label = needsApprove ? `Approve ${action === "deposit" ? "WPOTATO" : "USDC"}` : { deposit: "Deposit POTATO", borrow: "Borrow USDC", repay: "Repay USDC" }[action];
  const f = (v: bigint, d: number, p = 2) => Number(formatUnits(v, d)).toFixed(p);

  return (
    <section className="card">
      <h2>Lend (Morpho Blue · WPOTATO → USDC · LLTV 77%)</h2>
      {address && (
        <p data-testid="lend-position">
          collateral <b>{f(collateral, 18)}</b> POTATO (${f(collateralValue, 6)}) · debt <b>{f(debt, 6)}</b> USDC · LTV{" "}
          <b style={{ color: ltvBps > 7700n ? "var(--err)" : undefined }}>{(Number(ltvBps) / 100).toFixed(1)}%</b> · can borrow up to {f(maxBorrow, 6)} USDC
        </p>
      )}
      <div className="row">
        {(["deposit", "borrow", "repay"] as const).map((a) => (
          <button key={a} className={a === action ? "" : "ghost"} onClick={() => setAction(a)}>{a}</button>
        ))}
      </div>
      <div className="row" style={{ marginTop: 8 }}>
        <input aria-label="lend amount" value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" style={{ width: 120 }} />
        <span>{action === "deposit" ? "POTATO" : "USDC"}</span>
        <button onClick={submit} disabled={!address || amt === 0n || tx.busy}>{label}</button>
        {tx.status && <span className="muted" data-testid="lend-status">{tx.status}</span>}
      </div>
      {price.error && <p className="err">oracle unavailable (stale price?): borrowing is disabled on-chain — scripts/oracle_push.sh 2.0</p>}
    </section>
  );
}
