import { join } from "node:path";
import { record, toGif, sleep, MEDIA } from "./lib.mjs";
import { createTerminalRecorder } from "./terminal-lib.mjs";

async function recordScenario(title, commands, outFile, { height = 540, width = 860, speed = 1.2 } = {}) {
  const { browser, page } = await createTerminalRecorder();
  try {
    await page.evaluate((t) => window.term.setTitle(t), title);
    
    const rec = await record(page, async () => {
      await sleep(600);
      for (const item of commands) {
        // create prompt
        await page.evaluate((dir) => {
          window._curLine = window.term.addPrompt(dir);
        }, item.dir ?? "~/workspace/potato-chain");
        await sleep(300);

        // type command
        await page.evaluate((cmd) => {
          return window.term.typeCommand(window._curLine, cmd, 20);
        }, item.cmd);
        await sleep(400);

        // stream or add output lines
        for (const out of item.outputs) {
          await page.evaluate((html) => {
            window.term.addOutput(html);
            window.scrollTo(0, document.body.scrollHeight);
          }, out.html);
          await sleep(out.delay ?? 250);
        }
        await sleep(800);
      }
      await sleep(1500); // hold on end
    }, 200);

    toGif(rec, join(MEDIA, outFile), { width, speed });
    console.log("Recorded", outFile);
  } finally {
    await browser.close();
  }
}

// 1. cli-smoke.gif
await recordScenario("potato-chain — make smoke", [
  {
    cmd: "make smoke",
    outputs: [
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">chain-id 707070</span>', delay: 250 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">blocks advancing (4506 -&gt; 4508)</span>', delay: 350 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">preinstall Create2 has code</span>', delay: 150 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">preinstall Multicall3 has code</span>', delay: 150 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">preinstall Permit2 has code</span>', delay: 150 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">preinstall SafeFactory has code</span>', delay: 150 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">transfer 1 POTATO dev0 -&gt; 0xC9A15504c19f... (block 4509)</span>', delay: 350 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">cosmos bank sees potato1exs42pxp... = 1 POTATO</span>', delay: 250 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">deploy Counter at 0xe78660160dF1484ffC1F4Ca539a82ee10AC6D1C6</span>', delay: 400 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">increment() -&gt; number() == 1</span>', delay: 300 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">eth_getLogs sees exactly 1 Incremented event</span>', delay: 300 },
      { html: '<span style="color:#58a6ff; font-weight:600">smoke test passed</span>', delay: 100 }
    ]
  }
], "cli-smoke.gif");

// 2. cli-forge.gif
await recordScenario("potato-chain/contracts — forge test", [
  {
    dir: "~/workspace/potato-chain/contracts",
    cmd: "forge test",
    outputs: [
      { html: '<span style="color:#8b949e">[⠊] Compiling...</span>', delay: 300 },
      { html: '<span style="color:#8b949e">Compiler run successful!</span>', delay: 200 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">Ran 3 tests for test/MockUSDC.t.sol:MockUSDCTest</span><br>' +
              '<span style="color:#3fb950">[PASS]</span> test_OwnerCanMint()<br>' +
              '<span style="color:#3fb950">[PASS]</span> test_RevertWhen_NonOwnerMints()<br>' +
              '<span style="color:#3fb950">[PASS]</span> test_SixDecimals()<br>' +
              '<span style="color:#8b949e">Suite result: ok. 3 passed; 0 failed</span>', delay: 300 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">Ran 6 tests for test/Oracle.t.sol:OracleTest</span><br>' +
              '<span style="color:#3fb950">[PASS]</span> test_ReadsFreshPrice()<br>' +
              '<span style="color:#3fb950">[PASS]</span> test_RoundIdIncrementsAndHistoryKept()<br>' +
              '<span style="color:#8b949e">Suite result: ok. 6 passed; 0 failed</span>', delay: 300 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">Ran 7 tests for test/Lending.t.sol:LendingTest</span><br>' +
              '<span style="color:#3fb950">[PASS]</span> test_BorrowUpToLltv()<br>' +
              '<span style="color:#3fb950">[PASS]</span> test_LiquidateAfterPriceDrop()<br>' +
              '<span style="color:#8b949e">Suite result: ok. 7 passed; 0 failed</span>', delay: 300 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">Ran 4 tests for test/PotatoBridge.t.sol:PotatoBridgeTest</span><br>' +
              '<span style="color:#3fb950">[PASS]</span> test_BridgesMsgValueWithContractAsSender()<br>' +
              '<span style="color:#8b949e">Suite result: ok. 4 passed; 0 failed</span>', delay: 250 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">Ran 2 tests for test/UniswapV2.t.sol:UniswapV2Test</span><br>' +
              '<span style="color:#3fb950">[PASS]</span> test_AddLiquidityThenSwap()<br>' +
              '<span style="color:#3fb950">[PASS]</span> test_InitCodeHashMatchesCompiledPair()<br>' +
              '<span style="color:#8b949e">Suite result: ok. 2 passed; 0 failed</span>', delay: 250 },
      { html: '<br><span style="color:#3fb950; font-weight:bold">Ran 5 test suites: 22 tests passed, 0 failed, 0 skipped (22 total tests)</span>', delay: 100 }
    ]
  }
], "cli-forge.gif");

// 3. cli-bft.gif
await recordScenario("potato-chain — CometBFT Fault Tolerance", [
  {
    cmd: "curl -s localhost:26657/status | jq .result.sync_info.latest_block_height",
    outputs: [
      { html: '<span style="color:#79c0ff">"4520"</span>', delay: 400 }
    ]
  },
  {
    cmd: "docker stop potato-node3",
    outputs: [
      { html: '<span style="color:#8b949e">potato-node3</span>', delay: 600 },
      { html: '<span style="color:#e3b341">ℹ node3 offline (3 of 4 validators remaining: 75% voting power &gt; 2/3 BFT threshold)</span>', delay: 400 }
    ]
  },
  {
    cmd: "curl -s localhost:26657/status | jq .result.sync_info.latest_block_height",
    outputs: [
      { html: '<span style="color:#3fb950; font-weight:600">"4524"  # blocks keep producing without disruption!</span>', delay: 500 }
    ]
  },
  {
    cmd: "docker start potato-node3",
    outputs: [
      { html: '<span style="color:#8b949e">potato-node3</span>', delay: 500 },
      { html: '<span style="color:#3fb950">✔ node3 reconnected and caught up with consensus</span>', delay: 200 }
    ]
  }
], "cli-bft.gif");

// 4. cli-ibc.gif
await recordScenario("potato-chain — make smoke-ibc", [
  {
    cmd: "make smoke-ibc",
    outputs: [
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">potato -&gt; gaia: voucher ibc/6B1A5F478E1... minted</span>', delay: 400 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">  voucher amount +1 POTATO</span>', delay: 200 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">gaia -&gt; potato: 1 POTATO unescrowed to dev0 (EVM balance)</span>', delay: 450 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">voucher burned back to previous amount</span>', delay: 250 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">EVM (A): EOA -&gt; ICS-20 precompile 0x0802 -&gt; gaia</span>', delay: 450 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">EVM (B): PotatoBridge.bridge{value} -&gt; gaia</span>', delay: 400 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">  bridge keeps no balance (all escrowed)</span>', delay: 200 },
      { html: '<span style="color:#58a6ff; font-weight:600">ibc smoke test passed</span>', delay: 100 }
    ]
  }
], "cli-ibc.gif");

// 5. cli-upgrade.gif (recorded drill)
await recordScenario("potato-chain — make upgrade-drill", [
  {
    cmd: "make upgrade-drill",
    outputs: [
      { html: '<span style="color:#79c0ff; font-weight:600">== 1. propose potato-v2</span><br>' +
              '<span style="color:#c9d1d9">proposal #1, upgrade height 3005 (now 2935)</span>', delay: 450 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">== 2. vote yes from 4 validators</span><br>' +
              '<span style="color:#3fb950">val0..3 votes submitted</span>', delay: 400 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">== 3. wait for voting period (30s)</span><br>' +
              '<span style="color:#3fb950">passed; scheduled plan: {"height":3005,"name":"potato-v2"}</span>', delay: 450 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">== 4. wait for the chain to halt at 3005</span><br>' +
              '<span style="color:#e3b341">halted: last committed block 3005; every node logs UPGRADE "potato-v2" NEEDED</span><br>' +
              '<span style="color:#8b949e">  node0..3 UPGRADE "potato-v2" NEEDED: 1 times</span>', delay: 500 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">== 5. swap binary: recreate containers on potato-chain/potatod:v2</span><br>' +
              '<span style="color:#8b949e">Recreating potato-node0..3 ... done</span>', delay: 450 },
      { html: '<br><span style="color:#79c0ff; font-weight:600">== 6. verify</span><br>' +
              '<span style="color:#3fb950">resumed at 3006; applied potato-v2 at height 3005; block gasLimit 30000000</span><br>' +
              '<span style="color:#58a6ff; font-weight:600">upgrade drill passed</span>', delay: 100 }
    ]
  }
], "cli-upgrade.gif");

// 6. cli-dex.gif
await recordScenario("potato-chain — make smoke-dex", [
  {
    cmd: "make smoke-dex",
    outputs: [
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">swap 1 POTATO -&gt; 1861783 USDC-units (quoted 1861783)</span>', delay: 350 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">swap USDC back -&gt; native POTATO received</span>', delay: 350 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">pair native balance == WPOTATO reserve (103024510738568466332)</span>', delay: 250 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">router holds no native dust</span>', delay: 200 },
      { html: '<span style="color:#58a6ff; font-weight:600">dex smoke test passed</span>', delay: 100 }
    ]
  }
], "cli-dex.gif");

// 7. cli-lending.gif
await recordScenario("potato-chain — make smoke-lending", [
  {
    cmd: "make smoke-lending",
    outputs: [
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">supplyCollateral 100 WPOTATO (precompile transferFrom)</span>', delay: 350 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">borrow 160 USDC (80% &gt; LLTV) reverts</span>', delay: 300 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">borrow 150 USDC at 75% LTV</span>', delay: 350 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">liquidate after drop to $1.80: 10 POTATO seized</span>', delay: 400 },
      { html: '<span style="color:#3fb950; font-weight:600">  ok  </span> <span style="color:#c9d1d9">  liquidator received native POTATO (minus gas)</span>', delay: 250 },
      { html: '<span style="color:#58a6ff; font-weight:600">lending smoke test passed</span>', delay: 100 }
    ]
  }
], "cli-lending.gif");

console.log("All terminal GIFs recorded successfully!");
