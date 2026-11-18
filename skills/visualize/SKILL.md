---
name: visualize
description: Draw one clear visual of one thing: a flow, a before and after, two options, a timeline. Use for /visualize, or when a picture explains faster than text.
---

# Visualize

A visual shows what you understood. A wrong one shows it at once.

- **One idea.** Ten boxes or fewer.
- **Mechanism, not system.** A flow with its yes and no branches, a before and after, two options side by side, or a timeline.
- **Worked example.** Real numbers, with their source. Mark invented ones "simulated".
- **Status.** Decided, proposed or open. Dashed for unknowns; accent on the result only.
- **Plain words.** Box titles of three to six words.

1. Draw it with [kit/visual.py](kit/visual.py).
2. Run `node kit/check.js <file>.svg` until it prints "no issues", then look at the screenshot it saves.
3. Return the SVG path and one line on what it shows.

Needs Python 3; the check needs Node and Playwright.
