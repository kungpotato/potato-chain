// DEV ONLY burner wallet: a throwaway key in sessionStorage, exposed as an EIP-1193 provider so
// wagmi's `injected` connector can use it. Lets us click through the app without MetaMask
// (e.g. in an automated browser). Enabled only when VITE_DEV_BURNER=1.
import { createWalletClient, createPublicClient, http, type EIP1193RequestFn, type Hex } from "viem";
import { generatePrivateKey, privateKeyToAccount } from "viem/accounts";
import { potato, RPC_URL } from "./chain";

const KEY = "potato.burner.pk";

function loadKey(): Hex {
  try {
    const existing = sessionStorage.getItem(KEY) as Hex | null;
    if (existing) return existing;
    const pk = generatePrivateKey();
    sessionStorage.setItem(KEY, pk);
    return pk;
  } catch {
    return generatePrivateKey(); // storage blocked: key lives for this page load only
  }
}

export function burnerProvider() {
  const account = privateKeyToAccount(loadKey());
  const wallet = createWalletClient({ account, chain: potato, transport: http(RPC_URL) });
  const pub = createPublicClient({ chain: potato, transport: http(RPC_URL) });

  const request = (async ({ method, params }: { method: string; params?: unknown[] }) => {
    switch (method) {
      case "eth_accounts":
      case "eth_requestAccounts":
        return [account.address];
      case "eth_chainId":
        return `0x${potato.id.toString(16)}`;
      case "wallet_switchEthereumChain":
      case "wallet_addEthereumChain":
        return null;
      case "personal_sign":
        return account.signMessage({ message: { raw: (params as [Hex])[0] } });
      case "eth_sendTransaction": {
        const [tx] = params as [{ to?: Hex; data?: Hex; value?: Hex; gas?: Hex }];
        const value = tx.value ? BigInt(tx.value) : undefined;
        // Always pass an explicit gas limit: otherwise viem fills the tx via eth_fillTransaction,
        // which on cosmos/evm v0.7.3 estimates against block 0 (docs/known-issues.md) and returns
        // intrinsic gas only -> contract calls run out of gas.
        // Raw eth_estimateGas on purpose: viem's estimateGas with a local account also goes through
        // eth_fillTransaction and inherits the same bad number.
        const estimate = async () =>
          BigInt(await pub.request({
            method: "eth_estimateGas",
            params: [{ from: account.address, to: tx.to, data: tx.data, value: tx.value }],
          } as never));
        const gas = tx.gas ? BigInt(tx.gas) : ((await estimate()) * 12n) / 10n;
        return wallet.sendTransaction({ to: tx.to, data: tx.data, value, gas });
      }
      default:
        return pub.request({ method, params } as never);
    }
  }) as EIP1193RequestFn;

  return { request, on: () => {}, removeListener: () => {} };
}
