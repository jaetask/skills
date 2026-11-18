// Check one visual: text outside the visual or running out of its box. Saves <file>.png beside it to look at.
// Usage: node check.js visual.svg   (prints "no issues" and exits 0, or each fault and exits 1)
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const file = path.resolve(process.argv[2]);
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('file://' + file);
  const faults = await page.evaluate(() => {
    const svg = document.querySelector('svg'), vb = svg.viewBox.baseVal, out = [];
    const rects = [...svg.querySelectorAll('rect:not(.bg)')].map((r) => r.getBBox());
    svg.querySelectorAll('text').forEach((t) => {
      const bb = t.getBBox();
      if (bb.x < 0 || bb.x + bb.width > vb.width || bb.y < 0 || bb.y + bb.height > vb.height) out.push(`text outside the visual: ${t.textContent}`);
      const cx = bb.x + 2, cy = bb.y + bb.height / 2;
      const host = rects.find((r) => cx >= r.x && cx <= r.x + r.width && cy >= r.y && cy <= r.y + r.height && r.width > 20);
      if (host && bb.x + bb.width > host.x + host.width - 4) out.push(`text runs out of its box: ${t.textContent}`);
    });
    return out;
  });
  await page.locator('svg').screenshot({ path: file.replace(/\.svg$/, '') + '.png' });
  await browser.close();
  console.log(faults.join('\n') || 'no issues');
  process.exit(faults.length ? 1 : 0);
})();
