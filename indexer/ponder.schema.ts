import { index, onchainTable } from "ponder";

// Latest state of each pool (upserted on every Sync).
export const pool = onchainTable("pool", (t) => ({
  id: t.hex().primaryKey(), // pair address
  reservePotato: t.bigint().notNull(), // 18 decimals
  reserveUsdc: t.bigint().notNull(), // 6 decimals
  priceUsdc: t.doublePrecision().notNull(), // USDC per 1 POTATO (display only, not for accounting)
  swapCount: t.integer().notNull(),
  updatedBlock: t.bigint().notNull(),
}));

// One row per Swap event.
export const swap = onchainTable(
  "swap",
  (t) => ({
    id: t.text().primaryKey(), // `${txHash}-${logIndex}`
    pool: t.hex().notNull(),
    side: t.text().notNull(), // "buy" = POTATO out of pool, "sell" = POTATO into pool
    trader: t.hex().notNull(), // tx.from (the router is Swap.sender)
    recipient: t.hex().notNull(),
    amountPotato: t.bigint().notNull(),
    amountUsdc: t.bigint().notNull(),
    priceUsdc: t.doublePrecision().notNull(), // execution price of this swap
    blockNumber: t.bigint().notNull(),
    timestamp: t.bigint().notNull(),
    txHash: t.hex().notNull(),
  }),
  (table) => ({
    timeIdx: index().on(table.timestamp),
    traderIdx: index().on(table.trader),
  }),
);
