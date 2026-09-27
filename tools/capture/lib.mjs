import puppeteer from "puppeteer-core";
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT = join(dirname(fileURLToPath(import.meta.url)), "../..");
export const MEDIA = join(ROOT, "docs/media");
const CHROME = process.env.CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

export async function launch(width = 1100, height = 720) {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, defaultViewport: { width, height, deviceScaleFactor: 1 } });
  const page = await browser.newPage();
  await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }]);
  return { browser, page };
}

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Records viewport frames every `everyMs` while `fn` runs; returns frame dir. */
export async function record(page, fn, everyMs = 250) {
  const dir = mkdtempSync(join(tmpdir(), "frames-"));
  let i = 0, on = true;
  const loop = (async () => {
    while (on) {
      await page.screenshot({ path: join(dir, `f${String(i++).padStart(5, "0")}.png`) }).catch(() => {});
      await sleep(everyMs);
    }
  })();
  try { await fn(); } finally { on = false; await loop; }
  return { dir, fps: 1000 / everyMs };
}

/** Frames -> optimized GIF (palette per clip). `speed` > 1 plays faster than real time. */
export function toGif({ dir, fps }, out, { width = 900, speed = 1 } = {}) {
  const outFps = Math.min(12, fps * speed);
  const vf = `setpts=PTS/${speed},fps=${outFps},scale=${width}:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4`;
  execFileSync("ffmpeg", ["-y", "-loglevel", "error", "-framerate", String(fps), "-i", join(dir, "f%05d.png"), "-vf", vf, "-loop", "0", out]);
  rmSync(dir, { recursive: true, force: true });
  return out;
}

/** Click the first button whose text includes `label` (within an optional section). */
export async function clickText(page, label, scope = "body") {
  const ok = await page.evaluate((label, scope) => {
    const b = [...document.querySelector(scope).querySelectorAll("button")].find((x) => x.textContent.includes(label) && !x.disabled);
    if (!b) return false;
    b.scrollIntoView({ block: "center" });
    b.click();
    return true;
  }, label, scope);
  if (!ok) throw new Error(`button not found/enabled: ${label}`);
}

/** Wait until `text` appears anywhere in the page (bounded). */
export async function waitText(page, text, timeout = 30000) {
  await page.waitForFunction((t) => document.body.innerText.includes(t), { timeout, polling: 250 }, text);
}
