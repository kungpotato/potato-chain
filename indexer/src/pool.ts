import { ponder } from "ponder:registry";
import { pool, swap } from "ponder:schema";

import { deployments } from "../ponder.config";

// Uniswap v2 orders a pair's tokens by address; lowercase hex compares like the numbers.
const usdcIsToken0 = deployments.USDC.toLowerCase() < deployments.WPOTATO.toLowerCase();

const POTATO_DECIMALS = 1e18;
const USDC_DECIMALS = 1e6;

/** Map (token0, token1) amounts onto (potato, usdc). */
function split<T>(a0: T, a1: T): { potato: T; usdc: T } {
  return usdcIsToken0 ? { potato: a1, usdc: a0 } : { potato: a0, usdc: a1 };
}

function price(potato: bigint, usdc: bigint): number {
  if (potato === 0n) return 0;
  return Number(usdc) / USDC_DECIMALS / (Number(potato) / POTATO_DECIMALS);
}

ponder.on("Pair:Sync", async ({ event, context }) => {
  const r = split(event.args.reserve0, event.args.reserve1);
  const values = {
    reservePotato: r.potato,
    reserveUsdc: r.usdc,
    priceUsdc: price(r.potato, r.usdc),
    updatedBlock: event.block.number,
  };
  await context.db
    .insert(pool)
    .values({ id: event.log.address, swapCount: 0, ...values })
    .onConflictDoUpdate(values);
});

ponder.on("Pair:Swap", async ({ event, context }) => {
  const { amount0In, amount1In, amount0Out, amount1Out, to } = event.args;
  const inAmt = split(amount0In, amount1In);
  const outAmt = split(amount0Out, amount1Out);
  const amountPotato = inAmt.potato + outAmt.potato;
  const amountUsdc = inAmt.usdc + outAmt.usdc;

  await context.db.insert(swap).values({
    id: `${event.transaction.hash}-${event.log.logIndex}`,
    pool: event.log.address,
    side: outAmt.potato > 0n ? "buy" : "sell",
    trader: event.transaction.from,
    recipient: to,
    amountPotato,
    amountUsdc,
    priceUsdc: price(amountPotato, amountUsdc),
    blockNumber: event.block.number,
    timestamp: event.block.timestamp,
    txHash: event.transaction.hash,
  });

  // Sync is emitted before Swap in the same tx, so the pool row exists.
  await context.db.update(pool, { id: event.log.address }).set((row) => ({ swapCount: row.swapCount + 1 }));
});
