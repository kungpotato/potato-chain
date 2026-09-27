import { join } from "node:path";
import { launch, record, toGif, sleep, MEDIA } from "./lib.mjs";

const HTML = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  background: #090b10;
  padding: 18px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}
.window {
  width: 820px;
  background: #131720;
  border-radius: 10px;
  box-shadow: 0 16px 40px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.08);
  overflow: hidden;
}
.header {
  height: 36px;
  background: #1c212d;
  display: flex;
  align-items: center;
  padding: 0 14px;
  position: relative;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}
.dots {
  display: flex;
  gap: 8px;
}
.dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}
.dot.red { background: #ff5f56; }
.dot.yellow { background: #ffbd2e; }
.dot.green { background: #27c93f; }
.title {
  position: absolute;
  left: 0; right: 0;
  text-align: center;
  color: #8b949e;
  font-size: 13px;
  font-weight: 500;
  pointer-events: none;
}
.term-body {
  padding: 16px 20px 22px 20px;
  font-family: ui-monospace, "SF Mono", Menlo, Monaco, Consolas, monospace;
  font-size: 13px;
  line-height: 1.5;
  color: #c9d1d9;
  min-height: 240px;
  white-space: pre-wrap;
  word-break: break-all;
}
.prompt-line {
  margin-bottom: 6px;
}
.prompt-symbol {
  color: #58a6ff;
  font-weight: 600;
}
.prompt-dir {
  color: #7ee787;
  font-weight: 500;
}
.cmd {
  color: #ffffff;
  font-weight: 600;
}
.output {
  margin-top: 4px;
  margin-bottom: 8px;
}
.cursor {
  display: inline-block;
  width: 8px;
  height: 15px;
  background: #58a6ff;
  vertical-align: middle;
  margin-left: 2px;
}
</style>
</head>
<body>
  <div class="window">
    <div class="header">
      <div class="dots">
        <div class="dot red"></div>
        <div class="dot yellow"></div>
        <div class="dot green"></div>
      </div>
      <div class="title" id="term-title">potato-chain — zsh</div>
    </div>
    <div class="term-body" id="term-content"></div>
  </div>
  <script>
    window.term = {
      content: document.getElementById("term-content"),
      setTitle(t) { document.getElementById("term-title").innerText = t; },
      clear() { this.content.innerHTML = ""; },
      addPrompt(dir = "~/workspace/potato-chain") {
        const div = document.createElement("div");
        div.className = "prompt-line";
        div.innerHTML = '<span class="prompt-symbol">➜</span> <span class="prompt-dir">' + dir + '</span> <span class="prompt-symbol">(main)</span> <span class="cmd"></span><span class="cursor"></span>';
        this.content.appendChild(div);
        return div;
      },
      typeCommand(lineEl, text, speedMs = 30) {
        return new Promise((resolve) => {
          const cmdEl = lineEl.querySelector(".cmd");
          let i = 0;
          const interval = setInterval(() => {
            if (i < text.length) {
              cmdEl.textContent += text[i++];
            } else {
              clearInterval(interval);
              lineEl.querySelector(".cursor")?.remove();
              resolve();
            }
          }, speedMs);
        });
      },
      addOutput(html) {
        const div = document.createElement("div");
        div.className = "output";
        div.innerHTML = html;
        this.content.appendChild(div);
      }
    };
  </script>
</body>
</html>`;

export async function createTerminalRecorder() {
  const { browser, page } = await launch(860, 520);
  await page.setContent(HTML);
  return { browser, page };
}
