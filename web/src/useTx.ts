import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";

/** writeContract + wait for receipt, with one status string for the UI. */
export function useTx() {
  const write = useWriteContract();
  const receipt = useWaitForTransactionReceipt({ hash: write.data });
  const status = write.isPending
    ? "confirm in wallet…"
    : receipt.isLoading
      ? "waiting for block…"
      : receipt.isSuccess
        ? receipt.data.status === "success" ? "✅ confirmed" : "❌ reverted"
        : receipt.error // wagmi rejects reverted receipts (after fetching the revert reason)
          ? `❌ reverted: ${receipt.error.message.split("\n")[0]}`
          : write.error
          ? `❌ ${write.error.message.split("\n")[0]}`
          : undefined;
  return { ...write, receipt, status, busy: write.isPending || receipt.isLoading };
}
