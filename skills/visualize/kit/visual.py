#!/usr/bin/env python3
"""One visual, one idea. Import the helpers or run this file for an example:

    from visual import text, box, path, svg
    Path("flow.svg").write_text(svg(640, 220, box(...) + path(...), "A flow that ..."))

Box classes: n plain, s context (grey), f result (accent), o open (dashed).
Text classes: t ink, m muted, a accent. Light and dark come from the viewer's setting.
"""
import html
import sys
from pathlib import Path

esc = html.escape


def text(x, y, s, size=13, weight=400, cls="m", anchor="start"):
    return f'<text x="{x}" y="{y}" class="{cls}" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}">{esc(s)}</text>'


def box(x, y, w, h, cls, lines, pad=12):
    """lines: [(text, size, weight, text_class), ...] stacked from the top."""
    out = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" class="{cls}"/>']
    cy = y + pad + 11
    for s, size, weight, tcls in lines:
        out.append(text(x + pad, cy, s, size, weight, tcls))
        cy += size + 7
    return "".join(out)


def path(d, accent=False, dashed=False):
    dash = ' stroke-dasharray="4 4"' if dashed else ""
    return f'<path d="{d}" class="{"ea" if accent else "e"}"{dash} marker-end="url(#{"ha" if accent else "h"})"/>'


STYLE = """<style>
svg { --paper:#fff; --ink:#0a0a0a; --muted:#525252; --accent:#0000ff; --tint:rgba(0,0,255,.05); --fill:rgba(10,10,10,.05); --line:rgba(10,10,10,.3);
  font-family: system-ui, -apple-system, 'Segoe UI', sans-serif }
@media (prefers-color-scheme: dark) { svg { --paper:#0d0d10; --ink:#f2f2f2; --muted:#a3a3a3; --accent:#8894ff; --tint:rgba(136,148,255,.12); --fill:rgba(255,255,255,.06); --line:rgba(255,255,255,.3) } }
.bg { fill: var(--paper) }
.n { fill: var(--paper); stroke: var(--ink) } .s { fill: var(--fill); stroke: var(--line) }
.f { fill: var(--tint); stroke: var(--accent); stroke-width: 1.2 } .o { fill: var(--paper); stroke: var(--ink); stroke-dasharray: 5 4 }
.t { fill: var(--ink) } .m { fill: var(--muted) } .a { fill: var(--accent) }
.e { stroke: var(--ink); stroke-width: 1.2; fill: none } .ea { stroke: var(--accent); stroke-width: 1.4; fill: none }
.hm { fill: var(--ink) } .ham { fill: var(--accent) }
</style>"""

DEFS = """<defs>
<marker id="h" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="hm"/></marker>
<marker id="ha" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="ham"/></marker>
</defs>"""


def svg(w, h, body, label):
    """A standalone SVG. label is the accessible description: write it as a sentence."""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-label="{esc(label)}">'
            f'{STYLE}{DEFS}<rect class="bg" width="{w}" height="{h}"/>{body}</svg>')


def example():
    b = box(20, 20, 260, 48, "n", [("1  Measure it", 12, 700, "t"), ("in its own units", 11, 400, "m")])
    b += path("M150,68 L150,92")
    b += box(20, 96, 260, 48, "o", [("2  Above the threshold?", 12, 700, "t"), ("dashed: still to measure", 11, 400, "m")])
    b += path("M150,144 L150,168") + text(158, 162, "no", 10, 700, "m")
    b += box(20, 172, 260, 44, "f", [("Keep the default", 12, 700, "a")])
    b += path("M280,120 L330,120") + text(305, 112, "yes", 10, 700, "m", "middle")
    b += box(334, 96, 160, 48, "f", [("Switch", 12, 700, "a"), ("it has to earn it", 11, 400, "m")])
    b += box(520, 20, 200, 124, "s", [("Worked example", 12, 700, "a"), ("A 400k, B 900k = 2.25x", 11, 400, "m"), ("stays on A", 11, 700, "t"), ("simulated", 11, 400, "m")])
    return svg(740, 236, b, "Measure, compare with a threshold, then keep the default or switch, with a worked example.")


if __name__ == "__main__":
    Path(sys.argv[1] if len(sys.argv) > 1 else "example.svg").write_text(example())
