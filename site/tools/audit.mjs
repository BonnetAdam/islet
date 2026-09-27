// Checks the website the way a visitor meets it, at four sizes, under the production headers of vercel.json:
// console errors, CSP violations, failed requests, images that did not load, horizontal overflow and text that
// overflows its box. Screenshots of every section (and of each demo state) go to site/.shots/.
// Usage: node tools/audit.mjs [--only desktop|laptop|tablet|phone] [--no-shots]
import { mkdir, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { parseArgs } from 'node:util';
import { setTimeout as sleep } from 'node:timers/promises';
import { launchChrome } from './cdp.mjs';
import { SITE_DIR, startServer } from './serve.mjs';

const SIZES = {
  desktop: { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false },
  laptop: { width: 1024, height: 700, deviceScaleFactor: 1, mobile: false },
  tablet: { width: 820, height: 1180, deviceScaleFactor: 1, mobile: true },
  phone: { width: 390, height: 844, deviceScaleFactor: 2, mobile: true },
};
const SECTIONS = ['top', 'how', 'features', 'agents', 'airpods', 'app', 'your-mac', 'compare', 'privacy', 'open-source', 'faq', 'download'];

const { values } = parseArgs({ options: { only: { type: 'string' }, 'no-shots': { type: 'boolean' } } });
const SHOTS = join(SITE_DIR, '.shots');
if (!values['no-shots']) { await rm(SHOTS, { recursive: true, force: true }); await mkdir(SHOTS, { recursive: true }); }

// Everything measured inside the page: returns a list of problems.
const INSPECT = `(() => {
  const out = [];
  const doc = document.documentElement;
  if (doc.scrollWidth > innerWidth + 1) out.push('page scrolls sideways: ' + doc.scrollWidth + ' > ' + innerWidth);
  for (const img of document.images) {
    if (img.complete && img.naturalWidth === 0) out.push('image did not load: ' + img.getAttribute('src'));
  }
  const wide = [];
  for (const el of document.querySelectorAll('body *')) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 || getComputedStyle(el).position === 'fixed') continue;
    if (r.right > innerWidth + 1 && !el.closest('.table-card') && !el.closest('.mac')) wide.push(el.tagName.toLowerCase() + (el.className ? '.' + String(el.className).split(' ')[0] : '') + ' right=' + Math.round(r.right));
    if (['P', 'H1', 'H2', 'H3', 'A', 'BUTTON', 'SPAN', 'LI', 'SUMMARY'].includes(el.tagName) && el.scrollWidth > el.clientWidth + 1 && getComputedStyle(el).overflow !== 'visible' && !el.classList.contains('visually-hidden')) out.push('text clipped: ' + el.tagName + ' ' + el.textContent.trim().slice(0, 40));
  }
  if (wide.length) out.push('past the right edge: ' + [...new Set(wide)].slice(0, 6).join(', '));
  out.push(...window.__islet.csp.map((c) => 'CSP: ' + c), ...window.__islet.errors.map((e) => 'error: ' + e));
  return out;
})()`;

const server = await startServer();
const chrome = await launchChrome();
let failures = 0;
try {
  for (const [name, size] of Object.entries(SIZES)) {
    if (values.only && values.only !== name) continue;
    const page = await chrome.newPage(size);
    await page.goto(server.url + '/');
    await sleep(1200);
    const problems = [...(await page.evaluate(INSPECT)), ...page.problems];
    for (const t of page.transfers()) if (t.status >= 400) problems.push(`HTTP ${t.status}: ${t.url}`);
    const bytes = page.transfers().reduce((sum, t) => sum + t.bytes, 0);
    console.log(`${name} ${size.width}x${size.height}: ${problems.length ? problems.length + ' problem(s)' : 'clean'}, ${Math.round(bytes / 1024)} KB transferred`);
    for (const p of problems) console.log('  - ' + p);
    failures += problems.length;
    if (!values['no-shots']) {
      // Each demo state on the hero, then every section from its top.
      const states = await page.evaluate(`[...document.querySelectorAll('.demo-chips .chip')].map((c) => c.dataset.state)`);
      for (const state of states) {
        await page.evaluate(`document.querySelector('.demo-chips .chip[data-state="${state}"]').click(); scrollTo(0, 0)`);
        await sleep(900);
        await page.screenshot(join(SHOTS, `${name}-hero-${state}.png`));
      }
      for (const id of SECTIONS) {
        await page.evaluate(`document.getElementById('${id}').scrollIntoView({ block: 'start', behavior: 'instant' })`);
        await sleep(350);
        await page.screenshot(join(SHOTS, `${name}-${id}.png`));
      }
      await page.evaluate(`scrollTo(0, document.documentElement.scrollHeight)`);
      await sleep(350);
      await page.screenshot(join(SHOTS, `${name}-footer.png`));
    }
    await page.close();
  }
} finally {
  await chrome.close();
  await server.close();
}
process.exitCode = failures ? 1 : 0;
