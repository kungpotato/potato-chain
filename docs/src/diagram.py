"""Tiny SVG builder: one diagram source -> widget SVG (theme classes) + PNG (hex colors).

Usage: python3 docs/src/<NN-name>.py        # writes docs/src/<NN-name>.svg + docs/<NN-name>.png
       python3 docs/src/<NN-name>.py widget # prints the widget SVG to stdout
"""
import os
import subprocess
import sys

RAMPS = {  # light-mode stops: fill(50), stroke(600), title(800), subtitle(600)
    "teal": ("#E1F5EE", "#0F6E56", "#085041", "#0F6E56"),
    "gray": ("#F1EFE8", "#5F5E5A", "#444441", "#5F5E5A"),
    "purple": ("#EEEDFE", "#534AB7", "#3C3489", "#534AB7"),
    "coral": ("#FAECE7", "#993C1D", "#712B13", "#993C1D"),
}
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


class Diagram:
    def __init__(self, name, height, title, desc, width=680):
        self.name, self.w, self.h, self.title, self.desc = name, width, height, title, desc
        self.parts = []

    def _txt(self, x, y, s, cls, mode, color, anchor="middle"):
        fill = "" if mode == "widget" else f' fill="{color}"'
        return f'<text class="{cls}" x="{x}" y="{y}" text-anchor="{anchor}"{fill}>{s}</text>'

    def box(self, x, y, w, h, title, sub=None, ramp="gray", small=False):
        def render(mode):
            f, s, t, u = RAMPS[ramp]
            cx = x + w / 2
            if mode == "widget":
                out = f'<g class="c-{ramp}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" stroke-width="0.5"/>'
            else:
                out = f'<g><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{f}" stroke="{s}" stroke-width="0.8"/>'
            if sub:
                out += self._txt(cx, y + h / 2 - 4, title, "th", mode, t)
                out += self._txt(cx, y + h / 2 + 14, sub, "ts", mode, u)
            else:
                out += self._txt(cx, y + h / 2 + 5, title, "ts" if small else "th", mode, t)
            return out + "</g>"
        self.parts.append(render)

    def text(self, x, y, s, cls="ts", anchor="start", color="#5F5E5A"):
        self.parts.append(lambda mode: self._txt(x, y, s, cls, mode, color, anchor))

    def line(self, x1, y1, x2, y2, color="#888780", dash=None, arrow=True):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        m = ' marker-end="url(#arrow)"' if arrow else ""
        self.parts.append(lambda mode: f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" '
                          f'stroke-width="{0.5 if mode == "widget" else 1}"{d}{m}/>')

    def frame(self, x, y, w, h, dash="5 4", color="#888780"):
        self.parts.append(lambda mode: f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="none" '
                          f'stroke="{color}" stroke-width="{0.5 if mode == "widget" else 0.8}" stroke-dasharray="{dash}"/>')

    def svg(self, mode):
        defs = ('<defs><marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" '
                'orient="auto-start-reverse"><path d="M2 1L8 5L2 9" fill="none" stroke="context-stroke" '
                'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></marker></defs>')
        body = "".join(p(mode) for p in self.parts)
        if mode == "widget":
            return (f'<svg width="100%" viewBox="0 0 {self.w} {self.h}" role="img"><title>{self.title}</title>'
                    f'<desc>{self.desc}</desc>{defs}{body}</svg>')
        style = ('<style>text{font-family:-apple-system,"Sukhumvit Set","Thonburi",sans-serif}'
                 '.th{font-size:14px;font-weight:500}.ts{font-size:12px}</style>')
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" width="{self.w}" '
                f'height="{self.h}">{style}{defs}<rect width="100%" height="100%" fill="#FFFFFF"/>{body}</svg>')

    def main(self):
        if len(sys.argv) > 1 and sys.argv[1] == "widget":
            print(self.svg("widget"))
            return
        src = os.path.dirname(os.path.abspath(__file__))
        svg_path = os.path.join(src, f"{self.name}.svg")
        png_path = os.path.join(os.path.dirname(src), f"{self.name}.png")
        with open(svg_path, "w") as fh:
            fh.write(self.svg("png"))
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        "--force-device-scale-factor=2", f"--window-size={self.w},{self.h}",
                        f"--screenshot={png_path}", f"file://{svg_path}"],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(png_path)
