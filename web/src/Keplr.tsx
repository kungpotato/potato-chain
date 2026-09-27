import { useState } from "react";
import { addr, potato, RPC_URL } from "./chain";

// Minimal slice of the Keplr injected API (avoids a @keplr-wallet/types dependency).
type KeplrKey = { bech32Address: string; ethereumHexAddress?: string; name: string };
type Keplr = {
  experimentalSuggestChain(info: unknown): Promise<void>;
  enable(chainId: string): Promise<void>;
  getKey(chainId: string): Promise<KeplrKey>;
};
declare global {
  interface Window { keplr?: Keplr }
}

const COSMOS_CHAIN_ID = "potato-1"; // keep in sync with config/chain.go
const currency = { coinDenom: "POTATO", coinMinimalDenom: "apotato", coinDecimals: 18 };

// cosmos/evm chains need coin type 60 + eth-address-gen/eth-key-sign so Keplr derives the SAME
// key as MetaMask (Ethereum HD path, keccak address); otherwise it would show a different account.
export const chainInfo = {
  chainId: COSMOS_CHAIN_ID,
  chainName: "Potato Localnet",
  rpc: import.meta.env.VITE_COMET_RPC_URL ?? "http://localhost:26657",
  rest: import.meta.env.VITE_REST_URL ?? "http://localhost:1317",
  bip44: { coinType: 60 },
  bech32Config: {
    bech32PrefixAccAddr: "potato", bech32PrefixAccPub: "potatopub",
    bech32PrefixValAddr: "potatovaloper", bech32PrefixValPub: "potatovaloperpub",
    bech32PrefixConsAddr: "potatovalcons", bech32PrefixConsPub: "potatovalconspub",
  },
  currencies: [currency],
  feeCurrencies: [{ ...currency, gasPriceStep: { low: 10_000_000, average: 25_000_000, high: 40_000_000 } }],
  stakeCurrency: currency,
  features: ["eth-address-gen", "eth-key-sign"],
  evm: { chainId: potato.id, rpc: RPC_URL },
};

export function KeplrPanel() {
  const [key, setKey] = useState<KeplrKey>();
  const [err, setErr] = useState<string>();

  async function connect() {
    setErr(undefined);
    const keplr = window.keplr;
    if (!keplr) return setErr("Keplr extension not found — install it, or use MetaMask above");
    try {
      await keplr.experimentalSuggestChain(chainInfo);
      await keplr.enable(COSMOS_CHAIN_ID);
      setKey(await keplr.getKey(COSMOS_CHAIN_ID));
    } catch (e) {
      setErr((e as Error).message);
    }
  }

  return (
    <section className="card">
      <h2>Keplr (Cosmos view of the same account)</h2>
      <div className="row">
        <button className="ghost" onClick={connect}>Add Potato to Keplr &amp; connect</button>
        {key && <code data-testid="keplr-addr">{key.bech32Address}</code>}
        {key?.ethereumHexAddress && <code className="muted">{key.ethereumHexAddress}</code>}
      </div>
      {err && <p className="err" data-testid="keplr-err">{err}</p>}
      <p className="muted">WPOTATO ({addr.WPOTATO.slice(0, 8)}…) is the same balance Keplr shows as POTATO.</p>
    </section>
  );
}
