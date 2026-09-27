// Frontend demo GIFs (needs: make web-dev, localnet, deployments, Ponder, Hermes).
import { join } from "node:path";
import { launch, record, toGif, clickText, waitText, sleep, MEDIA } from "./lib.mjs";

const URL = process.env.WEB_URL ?? "http://localhost:5173";
const GAIA_USER = process.env.GAIA_USER ?? "cosmos1ltn66ayhh7thvmms0wt09ywuyaqdhwm0dppahq";
const { browser, page } = await launch(1000, 700);

async function typeInto(label, value) {
  const sel = `input[aria-label="${label}"]`;
  await page.$eval(sel, (el) => el.scrollIntoView({ block: "center" }));
  await page.click(sel, { clickCount: 3 });
  await page.type(sel, value, { delay: 60 });
}
async function waitTestId(id, text, timeout = 30000) {
  await page.waitForFunction((id, t) => document.querySelector(`[data-testid=${id}]`)?.innerText.includes(t), { timeout, polling: 250 }, id, text);
}
async function scrollTo(heading) {
  await page.evaluate((h) => [...document.querySelectorAll("h2")].find((x) => x.textContent.includes(h))?.scrollIntoView({ block: "start" }), heading);
  await sleep(400);
}

try {
  await page.goto(URL, { waitUntil: "networkidle0" });
  await waitText(page, "Balances");

  // 1. faucet + swap
  const swap = await record(page, async () => {
    await sleep(600);
    await clickText(page, "Get 10 POTATO");
    await waitTestId("faucet-msg", "sent 10 POTATO");
    await waitTestId("bal-potato", "10");
    await sleep(800);
    await scrollTo("Market");
    await typeInto("amount in", "2");
    await sleep(1200);
    await clickText(page, "Sell POTATO");
    await waitTestId("swap-status", "confirmed");
    await sleep(2500); // Ponder picks up the swap
    await scrollTo("Market");
    await sleep(1200);
  });
  toGif(swap, join(MEDIA, "web-faucet-swap.gif"), { width: 820 });

  // 2. lending: deposit collateral, borrow
  const lend = await record(page, async () => {
    await scrollTo("Lend");
    await typeInto("lend amount", "5");
    await clickText(page, "Approve WPOTATO");
    await waitText(page, "Deposit POTATO");
    await clickText(page, "Deposit POTATO");
    await waitTestId("lend-position", "collateral 5.00");
    await sleep(800);
    await clickText(page, "borrow");
    await typeInto("lend amount", "4");
    await clickText(page, "Borrow USDC");
    await waitTestId("lend-position", "debt 4.00");
    await sleep(1500);
  });
  toGif(lend, join(MEDIA, "web-lend.gif"), { width: 820 });

  // 3. IBC bridge
  const bridge = await record(page, async () => {
    await scrollTo("Bridge");
    await typeInto("cosmos receiver", GAIA_USER);
    await typeInto("bridge amount", "1");
    await clickText(page, "Bridge", "section:has(input[aria-label='cosmos receiver'])");
    await waitTestId("bridge-status", "confirmed");
    await sleep(1500);
  });
  toGif(bridge, join(MEDIA, "web-bridge.gif"), { width: 820 });

  // full-page overview
  await page.evaluate(() => window.scrollTo(0, 0));
  await sleep(500);
  await page.screenshot({ path: join(MEDIA, "web-overview.png"), fullPage: true });
  console.log("web demo captured");
} finally {
  await browser.close();
}
