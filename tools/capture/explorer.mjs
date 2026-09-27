// Blockscout + Ponder screenshots (needs make explorer-up, indexer running).
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { launch, sleep, MEDIA, ROOT } from "./lib.mjs";

const EXPLORER = process.env.EXPLORER_URL ?? "http://localhost";
const INDEXER = process.env.INDEXER_URL ?? "http://localhost:42069";
const d = JSON.parse(readFileSync(join(ROOT, "deployments/localnet.json"), "utf8"));

const q = await fetch(`${INDEXER}/graphql`, {
  method: "POST", headers: { "content-type": "application/json" },
  body: JSON.stringify({ query: '{ swaps(orderBy: "timestamp", orderDirection: "desc", limit: 1) { items { txHash } } }' }),
}).then((r) => r.json());
const swapTx = q.data.swaps.items[0].txHash;

const { browser, page } = await launch(1280, 800);
async function shot(url, file, waitFor, { fullPage = false } = {}) {
  await page.goto(url, { waitUntil: "networkidle2", timeout: 60000 });
  if (waitFor) await page.waitForFunction((t) => document.body.innerText.includes(t), { timeout: 30000 }, waitFor).catch(() => console.warn(`! "${waitFor}" not found on ${url}`));
  await sleep(1500);
  await page.screenshot({ path: join(MEDIA, file), fullPage });
  console.log("captured", file);
}

try {
  await shot(`${EXPLORER}/`, "explorer-home.png", "Latest blocks");
  
  // swap tx without ads
  await page.goto(`${EXPLORER}/tx/${swapTx}`, { waitUntil: "networkidle2", timeout: 60000 });
  await page.waitForFunction((t) => document.body.innerText.includes(t), { timeout: 30000 }, "Success").catch(() => {});
  await page.evaluate(() => {
    const list = document.querySelector(".css-1kn4yyi");
    if (list) {
      const children = [...list.children];
      const idx = children.findIndex(c => c.innerText?.trim() === "Sponsored");
      if (idx !== -1) {
        children[idx + 1]?.remove();
        children[idx]?.remove();
      }
    }
  });
  await sleep(1000);
  await page.screenshot({ path: join(MEDIA, "explorer-swap-tx.png") });
  console.log("captured explorer-swap-tx.png");

  await shot(`${EXPLORER}/address/${d.Pair_WPOTATO_USDC}?tab=token_transfers`, "explorer-pool.png", "Token transfers");
  await shot(`${EXPLORER}/token/${d.WPOTATO}`, "explorer-wpotato.png", "Potato");

  // Ponder: GraphiQL with a real query result
  const query = `{\n  pools {\n    items {\n      priceUsdc\n      reservePotato\n      reserveUsdc\n      swapCount\n    }\n  }\n  swaps(orderBy: "timestamp", orderDirection: "desc", limit: 3) {\n    items {\n      side\n      amountPotato\n      amountUsdc\n      priceUsdc\n    }\n  }\n}`;
  await page.evaluateOnNewDocument((q) => {
    localStorage.setItem("graphiql:query", q);
    localStorage.setItem("graphiql:tabState", JSON.stringify({
      activeTabIndex: 0,
      tabs: [{
        id: "tab-0",
        hash: null,
        title: "DEX Query",
        query: q,
        variables: null,
        headers: null,
        operationName: null,
        response: null
      }]
    }));
  }, query);
  await page.goto(`${INDEXER}/graphql`, { waitUntil: "networkidle2" });
  await sleep(1500);
  await page.evaluate(() => {
    const playBtn = [...document.querySelectorAll("button")].find(b => b.innerText.includes("play icon") || b.getAttribute("aria-label")?.includes("Execute") || b.className.includes("execute-button"));
    if (playBtn) playBtn.click();
  });
  await sleep(2000);
  await page.screenshot({ path: join(MEDIA, "ponder-graphql.png") });
  console.log("captured ponder-graphql.png");
} finally {
  await browser.close();
}
